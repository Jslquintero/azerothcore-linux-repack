#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")"

if ! command -v docker >/dev/null 2>&1; then
    echo "Docker is required. Install Docker Engine/Desktop, then run this again." >&2
    exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
    echo "Docker Compose v2 is required. The command 'docker compose' was not found." >&2
    exit 1
fi

if [ ! -f .env ] && [ -f .env.example ]; then
    cp .env.example .env
    echo "Created .env from .env.example"
fi

docker compose up -d --build

if [ -f .env ]; then
    # shellcheck disable=SC1091
    . ./.env
fi

echo
echo "AzerothCore repack is starting."
echo "Auth: ${DOCKER_AUTH_EXTERNAL_PORT:-3724} | World: ${DOCKER_WORLD_EXTERNAL_PORT:-8085} | realmlist: 127.0.0.1"
echo "Use ./logs.sh to watch startup."
