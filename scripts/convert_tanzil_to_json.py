#!/usr/bin/env python3
# ============================================================================
# SACRED CONTENT NOTICE
# ----------------------------------------------------------------------------
# The Quran is sacred. This script does NOT generate, normalize, transliterate,
# correct, translate, or modify ANY Arabic content. Every Arabic string — verse
# text AND surah names — is taken verbatim, byte-for-byte, from the approved
# Tanzil source XML (Uthmani, Hafs, Version 1.1).
#
# This script is a one-time conversion utility. The resulting JSON file is
# committed to the repository and treated as READ-ONLY. To update the Quran
# data, replace the source XML, re-run this script, then update the approved
# hash in scripts/quran_hash.txt after manual verification.
#
# Usage:
#   python3 scripts/convert_tanzil_to_json.py <path/to/quran-uthmani.xml>
# ============================================================================
import json
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

REVELATION_TYPE = {
    "Meccan": {1,6,7,10,11,12,13,14,15,16,17,18,19,20,21,23,25,26,27,28,29,30,
               31,32,34,35,36,37,38,39,40,41,42,43,44,45,46,50,51,52,53,54,56,
               67,68,69,70,71,72,73,74,75,77,78,79,80,81,82,83,84,85,86,87,88,
               89,90,91,92,93,94,95,96,97,100,101,102,103,104,105,106,107,108,
               109,111,112,113,114},
    "Medinan": {2,3,4,5,8,9,22,24,33,47,48,49,55,57,58,59,60,61,62,63,64,65,
                66,76,98,99,110},
}


def revelation_for(idx: int) -> str:
    if idx in REVELATION_TYPE["Meccan"]:
        return "Meccan"
    if idx in REVELATION_TYPE["Medinan"]:
        return "Medinan"
    raise ValueError(f"Unknown revelation type for surah {idx}")


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: convert_tanzil_to_json.py <quran-uthmani.xml>", file=sys.stderr)
        return 2
    src = Path(sys.argv[1])
    dst = Path(__file__).resolve().parent.parent / "assets" / "quran" / "quran_uthmani.json"
    dst.parent.mkdir(parents=True, exist_ok=True)

    tree = ET.parse(src)
    root = tree.getroot()

    surahs = []
    total_ayahs = 0
    for sura_el in root.findall("sura"):
        idx = int(sura_el.get("index"))
        # Arabic name taken verbatim from Tanzil XML attribute.
        name_ar = sura_el.get("name")
        if name_ar is None:
            raise ValueError(f"Missing 'name' attribute on sura {idx}")
        ayahs = []
        for aya_el in sura_el.findall("aya"):
            aya_idx = int(aya_el.get("index"))
            text = aya_el.get("text")
            if text is None:
                raise ValueError(f"Missing 'text' on sura {idx}, aya {aya_idx}")
            # Verbatim. No .strip(), no normalization.
            ayahs.append({"number": aya_idx, "text": text})
        surahs.append({
            "number": idx,
            "name": name_ar,
            "revelationType": revelation_for(idx),
            "numberOfAyahs": len(ayahs),
            "ayahs": ayahs,
        })
        total_ayahs += len(ayahs)

    if len(surahs) != 114:
        raise ValueError(f"expected 114 surahs, got {len(surahs)}")
    if total_ayahs != 6236:
        raise ValueError(f"expected 6236 ayahs, got {total_ayahs}")

    doc = {
        "source": "Tanzil Quran Text (Uthmani, Hafs), Version 1.1",
        "license": "Creative Commons Attribution 3.0",
        "edition": "quran-uthmani",
        "language": "ar",
        "type": "quran",
        "surahs": surahs,
    }
    # ensure_ascii=False preserves the original Arabic codepoints exactly.
    with open(dst, "w", encoding="utf-8") as f:
        json.dump(doc, f, ensure_ascii=False, separators=(",", ":"))
    print(f"wrote {dst} surahs={len(surahs)} ayahs={total_ayahs}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
