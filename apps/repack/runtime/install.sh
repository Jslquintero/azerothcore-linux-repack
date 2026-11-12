#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"
source ./language.sh
choose_language
if ! command -v docker >/dev/null; then
  msg docker_missing >&2
  exit 1
fi
if ! docker compose version >/dev/null 2>&1; then
  msg compose_missing >&2
  exit 1
fi
if ! docker info >/dev/null 2>&1; then
  msg daemon_unavailable >&2
  exit 1
fi
version=$(cat VERSION)
if [[ -f .installed-version ]]; then
  [[ $(cat .installed-version) == "$version" ]] || {
    msg version_mismatch >&2
    exit 1
  }
  exec ./start.sh
fi
msg checking_package
sha256sum --check --quiet SHA256SUMS
if [[ ! -f .env ]]; then
  umask 077
  password=$(od -An -N24 -tx1 /dev/urandom | tr -d ' \n')
  printf 'COMPOSE_PROJECT_NAME=acore-offline\nREPACK_DB_PASSWORD=%s\nREPACK_AUTH_PORT=3724\nREPACK_WORLD_PORT=8085\nREPACK_SOAP_PORT=7878\n' "$password" > .env
fi
msg loading_images
docker load -i images.tar.gz
docker compose -f compose.json run --rm --no-deps init-data
docker compose -f compose.json up -d --no-build --pull never ac-database
msg preparing_database
for ((attempt=0; attempt<600; attempt++)); do
  installed=$(docker compose -f compose.json exec -T ac-database sh -c \
    'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" mysql --protocol=TCP -h127.0.0.1 -uroot \
      -Nse "SELECT version FROM repack_meta.installation WHERE ready=1"' \
    2>/dev/null) || installed=''
  if [[ -n "$installed" ]]; then
    [[ "$installed" == "$version" ]] || {
      msg database_version_mismatch >&2
      exit 1
    }
    printf '%s\n' "$version" > .installed-version
    exec ./start.sh
  fi
  sleep 2
done
msg database_timeout >&2
exit 1
