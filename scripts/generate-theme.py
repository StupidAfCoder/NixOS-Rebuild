#!/usr/bin/env python3
"""
Same generation backend Caelestia itself uses (materialyoucolor -- the
real Google material-color-utilities port, driven through the actual
MaterialDynamicColors role system), not matugen's CLI wrapper around it.

Usage: generate-theme.py <image> <dark|light> [contrast_level 0.0-1.0]
Writes colors.json (bar), colors.lua (Hyprland) from one shared scheme.
"""
import hashlib
import json
import math
import os
import sys
import tempfile
from pathlib import Path

from PIL import Image
from materialyoucolor.dislike.dislike_analyzer import DislikeAnalyzer
from materialyoucolor.dynamiccolor.material_dynamic_colors import MaterialDynamicColors
from materialyoucolor.hct import Hct
from materialyoucolor.quantize import ImageQuantizeCelebi
from materialyoucolor.scheme.scheme_vibrant import SchemeVibrant
from materialyoucolor.scheme.scheme_monochrome import SchemeMonochrome

OUT_PATH = Path.home() / ".nixos_dotfiles/quickshell/bar/theme/colors.json"
HYPR_OUT = Path.home() / ".nixos_dotfiles/hypr/colors.lua"

ROLE_MAP = {
    "primary": "accent", "onPrimary": "on_accent",
    "error": "error", "onError": "on_error",
    "background": "background", "onBackground": "on_background",
    "surface": "surface", "onSurface": "on_surface",
    "surfaceVariant": "surface_variant", "onSurfaceVariant": "on_surface_variant",
    "surfaceContainerLow": "surface_container_low",
    "surfaceContainer": "surface_container",
    "surfaceContainerHigh": "surface_container_high",
    "outline": "outline", "outlineVariant": "outline_variant",
    "shadow": "shadow",
}

MIN_DARK_TONE = 16
SURFACE_ROLES = {
    "background", "surface", "surfaceContainerLow",
    "surfaceContainer", "surfaceContainerHigh", "surfaceVariant",
}

# Checked against the RAW candidates, before DislikeAnalyzer runs -- Dislike
# fixup can inflate a near-zero-chroma color just enough to dodge this check,
# which is why the first version of this fix silently never fired.
GRAYSCALE_CHROMA_THRESHOLD = 8.0
GRAYSCALE_BOOST_CHROMA = 36.0
GRAYSCALE_BOOST_CHROMA_SECONDARY = 28.0
GRAYSCALE_HUE_SPLIT = 40.0

# Below this chroma, a pixel's HCT hue is essentially rounding noise, not
# real color. sRGB values near pure black/white don't map to one exact hue
# in HCT -- tiny compression/antialiasing residue in the R/G/B channels
# (e.g. (2,3,6) instead of (0,0,0)) gets amplified into a hue angle by the
# conversion even though a human would call the pixel "black". This is the
# actual root cause of the blue-tinted fallback: black-and-white images are
# MOSTLY near-black and near-white pixels, so weighting the hue average by
# population let this noise dominate and consistently drag the average
# toward whatever hue black-ish rounding artifacts happen to land on
# (blue, in practice, for most JPEG/PNG encoders).
MIN_TRUSTED_CHROMA = 4.0

# SchemeVibrant is designed to always force a saturated palette regardless
# of how little chroma the source color carries -- it will NOT pass a
# chroma-0 gray through as gray. So a true-neutral source (nothing in the
# image cleared the trust threshold) needs to route through SchemeMonochrome
# instead, which is the library's dedicated tone-only scheme.
#
# Earlier version of this detected "neutral" by re-checking the resulting
# Hct's chroma against a threshold -- fragile, because Hct.from_hct(hue,
# 0.0, tone) does NOT round-trip back to chroma=0 (HCT has to gamut-map
# through 8-bit sRGB and recompute chroma from that quantized int, leaving
# residual chroma as high as ~2.8 depending on tone). Rather than chase
# that noise floor with a threshold, grayscale_fallback now hands back an
# explicit `is_true_neutral` flag alongside the colors, so the caller never
# has to reverse-engineer intent from a lossy round-tripped number.

# SchemeMonochrome hardcodes chroma=0 into every single role it computes,
# regardless of the hue/chroma fed in as the source color -- confirmed by
# reading the library source directly. That means once the *scheme* is
# monochrome, no amount of tinting the input changes the output, and every
# true-grayscale wallpaper collapses to the exact same palette family.
# To let different B&W wallpapers still feel distinct, we keep the base
# UI (background/surface/etc, still generated via SchemeMonochrome) fully
# neutral, but hand-compute a small, deterministic tint for just the
# accent role -- seeded from a hash of the image's own pixel data, so the
# same wallpaper always gets the same tint and different wallpapers land
# on different hues. Set ENABLE_NEUTRAL_TINT = False to go back to pure
# gray-on-gray for every grayscale wallpaper.
ENABLE_NEUTRAL_TINT = True
NEUTRAL_TINT_CHROMA = 24.0
NEUTRAL_TINT_CHROMA_SECONDARY = 16.0

# Set via env var (THEME_DEBUG=1 python generate-theme.py ...) or the
# --debug-candidates CLI flag. Dumps the actual candidate hues that
# score_image considered -- their hue/chroma/tone AND what fraction of
# the image's pixels shared that hue -- before any of it gets collapsed
# into a single "primary"/"secondary" pair and baked into roles. Useful
# for seeing *why* a given wallpaper landed on the palette it did.
DEBUG_CANDIDATES = os.environ.get("THEME_DEBUG") == "1"


def make_thumbnail(image_path: str) -> str:
    img = Image.open(image_path).convert("RGB")
    img.thumbnail((128, 128), Image.Resampling.NEAREST)
    tmp = tempfile.NamedTemporaryFile(suffix=".jpg", delete=False)
    img.save(tmp.name, "JPEG", quality=90)
    return tmp.name


def weighted_average_hue(pixels: dict, min_chroma: float = MIN_TRUSTED_CHROMA):
    """Population-weighted average hue and chroma, computed ONLY from
    pixels that carry real chroma. Returns None if nothing in the image
    clears the trust threshold -- i.e. the image has no actual color
    signal to theme from at all, as opposed to just being dark/light.
    """
    sx = sy = total = chroma_total = 0.0
    for rgb, population in pixels.items():
        hct = Hct.from_int(rgb)
        if hct.chroma < min_chroma:
            continue
        rad = math.radians(hct.hue)
        sx += math.cos(rad) * population
        sy += math.sin(rad) * population
        chroma_total += hct.chroma * population
        total += population
    if total == 0:
        return None
    avg_hue = math.degrees(math.atan2(sy, sx)) % 360
    avg_chroma = chroma_total / total
    return avg_hue, avg_chroma


def seeded_neutral_hue(pixels: dict) -> float:
    """Deterministic pseudo-random hue in [0, 360) derived from the image's
    own quantized pixel data. Same wallpaper -> same hue every run (no
    randomness, no dependence on system clock/PID). Different wallpapers
    -> essentially uncorrelated hues, even if both are pure grayscale and
    therefore carry zero real chroma signal of their own to seed from.
    """
    key = ",".join(f"{rgb}:{pop}" for rgb, pop in sorted(pixels.items()))
    digest = hashlib.sha256(key.encode()).digest()
    return (int.from_bytes(digest[:4], "big") % 3600) / 10.0


def grayscale_fallback(pixels: dict, hues: list[Hct]) -> tuple[list[Hct], bool]:
    tone_a = hues[0].tone
    tone_b = min(100, tone_a + 15) if len(hues) < 2 else hues[-1].tone

    trusted = weighted_average_hue(pixels)

    if trusted is None:
        # No pixel in the whole image cleared the chroma trust threshold --
        # this is a genuinely monochrome image (like a black-and-white
        # manga panel), not just a dark or desaturated photo. There is no
        # real color to theme from. The base UI (background/surface/etc)
        # stays properly neutral either way -- that part is non-negotiable
        # for readability -- but if ENABLE_NEUTRAL_TINT is on, we still
        # hand back a small, image-seeded hue so this wallpaper's accent
        # doesn't look identical to every other B&W wallpaper's accent.
        print("[theme] no trusted chroma found, using neutral (non-color) scheme", file=sys.stderr)
        if not ENABLE_NEUTRAL_TINT:
            return [
                Hct.from_hct(0.0, 0.0, tone_a),
                Hct.from_hct(0.0, 0.0, tone_b),
            ], True

        seed_hue = seeded_neutral_hue(pixels)
        print(f"[theme] neutral tint seed_hue={seed_hue:.1f}", file=sys.stderr)
        return [
            Hct.from_hct(seed_hue, NEUTRAL_TINT_CHROMA, tone_a),
            Hct.from_hct((seed_hue + GRAYSCALE_HUE_SPLIT) % 360, NEUTRAL_TINT_CHROMA_SECONDARY, tone_b),
        ], True

    avg_hue, avg_chroma = trusted
    # Scale the boost to how much real color was actually found instead of
    # always slamming to a fixed high chroma -- a wallpaper with a faint
    # tint should end up with a faint accent, not a loud, unrelated one.
    boost = min(GRAYSCALE_BOOST_CHROMA, max(avg_chroma * 2.5, 12.0))
    boost_secondary = min(GRAYSCALE_BOOST_CHROMA_SECONDARY, boost * 0.78)

    print(f"[theme] trusted hue={avg_hue:.1f} avg_chroma={avg_chroma:.1f} boost={boost:.1f}", file=sys.stderr)

    return [
        Hct.from_hct(avg_hue, boost, tone_a),
        Hct.from_hct((avg_hue + GRAYSCALE_HUE_SPLIT) % 360, boost_secondary, tone_b),
    ], False


def score_image(image_path: str) -> tuple[list[Hct], bool]:
    thumb = make_thumbnail(image_path)
    pixels = ImageQuantizeCelebi(thumb, 1, 128)

    hue_population = [0] * 360
    population_sum = 0
    colors_hct = []
    for rgb, population in pixels.items():
        hct = Hct.from_int(rgb)
        colors_hct.append(hct)
        hue_population[int(hct.hue)] += population
        population_sum += population

    hue_excited = [0.0] * 360
    for hue in range(360):
        proportion = hue_population[hue] / population_sum
        for i in range(hue - 14, hue + 16):
            hue_excited[i % 360] += proportion

    TARGET_CHROMA, W_PROP, W_ABOVE, W_BELOW = 48.0, 0.7, 0.3, 0.1
    scored = []
    for hct in colors_hct:
        hue = round(hct.hue) % 360
        proportion_score = hue_excited[hue] * 100.0 * W_PROP
        w = W_BELOW if hct.chroma < TARGET_CHROMA else W_ABOVE
        chroma_score = (hct.chroma - TARGET_CHROMA) * w
        scored.append((proportion_score + chroma_score, hct, hue_excited[hue]))
    scored.sort(key=lambda x: x[0], reverse=True)

    if DEBUG_CANDIDATES:
        print("[theme:debug] top 10 scored candidates (score, hue, chroma, tone, coverage%):", file=sys.stderr)
        for score, hct, coverage in scored[:10]:
            print(
                f"[theme:debug]   score={score:7.2f}  hue={hct.hue:6.1f}  "
                f"chroma={hct.chroma:5.1f}  tone={hct.tone:5.1f}  coverage={coverage * 100:5.1f}%",
                file=sys.stderr,
            )

    candidates = []
    for cutoff in range(20, -1, -1):
        for score, hct, coverage in scored:
            if hct.chroma > cutoff and hct.tone > cutoff * 3:
                candidates.append(hct)
        if len(candidates) >= 5:
            break
    if not candidates:
        candidates = [scored[0][1]]

    distinct = []
    for hct in candidates:
        if all(abs(hct.hue - d.hue) > 25 for d in distinct):
            distinct.append(hct)
        if len(distinct) >= 4:
            break
    if not distinct:
        distinct = [scored[0][1]]

    # `distinct` up to here is still in population-score order (coverage-
    # weighted), inherited from `candidates`/`scored`. That's fine for
    # deciding WHICH hues are even in the running (the chroma/tone cutoff
    # above already did that job), but leaving it in that order means the
    # hue with the most pixel coverage becomes `hues[0]` (-> primary ->
    # the accent role) even when a shortlisted rival is far more vivid --
    # e.g. large-area foliage beating a small saturated robe/subject that
    # a human eye would actually call "the color" of the image. Re-sort
    # by chroma so the most saturated shortlisted hue wins the primary
    # slot; coverage still decided the shortlist, saliency now decides
    # the winner within it.
    distinct.sort(key=lambda h: h.chroma, reverse=True)

    if DEBUG_CANDIDATES:
        print("[theme:debug] final distinct hues chosen (before grayscale check):", file=sys.stderr)
        for hct in distinct:
            print(f"[theme:debug]   hue={hct.hue:6.1f}  chroma={hct.chroma:5.1f}  tone={hct.tone:5.1f}", file=sys.stderr)

    raw_max_chroma = max(h.chroma for h in distinct)
    is_true_neutral = False
    if raw_max_chroma < GRAYSCALE_CHROMA_THRESHOLD:
        print(f"[theme] grayscale detected, raw max chroma={raw_max_chroma:.1f}", file=sys.stderr)
        distinct, is_true_neutral = grayscale_fallback(pixels, distinct)
    else:
        print(f"[theme] not grayscale, raw max chroma={raw_max_chroma:.1f}", file=sys.stderr)

    result = [DislikeAnalyzer.fix_if_disliked(h) for h in distinct]
    return result, is_true_neutral


def write_hypr_colors(by_name, scheme, primary_hex_override: str | None = None):
    def hex6(role):
        return f"{by_name[role].get_hct(scheme).to_int() & 0xFFFFFF:06x}"

    active_border_hex = primary_hex_override or hex6("primary")

    HYPR_OUT.parent.mkdir(parents=True, exist_ok=True)
    HYPR_OUT.write_text(
        "return {\n"
        f'    active_border = "rgba({active_border_hex}cc)",\n'
        f'    inactive_border = "rgba({hex6("outlineVariant")}40)",\n'
        f'    background = "0x{hex6("shadow")}",\n'
        "}\n"
    )


def gen_colors(image_path: str, mode: str, contrast_level: float) -> dict:
    is_dark = mode == "dark"
    hues, is_true_neutral = score_image(image_path)
    primary = hues[0]
    secondary = hues[1] if len(hues) > 1 else primary

    # SchemeVibrant forces saturation onto whatever it's given, so a true
    # neutral source (produced by grayscale_fallback's no-trusted-chroma
    # branch) comes out re-colored via hue rounding noise instead of
    # staying gray. SchemeMonochrome is materialyoucolor's dedicated
    # tone-only scheme and is what actually keeps the base UI neutral.
    scheme_cls = SchemeMonochrome if is_true_neutral else SchemeVibrant
    scheme = scheme_cls(source_color_hct=primary, is_dark=is_dark, contrast_level=contrast_level)

    if is_true_neutral:
        print("[theme] using SchemeMonochrome (neutral source)", file=sys.stderr)

    dyn = MaterialDynamicColors()
    by_name = {c.name: c for c in dyn.all_colors}

    out = {}
    for role, key in ROLE_MAP.items():
        hct = by_name[role].get_hct(scheme)
        if is_dark and role in SURFACE_ROLES and hct.tone < MIN_DARK_TONE:
            hct = Hct.from_hct(hct.hue, hct.chroma, MIN_DARK_TONE)
        out[key] = f"#{hct.to_int() & 0xFFFFFF:06x}"

    # SchemeMonochrome hardcodes chroma=0 into EVERY role, including
    # primary/onPrimary -- it discards whatever hue/chroma `primary`
    # carries. So on a true-neutral image the loop above just wrote gray
    # into "accent"/"on_accent" no matter what. If tinting is enabled,
    # override just those two here with the seeded tint computed in
    # grayscale_fallback (carried through as `primary`), so the rest of
    # the UI stays cleanly neutral but the accent still has personality.
    accent_override_hex = None
    if is_true_neutral and ENABLE_NEUTRAL_TINT:
        acc_tone = 80 if is_dark else 40
        acc_hct = Hct.from_hct(primary.hue, primary.chroma, acc_tone)
        accent_override_hex = f"{acc_hct.to_int() & 0xFFFFFF:06x}"
        out["accent"] = f"#{accent_override_hex}"

        acc_on_tone = 20 if is_dark else 100
        acc_on_hct = Hct.from_hct(primary.hue, min(primary.chroma, 12), acc_on_tone)
        out["on_accent"] = f"#{acc_on_hct.to_int() & 0xFFFFFF:06x}"

    sec_tone = 80 if is_dark else 40
    sec_hct = Hct.from_hct(secondary.hue, secondary.chroma, sec_tone)
    out["accent_secondary"] = f"#{sec_hct.to_int() & 0xFFFFFF:06x}"

    sec_on_tone = 20 if is_dark else 100
    sec_on_hct = Hct.from_hct(secondary.hue, min(secondary.chroma, 12), sec_on_tone)
    out["on_accent_secondary"] = f"#{sec_on_hct.to_int() & 0xFFFFFF:06x}"

    write_hypr_colors(by_name, scheme, primary_hex_override=accent_override_hex)
    return out


def main():
    if len(sys.argv) < 3:
        print("usage: generate-theme.py <image> <dark|light> [contrast_level] [--debug-candidates]", file=sys.stderr)
        sys.exit(1)

    args = sys.argv[1:]
    global DEBUG_CANDIDATES
    if "--debug-candidates" in args:
        DEBUG_CANDIDATES = True
        args.remove("--debug-candidates")

    image_path, mode = args[0], args[1]
    contrast_level = float(args[2]) if len(args) > 2 else 0.0
    if mode not in ("dark", "light"):
        print("mode must be 'dark' or 'light'", file=sys.stderr)
        sys.exit(1)

    colors = gen_colors(image_path, mode, contrast_level)
    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUT_PATH.write_text(json.dumps(colors, indent=2))
    print(f"wrote {OUT_PATH}")
    print(f"wrote {HYPR_OUT}")


if __name__ == "__main__":
    main()