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

Firstly run below to setup UID and GID in .env file:
```
echo "UID=$(id -u)" >> .env
echo "GID=$(id -g)" >> .env
```

- `HERMES_UID=${UID}`: file ownership UID inside the container.
- `HERMES_GID=${GID}`: file ownership GID inside the container.
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
mkdir -p ./opt_data
mkdir -p ./opt_hermes
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
- Ensuter terminal is enabled: `uv run hermes skills enable terminal`
- Run `sudo chmod 666 /var/run/docker.sock` if you see docker errors (on host)

### 1. Architecture Mismatch (Docker Binary)
**Issue:** You receive errors like `Docker command is available but 'docker version' failed.`
**Cause:** Mounting `/usr/local/bin/docker` from a Mac into a Linux container tries to force the container to run a macOS binary.
**Fix:** Never mount the Docker CLI binary from the host. Instead, install the Linux `docker-ce-cli` directly inside the `Dockerfile`. Use `dpkg --print-architecture` in the install script so it automatically fetches the ARM64 version for Mac and the AMD64 version for Linux.

### 2. Docker Socket Permissions
**Issue:** `permission denied while trying to connect to the docker API at unix:///var/run/docker.sock`
**Cause:** The Docker socket is owned by `root`. Because you mapped a host user (e.g., UID 501 or 1000) to the container to manage file permissions, the container user is blocked from using the socket.
**Fix:** Install `sudo` in the `Dockerfile` and grant passwordless access. In your `docker-compose.yml`, prepend the startup command to open the socket permissions at boot before starting the agent:
`command: sh -c "sudo chmod 666 /var/run/docker.sock && uv sync && ..."`

### 3. The "Mounts Denied" Path Trap
**Issue:** Hermes fails to spawn a sub-container with an error like: `The path /opt/data/skills is not shared from the host and is not known to Docker.`
**Cause:** If Hermes is configured to use the **Docker** terminal backend, it passes its *internal* container paths to your Mac's Docker Engine. The Mac daemon looks for `/opt/data/skills` at the root of your macOS hard drive and fails.
**Fix (Two options):**
1.  **Use Absolute Paths:** Change your `docker-compose.yml` to map exact host paths (e.g., `- ${PWD}/opt_data:${PWD}/opt_data`) and set `HOME=${PWD}/opt_data` so Hermes passes valid host paths to the daemon.
2.  **Create a Mac Symlink/Folder:** Run `sudo mkdir -p /opt/data` on your Mac, take ownership of it, and add it to Docker Desktop's File Sharing list. 

### 4. Choosing the Right Terminal Backend
**Issue:** Deciding between **Local** and **Docker** when configuring Hermes.
**Tip:** * **Docker:** Safest for running untrusted code, but requires solving the DooD Path Trap (see #3) and socket permission hurdles.
* **Local:** Much simpler to set up and avoids path mismatches. Since you are actively mapping `/opt_data` to your host, running "Local" is safe. If the agent breaks its internal Python environment, a simple container restart (which triggers `uv sync`) will instantly repair it without losing your mapped memory and skills.

### 5. Resolving "Amnesia" or Hardcoded Config Errors
**Issue:** You update `docker-compose.yml` volume paths, but Hermes still errors out looking for old paths, or it suddenly forgets its past memories.
**Cause:** Hermes saves paths internally inside a persistent `config.yaml` file located in your mapped data directory (e.g., `./opt_data`).
**Fix:** Open `./opt_data/config.yaml` and manually update the paths for `cwd`, `workspace`, and `skills_dir`. Alternatively, delete `config.yaml` and let Hermes generate a fresh one on the next boot.

### 6. Container Reset vs Image Rebuild
**Issue:** You change a setting, run `docker compose up`, but the error persists.
**Tip:**
* **`docker compose restart`**: Only restarts the active process. Good for applying changes made to external config files or triggering `uv sync`.
* **`docker compose down` then `up -d`**: Destroys the container and recreates it. Required if you changed volume mappings, environment variables, or the startup command in `docker-compose.yml`.
* **`docker compose up -d --build`**: Rebuilds the underlying system blueprint. Required *only* if you changed the `Dockerfile` (like adding new `apt-get` packages or changing user groups).