#!/bin/bash
set -e

# Asegurarse de que el bundle de Flutter esté construido
if [ ! -d "build/linux/x64/release/bundle" ]; then
    echo "Construyendo Flutter..."
    flutter build linux --release
fi

VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //')
VERSION_CLEAN=$(echo $VERSION | cut -d'+' -f1)

# Generar el Tarball primero (necesario como fuente para el RPM)
./scripts/package_tarball.sh "$VERSION_CLEAN"

# Preparar estructura de rpmbuild
mkdir -p rpmbuild/{SOURCES,SPECS,RPMS,SRPMS,BUILD,BUILDROOT}
cp "game_link-${VERSION_CLEAN}-linux-x64.tar.xz" rpmbuild/SOURCES/
cp rpm/game-link.spec rpmbuild/SPECS/

# Reemplazar la versión en el archivo .spec
sed -i "s/REPLACEME_VERSION/$VERSION_CLEAN/g" rpmbuild/SPECS/game-link.spec

# Construir la imagen de Docker para Fedora
docker build -t game-link-fedora -f Dockerfile.fedora .

echo "Construyendo paquete RPM..."

# Ejecutar rpmbuild dentro del contenedor
docker run --rm -v "$(pwd):/build" game-link-fedora bash -c "
    rpmbuild --define \"_topdir /build/rpmbuild\" \
             --define \"version $VERSION_CLEAN\" \
             -ba /build/rpmbuild/SPECS/game-link.spec
"

echo "¡Paquetes RPM y SRPM generados con éxito en rpmbuild/RPMS y rpmbuild/SRPMS!"
