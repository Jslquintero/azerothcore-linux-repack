#!/usr/bin/env bash

normalize_language() {
  case "${1,,}" in
    1|en|english) printf 'en\n' ;;
    2|es|espanol|español) printf 'es\n' ;;
    *) return 1 ;;
  esac
}

load_language() {
  local selected=${REPACK_LANG:-}
  if [[ -z "$selected" && -r .language ]]; then
    selected=$(<.language)
  fi
  LANGUAGE=$(normalize_language "$selected" 2>/dev/null || printf 'en\n')
  export LANGUAGE
}

choose_language() {
  local selected=${REPACK_LANG:-}
  local saved=en
  if [[ -r .language ]]; then
    saved=$(normalize_language "$(<.language)" 2>/dev/null || printf 'en\n')
  fi

  if [[ -z "$selected" && -t 0 ]]; then
    printf 'Select language / Selecciona idioma:\n'
    printf '  1) English\n  2) Español\n'
    if [[ "$saved" == es ]]; then
      read -r -p 'Choice / Opción [2]: ' selected || selected=''
      selected=${selected:-2}
    else
      read -r -p 'Choice / Opción [1]: ' selected || selected=''
      selected=${selected:-1}
    fi
  elif [[ -z "$selected" ]]; then
    selected=$saved
  fi

  if ! LANGUAGE=$(normalize_language "$selected" 2>/dev/null); then
    LANGUAGE=en
    msg invalid_language
  fi
  export LANGUAGE
  printf '%s\n' "$LANGUAGE" > .language
}

msg() {
  local key=$1
  shift
  case "$LANGUAGE:$key" in
    en:invalid_language) printf 'Invalid choice; using English.\n' ;;
    es:invalid_language) printf 'Opción inválida; se usará Español.\n' ;;
    en:docker_missing) printf 'Docker is not installed or is unavailable. Install Docker and try again.\n' ;;
    es:docker_missing) printf 'Docker no está instalado o no está disponible. Instálalo y vuelve a intentarlo.\n' ;;
    en:compose_missing) printf 'Docker Compose v2 is unavailable. Install the Docker Compose plugin and try again.\n' ;;
    es:compose_missing) printf 'Docker Compose v2 no está disponible. Instala el plugin de Docker Compose y vuelve a intentarlo.\n' ;;
    en:daemon_unavailable) printf 'Docker is not running or the current user cannot access it.\n' ;;
    es:daemon_unavailable) printf 'Docker no está iniciado o el usuario actual no puede acceder a él.\n' ;;
    en:version_mismatch) printf 'This folder belongs to a different installed version. Its data was kept; automatic replacement is not supported.\n' ;;
    es:version_mismatch) printf 'Esta carpeta pertenece a otra versión instalada. Sus datos se conservaron; no se admite reemplazarla automáticamente.\n' ;;
    en:checking_package) printf 'Verifying package files...\n' ;;
    es:checking_package) printf 'Verificando los archivos del paquete...\n' ;;
    en:loading_images) printf 'Loading bundled Docker images (no downloads)...\n' ;;
    es:loading_images) printf 'Cargando las imágenes Docker incluidas (sin descargas)...\n' ;;
    en:preparing_database) printf 'Preparing the initial database. This may take several minutes...\n' ;;
    es:preparing_database) printf 'Preparando la base de datos inicial. Puede tardar varios minutos...\n' ;;
    en:database_version_mismatch) printf 'The database volume belongs to a different version. It was not replaced.\n' ;;
    es:database_version_mismatch) printf 'El volumen de base de datos pertenece a otra versión. No se reemplazó.\n' ;;
    en:database_timeout) printf 'The database did not finish initializing. Check: docker compose -f compose.json logs ac-database\n' ;;
    es:database_timeout) printf 'La base de datos no terminó de inicializarse. Revisa: docker compose -f compose.json logs ac-database\n' ;;
    en:account_python) printf 'This account helper requires Python 3. You can also create an account with ./console.sh:\n' ;;
    es:account_python) printf 'Este asistente requiere Python 3. También puedes crear la cuenta con ./console.sh:\n' ;;
    en:account_command) printf 'account create USERNAME PASSWORD\n' ;;
    es:account_command) printf 'account create USUARIO CONTRASEÑA\n' ;;
    en:account_prompt) printf 'Account name (letters and numbers, max 16): ' ;;
    es:account_prompt) printf 'Nombre de cuenta (letras y números, máximo 16): ' ;;
    en:password_prompt) printf 'Password (letters and numbers, max 16): ' ;;
    es:password_prompt) printf 'Contraseña (letras y números, máximo 16): ' ;;
    en:account_input_invalid) printf 'Use 1 to 16 letters or numbers for both fields.\n' ;;
    es:account_input_invalid) printf 'Usa entre 1 y 16 letras o números en ambos campos.\n' ;;
    en:account_db_unavailable) printf 'Could not query the account database. Run this script from the installed repack folder and make sure the database is healthy.\n' ;;
    es:account_db_unavailable) printf 'No se pudo consultar la base de cuentas. Ejecuta este script desde la carpeta del repack instalado y comprueba que la base esté saludable.\n' ;;
    en:account_exists) printf 'Account %s already exists.\n' "$1" ;;
    es:account_exists) printf 'La cuenta %s ya existe.\n' "$1" ;;
    en:start_server) printf 'Start the server with ./start.sh first.\n' ;;
    es:start_server) printf 'Primero inicia el servidor con ./start.sh.\n' ;;
    en:console_unavailable) printf 'Could not connect to the server console.\n' ;;
    es:console_unavailable) printf 'No se pudo conectar a la consola del servidor.\n' ;;
    en:account_created) printf 'Account %s created. You can now log in with your client.\n' "$1" ;;
    es:account_created) printf 'Cuenta %s creada. Ya puedes iniciar sesión con tu cliente.\n' "$1" ;;
    en:account_unconfirmed) printf 'Could not confirm account creation. Check ./logs.sh and wait for the server to finish starting.\n' ;;
    es:account_unconfirmed) printf 'No se pudo confirmar la cuenta. Revisa ./logs.sh y espera a que el servidor termine de iniciar.\n' ;;
    en:server_starting) printf 'Starting server. Follow ./logs.sh until the world is ready.\n' ;;
    es:server_starting) printf 'Iniciando el servidor. Revisa ./logs.sh hasta que el mundo esté listo.\n' ;;
    en:realmlist) printf 'WoW 3.3.5a client realmlist: set realmlist 127.0.0.1\n' ;;
    es:realmlist) printf 'Realmlist del cliente WoW 3.3.5a: set realmlist 127.0.0.1\n' ;;
    en:create_account_hint) printf 'Create an account with ./create-account.sh when the server is ready.\n' ;;
    es:create_account_hint) printf 'Crea una cuenta con ./create-account.sh cuando el servidor esté listo.\n' ;;
    en:client_files) printf 'Install client/patch-z.mpq in Data and client/AcoreRacialTooltips in Interface/AddOns.\n' ;;
    es:client_files) printf 'Instala client/patch-z.mpq en Data y client/AcoreRacialTooltips en Interface/AddOns.\n' ;;
    en:console_create_account) printf 'Create an account: account create USERNAME PASSWORD\n' ;;
    es:console_create_account) printf 'Crear una cuenta: account create USUARIO CONTRASEÑA\n' ;;
    en:console_detach) printf 'Detach without stopping the server: Ctrl+P, Ctrl+Q.\n' ;;
    es:console_detach) printf 'Salir de la consola sin detener el servidor: Ctrl+P, Ctrl+Q.\n' ;;
    *) return 1 ;;
  esac
}
