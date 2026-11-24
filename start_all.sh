#!/usr/bin/env bash
# Prepare and start exactly one Foundry VTT container.
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
cd "$ROOT_DIR"
fail() { printf '%s\n' "$*" >&2; exit 1; }
command -v docker >/dev/null || fail "Docker is required."
command -v python3 >/dev/null || fail "Python 3 is required."
docker compose version >/dev/null || fail "Docker Compose v2 is required."
if [[ ! -e .env && ! -L .env ]]; then
  install -m 0600 .env.sample .env
  echo "Created private .env. Fill the four Foundry credentials, then rerun ./start_all.sh."
  exit 0
fi
[[ -f .env && ! -L .env ]] || fail ".env must be a regular file."
python3 scripts/render_secret_files.py
bash scripts/generate_docker_compose.sh
bash scripts/check_compose_templates.sh
if [[ "$(id -u)" == 0 || ( "$(id -u)" == 1000 && "$(id -g)" == 1000 ) ]]; then
  bash scripts/prepare_runtime.sh
else
  command -v sudo >/dev/null || fail "sudo is required to prepare UID/GID 1000 mounts."
  sudo bash scripts/prepare_runtime.sh
fi
DC=(docker compose --env-file .env -f docker-compose.yml)
"${DC[@]}" config --quiet
# Recreate to remount an atomically replaced secret. Persistent data is retained.
exec "${DC[@]}" up -d --force-recreate foundry03
