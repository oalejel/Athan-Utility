# Localization policy

Athan Utility ships in 12 languages. Before this policy existed, every translation
pass meant re-reading all ~280 strings in all 12 files to work out what had changed —
which is how we ended up with duplicate keys, strings translated twice, an English
file that was *less* complete than Arabic, and one Urdu format string whose `%1$@`
placeholders had been scrambled into `@$2%`.

The rules below exist so that never has to happen again. The whole point: **a string
whose English text has not changed since it was translated is never looked at again.**

## The three files that make it work

| File | Role |
|---|---|
| `Athan Utility/en.lproj/Localizable.strings` | The **only** source of truth. |
| `Athan Utility/l10n.lock.json` | Per language, per key: a hash of the English value *at the time that key was translated*. |
| `tools/l10n.py` | Reads both and tells you exactly what is outstanding. |

The lock file is what turns "translate everything again" into "translate these four
strings." It is committed, and it is not optional — a translation without a lock entry
is indistinguishable from a translation that predates the current English.

## Rules

**1. English first, always.** A new string is added to `en.lproj` in the same commit
as the code that uses it. Never add a key to a translation that does not exist in
English — it becomes an orphan no user can ever see, and it is why `ar` and `es` were
carrying 13 dead strings each.

**2. Changing English text means retranslating it.** Fixing a typo in an English value
changes its hash, so every language is marked `stale` for that key and shows up in the
next `todo`. This is the behavior we want. If a change is genuinely cosmetic and no
translation needs to move, run `tools/l10n.py lock` to re-baseline deliberately —
never silently.

**3. Never hand-append to a `.lproj` file.** Use `tools/l10n.py apply`. Appending by
hand is what produced 93 duplicate keys in Chinese; `apply` replaces in place, rejects
unknown keys, rejects format-specifier mismatches, lints, and writes the lock in one
step.

**4. Format specifiers may be reordered, never dropped.** Translations are free to
turn `"%@ at %@"` into `"%2$@ ... %1$@"` — most RTL and verb-final languages need to.
`apply` compares the multiset of conversion *types*, so reordering passes and a
dropped or mangled placeholder fails.

**5. `tools/l10n.py check` must be clean before a release build.** Missing, stale,
duplicate, format-broken, or non-linting all fail it.

## Workflow

Adding strings:

```sh
# 1. add the new keys to en.lproj alongside the code that uses them
python3 tools/l10n.py status          # every language now shows N missing
python3 tools/l10n.py todo de /tmp/de.strings   # exactly what de owes, English side
# 2. translate /tmp/de.strings (see tools/l10n-style.md for the terminology rules)
python3 tools/l10n.py apply de /tmp/de.strings  # validates, merges, lints, locks
python3 tools/l10n.py check
```

Delegating to translation agents: hand each agent `tools/l10n-style.md`, its own
`todo` file, and the `apply` command. Never let an agent edit a `.lproj` file
directly — `apply` is the guardrail that makes an agent's output safe to merge.

Housekeeping:

```sh
python3 tools/l10n.py prune    # delete keys English no longer has
python3 tools/l10n.py unused   # advisory: en keys no .swift literal references
```

`unused` reports false positives for keys assembled at runtime, so read the list
before deleting from `en.lproj`.

## Optional: block the mistake at commit time

```sh
printf '#!/bin/sh\npython3 tools/l10n.py check || { echo "l10n out of sync — see tools/LOCALIZATION.md"; exit 1; }\n' \
  > .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit
```

## The longer-term move: String Catalogs

Xcode 15+ `.xcstrings` catalogs do natively what `l10n.lock.json` does here: one file
per target, per-language state tracking, automatic `NEEDS_REVIEW` when the source
string changes, and extraction straight from the code so `en` can never fall behind.
That is where this should end up.

It is deliberately **not** being done for 8.0 — migrating 12 files and 280 keys while
a release is in flight trades a solved problem for an unsolved one. Do it early in the
next cycle: Xcode's *Product → Export Localizations* handles the conversion, and this
policy's rules survive the move nearly unchanged (`en` stays canonical, source edits
still force review, agents still get a filtered subset rather than the whole catalog).
