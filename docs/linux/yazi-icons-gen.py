#!/usr/bin/env python3
"""Regenerate the [icon] block of the Yazi matugen template from Yazi's own preset.

Only folders follow the DMS palette (`primary`). File icons keep Yazi's brand colours, so
Python, JS, HTML... stay recognisable. Glyphs always come from the preset.

    python3 docs/linux/yazi-icons-gen.py [path-or-url-to-theme-dark.toml]

It rewrites the block between the BEGIN/END markers in
dot_config/matugen/dms/templates/yazi-flavor.toml (appending it if missing).
Run it again after a Yazi upgrade that adds icons, then review `git diff`.
"""

import json
import re
import sys
import tomllib
import urllib.request
from pathlib import Path

PRESET = "https://raw.githubusercontent.com/sxyazi/yazi/v26.9.1/yazi-config/preset/theme-dark.toml"
TEMPLATE = Path(__file__).resolve().parents[2] / "dot_config/matugen/dms/templates/yazi-flavor.toml"
BEGIN = "# BEGIN generated icons (docs/linux/yazi-icons-gen.py)"
END = "# END generated icons"


def dank(n):
    return "{{dank16.color%d.default.hex}}" % n


def role(name):
    return "{{colors.%s.default.hex}}" % name


FOLDER = "{{colors.primary.default.hex}}"
FOLDER_CONDS = {"dir", "dir & hovered"}


def q(value):
    return json.dumps(value, ensure_ascii=False)


def build(icon):
    lines = [BEGIN, "[icon]", "dirs = ["]
    for rule in icon["dirs"]:
        lines.append(f"\t{{ name = {q(rule['name'])}, text = {q(rule['text'])}, fg = \"{FOLDER}\" }},")
    lines += ["]", "conds = ["]
    for rule in icon["conds"]:
        fg = FOLDER if rule["if"] in FOLDER_CONDS else rule["fg"]
        lines.append(f"\t{{ if = {q(rule['if'])}, text = {q(rule['text'])}, fg = \"{fg}\" }},")
    lines += ["]", END, ""]
    return "\n".join(lines)


def main():
    src = sys.argv[1] if len(sys.argv) > 1 else PRESET
    raw = urllib.request.urlopen(src).read() if src.startswith("http") else Path(src).read_bytes()
    icon = tomllib.loads(raw.decode())["icon"]
    block = build(icon)
    text = TEMPLATE.read_text()
    pattern = re.compile(re.escape(BEGIN) + r".*?" + re.escape(END) + r"\n?", re.S)
    text = pattern.sub("", text).rstrip("\n") + "\n\n" + block
    TEMPLATE.write_text(text)
    print("folder rules:", len(icon["dirs"]) + len(FOLDER_CONDS))


if __name__ == "__main__":
    main()
