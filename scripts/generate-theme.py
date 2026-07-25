#!/usr/bin/env python3
"""
Same generation backend Caelestia itself uses (materialyoucolor -- the
real Google material-color-utilities port, driven through the actual
MaterialDynamicColors role system), not matugen's CLI wrapper around it.

Usage: generate-theme.py <image> <dark|light> [contrast_level 0.0-1.0]
Writes colors.json (bar), colors.lua (Hyprland) from one shared scheme.
"""
import json
import sys
import tempfile
from pathlib import Path

from PIL import Image
from materialyoucolor.dislike.dislike_analyzer import DislikeAnalyzer
from materialyoucolor.dynamiccolor.material_dynamic_colors import MaterialDynamicColors
from materialyoucolor.hct import Hct
from materialyoucolor.quantize import ImageQuantizeCelebi
from materialyoucolor.scheme.scheme_vibrant import SchemeVibrant

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

# MD3's dark scheme spec puts background around HCT tone ~6 (near-black) by
# design. Nice for OLED, gloomy against a vibrant wallpaper. This floors
# background/surface roles to a lighter tone in dark mode, keeping the
# wallpaper's actual hue/chroma -- only the lightness gets lifted.
MIN_DARK_TONE = 16
SURFACE_ROLES = {
    "background", "surface", "surfaceContainerLow",
    "surfaceContainer", "surfaceContainerHigh", "surfaceVariant",
}


def make_thumbnail(image_path: str) -> str:
    # Caelestia scores off a 128x128 thumbnail, not the full wallpaper --
    # quantizing a 1920x1080 image does ~120x more work than it needs to.
    img = Image.open(image_path).convert("RGB")
    img.thumbnail((128, 128), Image.Resampling.NEAREST)
    tmp = tempfile.NamedTemporaryFile(suffix=".jpg", delete=False)
    img.save(tmp.name, "JPEG", quality=90)
    return tmp.name


def score_image(image_path: str) -> list[Hct]:
    # Quantize the image, weight by hue proportion + chroma, then keep the
    # top few *distinct* hues (deduped so "variety" isn't two shades of
    # the same pink). candidates[0] is always the true dominant color --
    # nothing randomizes or overrides it. The rest are genuine other
    # colors actually present in the wallpaper, for secondary use.
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
        scored.append((proportion_score + chroma_score, hct))
    scored.sort(key=lambda x: x[0], reverse=True)

    candidates = []
    for cutoff in range(20, -1, -1):
        for _, hct in scored:
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

    return [DislikeAnalyzer.fix_if_disliked(h) for h in distinct] or \
           [DislikeAnalyzer.fix_if_disliked(scored[0][1])]


def write_hypr_colors(by_name, scheme):
    def hex6(role):
        return f"{by_name[role].get_hct(scheme).to_int() & 0xFFFFFF:06x}"

    HYPR_OUT.parent.mkdir(parents=True, exist_ok=True)
    HYPR_OUT.write_text(
        "return {\n"
        f'    active_border = "rgba({hex6("primary")}cc)",\n'
        f'    inactive_border = "rgba({hex6("outlineVariant")}40)",\n'
        f'    background = "0x{hex6("shadow")}",\n'
        "}\n"
    )


def gen_colors(image_path: str, mode: str, contrast_level: float) -> dict:
    is_dark = mode == "dark"
    hues = score_image(image_path)
    primary = hues[0]
    secondary = hues[1] if len(hues) > 1 else primary

    scheme = SchemeVibrant(source_color_hct=primary, is_dark=is_dark, contrast_level=contrast_level)

    dyn = MaterialDynamicColors()
    by_name = {c.name: c for c in dyn.all_colors}

    out = {}
    for role, key in ROLE_MAP.items():
        hct = by_name[role].get_hct(scheme)
        if is_dark and role in SURFACE_ROLES and hct.tone < MIN_DARK_TONE:
            hct = Hct.from_hct(hct.hue, hct.chroma, MIN_DARK_TONE)
        out[key] = f"#{hct.to_int() & 0xFFFFFF:06x}"

    # A genuine second color actually present in the wallpaper (not a
    # hue-rotation of primary), for elements that should stand apart --
    # e.g. the media widget's progress fill. background/text/primary stay
    # locked to the true dominant color untouched.
    sec_tone = 80 if is_dark else 40
    sec_hct = Hct.from_hct(secondary.hue, secondary.chroma, sec_tone)
    out["accent_secondary"] = f"#{sec_hct.to_int() & 0xFFFFFF:06x}"

    sec_on_tone = 20 if is_dark else 100
    sec_on_hct = Hct.from_hct(secondary.hue, min(secondary.chroma, 12), sec_on_tone)
    out["on_accent_secondary"] = f"#{sec_on_hct.to_int() & 0xFFFFFF:06x}"

    write_hypr_colors(by_name, scheme)
    return out


def main():
    if len(sys.argv) < 3:
        print("usage: generate-theme.py <image> <dark|light> [contrast_level]", file=sys.stderr)
        sys.exit(1)

    image_path, mode = sys.argv[1], sys.argv[2]
    contrast_level = float(sys.argv[3]) if len(sys.argv) > 3 else 0.0
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