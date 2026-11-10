#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"
[[ -f .installed-version ]] || exec ./instalar.sh
[[ $(cat .installed-version) == "$(cat VERSION)" ]] || { echo 'Versión instalada incompatible.' >&2; exit 1; }
docker compose -f compose.json up -d --no-build --pull never ac-authserver ac-worldserver
echo 'Servidor iniciándose. Consulta ./logs.sh hasta que termine de cargar el mundo.'
echo 'Cliente WoW 3.3.5a: set realmlist 127.0.0.1'
echo 'Crea tu cuenta con ./crear-cuenta.sh cuando el servidor esté listo.'
echo 'Instala client/patch-z.mpq en Data y client/AcoreRacialTooltips en Interface/AddOns.'
