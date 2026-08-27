#!/usr/bin/env python3
"""Composite the transparent Buddy mark over a solid background colour.

The mark itself comes from tool/render_app_icon.dart, which renders the real
BuddyMascot widget, so the icon can never drift from the character in the app.

    python3 tool/compose_app_icon.py "#E8784A"

Writes assets/icon/app_icon.png. Keep the colour in sync with
`adaptive_icon_background` in pubspec.yaml, which Android composites the
foreground over itself.
"""

import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
FOREGROUND = ROOT / "assets/icon/app_icon_foreground.png"
OUTPUT = ROOT / "assets/icon/app_icon.png"


def compose(hex_colour: str) -> Image.Image:
    rgb = tuple(int(hex_colour.lstrip("#")[i : i + 2], 16) for i in (0, 2, 4))
    mark = Image.open(FOREGROUND).convert("RGBA")
    canvas = Image.new("RGBA", mark.size, rgb + (255,))
    canvas.alpha_composite(mark)
    return canvas


def main() -> None:
    if len(sys.argv) != 2:
        sys.exit(f"usage: {sys.argv[0]} '#RRGGBB'")
    icon = compose(sys.argv[1])
    icon.save(OUTPUT)
    print(f"wrote {OUTPUT.relative_to(ROOT)} {icon.size} on {sys.argv[1]}")


if __name__ == "__main__":
    main()
