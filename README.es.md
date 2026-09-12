# AzerothCore Linux Repack

[English](README.md)

Repack personal y autocontenido de AzerothCore WotLK para Linux, basado en la
rama de AzerothCore de mod-playerbots. Incluye el código del servidor, la
configuración Docker y todos los módulos en un solo repositorio para poder
clonarlo y arrancarlo con Docker Compose.

Este es un repack personal hecho alrededor de mis propios ajustes de gameplay.
Lo dejo público por si alguien más quiere usarlo, bifurcarlo o tomarlo como base.

## Inicio Rápido

Requisitos:

- Docker
- Docker Compose v2

Arrancar el repack:

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

Para jugar en LAN, cambia `127.0.0.1` por la IP LAN de la máquina donde corre el
servidor.

## Defaults Incluidos

Este repositorio incluye intencionalmente un `docker-compose.override.yml`
oficial. Docker Compose lo carga automáticamente junto con `docker-compose.yml`;
en este repack, el override es parte de la configuración esperada, no un archivo
local privado.

La configuración incluida activa los defaults del repack, entre ellos:

- Playerbots.
- Progresión individual.
- Blood Elves, Draenei y Death Knights disponibles desde el inicio.
- Manejo de progresión, nivel, raza, clase y mapas de bots aleatorios adaptado a
  este repack.
- Autobalance, transmog, monturas de cuenta, logros de cuenta, auction house bot,
  AoE loot, learn spells, leech, reagent bank, sin cooldown de hearthstone y
  Time Is Time.

## Módulos Incluidos

Los módulos están vendorizados directamente bajo `modules/` como carpetas
normales, no como submódulos de Git. Esto mantiene el repositorio autocontenido
para quien solo quiera clonar, iniciar y jugar.

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

## Dashboard Opcional

También existe un dashboard custom que puede usarse con este repack:

https://github.com/Jslquintero/azerothcore-dashboard

El dashboard es una app Electron para manejar servicios Docker de AzerothCore en
Linux. Su README describe funciones como iniciar/detener/reiniciar servicios,
ejecutar comandos de consola del worldserver, manejar cuentas, ver logs en vivo,
editar variables de `docker-compose.override.yml`, cambiar ajustes del reino,
buscar items, ver documentación de módulos, integrarse a la bandeja del sistema
y recibir notificaciones de actualización.

El dashboard es opcional. El repack funciona desde la terminal con los scripts
incluidos en este repositorio.

## Configuración Local

`start.sh` crea `.env` desde `.env.example` si `.env` todavía no existe. Edita
`.env` para ajustes locales como puertos, contraseña de base de datos o nombres
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

## Notas

- Este repack está pensado para servidores personales y jugar con amigos.
- No está pensado como paquete profesional para hosting de servidores privados.
- Los SQL grandes están incluidos porque AzerothCore los necesita para una
  instalación completa desde código fuente.
- La extracción de datos del cliente puede seguir siendo necesaria dependiendo
  de la imagen Docker y los volúmenes disponibles.
