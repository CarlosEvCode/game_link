#!/bin/bash
set -e

APP_NAME="game_link"
VERSION=${1:-"unknown"}
BUNDLE_DIR="build/linux/x64/release/bundle"
OUTPUT_NAME="${APP_NAME}-${VERSION}-linux-x64.tar.xz"

echo "[  INFO ] Generando Tarball para $APP_NAME version $VERSION..."

# Crear carpeta temporal para empaquetar
TEMP_DIR="${APP_NAME}"
rm -rf "$TEMP_DIR" && mkdir -p "$TEMP_DIR"

# Copiar el bundle
cp -r $BUNDLE_DIR/* "$TEMP_DIR/"

# Copiar el desktop e icono (para empaquetado)
cp linux/game_link.desktop "$TEMP_DIR/"
cp linux/game_link.png "$TEMP_DIR/"

# Inyectar SQLite por seguridad
SQLITE_SRC=$(ldconfig -p | grep libsqlite3.so.0 | head -n1 | awk '{print $4}')
[ -z "$SQLITE_SRC" ] && SQLITE_SRC="/usr/lib/x86_64-linux-gnu/libsqlite3.so.0"
if [ -f "$SQLITE_SRC" ]; then
    mkdir -p "$TEMP_DIR/lib"
    cp -v "$SQLITE_SRC" "$TEMP_DIR/lib/libsqlite3.so.0"
    ln -sf libsqlite3.so.0 "$TEMP_DIR/lib/libsqlite3.so"
fi

# Crear un script de lanzamiento simple
cat > "$TEMP_DIR/launch.sh" <<EOF
#!/bin/sh
HERE="\$(dirname "\$(readlink -f "\$0")")"
export LD_LIBRARY_PATH="\$HERE/lib:\$LD_LIBRARY_PATH"
exec "\$HERE/$APP_NAME" "\$@"
EOF
chmod +x "$TEMP_DIR/launch.sh"

# Comprimir
tar -cJf "$OUTPUT_NAME" "$TEMP_DIR"

# Limpieza
rm -rf "$TEMP_DIR"

echo "[  DONE ] Tarball generado: $OUTPUT_NAME"
