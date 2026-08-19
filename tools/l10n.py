#!/usr/bin/env python3
"""
l10n.py — keeps the 12 Localizable.strings files in sync with the English source.

en.lproj is the single source of truth. `l10n.lock.json` records, per language and
per key, a hash of the *English* value at the moment that key was last translated.
That one fact is what makes incremental translation possible: a key whose English
text has not changed since the lock was written never needs to be looked at again.

    tools/l10n.py status            # what each language is missing / has stale
    tools/l10n.py todo de           # English source for exactly what de needs
    tools/l10n.py apply de out.strings   # merge translations back in (no dupes)
    tools/l10n.py lock de           # mark de as current (after a manual edit)
    tools/l10n.py check             # exit 1 if anything is missing/stale — for CI

See tools/LOCALIZATION.md for the workflow this is meant to be used with.
"""

import hashlib
import json
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STRINGS_DIR = os.path.join(ROOT, "Athan Utility")
LOCK_PATH = os.path.join(STRINGS_DIR, "l10n.lock.json")
SOURCE = "en"

# One entry per line: "key" = "value";  — values may contain escaped quotes.
ENTRY = re.compile(r'^\s*"((?:[^"\\]|\\.)+)"\s*=\s*"((?:[^"\\]|\\.)*)"\s*;')
SPEC = re.compile(r"%(?:(\d+)\$)?([@dsf])")


def specs(value):
    """The conversions a string performs, order-independent.

    A translation is allowed — often required — to reorder arguments by switching
    "%@ at %@" to "%2$@ ... %1$@", so compare the multiset of conversion TYPES, not
    the literal specifier text. What must not change is how many of each there are.
    """
    return sorted(m.group(2) for m in SPEC.finditer(value))


def languages():
    return sorted(
        d[:-6]
        for d in os.listdir(STRINGS_DIR)
        if d.endswith(".lproj")
        and d != "Base.lproj"
        and os.path.exists(os.path.join(STRINGS_DIR, d, "Localizable.strings"))
    )


def path_for(lang):
    return os.path.join(STRINGS_DIR, lang + ".lproj", "Localizable.strings")


def read(lang):
    """key -> value, in file order. Later duplicates are reported, not silently kept."""
    vals, dupes = {}, []
    with open(path_for(lang), encoding="utf-8") as f:
        for line in f:
            m = ENTRY.match(line)
            if not m:
                continue
            k, v = m.group(1), m.group(2)
            if k in vals:
                dupes.append(k)
            else:
                vals[k] = v
    return vals, dupes


def digest(value):
    return hashlib.sha1(value.encode("utf-8")).hexdigest()[:12]


def load_lock():
    if os.path.exists(LOCK_PATH):
        with open(LOCK_PATH, encoding="utf-8") as f:
            return json.load(f)
    return {}


def save_lock(lock):
    with open(LOCK_PATH, "w", encoding="utf-8") as f:
        json.dump(lock, f, indent=1, sort_keys=True, ensure_ascii=False)
        f.write("\n")


def analyze(lang, src, lock):
    """missing / stale / orphan / dupes / fmt for one language."""
    vals, dupes = read(lang)
    seen = lock.get(lang, {})
    missing = [k for k in src if k not in vals]
    stale = [k for k in src if k in vals and seen.get(k) != digest(src[k])]
    orphan = [k for k in vals if k not in src]
    fmt = [
        k
        for k, v in vals.items()
        if k in src and specs(v) != specs(src[k])
    ]
    return {
        "missing": missing,
        "stale": stale,
        "orphan": orphan,
        "dupes": dupes,
        "fmt": fmt,
    }


def lint(lang):
    r = subprocess.run(
        ["plutil", "-lint", path_for(lang)], capture_output=True, text=True
    )
    return r.stdout.strip().endswith("OK")


def cmd_status(args):
    src, src_dupes = read(SOURCE)
    lock = load_lock()
    print(f"source: {SOURCE}.lproj — {len(src)} keys" + (f"  ⚠︎ {len(src_dupes)} duplicate keys" if src_dupes else ""))
    print(f"{'lang':<9}{'missing':>9}{'stale':>7}{'orphan':>8}{'dupes':>7}{'fmt':>5}  lint")
    bad = False
    for lang in languages():
        if lang == SOURCE:
            continue
        a = analyze(lang, src, lock)
        ok = lint(lang)
        n = {k: len(v) for k, v in a.items()}
        if n["missing"] or n["stale"] or n["dupes"] or n["fmt"] or not ok:
            bad = True
        print(
            f"{lang:<9}{n['missing']:>9}{n['stale']:>7}{n['orphan']:>8}"
            f"{n['dupes']:>7}{n['fmt']:>5}  {'OK' if ok else 'FAIL'}"
        )
    return 1 if bad else 0


def cmd_todo(args):
    """Write the English source for everything `lang` still owes, to stdout or a file."""
    lang = args[0]
    src, _ = read(SOURCE)
    lock = load_lock()
    a = analyze(lang, src, lock)
    vals, _ = read(lang)
    todo = a["missing"] + a["stale"]
    if not todo:
        sys.stderr.write(f"{lang}: nothing to translate\n")
        return 0
    out = [f"// {lang}: {len(a['missing'])} new, {len(a['stale'])} changed since last translation\n"]
    for k in todo:
        if k in a["stale"]:
            out.append(f'// WAS: "{vals[k]}"\n')
        out.append(f'"{k}" = "{src[k]}";\n')
    text = "".join(out)
    if len(args) > 1:
        with open(args[1], "w", encoding="utf-8") as f:
            f.write(text)
        sys.stderr.write(f"{lang}: wrote {len(todo)} keys to {args[1]}\n")
    else:
        sys.stdout.write(text)
    return 0


def cmd_apply(args):
    """Merge a translated .strings fragment into lang, replacing rather than appending
    any key that already exists (this is what stops duplicate-key corruption), then
    lock those keys against the current English."""
    lang, frag = args[0], args[1]
    src, _ = read(SOURCE)
    incoming = {}
    with open(frag, encoding="utf-8") as f:
        for line in f:
            m = ENTRY.match(line)
            if m:
                incoming[m.group(1)] = m.group(2)

    unknown = [k for k in incoming if k not in src]
    if unknown:
        sys.stderr.write(f"refusing: {len(unknown)} key(s) not in {SOURCE}: {unknown[:5]}\n")
        return 1
    bad = [k for k, v in incoming.items() if specs(v) != specs(src[k])]
    if bad:
        sys.stderr.write(f"refusing: format-specifier mismatch in {bad}\n")
        return 1

    p = path_for(lang)
    with open(p, encoding="utf-8") as f:
        lines = f.readlines()
    replaced, out = set(), []
    for line in lines:
        m = ENTRY.match(line)
        if m and m.group(1) in incoming:
            k = m.group(1)
            out.append(f'"{k}" = "{incoming[k]}";\n')
            replaced.add(k)
        else:
            out.append(line)
    appended = [k for k in incoming if k not in replaced]
    if appended:
        if out and not out[-1].endswith("\n"):
            out.append("\n")
        out.append("\n")
        for k in appended:
            out.append(f'"{k}" = "{incoming[k]}";\n')
    with open(p, "w", encoding="utf-8") as f:
        f.writelines(out)

    if not lint(lang):
        sys.stderr.write(f"{lang}: plutil -lint FAILED — fix before committing\n")
        return 1

    lock = load_lock()
    lock.setdefault(lang, {})
    for k in incoming:
        lock[lang][k] = digest(src[k])
    save_lock(lock)
    sys.stderr.write(
        f"{lang}: {len(replaced)} updated, {len(appended)} added, locked. lint OK\n"
    )
    return 0


def cmd_lock(args):
    """Declare a language current against today's English — for keys edited by hand.
    With no args, locks every key that exists in every language."""
    src, _ = read(SOURCE)
    lock = load_lock()
    targets = args if args else [l for l in languages() if l != SOURCE]
    for lang in targets:
        vals, _ = read(lang)
        lock[lang] = {k: digest(src[k]) for k in vals if k in src}
        sys.stderr.write(f"{lang}: locked {len(lock[lang])} keys\n")
    save_lock(lock)
    return 0


def cmd_check(args):
    return cmd_status(args)


def cmd_prune(args):
    """Delete orphans — keys a translation still carries that English no longer has.
    These are strings the UI stopped using; they cost a reviewer's attention on every
    future pass and can never be shown to a user."""
    src, _ = read(SOURCE)
    lock = load_lock()
    for lang in [l for l in languages() if l != SOURCE]:
        dead = set(analyze(lang, src, lock)["orphan"])
        if not dead:
            continue
        p = path_for(lang)
        with open(p, encoding="utf-8") as f:
            lines = f.readlines()
        kept = [l for l in lines if not (ENTRY.match(l) and ENTRY.match(l).group(1) in dead)]
        with open(p, "w", encoding="utf-8") as f:
            f.writelines(kept)
        for k in dead:
            lock.get(lang, {}).pop(k, None)
        sys.stderr.write(f"{lang}: pruned {len(dead)} dead keys\n")
    save_lock(lock)
    return 0


def cmd_unused(args):
    """Advisory: English keys no literal in any .swift file references. Keys built at
    runtime (string interpolation, enum rawValues) show up here as false positives, so
    read the list before deleting anything."""
    src, _ = read(SOURCE)
    swift = subprocess.run(
        ["grep", "-rh", "--include=*.swift", "-o", r'"[^"]\{1,120\}"', ROOT],
        capture_output=True, text=True,
    ).stdout
    literals = set(swift.split("\n"))
    for k in src:
        if f'"{k}"' not in literals:
            print(k)
    return 0


COMMANDS = {
    "status": cmd_status,
    "todo": cmd_todo,
    "apply": cmd_apply,
    "lock": cmd_lock,
    "check": cmd_check,
    "prune": cmd_prune,
    "unused": cmd_unused,
}

if __name__ == "__main__":
    if len(sys.argv) < 2 or sys.argv[1] not in COMMANDS:
        sys.stderr.write(__doc__)
        sys.exit(2)
    sys.exit(COMMANDS[sys.argv[1]](sys.argv[2:]))
