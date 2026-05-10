#!/bin/bash
set -e

# Asegurarse de que el bundle de Flutter esté construido
if [ ! -d "build/linux/x64/release/bundle" ]; then
    echo "Construyendo Flutter..."
    flutter build linux --release
fi

# Construir la imagen de Docker
docker build -t game-link-debian -f Dockerfile.debian .

# Ejecutar la construcción del paquete .deb
# Montamos el directorio actual en /build dentro del contenedor
docker run --rm -v "$(pwd):/build" game-link-debian bash -c "
    # Limpiar compilaciones anteriores en la carpeta debian
    dh_clean
    # Construir el paquete binario (.deb)
    # -us -uc significa unsigned source, unsigned changes (para local no necesitamos firma)
    dpkg-buildpackage -b -us -uc
"

echo "¡Paquete .deb generado con éxito!"
