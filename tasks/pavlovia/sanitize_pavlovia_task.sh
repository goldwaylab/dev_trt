#!/usr/bin/env bash
# Copy a Pavlovia/PsychoJS task repo into a sibling *_generic_share directory,
# excluding common non-shareable or generated files. Review output before any public git push.
#
# Usage:
#   ./sanitize_pavlovia_task.sh /path/to/crcns_tp0_s1_risk
#
# Output:
#   /path/to/crcns_tp0_s1_risk_generic_share
set -euo pipefail

SRC="${1:?Usage: $0 /path/to/cloned_pavlovia_repo}"

if [[ ! -d "$SRC" ]]; then
  echo "Not a directory: $SRC" >&2
  exit 1
fi

SRC="$(cd "$SRC" && pwd)"
BASE="$(basename "$SRC")"
DEST="$(dirname "$SRC")/${BASE}_generic_share"

echo "Source: $SRC"
echo "Dest:   $DEST"

if [[ -e "$DEST" ]]; then
  echo "Destination already exists: $DEST" >&2
  echo "Remove or rename it, then re-run." >&2
  exit 1
fi

mkdir -p "$DEST"

# rsync: copy tree, exclude junk / data / logs / OS files
rsync -aH \
  --exclude '.git/' \
  --exclude 'node_modules/' \
  --exclude '.DS_Store' \
  --exclude 'Thumbs.db' \
  --exclude '*.log' \
  --exclude '*.tmp' \
  --exclude '__pycache__/' \
  --exclude '.Rhistory' \
  --exclude '.RData' \
  --exclude 'data/' \
  --exclude 'Data/' \
  --exclude 'results/' \
  --exclude 'Results/' \
  --exclude 'downloads/' \
  --exclude 'exports/' \
  --exclude 'venv/' \
  --exclude 'shareable_copy/' \
  "$SRC/" "$DEST/"

echo ""
echo "Done. Next steps:"
echo "  1) cd \"$DEST\""
echo "  2) Search for participant IDs / study strings:  rg -i 'participant|prolific|sona|email' ."
echo "  3) Manually remove or replace any condition/data CSVs that contain real study runs (trial exports)."
echo "  4) If you need example CSVs for docs, add a README-only note — do not commit real data."
echo "  5) git init && commit (optional public mirror)"
