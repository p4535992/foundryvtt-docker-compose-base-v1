# Local module development and testing

This helper runs on the Docker host; it does not create a second container. Use a separate module repository and a disposable Foundry world.

## Build and deploy

1. Install and start the stack using the root README.
2. Build the module using its own tools (for example `npm run build`).
3. Ensure the output contains `module.json` with the correct `id`.
4. With Python 3 and rsync installed, run:

```bash
/path/to/stack/scripts/testing/deploy-module03.sh ./dist --dry-run
/path/to/stack/scripts/testing/deploy-module03.sh ./dist
```

The helper syncs files only into `foundry03/data/Data/modules/<id>/`. It removes stale files from that module directory only, so do not keep untracked work there. Keep source code in the module repository. It does not back up the previous build. Do not deploy while the module is actively writing to its own package files.

Alternatively configure a build/watch task to write to this directory directly. Do not create a host symlink to a module project outside the bind mount; it may not resolve inside the container.

## Permissions

The felddy layout uses UID/GID 1000. Run your build/deploy as the corresponding host user, or arrange restricted filesystem access to the module directory. If existing mount directories have different ownership, use `sudo bash scripts/prepare_runtime.sh` once; this changes only directory permissions, never recursively changes world or module files. On a remote host, copy the built module using your own SSH/rsync workflow and run the helper on the Docker host.

## Test

Open http://localhost:30000/, install a game system, create and launch a test world, then enable the module. Reload the browser after each build. Restart the service if necessary:

```bash
docker compose restart foundry03
docker compose logs -f foundry03
```

For automated browser tests, use Playwright in the module repository (not another Docker service), targeting the actual test world URL such as `http://localhost:30000/game`. Keep browser session cookies and test reports out of version control. No relay or MCP integration is included.
