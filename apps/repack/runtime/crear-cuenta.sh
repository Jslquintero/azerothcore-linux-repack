#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C
cd -- "$(dirname -- "$0")"
command -v python3 >/dev/null || {
  echo 'El asistente necesita Python 3. También puedes crear la cuenta con ./console.sh:' >&2
  echo 'account create USUARIO CONTRASEÑA' >&2
  exit 1
}
read -rp 'Nombre de cuenta (letras y números, máximo 16): ' username
read -rsp 'Contraseña (letras y números, máximo 16): ' password
echo
[[ "$username" =~ ^[a-zA-Z0-9]{1,16}$ && "$password" =~ ^[a-zA-Z0-9]{1,16}$ ]] || {
  echo 'Usa entre 1 y 16 letras/números en ambos campos.' >&2
  exit 1
}
username=${username^^}
exists() {
  docker compose -f compose.json exec -T ac-database sh -c \
    'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" mysql -uroot -Nse "$1"' sh \
    "SELECT COUNT(*) FROM acore_auth.account WHERE username='$username'" 2>/dev/null
}
[[ $(exists) == 0 ]] || { echo 'La cuenta ya existe o la base no está disponible.' >&2; exit 1; }
container=$(docker compose -f compose.json ps -q ac-worldserver)
[[ -n "$container" ]] || { echo 'Inicia el servidor con ./start.sh primero.' >&2; exit 1; }
# Docker requires a real PTY to attach stdin to a TTY-enabled worldserver.
# The server validates and hashes credentials; do not place passwords in argv.
python3 - "$container" 3<<<"account create $username $password" <<'PY'
import os
import pty
import select
import subprocess
import sys
import time

master, slave = pty.openpty()
process = subprocess.Popen(['docker', 'attach', '--sig-proxy=false', sys.argv[1]],
                           stdin=slave, stdout=slave, stderr=slave)
os.close(slave)
try:
    time.sleep(1)
    if process.poll() is not None:
        raise SystemExit('No se pudo conectar a la consola del servidor.')
    os.write(master, os.read(3, 256))
    end = time.monotonic() + 3
    while time.monotonic() < end:
        if select.select([master], [], [], 0.2)[0]:
            try:
                os.read(master, 65536)  # Discard TTY echo containing credentials.
            except OSError:
                break
finally:
    process.kill()  # Kill only the attach client; the server remains running.
    process.wait(timeout=10)
    os.close(master)
PY
unset password
for ((attempt=0; attempt<60; attempt++)); do
  if [[ $(exists) == 1 ]]; then
    echo "Cuenta $username creada. Ya puedes entrar con tu cliente."
    exit 0
  fi
  sleep 2
done
echo 'No se pudo confirmar la cuenta. Revisa ./logs.sh y espera a que el servidor esté listo.' >&2
exit 1
