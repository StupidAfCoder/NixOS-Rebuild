#!/usr/bin/env python3
"""
Generic template -> theme recolor tool.

- TEMPLATE never changes; it's your original hand-drawn art.
- ROLE_MAP says which exact colors in the template are "reactive" (tied to
  a theme role) vs fixed (part of the character's fixed identity: skin,
  outline, hat, etc). Only colors listed here get touched.
- For any "shadow" role, we don't hardcode a second theme color -- we
  measure how much darker the original shadow was vs its base color in
  the template, then apply that same proportional darkening to whatever
  the new theme color is. That way shading always looks correct no
  matter what accent color a given wallust/matugen run produces.
"""
import sys, os, json, colorsys, tempfile
from PIL import Image

def hex_to_rgb(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

def rgb_to_hex(rgb):
    return '#%02x%02x%02x' % rgb

def relative_lightness_ratio(base_hex, shadow_hex):
    br, bg, bb = [c/255 for c in hex_to_rgb(base_hex)]
    sr, sg, sb = [c/255 for c in hex_to_rgb(shadow_hex)]
    _, bl, _ = colorsys.rgb_to_hls(br, bg, bb)
    _, sl, _ = colorsys.rgb_to_hls(sr, sg, sb)
    return sl / bl if bl > 0 else 1.0

def apply_lightness_ratio(hex_color, ratio):
    r, g, b = [c/255 for c in hex_to_rgb(hex_color)]
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    l = max(0.0, min(1.0, l * ratio))
    r, g, b = colorsys.hls_to_rgb(h, l, s)
    return (round(r*255), round(g*255), round(b*255))

def recolor(template_path, role_map, theme, output_path):
    im = Image.open(template_path).convert('RGBA')
    px = im.load()

    # Precompute concrete replacement colors for each source color
    replacements = {}
    for src_hex, role in role_map.items():
        src_rgb = hex_to_rgb(src_hex)
        if role.endswith('_shadow'):
            base_role = role[:-len('_shadow')]
            base_role_hex_in_template = [k for k, v in role_map.items() if v == base_role][0]
            ratio = relative_lightness_ratio(base_role_hex_in_template, src_hex)
            new_rgb = apply_lightness_ratio(theme[base_role], ratio)
        else:
            new_rgb = hex_to_rgb(theme[role])
        replacements[src_rgb] = new_rgb

    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            key = (r, g, b)
            if key in replacements:
                nr, ng, nb = replacements[key]
                px[x, y] = (nr, ng, nb, a)

    # Atomic write: save to a temp file in the SAME directory as the
    # destination (guarantees the rename stays on one filesystem), then
    # os.replace() it into place. A watcher (FileView/inotify) can then
    # only ever see the fully-old or fully-new file -- never a
    # half-written one mid-save. Without this, QML's Image decoder can
    # catch the file mid-write and throw "Unsupported image format".
    out_dir = os.path.dirname(os.path.abspath(output_path))
    fd, tmp_path = tempfile.mkstemp(suffix='.png', dir=out_dir)
    os.close(fd)
    try:
        im.save(tmp_path)
        os.replace(tmp_path, output_path)
    except Exception:
        os.unlink(tmp_path)
        raise

    return output_path

if __name__ == '__main__':
    # Only the robe is theme-reactive; skin, outline, hat, highlights stay
    # exactly as drawn -- that's what keeps the character's identity intact
    # while still picking up the current accent color.
    ROLE_MAP = {
        '#5b6ee1': 'accent',
        '#3f3f74': 'accent_shadow',
    }

    THEME = json.load(open(sys.argv[3])) if len(sys.argv) > 3 else {
        'accent': '#7aa2f7'   # Tokyo Night accent -- placeholder until wallust/matugen exist
    }

    recolor(sys.argv[1], ROLE_MAP, THEME, sys.argv[2])
    print('wrote', sys.argv[2])