#!/usr/bin/env bash
# Only create/prepare mount directories; never recursively alter user data.
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$ROOT_DIR"
[[ -d foundry03 && ! -L foundry03 ]] || { echo "Unsafe foundry03 directory." >&2; exit 1; }

secure_dir() {
  local path="$1"
  [[ ! -L "$path" ]] || { echo "Symlink forbidden: $path" >&2; exit 1; }
  if [[ ! -e "$path" ]]; then
    mkdir -- "$path"
  fi
  [[ -d "$path" ]] || { echo "Not a directory: $path" >&2; exit 1; }
  if [[ "$(stat -c '%u:%g' "$path")" != 1000:1000 ]]; then
    chown 1000:1000 "$path"
  fi
  chmod 0750 "$path"
}
for path in foundry03/data foundry03/data/Data \
  foundry03/data/Data/modules foundry03/data/Data/systems \
  foundry03/data/Data/worlds foundry03/logs; do
  secure_dir "$path"
done
echo "Foundry03 runtime directories ready."
