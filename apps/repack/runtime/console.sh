#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"
echo 'Crear cuenta: account create USUARIO CONTRASEÑA'
echo 'Salir de la consola sin apagar el servidor: Ctrl+P, Ctrl+Q.'
docker compose -f compose.json attach --sig-proxy=false ac-worldserver
