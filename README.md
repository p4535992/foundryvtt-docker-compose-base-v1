# Foundry VTT — single-container module development stack

**English (primary)** · [Italiano](README.it.md)

A minimal, local development variant of [base-v2](https://github.com/p4535992/foundryvtt-docker-compose-base-v2). It retains only the Foundry03 module test server: one Foundry VTT installation, one license and persistent host directories. No Traefik, DuckDNS, database, relay, bot or backup container.

## Requirements

- Linux (or WSL2 with Docker integration), Docker Engine and Docker Compose v2.
- Bash, Python 3, and sudo if the bind mount permissions require it.
- A valid Foundry VTT account and license. Use a disposable test world, not a production world.

## Quick start

```bash
./start_all.sh
```

On the first run the script creates a private `.env` from `.env.sample` and stops. Fill in the four Foundry credentials and run the command again. The script generates Compose, prepares persistent directories, renders a private Docker secret and validates the configuration before starting exactly one service.

Open **http://localhost:30000/**, complete Foundry setup, install the system you need and launch a test world. The port is bound to loopback by default. For a remote Linux host use an SSH tunnel (adjust the remote port if changed):

```bash
ssh -L 30000:127.0.0.1:30000 user@server
```

```bash
./down_all.sh                         # graceful shutdown; retains all data
docker compose ps
docker compose logs -f foundry03
```

The start script recreates the container to apply configuration and secret changes; bind-mounted data remains intact.

## Repository layout

```text
.env.sample
.gitignore
docker-compose-tree.template.yml.sample
docker-compose.yml                    # generated from the service template
foundry03/
  docker-compose.template.yml
  data/                               # /data
    Data/
      modules/
      systems/
      worlds/
  logs/                               # /data/Logs
scripts/
  generate_docker_compose.sh
  prepare_runtime.sh
  render_secret_files.py
  testing/
    deploy-module03.sh
    README.md
secrets/
  foundry03.json.example
start_all.sh
down_all.sh
README.md
README.it.md
VERSION
```

The runtime subdirectories are created on startup. Only placeholders and examples are tracked.

## Module development

Build a module in its own repository. Its deployable directory must contain `module.json` at the root. Use the local deployment helper:

```bash
/path/to/stack/scripts/testing/deploy-module03.sh ./dist --dry-run
/path/to/stack/scripts/testing/deploy-module03.sh ./dist
```

Or configure your module's build/watch tool to write directly to `foundry03/data/Data/modules/<module-id>/`. The bind mount exposes changes immediately without rebuilding the Docker image. Enable the module in the test world and reload the browser; restart Foundry if required for manifest or server-side changes. See [module development](scripts/testing/README.md).

## Configuration and safety

- `FOUNDRY03_IMAGE_TAG=14` follows the base-v2 development instance. Pin a precise compatible tag for reproducible testing; changing major versions can migrate world data.
- `FOUNDRY03_BIND_IP=127.0.0.1` and `FOUNDRY03_HOST_PORT=30000` control direct HTTP access. No TLS is provided; do not expose this development instance publicly.
- The project name defaults to `foundryvtt-dev` so Compose-generated container names do not collide with base-v2.
- Foundry uses UID/GID 1000 in this layout. See the testing guide for permissions.
- `.env`, generated secrets, runtime data and logs must never be committed. Keep the Foundry license private.
- There are no automated infrastructure backups. Native Foundry backups remain enabled; stop Foundry before making a manual filesystem backup.
- Foundry VTT itself requires a valid license. No license for this Compose repository is asserted here.
