#!/usr/bin/env python3
"""Single-seed wallpaper themes. Preview is pure; only the CLI publishes files.

Compatible: generate-theme.py IMAGE dark|light [CONTRAST]
New: --recipe wallpaper|black|neutral|tonal|expressive|paper|mono --tone -15..15
     --saturation 0..1.6 --source representative|dominant|colorful --preview
"""
import argparse
import json
import math
import os
import tempfile
from pathlib import Path

from PIL import Image, ImageOps
from materialyoucolor.hct import Hct

ROOT = Path(__file__).resolve().parents[1]
RECIPES = ("wallpaper", "black", "neutral", "tonal", "expressive", "paper", "mono")


def atomic_write(path, text):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    name = None
    try:
        with tempfile.NamedTemporaryFile(mode="w", dir=path.parent, delete=False) as f:
            name = f.name
            f.write(text)
            f.flush()
            os.fsync(f.fileno())
        os.replace(name, path)
    finally:
        if name and os.path.exists(name):
            os.unlink(name)


def luminance(color):
    rgb = [int(color[i:i + 2], 16) / 255 for i in (1, 3, 5)]
    rgb = [v / 12.92 if v <= .04045 else ((v + .055) / 1.055) ** 2.4 for v in rgb]
    return sum(v * w for v, w in zip(rgb, (.2126, .7152, .0722)))


def contrast(a, b):
    x, y = sorted((luminance(a), luminance(b)))
    return (y + .05) / (x + .05)


def hct_hex(hue, chroma, tone):
    return f"#{Hct.from_hct(hue, chroma, tone).to_int() & 0xffffff:06x}"


def hue_distance(a, b):
    return abs((a - b + 180) % 360 - 180)


def extract_seed(path, preference="representative"):
    # Lossless samples, with transparent pixels excluded (not flattened to black).
    with Image.open(path) as original:
        image = ImageOps.exif_transpose(original).convert("RGBA")
        image.thumbnail((160, 160), Image.Resampling.LANCZOS)
        pixels = image.get_flattened_data() if hasattr(image, "get_flattened_data") else image.getdata()
        samples = [(r, g, b) for r, g, b, a in pixels if a >= 128]
    if not samples:
        raise ValueError("Image has no opaque pixels to extract")
    strip = Image.new("RGB", (len(samples), 1))
    strip.putdata(samples)
    quantized = strip.quantize(colors=48, method=Image.Quantize.MEDIANCUT).convert("RGB")
    counts = quantized.getcolors(len(samples))
    candidates = []
    for count, rgb in counts:
        h = Hct.from_int(0xff000000 | rgb[0] << 16 | rgb[1] << 8 | rgb[2])
        candidates.append((count / len(samples), h, rgb))
    # Require a meaningful colored area, not a single bright/compression pixel.
    colored = [(p, h, rgb) for p, h, rgb in candidates if h.chroma >= 8 and 5 < h.tone < 96]
    if sum(p for p, _, _ in colored) < .025:
        return {"hue": 0., "chroma": 0., "neutral": True, "seed": "#808080"}

    def score(candidate):
        p, h, _ = candidate
        family = sum(pop for pop, other, _ in colored if hue_distance(h.hue, other.hue) < 20)
        # Dominant favors area; colorful favors chroma but still penalizes tiny accents.
        if preference == "dominant":
            return family + p * .3
        weight = .7 if preference == "colorful" else .3
        return math.sqrt(family) + weight * min(h.chroma, 90) / 90 + p * .15

    _, winner, rgb = max(colored, key=score)
    return {"hue": winner.hue, "chroma": winner.chroma, "neutral": False,
            "seed": "#" + "".join(f"{c:02x}" for c in rgb)}


def generate(path, mode="dark", contrast_level=0., recipe="black", tone=0., saturation=1., source="representative"):
    if mode not in ("dark", "light") or recipe not in RECIPES:
        raise ValueError("Invalid mode or recipe")
    for value, lo, hi, name in ((contrast_level, 0, 1, "contrast"), (tone, -15, 15, "tone"), (saturation, 0, 1.6, "saturation")):
        if not math.isfinite(value) or not lo <= value <= hi:
            raise ValueError(f"{name} must be between {lo} and {hi}")
    if source not in ("representative", "dominant", "colorful"):
        raise ValueError("Invalid source preference")
    seed = extract_seed(path, source)
    neutral = seed["neutral"] or recipe == "mono" or saturation == 0
    hue = seed["hue"]
    chroma = 0 if neutral else min(90, seed["chroma"] * saturation * (1.3 if recipe == "expressive" else 1))
    light = mode == "light" or recipe == "paper"
    tinted = recipe in ("wallpaper", "tonal", "expressive", "paper") and not neutral
    surface_chroma = min(chroma * (.55 if recipe == "wallpaper" else .25), 36 if recipe == "wallpaper" else 16) if tinted else 0
    levels = [96, 98, 94, 91, 87, 83] if light else ([0, 3, 5, 8, 12, 16] if recipe == "black" else [5, 7, 9, 12, 16, 20])
    if recipe == "wallpaper" and not light:
        levels = [12, 14, 16, 19, 22, 26]
    keys = ("background", "surface", "surface_container_low", "surface_container", "surface_container_high", "surface_variant")
    colors = {key: hct_hex(hue, surface_chroma, level) for key, level in zip(keys, levels)}
    colors["background"] = "#000000" if recipe == "black" and not light else colors["background"]
    target = 7 if contrast_level >= .5 else 4.5
    text = "#111111" if light else "#f1f1ec"
    muted = "#484848" if light else "#bcbcb7"
    backgrounds = [colors[k] for k in keys]
    if min(contrast(muted, bg) for bg in backgrounds) < target:
        muted = text
    colors.update(on_background=text, on_surface=text, on_surface_variant=muted)
    acc_tone = max(22, min(92, (36 if light else 76) + tone))
    # Validate the final gamut-mapped color against ALL interactive surfaces.
    for _ in range(101):
        accent = hct_hex(hue, chroma, acc_tone)
        if min(contrast(accent, bg) for bg in backgrounds) >= target:
            break
        acc_tone = max(0, min(100, acc_tone + (-1 if light else 1)))
    on_accent = max(("#000000", "#ffffff"), key=lambda c: contrast(c, accent))
    colors.update(accent=accent, on_accent=on_accent,
                  accent_secondary=accent, on_accent_secondary=on_accent,
                  outline="#707070" if light else "#777777",
                  outline_variant="#b8b8b1" if light else "#303030", shadow="#000000",
                  error="#a51c25" if light else "#ffb4ab",
                  on_error="#ffffff" if light else "#380000")
    if tinted:
        colors["outline_variant"] = hct_hex(hue, surface_chroma, 72 if light else 32)
        colors["outline"] = hct_hex(hue, surface_chroma, 44 if light else 54)
    return {**colors, "_meta": {**seed, "recipe": recipe, "tone": tone, "saturation": saturation,
                                "source": source, "mode": "light" if light else "dark"}}


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("image")
    p.add_argument("mode", choices=("dark", "light"))
    p.add_argument("contrast", nargs="?", type=float, default=0)
    p.add_argument("--recipe", choices=RECIPES, default="black")
    p.add_argument("--tone", type=float, default=0)
    p.add_argument("--saturation", type=float, default=1)
    p.add_argument("--source", choices=("representative", "dominant", "colorful"), default="representative")
    p.add_argument("--preview", action="store_true")
    p.add_argument("--debug-candidates", action="store_true", help="Print seed diagnostics to stderr")
    p.add_argument("--output-dir", type=Path, default=ROOT)
    a = p.parse_args()
    try:
        result = generate(a.image, a.mode, a.contrast, a.recipe, a.tone, a.saturation, a.source)
        if a.preview:
            print(json.dumps(result))
            return
        # Compute both complete files before publishing. Each replacement is atomic.
        lua = ('return {\n    active_border = "rgba(%scc)",\n    inactive_border = "rgba(%s60)",\n'
               '    background = "0x000000",\n}\n') % (result["accent"][1:], result["outline_variant"][1:])
        atomic_write(a.output_dir / "hypr/colors.lua", lua)
        atomic_write(a.output_dir / "quickshell/bar/theme/colors.json", json.dumps(result, indent=2) + "\n")
        if a.debug_candidates:
            import sys
            print(json.dumps(result["_meta"]), file=sys.stderr)
    except (OSError, ValueError, Image.DecompressionBombError) as exc:
        p.exit(1, f"theme: {exc}\n")


if __name__ == "__main__":
    main()
