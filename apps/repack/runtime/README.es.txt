AzerothCore WotLK Offline Repack — Linux x86_64

Requisitos
- Docker Engine con el plugin Docker Compose v2
- Cliente WoW 3.3.5a, compilación 12340 (no incluido)
- Al menos 30 GB libres para la extracción, las imágenes y los datos del juego

Instalación e inicio
1. Ejecuta ./install.sh y elige English o Español cuando se solicite.
2. El instalador carga las imágenes Docker incluidas y prepara el servidor.
   No descarga imágenes ni compila el servidor.
3. Espera a que worldserver termine de iniciar. Revisa los logs con ./logs.sh.
4. Ejecuta ./create-account.sh y elige el idioma de sus mensajes.
5. Copia client/patch-z.mpq en la carpeta Data del cliente.
6. Copia client/AcoreRacialTooltips en Interface/AddOns y activa el addon.
7. Configura el realmlist del cliente así: set realmlist 127.0.0.1
8. Ejecuta ./start.sh para iniciar los servidores después y ./stop.sh para
   detenerlos.

Puedes conectarte a la consola de worldserver con ./console.sh. Sal con
Ctrl+P, Ctrl+Q; el servidor seguirá activo. Si no tienes Python 3, crea una
cuenta desde esa consola con: account create USUARIO CONTRASEÑA

La primera inicialización de la base puede tardar varios minutos. El preset
inicia 100 bots; puedes ajustar la cantidad de random bots en compose.json.

Las cuentas y personajes se guardan en volúmenes Docker del proyecto
acore-offline. No ejecutes docker compose down -v: eliminaría los datos
guardados. Conserva el archivo .env y no cambies COMPOSE_PROJECT_NAME después
de instalar para que Docker use los mismos volúmenes.

Reinstalar esta misma versión del paquete conserva los datos. No se admiten
actualizaciones automáticas entre versiones. Haz un respaldo de la base antes
de reemplazar el paquete o cambiar de versión.

MySQL no publica puertos en el host. Los puertos de autenticación, mundo y SOAP
solo se publican en 127.0.0.1. El dashboard opcional de AzerothCore puede
gestionar cuentas y ejecutar comandos mediante SOAP; configúralo con una cuenta
GM nivel 3. No expongas SOAP a Internet. Para jugar desde otra computadora de
la LAN, configura los puertos del juego y la dirección del realm. El cliente
WoW no está incluido.
