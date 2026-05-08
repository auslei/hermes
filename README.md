# Hermes Agent

This project runs the `nousresearch/hermes-agent` container with a mounted local data directory and two helper shell scripts for day-to-day use.

The container itself starts with `gateway run`, and the interactive Hermes CLI is launched from inside the running container with `uv run hermes`.

## What Runs

- `docker-compose.yml`: starts the `hermes` container.
- `hermes.sh`: opens the Hermes CLI with `uv run hermes` inside the running container.
- `hermes_terminal.sh`: opens a bash shell inside the running container.

## Container Configuration

- Image: `nousresearch/hermes-agent:latest`
- Container name: `hermes`
- Command: `gateway run`
- Data mount: `./data:/opt/data`
- Docker socket: `/var/run/docker.sock:/var/run/docker.sock`

## Ports

- `8642`: Gateway API
- `9119`: Dashboard UI

## Environment

- `HERMES_UID=${UID:-1000}`: file ownership UID inside the container.
- `HERMES_GID=${GID:-1000}`: file ownership GID inside the container.
- `GATEWAY_ALLOW_ALL_USERS=true`: allows gateway access for all users in the container.
- `HERMES_DASHBOARD=1`: enables the dashboard UI.

`host.docker.internal` is mapped to the host gateway IP so the container can reach services running on the host.

## Setup

Create the local data directory first:

```bash
mkdir -p ./data
```

Pull the image and run initial setup:

```bash
docker compose pull
docker run -it --rm -v ./data:/opt/data nousresearch/hermes-agent setup
```

Start the container:

```bash
docker compose up -d
```

## Starting Hermes

`uv` is required for the CLI flow used by this repo. The provided launcher script starts Hermes with `uv run hermes` inside the running container.

Make the scripts executable if needed:

```bash
chmod +x ./hermes.sh ./hermes_terminal.sh
```

Launch the Hermes CLI:

```bash
./hermes.sh
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
```

## Data Directory

Hermes configuration, memory, and generated outputs are stored in `./data` on the host and mounted at `/opt/data` in the container.
# hermes
