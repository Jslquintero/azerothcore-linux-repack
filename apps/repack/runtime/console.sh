#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"
source ./language.sh
load_language
msg console_create_account
msg console_detach
docker compose -f compose.json attach --sig-proxy=false ac-worldserver
