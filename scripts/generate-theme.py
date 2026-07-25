#!/usr/bin/env python3
"""
Same generation backend Caelestia itself uses (materialyoucolor --
the real Google material-color-utilities port, driven through the
actual MaterialDynamicColors role system), not matugen's CLI wrapper.

Usage: generate-theme.py <image> <dark|light> [contrast_level 0.0-1.0]
Writes colors.json in the exact shape quickshell/bar/Colors.qml expects.
"""
import json
import sys
from pathlib import Path

from materialyoucolor.dislike.dislike_analyzer import DislikeAnalyzer
from materialyoucolor.dynamiccolor.material_dynamic_colors import MaterialDynamicColors
from materialyoucolor.hct import Hct
from materialyoucolor.quantize import ImageQuantizeCelebi
from materialyoucolor.scheme.scheme_vibrant import SchemeVibrant

OUT_PATH = Path.home() / ".nixos_dotfiles/quickshell/bar/theme/colors.json"

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


def score_image(image_path: str) -> Hct:
    pixels = ImageQuantizeCelebi(image_path, 1, 128)

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

    for cutoff in range(20, -1, -1):
        for _, hct in scored:
            if hct.chroma > cutoff and hct.tone > cutoff * 3:
                return DislikeAnalyzer.fix_if_disliked(hct)
    return DislikeAnalyzer.fix_if_disliked(scored[0][1])


def gen_colors(image_path: str, mode: str, contrast_level: float) -> dict:
    is_dark = mode == "dark"
    primary = score_image(image_path)
    scheme = SchemeVibrant(source_color_hct=primary, is_dark=is_dark, contrast_level=contrast_level)

    dyn = MaterialDynamicColors()
    by_name = {c.name: c for c in dyn.all_colors}

    out = {}
    for role, key in ROLE_MAP.items():
        hct = by_name[role].get_hct(scheme)
        out[key] = f"#{hct.to_int() & 0xFFFFFF:06x}"
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


if __name__ == "__main__":
    main()