# Hermes Agent

This project runs the `nousresearch/hermes-agent` container with a mounted local data directory and two helper shell scripts for day-to-day use.

The container is built from this repo and starts with an `uv`-based command:

`uv sync && HERMES_ALLOW_ROOT_GATEWAY=1 uv run hermes gateway run`

Interactive Hermes usage also happens through `uv run hermes` inside the running container.

## What Runs

- `docker-compose.yml`: builds and starts the `hermes` container.
- `hermes.sh`: helper entrypoint for shell mode or Hermes subcommands.
- `hermes_terminal.sh`: opens a bash shell inside the running container.

## Container Configuration

- Build: `.` (local Dockerfile)
- Container name: `hermes`
- Command: `sh -c "uv sync && HERMES_ALLOW_ROOT_GATEWAY=1 uv run hermes gateway run"`
- Data mount: `./data:/opt/data`
- Hermes home mount: `./data/hermes:/opt/hermes/.hermes`
- Output mount: `./output:/output`
- Docker socket: `/var/run/docker.sock:/var/run/docker.sock`
- Docker CLI binary mount: `/usr/bin/docker:/usr/bin/docker`

## Ports

- `8642`: Gateway API
- `9119`: Dashboard UI

## Environment

- `HERMES_UID=${UID:-1000}`: file ownership UID inside the container.
- `HERMES_GID=${GID:-1000}`: file ownership GID inside the container.
- `GATEWAY_ALLOW_ALL_USERS=true`: allows gateway access for all users in the container.
- `HERMES_OUTPUT_PATH=${PWD}/output`: host output target path.
- `HERMES_DASHBOARD=1`: enables the dashboard UI.
- `npm_config_cache=/tmp/.npm`: npm cache path in container.
- `UV_CACHE_DIR=/opt/data/.uv-cache`: uv cache path on mounted data volume.
- `HOME=/opt/hermes`: sets Hermes user home inside container.
- `XDG_CACHE_HOME=/tmp/.cache`: cache home path in container.
- `HERMES_MODEL_CONTEXT_LENGTH=40960`: explicit model context length.
- `HERMES_MODEL_MIN_CONTEXT_LENGTH=32768`: minimum accepted context length override.

`host.docker.internal` is mapped to the host gateway IP so the container can reach services running on the host.

## Setup

Create the local data directory first:

```bash
mkdir -p ./data
mkdir -p ./data/hermes
mkdir -p ./output
```

Run setup once:

```bash
docker run -it --rm -v ./data:/opt/data nousresearch/hermes-agent setup
```

Build and start the container:

```bash
docker compose up -d
```

## Starting Hermes

`uv` is required for this repo's startup and CLI flow.

The helper script behavior is:

- `./hermes.sh` with no arguments: opens `/bin/bash` inside the container.
- `./hermes.sh <args>`: runs `uv run hermes <args>` inside the container.

Make the scripts executable if needed:

```bash
chmod +x ./hermes.sh ./hermes_terminal.sh
```

Open shell mode (default):

```bash
./hermes.sh
```

Run Hermes command mode (examples):

```bash
./hermes.sh --help
./hermes.sh gateway status
```

Open a shell in the container:

```bash
./hermes_terminal.sh
```

If the container is not running, both scripts will fail and prompt you to start it with `docker compose up -d` first.

## Access

Once the container is up, the services are available at:

- Dashboard UI: `http://localhost:9119`
- Gateway API: `http://localhost:8642`

## Common Commands

```bash
docker compose down
docker compose logs -f
docker compose ps
docker compose up
```

## Data Directory

Hermes configuration and working state are stored in `./data` on the host and mounted into the container.

Generated outputs are written to `./output` on the host through the `/output` mount.

## Troubleshooting
- Always use uv run before hermes in terminal
- Ensuter terminal is enabled: 
`uv run hermes skills enable terminal`