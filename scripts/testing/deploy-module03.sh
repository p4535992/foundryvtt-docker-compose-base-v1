#!/usr/bin/env bash
# Deploy only a built module to the local Foundry03 bind mount.
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
usage() { echo "Usage: $0 BUILD_DIRECTORY [--dry-run]" >&2; exit 2; }
(( $# == 1 || $# == 2 )) || usage
if (( $# == 2 )); then [[ "$2" == --dry-run ]] || usage; fi
SRC="$(cd -- "$1" && pwd -P)"
for p in foundry03 foundry03/data foundry03/data/Data foundry03/data/Data/modules; do
  [[ -d "$ROOT_DIR/$p" && ! -L "$ROOT_DIR/$p" ]] || {
    echo "Missing or unsafe modules directory. Start Foundry first." >&2; exit 1;
  }
done
MODULES="$ROOT_DIR/foundry03/data/Data/modules"
[[ -f "$SRC/module.json" && ! -L "$SRC/module.json" ]] || {
  echo "Build must contain module.json." >&2; exit 1;
}
ID="$(python3 - "$SRC/module.json" <<'PY'
import json, re, sys
with open(sys.argv[1], encoding="utf-8") as stream:
    manifest = json.load(stream)
module_id = manifest.get("id")
if not isinstance(module_id, str) or not re.fullmatch(r"[a-z0-9][a-z0-9_-]*", module_id):
    sys.exit("Invalid module.json id.")
print(module_id)
PY
)"
DEST="$MODULES/$ID"
[[ ! -L "$DEST" && ( ! -e "$DEST" || -d "$DEST" ) ]] || {
  echo "Unsafe module destination." >&2; exit 1;
}
# Refuse overlapping source/destination and symbolic links in build output.
case "$SRC/" in "$DEST/"*) echo "Source overlaps destination." >&2; exit 1;; esac
case "$DEST/" in "$SRC/"*) echo "Destination overlaps source." >&2; exit 1;; esac
[[ -z "$(find "$SRC" -type l -print -quit)" ]] || {
  echo "Build contains a symlink; deploy real build files instead." >&2; exit 1;
}
command -v rsync >/dev/null || { echo "rsync is required for this optional helper." >&2; exit 1; }
ARGS=(-a --no-owner --no-group --delete --itemize-changes)
if (( $# == 2 )); then ARGS+=(--dry-run); fi
# --delete is scoped to this module only; never targets a world or another module.
rsync "${ARGS[@]}" -- "$SRC/" "$DEST/"
