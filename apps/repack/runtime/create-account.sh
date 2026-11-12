#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C
cd -- "$(dirname -- "$0")"
source ./language.sh
choose_language
command -v python3 >/dev/null || {
  msg account_python >&2
  msg account_command >&2
  exit 1
}
read -rp "$(msg account_prompt)" username
read -rsp "$(msg password_prompt)" password
echo
[[ "$username" =~ ^[a-zA-Z0-9]{1,16}$ && "$password" =~ ^[a-zA-Z0-9]{1,16}$ ]] || {
  msg account_input_invalid >&2
  exit 1
}
username=${username^^}
exists() {
  docker compose -f compose.json exec -T ac-database sh -c \
    'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" mysql -uroot -Nse "$1"' sh \
    "SELECT COUNT(*) FROM acore_auth.account WHERE username='$username'" 2>/dev/null
}
if ! account_count=$(exists) || [[ ! "$account_count" =~ ^[0-9]+$ ]]; then
  msg account_db_unavailable >&2
  exit 1
fi
if (( account_count > 0 )); then
  msg account_exists "$username" >&2
  exit 1
fi
container=$(docker compose -f compose.json ps -q ac-worldserver)
[[ -n "$container" ]] || { msg start_server >&2; exit 1; }
# Docker requires a real PTY to attach stdin to a TTY-enabled worldserver.
# The server validates and hashes credentials; do not place passwords in argv.
python3 - "$container" "$(msg console_unavailable)" 3<<<"account create $username $password" <<'PY'
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
        raise SystemExit(sys.argv[2])
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
    msg account_created "$username"
    exit 0
  fi
  sleep 2
done
msg account_unconfirmed >&2
exit 1
