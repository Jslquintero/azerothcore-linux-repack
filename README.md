# AzerothCore Linux Repack by Jslquintero

## English

This is my personal Linux repack for **AzerothCore WotLK 3.3.5a**, packaged as a
self-contained repo with Docker Compose, included modules, and my own gameplay
defaults.

It is based on the mod-playerbots AzerothCore branch, but this repo is meant to
stand on its own. I made local changes to both the core and some modules,
including Playerbots behavior, so the goal is simple: clone it, start it, and
play without hunting down separate module repos.

This is not an official AzerothCore distribution. It is a personal server setup
that I am sharing publicly in case someone else finds it useful, wants to fork
it, or wants to use it as a base for their own server.

### Quick Start

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

For LAN, replace `127.0.0.1` with the server machine's LAN IP.

### Repack Defaults

This repo intentionally includes an official `docker-compose.override.yml`.
Docker Compose loads it automatically together with `docker-compose.yml`. In
this repack, the override is part of the default setup, not a private local
file.

Included gameplay defaults:

- Playerbots enabled.
- Individual Progression enabled.
- Blood Elves, Draenei, and Death Knights available from the start.
- Random bot progression, level, race, class, and map handling adapted for this
  repack.
- Autobalance.
- Transmog.
- Account-wide mounts and achievements.
- Auction House Bot.
- AoE Loot.
- Learn Spells.
- Leech.
- Reagent Bank.
- No Hearthstone cooldown.
- Time Is Time.

### Included Modules

Modules are vendored directly under `modules/` as normal folders, not Git
submodules. This keeps the repo self-contained.

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

### Optional Dashboard

I also made a custom dashboard that can be used with this repack:

https://github.com/Jslquintero/azerothcore-dashboard

The dashboard is an Electron app for managing AzerothCore Docker services on
Linux. It can be used for service start/stop/restart, worldserver console
commands, account management, live logs, editing `docker-compose.override.yml`
variables, realm settings, item browsing, module docs, tray integration, and
update notifications.

The dashboard is optional. This repack also works from the terminal with the
scripts included here.

### Local Config

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

### Notes

- Built for personal servers and playing with friends.
- Not intended as a professional private server hosting package.
- Large SQL files are included because this is a source-based repack.
- Client data extraction may still be required depending on your Docker image
  setup and available volumes.

---

## Español

Este es mi repack personal para Linux de **AzerothCore WotLK 3.3.5a**,
empaquetado como un repo autocontenido con Docker Compose, módulos incluidos y
mis propios defaults de gameplay.

Está basado en la rama de AzerothCore de mod-playerbots, pero este repo está
pensado para funcionar como proyecto independiente. Hice cambios locales tanto
en el core como en algunos módulos, incluyendo comportamiento de Playerbots, así
que la idea es simple: clonar, iniciar y jugar sin tener que buscar módulos en
repos separados.

Esta no es una distribución oficial de AzerothCore. Es mi setup personal de
servidor, publicado por si a alguien más le sirve, quiere hacer fork o usarlo
como base para su propio servidor.

### Inicio Rápido

Requisitos:

- Docker
- Docker Compose v2

Iniciar el repack:

```bash
./start.sh
```

Ver logs de authserver y worldserver:

```bash
./logs.sh
```

Detener todo:

```bash
./stop.sh
```

Entrar a la consola del worldserver:

```bash
./console.sh
```

Configura el realmlist de tu cliente WoW 3.3.5a así:

```text
set realmlist 127.0.0.1
```

Para LAN, cambia `127.0.0.1` por la IP LAN de la máquina donde corre el
servidor.

### Defaults Del Repack

Este repo incluye intencionalmente un `docker-compose.override.yml` oficial.
Docker Compose lo carga automáticamente junto con `docker-compose.yml`. En este
repack, el override es parte del setup default, no un archivo local privado.

Defaults de gameplay incluidos:

- Playerbots activado.
- Individual Progression activado.
- Blood Elves, Draenei y Death Knights disponibles desde el inicio.
- Manejo de progresión, nivel, raza, clase y mapas de random bots adaptado para
  este repack.
- Autobalance.
- Transmog.
- Mounts y achievements account-wide.
- Auction House Bot.
- AoE Loot.
- Learn Spells.
- Leech.
- Reagent Bank.
- Sin cooldown de Hearthstone.
- Time Is Time.

### Módulos Incluidos

Los módulos están vendorizados directamente bajo `modules/` como carpetas
normales, no como Git submodules. Esto mantiene el repo autocontenido.

Módulos destacados:

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

### Dashboard Opcional

También hice un dashboard custom que se puede usar con este repack:

https://github.com/Jslquintero/azerothcore-dashboard

El dashboard es una app Electron para manejar servicios Docker de AzerothCore en
Linux. Sirve para iniciar/detener/reiniciar servicios, ejecutar comandos en la
consola del worldserver, manejar cuentas, ver logs en vivo, editar variables de
`docker-compose.override.yml`, cambiar settings del realm, buscar items, ver
docs de módulos, usar tray integration y recibir update notifications.

El dashboard es opcional. Este repack también funciona desde la terminal con los
scripts incluidos aquí.

### Config Local

`start.sh` crea `.env` desde `.env.example` si `.env` todavía no existe. Edita
`.env` para settings locales como puertos, password de base de datos o nombres
de volúmenes.

Valores comunes:

```env
DOCKER_AUTH_EXTERNAL_PORT=3724
DOCKER_WORLD_EXTERNAL_PORT=8085
DOCKER_SOAP_EXTERNAL_PORT=7878
DOCKER_DB_EXTERNAL_PORT=3306
```

Para overrides personales de Compose, crea un archivo local separado:

```bash
docker compose -f docker-compose.yml -f docker-compose.override.yml -f docker-compose.local.yml up -d --build
```

Los archivos `*.local.yml`, `*.local.yaml`, `*.local.override.yml` y
`*.local.override.yaml` son ignorados por Git.

### Notas

- Hecho para servidores personales y jugar con amigos.
- No está pensado como paquete profesional para hosting de servidores privados.
- Los SQL grandes están incluidos porque este es un repack basado en source.
- La extracción de datos del cliente puede seguir siendo necesaria dependiendo
  de la imagen Docker y los volúmenes disponibles.
