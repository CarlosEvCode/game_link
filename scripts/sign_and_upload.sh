#!/bin/bash
set -e

# Configurar dput dentro del contenedor
cat > ~/.dput.cf <<EOF
[my-ppa]
fqdn = ppa.launchpad.net
method = ftp
incoming = ~evcode/ubuntu/game-link/
login = anonymous
allow_unsigned_uploads = 0
EOF

echo "📥 Importando llave privada GPG..."
gpg --import /build_parent/lutris_game_station/mi_llave_privada.asc

echo "✍️ Firmando el paquete con debsign (introduce la contraseña de tu llave GPG)..."
debsign -k "programer.cm12@gmail.com" /build_parent/game-link_2.17.0-1_source.changes

echo "🚀 Subiendo a Launchpad PPA..."
dput my-ppa /build_parent/game-link_2.17.0-1_source.changes

echo "✅ ¡Subida completada con éxito!"
