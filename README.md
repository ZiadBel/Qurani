# Qurani

A Flutter application for reading the Holy Qur'an from a bundled, hash-verified
local asset. The project is built around a single non-negotiable rule: the
Qur'anic text shipped with the app must be exactly the approved Uthmani (Hafs)
mushaf — never modified, never normalized, never fetched at runtime.

---

## Sacred Content Notice (read first)

The Qur'an is sacred. The text bundled in this repository — `assets/quran/quran_uthmani.json`
— originates from the **Tanzil Project, Uthmani script, Hafs reading, version 1.1**,
and is treated as a **read-only artifact**.

You must **never**:

- Manually edit `assets/quran/quran_uthmani.json`.
- Edit, regenerate, or remove `scripts/quran_hash.txt`.
- Normalize, transliterate, "fix," lint, reformat, strip diacritics from,
  or otherwise transform any Qur'anic text anywhere in this codebase.
- Hardcode Qur'anic verses inline in Dart, tests, fixtures, scripts, docs,
  or comments.
- Fetch Qur'anic text from any network source at runtime.

If you ever need to update the bundled mushaf, the only sanctioned path is:

1. Replace the upstream Tanzil source XML.
2. Re-run `scripts/convert_tanzil_to_json.py` to regenerate the JSON verbatim.
3. **Manually verify the resulting file** against the official mushaf.
4. Update `scripts/quran_hash.txt` with the new SHA-256.

The build will refuse to proceed if any of the above conditions are violated.

---

## What this app is

Qurani is a clean, Arabic-first Qur'an reader. It is intended to be a quiet,
distraction-free surface for reading the mushaf on phones, tablets, and the
web, with full right-to-left layout and traditional Uthmani typography.

It does **not** include translations, tafsir, audio recitation, or social
features. Its single responsibility is to render the approved Arabic text
faithfully.

## Main features

- **Full mushaf**: all 114 surahs, all 6,236 ayahs.
- **Uthmani (Hafs) script** rendered with the bundled `AmiriQuran` and `Amiri`
  fonts for accurate diacritics and pause marks.
- **Surah list** with surah name, ayah count, and revelation type (Meccan / Medinan).
- **Continuous reading view** with mushaf-style pagination, ayah numbering, and
  RTL-aware scrolling.
- **Adjustable text scale** for accessibility (1.0× / 1.5× / 2.0×).
- **Light and dark reading palettes** that follow the system theme.
- **Last-read bookmark** persisted locally via `shared_preferences` — the app
  reopens to where you left off.
- **Diacritic-insensitive search** over surah names and verse text. Normalization
  is computed transiently per query; the underlying asset bytes are never
  mutated.
- **Arabic and English UI locales** with RTL forced globally so Arabic flows
  correctly regardless of device frame.
- **Device Preview** in debug builds for multi-device QA (bypassed in release).

## Technologies used

- **Flutter** (stable channel) and **Dart** (SDK `^3.11.3`).
- **Material 3** theming with seeded color scheme.
- **`shared_preferences`** for local persistence (bookmark only).
- **`device_preview`** for debug-only multi-device previews.
- **`flutter_localizations`** for Arabic / English locale delegates.
- **`crypto`** (dev) for the in-test asset SHA-256 check.
- **`flutter_lints`** for static analysis.
- **Python 3** for the build-time validation and one-time conversion scripts
  (`scripts/validate_quran.py`, `scripts/convert_tanzil_to_json.py`).

## Qur'an text source

| Field           | Value                                                                   |
| --------------- | ----------------------------------------------------------------------- |
| Project         | [Tanzil Qur'an Project](https://tanzil.net)                             |
| Script / Riwāya | Uthmani (`quran-uthmani.xml`), Hafs ʿan ʿĀṣim                           |
| Version         | 1.1                                                                     |
| Bundled as      | `assets/quran/quran_uthmani.json` (verbatim conversion of the XML)      |
| Approved hash   | `scripts/quran_hash.txt` (SHA-256 of the JSON file, byte-for-byte)      |
| License         | Per the Tanzil Project terms — text is unaltered and used for tilawah.  |

The conversion from XML to JSON was a one-time, no-mutation transform: surah
names and verse text are copied byte-for-byte from the Tanzil source. The JSON
itself is then committed and frozen.

## Data integrity and SHA-256 validation

Integrity is enforced in three independent layers so that any accidental edit
is caught long before a release build:

1. **Pre-build script — `scripts/prebuild.sh`**
   Runs `scripts/validate_quran.py`, which:
   - Loads `assets/quran/quran_uthmani.json` and parses it as JSON.
   - Verifies exactly **114 surahs** and exactly **6,236 ayahs**.
   - Verifies each surah's ayah count against the canonical Hafs mushaf table.
   - Computes the SHA-256 of the asset and compares it to `scripts/quran_hash.txt`.
   - Exits non-zero on any mismatch, aborting the build.

2. **In-app runtime check — `lib/data/quran_repository.dart`**
   The repository is the *only* component permitted to read Qur'anic text. It
   loads exclusively from the bundled asset path, never from the network, and
   never mutates the strings it returns.

3. **Test suite**
   - `test/asset_hash_test.dart` recomputes the SHA-256 of the bundled asset
     at test time and asserts it matches `scripts/quran_hash.txt`.
   - `test/no_hardcoded_quran_test.dart` scans the source tree to ensure no
     Arabic Qur'anic text has been hardcoded anywhere in `lib/` or `test/`.
   - `test/quran_repository_test.dart` confirms surah/ayah counts and shape.

The current approved hash (must never change unless the mushaf is intentionally
re-imported following the procedure above):

```
af68cb0cc15b7ac512b4f05a6f2492b6f94f3d385357c8d1c5fc154c6ba47675
```

## How to run the app

Prerequisites: Flutter SDK on the stable channel (matching `pubspec.yaml`'s
`sdk: ^3.11.3`), and Python 3 for the pre-build validator.

```bash
# 1. Fetch dependencies
flutter pub get

# 2. ALWAYS run the integrity check before building or running
scripts/prebuild.sh

# 3. Launch on a connected device / emulator
flutter run

# 4. Or build a release artifact (run prebuild first)
scripts/prebuild.sh && flutter build apk          # Android
scripts/prebuild.sh && flutter build ios          # iOS (on macOS)
scripts/prebuild.sh && flutter build web          # Web
```

`scripts/prebuild.sh` is intentionally a separate step: it is the gate that
guarantees the mushaf you are about to ship is the approved one.

## How to run tests and validation

```bash
# 1. Run the SHA-256 + structural validator (must pass before anything else)
scripts/prebuild.sh

# 2. Run the full Flutter test suite (asset hash test, repository test,
#    no-hardcoded-Quran scan, paginator, search, scroll/interaction, etc.)
flutter test

# 3. Run static analysis (lints + type checks)
flutter analyze
```

All three must pass. The asset hash test inside `flutter test` is a second,
independent line of defense against any modification to the bundled Qur'anic
text.

## Project layout

```
lib/
  data/
    quran_repository.dart   # ONLY component that reads Qur'anic text
    bookmark_service.dart   # Last-read bookmark via shared_preferences
    search_service.dart     # Diacritic-insensitive verse/name search
  models/
    surah.dart
    ayah.dart
  ui/
    surah_list_screen.dart
    surah_reading_screen.dart
    mushaf_paginator.dart
    reading_palette.dart
  main.dart
assets/
  quran/
    quran_uthmani.json      # READ-ONLY sacred text — DO NOT EDIT
  fonts/
    AmiriQuran.ttf
    Amiri-Regular.ttf
scripts/
  prebuild.sh               # Gatekeeper — runs validate_quran.py
  validate_quran.py         # SHA-256 + structural integrity check
  convert_tanzil_to_json.py # One-time, verbatim XML→JSON utility
  quran_hash.txt            # Approved SHA-256 — DO NOT EDIT
test/
  asset_hash_test.dart
  no_hardcoded_quran_test.dart
  quran_repository_test.dart
  paginator_test.dart
  search_service_test.dart
  scroll_and_interaction_test.dart
  device_preview_check_test.dart
```

---

## Warning — Qur'anic text must never be manually edited

This warning is repeated because it is the most important rule in the
repository:

> The bundled Qur'anic text in `assets/quran/quran_uthmani.json` and the
> approved hash in `scripts/quran_hash.txt` are **sacred, read-only artifacts**.
> Do not edit them by hand. Do not "clean them up." Do not let an editor's
> auto-format, line-ending conversion, BOM insertion, or whitespace trim touch
> them. Any modification — even one invisible byte — will cause the SHA-256
> check to fail and the build to abort, *by design*. If that ever happens,
> restore the file from version control; do not regenerate the hash to make
> the error go away.
