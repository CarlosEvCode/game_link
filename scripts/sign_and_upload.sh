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

VERSION_DEB=$(head -n 1 /build_parent/lutris_game_station/debian/changelog | cut -d'(' -f2 | cut -d')' -f1)
CHANGES_FILE="/build_parent/game-link_${VERSION_DEB}_source.changes"

echo "✍️ Firmando el paquete con debsign (introduce la contraseña de tu llave GPG)..."
debsign -k "programer.cm12@gmail.com" "$CHANGES_FILE"

echo "🚀 Subiendo a Launchpad PPA..."
dput my-ppa "$CHANGES_FILE"

echo "✅ ¡Subida completada con éxito!"
