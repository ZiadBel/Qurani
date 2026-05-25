#!/usr/bin/env bash
# Pre-build hook: aborts the build if Quran data fails integrity checks.
# Usage: scripts/prebuild.sh && flutter build apk
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 "$DIR/validate_quran.py"
