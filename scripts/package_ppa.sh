#!/bin/bash
set -e

# Este script prepara el paquete FUENTE para subir a Launchpad (PPA)
# Requiere que Flutter ya esté compilado en build/linux/x64/release/bundle

VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //')
VERSION_CLEAN=$(echo $VERSION | cut -d'+' -f1)
PPA_VERSION="${VERSION_CLEAN}-1ppa1~noble"

echo "Preparando paquete fuente para PPA versión $PPA_VERSION..."

# 1. Actualizar el changelog temporalmente para el PPA si es necesario
# O simplemente usar el actual si coincide.
# Launchpad prefiere versiones que indiquen el release (ej. ~noble)

# 2. Crear el tarball original (.orig.tar.xz) que espera Debian
# EXCLUIMOS build, .git, .dart_tool para que sea ligero
echo "Creando tarball fuente (excluyendo carpetas pesadas)..."
tar -cJf "../game-link_${VERSION_CLEAN}.orig.tar.xz" \
    --exclude=debian \
    --exclude=build \
    --exclude=.git \
    --exclude=.dart_tool \
    --exclude=*.deb \
    --exclude=*.AppImage \
    --exclude=*.flatpak \
    .

# 3. Construir el paquete fuente en Docker
docker run --rm -v "$(pwd)/..:/build_parent" -v "$(pwd):/build" game-link-debian bash -c "
    cd /build
    # Generar el paquete fuente (-S)
    # -us -uc para no firmar dentro del contenedor (se firma fuera con la llave del usuario)
    dpkg-buildpackage -S -us -uc
"

echo ""
echo "¡Paquete fuente preparado en el directorio superior!"
echo "Archivos generados:"
ls -1 ../game-link_${VERSION_CLEAN}*
echo ""
echo "PASOS SIGUIENTES:"
echo "1. Firmar el paquete (desde tu Arch Linux, asumiendo que tienes gpg configurado):"
echo "   debsign -kTuIDLlave ../game-link_${VERSION_CLEAN}-1_source.changes"
echo ""
echo "2. Subir a Launchpad:"
echo "   dput ppa:tu-usuario/game-link ../game-link_${VERSION_CLEAN}-1_source.changes"
