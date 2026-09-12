# AzerothCore Linux Repack

[Español](README.es.md)

A personal, self-contained AzerothCore WotLK repack for Linux, based on the
mod-playerbots AzerothCore branch. It ships the server source, Docker setup, and
all included modules in one repository so it can be cloned and started with
Docker Compose.

This is a personal repack shaped around my own preferred gameplay defaults. It
is public in case someone else wants to use it, fork it, or build on it.

## Quick Start

Requirements:

- Docker
- Docker Compose v2

Start the repack:

```bash
./start.sh
```

Watch the authserver and worldserver logs:

```bash
./logs.sh
```

Stop everything:

```bash
./stop.sh
```

Attach to the worldserver console:

```bash
./console.sh
```

Set your WoW 3.3.5a client realmlist to:

```text
set realmlist 127.0.0.1
```

For LAN use, replace `127.0.0.1` with the server machine's LAN IP.

## Included Defaults

This repository intentionally ships an official `docker-compose.override.yml`.
Docker Compose loads it automatically together with `docker-compose.yml`; in
this repack, the override is part of the intended setup, not a private local
file.

The included setup enables the repack's defaults, including:

- Playerbots.
- Individual progression.
- Blood Elves, Draenei, and Death Knights available from the start.
- Random bot progression, level, race, class, and map handling adapted for this
  repack.
- Autobalance, transmog, account mounts, account achievements, auction house
  bot, AoE loot, learn spells, leech, reagent bank, no hearthstone cooldown, and
  Time Is Time.

## Included Modules

Modules are vendored directly under `modules/` as normal folders, not Git
submodules. This keeps the repository self-contained for people who just want to
clone, start, and play.

Notable included modules:

- `mod-playerbots`
- `mod-individual-progression`
- `mod-autobalance`
- `mod-ah-bot`
- `mod-transmog`
- `mod-account-achievements`
- `mod-account-mounts`
- `mod-aoe-loot`
- `mod-learn-spells`
- `mod-player-bot-level-brackets`
- `mod-reagent-bank`
- `mod-TimeIsTime`

## Optional Dashboard

There is also a custom dashboard that can be used with this repack:

https://github.com/Jslquintero/azerothcore-dashboard

The dashboard is an Electron app for managing AzerothCore Docker services on
Linux. Its README describes features such as service start/stop/restart,
worldserver console commands, account management, live logs, editing
`docker-compose.override.yml` variables, realm settings, an item browser, module
documentation, tray integration, and update notifications.

The dashboard is optional. The repack works from the terminal with the scripts in
this repository.

## Local Configuration

`start.sh` creates `.env` from `.env.example` if `.env` does not already exist.
Edit `.env` for local settings such as ports, database password, or volume
names.

Common values:

```env
DOCKER_AUTH_EXTERNAL_PORT=3724
DOCKER_WORLD_EXTERNAL_PORT=8085
DOCKER_SOAP_EXTERNAL_PORT=7878
DOCKER_DB_EXTERNAL_PORT=3306
```

For personal Compose overrides, create a separate local file:

```bash
docker compose -f docker-compose.yml -f docker-compose.override.yml -f docker-compose.local.yml up -d --build
```

Files named `*.local.yml`, `*.local.yaml`, `*.local.override.yml`, and
`*.local.override.yaml` are ignored by Git.

## Notes

- This repack is aimed at personal servers and playing with friends.
- It is not intended as a professional private server hosting package.
- Large SQL files are included because AzerothCore needs them for a complete
  source-based setup.
- Client data extraction may still be required depending on your Docker image
  setup and available volumes.
