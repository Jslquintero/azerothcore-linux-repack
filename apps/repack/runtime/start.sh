#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"
source ./language.sh
load_language
[[ -f .installed-version ]] || exec ./install.sh
[[ $(cat .installed-version) == "$(cat VERSION)" ]] || { msg version_mismatch >&2; exit 1; }
docker compose -f compose.json up -d --no-build --pull never ac-authserver ac-worldserver
msg server_starting
msg realmlist
msg create_account_hint
msg client_files
