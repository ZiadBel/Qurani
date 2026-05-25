#!/usr/bin/env python3
# ============================================================================
# QURAN DATA VALIDATION
# ----------------------------------------------------------------------------
# This script runs BEFORE the build. If any check fails it exits non-zero and
# the build is aborted.
#
# Checks:
#   1. assets/quran/quran_uthmani.json exists and is valid JSON.
#   2. Total Surahs == 114.
#   3. Total Ayahs == 6236.
#   4. Per-Surah Ayah counts match the canonical mushaf.
#   5. SHA-256 of the JSON file matches scripts/quran_hash.txt.
#
# The Quran text is sacred. This script ONLY reads and compares — it never
# writes, normalizes, or mutates the file in any way.
# ============================================================================
import hashlib
import json
import sys
from pathlib import Path

# Canonical Hafs/Uthmani ayah counts per surah (number of verses). These are
# mathematical facts about the mushaf, not Quranic text. Surah 1 to 114 in
# order.
CANONICAL_AYAH_COUNTS = [
    7, 286, 200, 176, 120, 165, 206, 75, 129, 109,
    123, 111, 43, 52, 99, 128, 111, 110, 98, 135,
    112, 78, 118, 64, 77, 227, 93, 88, 69, 60,
    34, 30, 73, 54, 45, 83, 182, 88, 75, 85,
    54, 53, 89, 59, 37, 35, 38, 29, 18, 45,
    60, 49, 62, 55, 78, 96, 29, 22, 24, 13,
    14, 11, 11, 18, 12, 12, 30, 52, 52, 44,
    28, 28, 20, 56, 40, 31, 50, 40, 46, 42,
    29, 19, 36, 25, 22, 17, 19, 26, 30, 20,
    15, 21, 11, 8, 8, 19, 5, 8, 8, 11,
    11, 8, 3, 9, 5, 4, 7, 3, 6, 3,
    5, 4, 5, 6,
]
assert len(CANONICAL_AYAH_COUNTS) == 114
assert sum(CANONICAL_AYAH_COUNTS) == 6236


def fail(msg: str) -> int:
    sys.stderr.write(f"[quran-validate] FAIL: {msg}\n")
    return 1


def main() -> int:
    root = Path(__file__).resolve().parent.parent
    json_path = root / "assets" / "quran" / "quran_uthmani.json"
    hash_path = root / "scripts" / "quran_hash.txt"

    if not json_path.exists():
        return fail(f"missing Quran asset: {json_path}")
    if not hash_path.exists():
        return fail(f"missing approved hash file: {hash_path}")

    raw = json_path.read_bytes()
    computed = hashlib.sha256(raw).hexdigest()
    approved = hash_path.read_text().strip()
    if computed != approved:
        return fail(
            "Quran JSON hash mismatch.\n"
            f"  approved: {approved}\n"
            f"  computed: {computed}\n"
            "If you are intentionally updating the Quran data, replace the\n"
            "source XML, regenerate the JSON, MANUALLY VERIFY the contents,\n"
            "then update scripts/quran_hash.txt with the new hash."
        )

    try:
        doc = json.loads(raw.decode("utf-8"))
    except json.JSONDecodeError as e:
        return fail(f"invalid JSON: {e}")

    surahs = doc.get("surahs")
    if not isinstance(surahs, list):
        return fail("missing 'surahs' array")
    if len(surahs) != 114:
        return fail(f"expected 114 surahs, found {len(surahs)}")

    total = 0
    for i, s in enumerate(surahs, start=1):
        if s.get("number") != i:
            return fail(f"surah at index {i-1} has number={s.get('number')}, expected {i}")
        if not isinstance(s.get("name"), str) or not s["name"]:
            return fail(f"surah {i} missing 'name'")
        ayahs = s.get("ayahs")
        if not isinstance(ayahs, list):
            return fail(f"surah {i} missing 'ayahs' array")
        expected_n = CANONICAL_AYAH_COUNTS[i - 1]
        if len(ayahs) != expected_n:
            return fail(
                f"surah {i} ayah count mismatch: file={len(ayahs)} canonical={expected_n}"
            )
        if s.get("numberOfAyahs") != expected_n:
            return fail(
                f"surah {i} numberOfAyahs={s.get('numberOfAyahs')} but canonical={expected_n}"
            )
        for j, a in enumerate(ayahs, start=1):
            if a.get("number") != j:
                return fail(f"surah {i} ayah at index {j-1} has number={a.get('number')}")
            t = a.get("text")
            if not isinstance(t, str) or not t:
                return fail(f"surah {i} ayah {j} missing/empty 'text'")
        total += len(ayahs)

    if total != 6236:
        return fail(f"total ayahs={total}, expected 6236")

    print(f"[quran-validate] OK  surahs=114  ayahs=6236  sha256={computed[:12]}…")
    return 0


if __name__ == "__main__":
    sys.exit(main())
