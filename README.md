# AzerothCore WotLK Personal Repack

Personal, batteries-included AzerothCore WotLK repack based on the
mod-playerbots AzerothCore branch. It ships the core, Docker setup, and modules
as one repository so it can be cloned and started with Docker Compose.

This repack intentionally includes an official `docker-compose.override.yml`.
Docker Compose loads it automatically with `docker-compose.yml`; it is not a
private local override in this repo.

## Quick Start

Requirements:

- Docker
- Docker Compose v2

Start everything:

```bash
./start.sh
```

Watch startup logs:

```bash
./logs.sh
```

Stop everything:

```bash
./stop.sh
```

Set your WoW 3.3.5a client realmlist to:

```text
set realmlist 127.0.0.1
```

## What Is Included

- AzerothCore WotLK server source.
- Playerbots support with local repack changes.
- Included modules under `modules/`.
- Official repack defaults in `docker-compose.override.yml`.
- Docker-managed MySQL database, authserver, worldserver, logs, and data
  volumes.

## Repack Gameplay Defaults

The included override enables the repack's intended defaults, including:

- Playerbots.
- Individual progression.
- Blood Elves, Draenei, and Death Knights available from the start.
- Random bot progression/map limiting logic.
- Autobalance, transmog, account mounts/achievements, auction house bot, AoE
  loot, and other quality-of-life modules.

## Local Customization

`start.sh` creates `.env` from `.env.example` if it does not exist. Edit `.env`
for ports, database password, or volume names.

For personal Compose changes, create a separate local file, for example:

```bash
docker compose -f docker-compose.yml -f docker-compose.override.yml -f docker-compose.local.yml up -d --build
```

Files named `*.local.yml`, `*.local.yaml`, `*.local.override.yml`, and
`*.local.override.yaml` are ignored by Git.

## Repository Notes

The modules are vendored as normal folders, not Git submodules. This keeps the
repo self-contained for people who just want to clone, start, and play.
