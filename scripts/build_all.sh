#!/bin/bash
set -e

# Colores para la terminal
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}[ START ] Iniciando proceso de construcción completa...${NC}"

# 1. Detectar si estamos en un contenedor
IN_CONTAINER=false
if [ -f /.dockerenv ]; then
    IN_CONTAINER=true
    echo -e "${BLUE}[ DOCKER ] Entorno de contenedor detectado.${NC}"
fi

# 2. Obtener versión del pubspec.yaml
VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //')
VERSION_CLEAN=$(echo $VERSION | cut -d'+' -f1)
echo -e "${BLUE}📌 Versión detectada: $VERSION_CLEAN${NC}"

# 3. Gestión de dependencias
if [ "$IN_CONTAINER" = true ]; then
    echo -e "${BLUE}[ CLEAN ] Limpiando configuración local para evitar conflictos...${NC}"
    rm -rf .dart_tool/
    flutter pub get
else
    if [ ! -d ".dart_tool" ]; then
        echo -e "${BLUE}[ CLEAN ] Obteniendo dependencias...${NC}"
        flutter pub get
    fi
fi

# 4. Compilación de Flutter
echo -e "${BLUE}[ BUILD ] Compilando Flutter para Linux (Release)...${NC}"
flutter build linux --release --build-name=$VERSION_CLEAN

# 5. Empaquetado
echo -e "${GREEN}[  INFO ] Generando paquetes...${NC}"
./scripts/package_appimage.sh "$VERSION_CLEAN"
./scripts/package_tarball.sh "$VERSION_CLEAN"
./scripts/package_debian.sh "$VERSION_CLEAN"
./scripts/package_rpm.sh "$VERSION_CLEAN"

echo -e "${GREEN}[  DONE ] ¡Proceso completado con éxito!${NC}"
