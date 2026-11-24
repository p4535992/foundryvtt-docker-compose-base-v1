#!/usr/bin/env bash
# Graceful shutdown, no backup container and no deletion of runtime data.
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
cd "$ROOT_DIR"
[[ -f .env && ! -L .env ]] || { echo "Missing private .env; run ./start_all.sh first." >&2; exit 1; }
exec docker compose --env-file .env -f docker-compose.yml down --timeout 120
