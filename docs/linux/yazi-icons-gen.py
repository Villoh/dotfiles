#!/usr/bin/env python3
"""Regenerate the [icon] block of the Yazi matugen template from Yazi's own preset.

Yazi's preset (yazi-config/preset/theme-dark.toml) colours every icon with a fixed
hex. This keeps each rule's glyph and swaps the colour for a DMS palette
placeholder, grouped by hue, so the icons follow the wallpaper/theme.

    python3 docs/linux/yazi-icons-gen.py [path-or-url-to-theme-dark.toml]

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
from collections import Counter
from pathlib import Path

PRESET = "https://raw.githubusercontent.com/sxyazi/yazi/v26.9.1/yazi-config/preset/theme-dark.toml"
TEMPLATE = Path(__file__).resolve().parents[2] / "dot_config/matugen/dms/templates/yazi-flavor.toml"
BEGIN = "# BEGIN generated icons (docs/linux/yazi-icons-gen.py)"
END = "# END generated icons"


def dank(n):
    return "{{dank16.color%d.default.hex}}" % n


def role(name):
    return "{{colors.%s.default.hex}}" % name


# Hue groups -> palette references. dank16 has no orange or usable magenta (color5 is
# near-black on some themes), so orange folds into yellow and purple uses `tertiary`.
def group(hex_color):
    r, g, b = (int(hex_color[i : i + 2], 16) / 255 for i in (1, 3, 5))
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    h *= 360
    if s < 0.15 or l < 0.12:
        if l >= 0.75:
            return "light", role("on_surface")
        return ("dark", role("outline")) if l < 0.45 else ("grey", role("on_surface_variant"))
    bright = l >= 0.55
    if h >= 340 or h < 15:
        return "red", dank(9 if bright else 1)
    if h < 70:
        return "yellow", dank(11 if bright else 3)
    if h < 170:
        return "green", dank(10 if bright else 2)
    if h < 200:
        return "cyan", dank(6)
    if h < 260:
        return "blue", dank(12 if bright else 4)
    return "purple", role("tertiary")


CONDS = {
    "orphan": role("error"),
    "link": role("outline"),
    "block": role("tertiary"),
    "char": role("tertiary"),
    "fifo": role("tertiary"),
    "sock": role("tertiary"),
    "sticky": role("tertiary"),
    "dummy": role("error"),
    "dir & hovered": role("primary"),
    "dir": role("primary"),
    "exec": dank(2),
    "!dir": role("on_surface"),
}


def q(value):
    return json.dumps(value, ensure_ascii=False)


def build(icon):
    stats = Counter()
    lines = [BEGIN, "[icon]"]
    for key in ("dirs", "files", "exts"):
        lines.append(f"{key} = [")
        for rule in icon[key]:
            name, fg = group(rule["fg"])
            stats[name] += 1
            lines.append(f"\t{{ name = {q(rule['name'])}, text = {q(rule['text'])}, fg = \"{fg}\" }},")
        lines.append("]")
    lines.append("conds = [")
    for rule in icon["conds"]:
        fg = CONDS[rule["if"]]
        lines.append(f"\t{{ if = {q(rule['if'])}, text = {q(rule['text'])}, fg = \"{fg}\" }},")
    lines += ["]", END, ""]
    return "\n".join(lines), stats


def main():
    src = sys.argv[1] if len(sys.argv) > 1 else PRESET
    raw = urllib.request.urlopen(src).read() if src.startswith("http") else Path(src).read_bytes()
    icon = tomllib.loads(raw.decode())["icon"]
    unknown = {r["if"] for r in icon["conds"]} - set(CONDS)
    if unknown:
        sys.exit(f"unmapped conds: {sorted(unknown)}")
    block, stats = build(icon)
    text = TEMPLATE.read_text()
    pattern = re.compile(re.escape(BEGIN) + r".*?" + re.escape(END) + r"\n?", re.S)
    text = pattern.sub("", text).rstrip("\n") + "\n\n" + block
    TEMPLATE.write_text(text)
    print("groups:", dict(stats.most_common()))


if __name__ == "__main__":
    main()
