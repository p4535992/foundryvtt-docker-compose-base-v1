#!/usr/bin/env bash
# Generate the root Compose file from exactly one service and the manifest.
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
MANIFEST="$ROOT_DIR/docker-compose-tree.template.yml.sample"
TEMPLATE="$ROOT_DIR/foundry03/docker-compose.template.yml"
OUTPUT="${1:-$ROOT_DIR/docker-compose.yml}"
[[ ! -L "$OUTPUT" && -d "$(dirname "$OUTPUT")" ]] || {
  echo "Unsafe output path: $OUTPUT" >&2; exit 1;
}
[[ "$(grep -c '^  - path:' "$MANIFEST")" == 1 ]]
grep -Fxq '  - path: ./foundry03/docker-compose.template.yml' "$MANIFEST"
[[ "$(head -n 1 "$TEMPLATE")" == 'services:' ]]
[[ "$(grep -Ec '^  [a-zA-Z0-9_-]+:[[:space:]]*$' "$TEMPLATE")" == 1 ]]
grep -Fxq '  foundry03:' "$TEMPLATE"
grep -Fxq 'networks:' "$MANIFEST"

TMP="$(mktemp "${OUTPUT}.XXXXXX")"
trap 'rm -f -- "$TMP"' EXIT
{
  printf '# Generated from templates. Do not edit manually.\n\n'
  cat "$TEMPLATE"
  printf '\n'
  sed -n '/^networks:$/,$p' "$MANIFEST"
} > "$TMP"
if [[ -f "$OUTPUT" ]] && cmp -s "$TMP" "$OUTPUT"; then
  exit 0
fi
chmod 0644 "$TMP"
mv -f -- "$TMP" "$OUTPUT"
