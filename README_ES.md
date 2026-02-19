# AzerothCore Linux Repack

Un repack autocontenido de AzerothCore WotLK 3.3.5a para Linux con imagenes Docker preconstruidas. No necesitas compilar nada — solo extraer y ejecutar.

## Contenido

- **AzerothCore WotLK** (fork con Playerbots)
- **Imagenes Docker preconstruidas** — ahorra los 20-40 min de compilacion
- **AzerothCore Dashboard** (AppImage)
- **Modulos:**
  - mod-playerbots
  - mod-individual-progression
  - mod-autobalance
  - mod-transmog
  - mod-ah-bot
  - mod-learn-spells
  - mod-aoe-loot
  - mod-account-achievements
  - mod-junk-to-gold
  - mod-leech
  - mod-no-hearthstone-cooldown
  - mod-reagent-bank
  - mod-account-mounts
  - mod-player-bot-level-brackets
  - mod-TimeIsTime
  - mod-npc-buffer

## Requisitos

- **Linux** (probado en Fedora, deberia funcionar en cualquier distro)
- **Docker** y **Docker Compose** instalados
- ~3 GB de espacio libre en disco

## Inicio Rapido

1. Descarga `azerothcore-repack.tar.xz` desde la pagina de [Releases](../../releases).

2. Extraer y ejecutar:

   ```bash
   tar -xf azerothcore-repack.tar.xz
   cd azerothcore-repack
   ./start.sh
   ```

3. El script hara lo siguiente:
   - Cargar las imagenes Docker preconstruidas
   - Iniciar todos los contenedores (base de datos, worldserver, authserver)
   - Esperar a que la base de datos este lista
   - Aplicar los scripts SQL de los modulos
   - Reiniciar el servidor con los cambios aplicados

4. Crear una cuenta GM:

   ```bash
   docker attach ac-worldserver
   account create <usuario> <contraseña>
   account set gmlevel <usuario> 3 -1
   ```

   Salir de la consola con: `Ctrl+P`, `Ctrl+Q`

5. Configurar el realmlist de tu cliente WoW 3.3.5a:
   ```
   set realmlist 127.0.0.1
   ```

## Puertos

| Servicio    | Puerto |
| ----------- | ------ |
| Worldserver | 8085   |
| Authserver  | 3724   |
| MySQL       | 3306   |

## Detener el Servidor

```bash
cd azerothcore-repack/azerothcore-wotlk
docker compose down
```

## Reiniciar (despues de la primera vez)

Despues de la primera ejecucion, no necesitas `start.sh` de nuevo. Solo:

```bash
cd azerothcore-repack/azerothcore-wotlk
docker compose up -d
```

## Instalacion Manual (Construir tu Propia Version)

Si prefieres compilar desde el codigo fuente y elegir tus propios modulos:

```bash
git clone <este-repo>
cd azerothcore-linux-repack
./install.sh
```

Edita `install.sh` para agregar o quitar modulos a tu gusto. Despues de que termine la compilacion:
```bash
./setup-sql.sh
```

**Nota:** El release `.tar.xz` es una version preconstruida con un conjunto especifico de modulos — principalmente por conveniencia y como copia de seguridad personal.

## Licencia

AzerothCore se distribuye bajo la [GNU AGPL v3](https://www.gnu.org/licenses/agpl-3.0.en.html). Cada modulo conserva su propia licencia.
