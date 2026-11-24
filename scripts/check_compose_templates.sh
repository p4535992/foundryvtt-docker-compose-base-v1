#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
TMP="$(mktemp)"
trap 'rm -f -- "$TMP"' EXIT
bash "$ROOT_DIR/scripts/generate_docker_compose.sh" "$TMP"
cmp -s "$TMP" "$ROOT_DIR/docker-compose.yml" || {
  echo "Compose is out of sync; run scripts/generate_docker_compose.sh." >&2
  exit 1
}
echo "Compose matches its single-service template."
