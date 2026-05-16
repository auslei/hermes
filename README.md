# Hermes Agent & WebUI

This project runs the `nousresearch/hermes-agent` container alongside the 3rd party `hermes-webui`. It includes a mounted local data directory and helper shell scripts for day-to-day use.

The agent container is built locally to include necessary system dependencies (Docker CLI, Node.js, etc.) and starts with an `uv`-based command:

`uv sync --all-extras && HERMES_ALLOW_ROOT_GATEWAY=1 uv run hermes gateway run`

## What Runs

- `docker-compose.yml`: builds and starts the `hermes` (agent) and `hermes-webui` (3rd party UI) containers.
- `hermes.sh`: helper entrypoint for shell mode or Hermes subcommands.
- `hermes_terminal.sh`: opens a bash shell inside the running `hermes` agent container.

## Container Configuration

### Hermes Agent
- Build: `.` (local Dockerfile based on `nousresearch/hermes-agent`)
- Container name: `hermes`
- Command: `sh -c "uv sync --all-extras && HERMES_ALLOW_ROOT_GATEWAY=1 uv run hermes gateway run"`
- Data mount: `./opt_data:/opt/data`
- Hermes home mount: `./opt_hermes/.hermes:/opt/hermes/.hermes`
- Output mount: `./output:/output`
- Docker socket: `/var/run/docker.sock:/var/run/docker.sock` (DooD - Docker-outside-of-Docker)

### Hermes WebUI (3rd Party)
- Image: `ghcr.io/nesquena/hermes-webui:latest`
- Container name: `hermes-webui`
- Data mount: `./opt_data:/home/hermeswebui/.hermes` (shares config with agent)
- Output mount: `./output:/workspace`
- Agent Source mount: `hermes-agent-src:/home/hermeswebui/.hermes/hermes-agent`

## Ports

- `8642`: Gateway API (Agent)
- `9119`: Dashboard UI (Agent Built-in)
- `8787`: Hermes WebUI (3rd Party Interface)

## Environment

Firstly, run the following to setup UID and GID in the `.env` file to ensure proper file permissions:
```bash
echo "UID=$(id -u)" >> .env
echo "GID=$(id -g)" >> .env
```

Key Variables:
- `HERMES_UID=${UID}` / `HERMES_GID=${GID}`: Synchronizes host user permissions inside containers.
- `HERMES_SANDBOX_TYPE=local`: Configured to run skills in the local container environment for simplicity.
- `HERMES_DASHBOARD=1`: Enables the built-in dashboard UI on port 9119.
- `HERMES_OUTPUT_PATH=${PWD}/output`: Host path for generated artifacts.

## Setup

Create the local data directories first:

```bash
mkdir -p ./opt_data
mkdir -p ./opt_hermes
mkdir -p ./output
```

Build and start the containers:

```bash
docker compose up -d
```

## Using Hermes CLI

The helper scripts allow you to interact with the running agent container:

- `./hermes.sh` with no arguments: opens `/bin/bash` inside the container.
- `./hermes.sh <args>`: runs `uv run hermes <args>` inside the container.
- `./hermes_terminal.sh`: direct shortcut to a bash shell.

Make the scripts executable:
```bash
chmod +x ./hermes.sh ./hermes_terminal.sh
```

Examples:
```bash
./hermes.sh gateway status
./hermes.sh skills list
```

## Access

Once the containers are up, the services are available at:

- **3rd Party WebUI:** [http://localhost:8787](http://localhost:8787) (Recommended)
- **Built-in Dashboard:** [http://localhost:9119](http://localhost:9119)
- **Gateway API:** [http://localhost:8642](http://localhost:8642)

## Troubleshooting

### 1. Permission Denied on Docker Socket
**Issue:** `permission denied while trying to connect to the docker API at unix:///var/run/docker.sock`
**Fix:** The `Dockerfile` now installs `sudo` and grants passwordless access. If you still encounter issues on the host, you may need to run:
`sudo chmod 666 /var/run/docker.sock`

### 2. Architecture Mismatch (Docker Binary)
**Issue:** Errors like `Docker command is available but 'docker version' failed.`
**Status:** **Resolved.** The local `Dockerfile` now automatically installs the correct `docker-ce-cli` for your architecture (ARM64 for Mac, AMD64 for Linux) instead of mounting the host binary.

### 3. Choosing the Right Terminal Backend
**Tip:** This setup uses `HERMES_SANDBOX_TYPE=local`. This is the simplest configuration as it runs skills directly within the `hermes` container. Since `/opt_data` is persisted on your host, you can safely restart or rebuild the container without losing your memory or skills.

### 4. Resolving "Amnesia" or Path Errors
**Issue:** Hermes fails to find skills or forgets past memories after a configuration change.
**Cause:** Hermes saves internal paths in `opt_data/config.yaml`.
**Fix:** If paths change (e.g., you renamed a folder on the host), update `opt_data/config.yaml` manually or delete it to let Hermes re-generate a fresh configuration on next boot.

### 5. WebUI Connection Issues
**Issue:** The WebUI cannot connect to the agent.
**Fix:** Ensure the `hermes` agent container is running (`docker compose ps`). The WebUI depends on the agent being healthy. Check logs for both:
```bash
docker compose logs -f hermes
docker compose logs -f hermes-webui
```

### 6. Container Reset vs Image Rebuild
- **`docker compose restart`**: Quick restart of processes.
- **`docker compose down && docker compose up -d`**: Recreates containers (apply `docker-compose.yml` changes).
- **`docker compose up -d --build`**: Rebuilds the agent image (apply `Dockerfile` changes).