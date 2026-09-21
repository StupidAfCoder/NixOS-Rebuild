# Bundled pixel icons

32 icons from **pixelarticons** by Gerrit Halfmann:
https://github.com/halfmage/pixelarticons

Pinned source commit: `efb6e172f2cec1abb1fb61a9a7bfe60e671ec002`.
MIT license: see `LICENSE` in this directory.

`bluetooth.svg`, `bluetooth-off.svg`, and `bluetooth-connected.svg` are the existing
custom icons from this repository's `bar/assets`, copied here for consistent lookup.

`nixos.svg` is the repository’s original NixOS logo with its two fixed blue fills
replaced by `currentColor`, so the launcher respects the single shell accent.

`ColoredIcon.qml` replaces SVG `currentColor` with the active theme color and uses
a geometric fallback if a file cannot be read. No global pixelarticons path is required.
