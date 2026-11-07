#!/usr/bin/env python3
"""Regenerate the [icon] block of the Yazi matugen template from Yazi's own presets.

Folders follow the DMS palette (`primary`). File icons keep Yazi's brand colours, so
Python, JS, HTML... stay recognisable.

The file/extension/condition lists are written out in full for both modes and picked by
DMS's own light/dark mode (`is_dark_mode`), not by Yazi's detection. Yazi chooses its base
preset (theme-dark.toml or theme-light.toml) from what the terminal reports, and behind a
multiplexer that can be wrong: a dark DMS then got the light preset's dark icons. In dark
mode, colours too dark for a dark background are also lightened (same hue, more lightness).

    python3 docs/linux/yazi-icons-gen.py [dark-preset [light-preset]]   (path or URL)

It rewrites the block between the BEGIN/END markers in
dot_config/matugen/dms/templates/yazi-flavor.toml (appending it if missing).
Run it again after a Yazi upgrade that adds icons, then review `git diff`.
"""

import colorsys
import json
import re
import sys
import tomllib
import urllib.request
from pathlib import Path

BASE = "https://raw.githubusercontent.com/sxyazi/yazi/v26.9.1/yazi-config/preset/"
TEMPLATE = Path(__file__).resolve().parents[2] / "dot_config/matugen/dms/templates/yazi-flavor.toml"
BEGIN = "# BEGIN generated icons (docs/linux/yazi-icons-gen.py)"
END = "# END generated icons"
DARK_BG = "#0b0d15"  # a typical DMS dark surface; dark-mode icons are lightened against it
MIN_CONTRAST = 5.5
FOLDER = "{{colors.primary.default.hex}}"
FOLDER_CONDS = {"dir", "dir & hovered"}


def _lum(hex_color):
    def lin(c):
        c /= 255
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

    r, g, b = (int(hex_color[i : i + 2], 16) for i in (1, 3, 5))
    return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b)


def contrast(hex_color):
    a, b = _lum(hex_color), _lum(DARK_BG)
    return (max(a, b) + 0.05) / (min(a, b) + 0.05)


def lighten(hex_color):
    """Same hue and saturation, lightness raised until the contrast is enough."""
    r, g, b = (int(hex_color[i : i + 2], 16) / 255 for i in (1, 3, 5))
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    while contrast(hex_color) < MIN_CONTRAST and l < 0.9:
        l += 0.01
        rgb = colorsys.hls_to_rgb(h, l, s)
        hex_color = "#" + "".join(f"{round(c * 255):02x}" for c in rgb)
    return hex_color


def q(value):
    return json.dumps(value, ensure_ascii=False)


def rule(key, rule_, fg):
    return f"\t{{ {key} = {q(rule_[key])}, text = {q(rule_['text'])}, fg = \"{fg}\" }},"


def lists(icon, dark):
    lines = []
    for key in ("files", "exts"):
        lines.append(f"{key} = [")
        for r in icon[key]:
            fg = lighten(r["fg"]) if dark else r["fg"]
            lines.append(rule("name", r, fg))
        lines.append("]")
    lines.append("conds = [")
    for r in icon["conds"]:
        fg = FOLDER if r["if"] in FOLDER_CONDS else r["fg"]
        lines.append(rule("if", r, fg))
    lines.append("]")
    return lines


def build(dark, light):
    lines = [BEGIN, "[icon]", "dirs = ["]
    for r in dark["dirs"]:
        lines.append(rule("name", r, FOLDER))
    lines.append("]")
    lines.append("<* if {{ is_dark_mode }} *>")
    lines += lists(dark, dark=True)
    lines.append("<* else *>")
    lines += lists(light, dark=False)
    lines += ["<* endif *>", END, ""]
    return "\n".join(lines)


def load(src):
    raw = urllib.request.urlopen(src).read() if src.startswith("http") else Path(src).read_bytes()
    return tomllib.loads(raw.decode())["icon"]


def main():
    dark = load(sys.argv[1] if len(sys.argv) > 1 else BASE + "theme-dark.toml")
    light = load(sys.argv[2] if len(sys.argv) > 2 else BASE + "theme-light.toml")
    block = build(dark, light)
    text = TEMPLATE.read_text()
    pattern = re.compile(re.escape(BEGIN) + r".*?" + re.escape(END) + r"\n?", re.S)
    text = pattern.sub("", text).rstrip("\n") + "\n\n" + block
    TEMPLATE.write_text(text)
    print("dark files/exts:", len(dark["files"]), len(dark["exts"]), "| light:", len(light["files"]), len(light["exts"]))


if __name__ == "__main__":
    main()
