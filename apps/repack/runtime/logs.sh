#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"
docker compose -f compose.json logs -f --tail 100 ac-authserver ac-worldserver
