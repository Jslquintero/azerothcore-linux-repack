# AzerothCore Linux Repack

A self-contained, ready-to-run AzerothCore WotLK 3.3.5a server repack for Linux with prebuilt Docker images. No compilation needed — just extract and run.

## Included

- **AzerothCore WotLK** (Playerbot fork)
- **Prebuilt Docker images** — skip the 20-40 min build
- **AzerothCore Dashboard** (AppImage)
- **Modules:**
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

## Requirements

- **Linux** (tested on Fedora, should work on any distro)
- **Docker** and **Docker Compose** installed
- ~3 GB of free disk space

## Quick Start

1. Download `azerothcore-repack.tar.xz` from the [Releases](../../releases) page.

2. Extract and run:
   ```bash
   tar -xf azerothcore-repack.tar.xz
   cd azerothcore-repack
   ./start.sh
   ```

3. The script will:
   - Load the prebuilt Docker images
   - Start all containers (database, worldserver, authserver)
   - Wait for the database to be ready
   - Apply module SQL scripts
   - Restart the server with changes applied

4. Create a GM account:
   ```bash
   docker attach ac-worldserver
   account create <username> <password>
   account set gmlevel <username> 3 -1
   ```
   Exit the console with: `Ctrl+P`, `Ctrl+Q`

5. Set your WoW 3.3.5a client realmlist to:
   ```
   set realmlist 127.0.0.1
   ```

## Ports

| Service      | Port |
|-------------|------|
| Worldserver | 8085 |
| Authserver  | 3724 |
| MySQL       | 3306 |

## Stopping the Server

```bash
cd azerothcore-repack/azerothcore-wotlk
docker compose down
```

## Restarting (after first setup)

After the first run, you don't need `start.sh` again. Just:
```bash
cd azerothcore-repack/azerothcore-wotlk
docker compose up -d
```

## License

AzerothCore is released under the [GNU AGPL v3](https://www.gnu.org/licenses/agpl-3.0.en.html). Each module retains its own license.
