#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"
command -v docker >/dev/null || { echo 'Instala Docker y vuelve a ejecutar este archivo.' >&2; exit 1; }
docker compose version >/dev/null
docker info >/dev/null
version=$(cat VERSION)
if [[ -f .installed-version ]]; then
  [[ $(cat .installed-version) == "$version" ]] || {
    echo 'Esta carpeta contiene otra versión instalada. Conserva sus datos; no se admite actualizar con una semilla nueva.' >&2
    exit 1
  }
  exec ./start.sh
fi
echo 'Verificando el paquete completo...'
sha256sum --check --quiet SHA256SUMS
if [[ ! -f .env ]]; then
  umask 077
  password=$(od -An -N24 -tx1 /dev/urandom | tr -d ' \n')
  printf 'COMPOSE_PROJECT_NAME=acore-offline\nREPACK_DB_PASSWORD=%s\nREPACK_AUTH_PORT=3724\nREPACK_WORLD_PORT=8085\n' "$password" > .env
fi
echo 'Cargando imágenes locales (sin descargas)...'
docker load -i images.tar.gz
docker compose -f compose.json run --rm --no-deps init-data
docker compose -f compose.json up -d --no-build --pull never ac-database
echo 'Preparando la base inicial. Este paso puede tardar varios minutos...'
for ((attempt=0; attempt<600; attempt++)); do
  installed=$(docker compose -f compose.json exec -T ac-database sh -c \
    'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" mysql --protocol=TCP -h127.0.0.1 -uroot \
      -Nse "SELECT version FROM repack_meta.installation WHERE ready=1"' \
    2>/dev/null) || installed=''
  if [[ -n "$installed" ]]; then
    [[ "$installed" == "$version" ]] || {
      echo 'El volumen de base de datos pertenece a otra versión. No se ha reemplazado.' >&2
      exit 1
    }
    printf '%s\n' "$version" > .installed-version
    exec ./start.sh
  fi
  sleep 2
done
echo 'La base no terminó de inicializarse. Revisa: docker compose -f compose.json logs ac-database' >&2
exit 1
