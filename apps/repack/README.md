# Offline distribution

The source checkout remains available for development. The offline distribution
uses precompiled local images and a clean SQL seed, and never runs a build or pull
on the player's machine. It currently targets Linux amd64 and requires Docker
Engine with Compose v2 already installed.

## Package a release

To generate the offline package, create a GitHub Release, and upload the archive
and checksum in one step, run this from the repository root after committing and
pushing the source changes:

```bash
./release-offline.sh 1.1.1
```

Use the next unused `MAJOR.MINOR.PATCH` version. The script requires `gh`
authenticated to the repository and a clean checkout matching the latest commit
on its upstream branch. It keeps the generated package and archive beside the
source checkout. Use `--output-dir /path/to/package` to choose another location;
options such as `--client-patch` are passed to the exporter. It refuses to
overwrite existing output or reuse an existing release/tag.

For packaging without publishing, use the exporter directly:

From the repository root:

```bash
./export-offline.sh --output /path/to/new/repack-directory
```

Packaging requires Python 3 with `mpyq` (`python3 -m pip install mpyq`), Docker access, the three local images used by Compose
(MySQL, authserver and worldserver), and the `ac-worldserver` container
with its complete server data mount, plus the running `ac-database`. Select other
containers with `--world-container` and `--database-container`. The matching client MPQ defaults to
`env/dist/client-patches/patch-z.mpq`; override it with `--client-patch`.
The output directory must not exist and must be outside the source tree.
Allow at least 30 GB of free disk space; actual requirements depend on maps and
database size. No images are built, downloaded or published by this script.

The exporter:

- Pins runtime images to unique tags derived from their image IDs.
- Creates temporary MySQL on an internal Docker network without published ports.
  Reads the working world database as the release content. This preserves the
  installed module content even where historical module SQL is incompatible with
  current AzerothCore schemas. The source database remains running and unchanged.
- Copies only table structures from auth and characters, never their row data.
  Adds stock realm/build metadata, arena and permission defaults, plus the
  static Playerbots name dictionaries. Initializes Playerbots from module SQL.
  Checks that accounts and characters are empty before exporting the four clean
  databases. It never copies the live configuration or `.env`.
- Requires a trusted, working release world database. Avoid editing world content
  while exporting; custom world tables must contain distributable game content,
  not private data. The exporter does not migrate legacy module SQL.
- Reads the server data volume read-only, overlays the repository custom DBCs
  in a disposable copy, and verifies the packaged DBC hashes. It does not
  generate DBCs or change the source volume. The client MPQ must contain the
  same versioned DBCs; packaging fails on missing or mismatched DBC hashes.
  The MPQ is verified, never rebuilt by the exporter.
- Includes module runtime data, defaults, the client patch/addon, scripts and
  SHA-256 checksums. Runtime images use their embedded default configuration.
- Removes its temporary containers, anonymous volumes and network even on failure.
  A failed output directory is retained with diagnostics; use a new directory on retry.

The source SQL, module assets, client MPQ and already compiled images must belong
to the same release. The manifest records the source revision, dirty state,
image IDs and client patch checksum. It does not claim that existing binaries
were built from the current checkout.

The output folder is the distributable artifact. To share one archive:

```bash
tar -czf AzerothCore-offline.tar.gz -C /path/to/new repack-directory
```

Images and maps are already compressed inside the folder; outer compression
also reduces the SQL seed and module assets.

## Install and verify

Run `./install.sh` from the output directory and choose English or Spanish. It
verifies checksums, loads images, restores maps, initializes MySQL, and starts the
servers. It creates a random
database password. MySQL has no host port and game ports bind to loopback.
SOAP also binds to loopback; use a GM level 3 account for dashboard SOAP
features, and do not expose that port publicly. Runtime services use a standard
bridge so Docker can publish the ports.
They do not need Internet access; local images use `pull_policy: never`.

Use `./create-account.sh` (choose English or Spanish; requires Python 3 for its
terminal helper) to create a player account after startup. Without Python, use
`./console.sh` and
`account create USER PASSWORD`. The helper sends
the account command to the server, which validates and hashes the password; it
then checks that the account was created. `./console.sh` remains available.
Follow `README.txt` for English instructions or `README.es.txt` for Spanish.
Install the bundled client patch and addon as described there.
The offline preset has 100 bots; adjust the two random bot count settings in
`compose.json` if desired after installation.

For an isolated smoke test beside an existing installation, create `.env` before
installing with a unique `COMPOSE_PROJECT_NAME`, a `REPACK_DB_PASSWORD`,
`REPACK_AUTH_PORT=13724` and `REPACK_WORLD_PORT=18085`. Test startup from empty
volumes, account creation, stop/start and repeated installation. The advertised
realm port remains 8085; test game login requires adjusting `realmlist.port` for
an alternate published port. Default installations use 8085 directly.

Existing volumes are retained on stop and reinstall. Version markers reject
cross-version replacement: automated upgrades/migrations are not implemented.
Never use `down -v` on an installation containing saves. Keep `.env` and the
project name when moving an installation, and back up its database first.

Installer regression tests (no Docker daemon needed):

```bash
python3 apps/repack/test_runtime.py
```
