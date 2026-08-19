#!/usr/bin/env python3
"""
validate-screenshots.py — check a screenshot set before it goes to App Store Connect.

Uploading a bad set is slow to discover and slow to undo: deliver pushes every locale,
then Apple rejects on the first violation. The two rejections we already hit this cycle
were an alpha channel on a correctly-sized image, and a size that was correct but
measured on the wrong file — neither is visible by eye. So check locally first.

    tools/validate-screenshots.py fastlane/screenshots            # iOS set
    tools/validate-screenshots.py fastlane/screenshots_mac --mac  # Mac set

Exits non-zero if anything would be rejected.
"""

import os
import subprocess
import sys
from collections import defaultdict

# App Store Connect accepted sizes, in pixels.
MAC_SIZES = {(1280, 800), (1440, 900), (2560, 1600), (2880, 1800)}
MAX_PER_LOCALE = 10


def probe(path):
    """(width, height, has_alpha) via sips, which is always present on macOS."""
    out = subprocess.run(["sips", "-g", "pixelWidth", "-g", "pixelHeight", "-g", "hasAlpha", path],
                         capture_output=True, text=True).stdout
    vals = {}
    for line in out.splitlines():
        if ":" in line:
            k, v = line.strip().split(":", 1)
            vals[k.strip()] = v.strip()
    try:
        return int(vals["pixelWidth"]), int(vals["pixelHeight"]), vals.get("hasAlpha") == "yes"
    except (KeyError, ValueError):
        return None


def main():
    if len(sys.argv) < 2:
        sys.stderr.write(__doc__)
        return 2
    root = sys.argv[1]
    is_mac = "--mac" in sys.argv
    if not os.path.isdir(root):
        sys.stderr.write(f"no such directory: {root}\n")
        return 2

    problems = []
    rows = []
    for locale in sorted(os.listdir(root)):
        d = os.path.join(root, locale)
        if not os.path.isdir(d):
            continue
        shots = sorted(f for f in os.listdir(d) if f.lower().endswith((".png", ".jpg", ".jpeg")))
        if not shots:
            problems.append(f"{locale}: no screenshots")
            continue
        if len(shots) > MAX_PER_LOCALE:
            problems.append(f"{locale}: {len(shots)} screenshots, App Store allows {MAX_PER_LOCALE}")

        sizes = defaultdict(list)
        for name in shots:
            info = probe(os.path.join(d, name))
            if info is None:
                problems.append(f"{locale}/{name}: unreadable")
                continue
            w, h, alpha = info
            # An alpha channel is rejected even at an accepted size — this is the one
            # that cost us a round trip, because the image looks perfectly fine.
            if alpha:
                problems.append(f"{locale}/{name}: has an alpha channel")
            if is_mac and (w, h) not in MAC_SIZES:
                problems.append(f"{locale}/{name}: {w}x{h} is not an accepted Mac size")
            sizes[(w, h)].append(name)

        # Within one locale every shot must share a size, or Apple treats them as
        # different display classes and the set comes out incomplete.
        if len(sizes) > 1:
            problems.append(f"{locale}: mixed sizes {sorted(sizes)}")
        rows.append((locale, len(shots), "x".join(map(str, next(iter(sizes)))) if sizes else "-"))

    width = max((len(r[0]) for r in rows), default=6)
    for locale, count, size in rows:
        print(f"{locale:<{width}}  {count:>2} shots  {size}")

    if problems:
        print("\nWould be rejected:")
        for p in problems:
            print(f"  - {p}")
        return 1
    print(f"\nOK — {len(rows)} locales, {sum(r[1] for r in rows)} screenshots")
    return 0


if __name__ == "__main__":
    sys.exit(main())
