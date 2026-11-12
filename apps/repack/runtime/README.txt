AzerothCore WotLK Offline Repack — Linux x86_64

Requirements
- Docker Engine with the Docker Compose v2 plugin
- A WoW 3.3.5a client, build 12340 (not included)
- At least 30 GB of free disk space for extraction, images, and game data

Install and start
1. Run ./install.sh. Choose English or Español when prompted.
2. The installer loads the bundled Docker images and initializes the server.
   It does not download images or compile the server.
3. Wait for the worldserver to finish starting. Follow its logs with ./logs.sh.
4. Run ./create-account.sh and choose the language for its prompts.
5. Copy client/patch-z.mpq into the client's Data directory.
6. Copy client/AcoreRacialTooltips into Interface/AddOns and enable the addon.
7. Set the client's realmlist to: set realmlist 127.0.0.1
8. Run ./start.sh to start the servers later, and ./stop.sh to stop them.

You can attach to the worldserver console with ./console.sh. Detach with
Ctrl+P, Ctrl+Q; this leaves the server running. Without Python 3, create an
account from that console with: account create USERNAME PASSWORD

The first database initialization can take several minutes. The preset starts
100 bots; adjust the random bot count settings in compose.json if desired.

Accounts and characters are stored in Docker volumes for the acore-offline
project. Do not run docker compose down -v: that deletes the saved data. Keep
the .env file and COMPOSE_PROJECT_NAME unchanged after installation so Docker
continues using the same volumes.

Reinstalling this same package version preserves existing data. Automatic
upgrades between package versions are not supported. Back up the database
before replacing a package or changing versions.

MySQL is not published to the host. Authentication, world, and SOAP ports bind
to 127.0.0.1. The optional AzerothCore Dashboard can manage accounts and issue
commands through SOAP; configure it with a GM level 3 account. Do not expose
SOAP publicly. For LAN access, configure the game ports and realm address before
connecting from another computer. The WoW client is not included.
