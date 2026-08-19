# Athan Utility localization guide

You are translating UI strings for **Athan Utility**, an iOS/watchOS/macOS Muslim prayer-times app.

## Mechanics (non-negotiable)
- Your todo file `/tmp/l10n/<lang>_todo.strings` holds English source lines: `"key" = "English";`
- Translate ONLY the right-hand value. Keep every key byte-identical.
- Keep every format specifier (`%@`, `%d`, `%1$@`, `%%`) — same count, same order where the language allows reordering use positional `%1$@`/`%2$@`.
- Never use a raw `"` inside a value. Use the language's typographic quotes (« », „ “, “ ”, ‹ ›) or drop them.
- Keep `\n` escapes as-is.
- APPEND your translated lines to `Athan Utility/<lang>.lproj/Localizable.strings` in the repo at `/Users/omaralejel/Athan-Utility-Working`. Do not touch existing lines. Do not add keys not in your todo file.
- When done run `plutil -lint "Athan Utility/<lang>.lproj/Localizable.strings"` — it MUST print OK. Fix and re-lint if not.
- Also verify: no key you appended already exists elsewhere in the file (`grep -c '"key"'` should be 1). Duplicates are a bug.

## Voice
Short, calm, native app copy — not literal translation. UI labels are terse; footers are one plain sentence. Match the register Apple uses in that language's iOS.

## Rule 1 — use Apple's own iOS wording
For platform nouns/verbs use exactly the term the localized iOS uses, not a dictionary word. This includes: Settings, Notifications, Widgets, Home Screen, Lock Screen, Today View, Smart Stack, Shortcuts, Siri, Focus, Menu Bar, Done, Cancel, Add, Remove, Allow, Preview, Calendar, Reminders, Location Services, Privacy & Security, Complications, Apple Watch, App Store, Dark Mode. If unsure, pick the phrasing you have actually seen in that language's iOS UI.

## Rule 2 — use the Islamic terminology that community actually says
Do NOT transliterate the English/Arabic forms if the local Muslim community uses different words. Use the prayer names, and the words for the call to prayer / prayer / qibla / imsak / fasting, that are standard in that language's Muslim usage — the ones printed on local mosque timetables and used by the country's religious authority.

Specifically:
- **Turkish** — Diyanet names: İmsak, Güneş, Öğle, İkindi, Akşam, Yatsı. Use *ezan* (not adhan), *namaz* (not salah), *kıble*, *sahur*, *iftar*, *oruç*. Sunrise row in a prayer table is *Güneş*; Fajr is *İmsak* (or *Sabah* where it means the prayer itself).
- **Urdu** — نماز (not صلاۃ) for prayer, اذان for the call. Prayer names: فجر، طلوعِ آفتاب، ظہر، عصر، مغرب، عشاء. Use قبلہ، سحری، افطار، روزہ.
- **Bengali** — আজান for the call, নামাজ for prayer. Prayer names: ফজর, সূর্যোদয়, যোহর, আসর, মাগরিব, এশা. Use কিবলা, সাহরি, ইফতার, রোজা.
- **Persian/Farsi** — اذان for the call, نماز for prayer. Prayer names: اذان صبح/فجر، طلوع آفتاب، ظهر، عصر، مغرب، عشا. Use قبله، سحر، افطار، روزه.

## Rule 3 — RTL (Arabic-script languages: ur, fa)
Write natural RTL text. Do not insert directional control characters. When a value mixes a Latin token (a `%@` that will hold "Fajr", an app name) with RTL text, keep word order natural for the language.

## Context for ambiguous keys
- `madhab` values: the Asr calculation school. "Default" here means the standard/majority opinion (Shafi'i/Maliki/Hanbali) — translate as the local equivalent of "Standard/Default", NOT as a school name.
- "Athan sound" = the muezzin audio that plays at prayer time.
- "Complication" = the small Apple Watch face element (use Apple's watchOS term).
- "Featured" = a section title over a grid of app features to discover.
- "Suhoor"/"Imsak" = the pre-dawn meal / its cutoff time.
