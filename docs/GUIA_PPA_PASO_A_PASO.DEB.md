# 🚀 Guía Definitiva: Empaquetado Debian y Subida a PPA para Game Link

Esta guía contiene los pasos exactos para gestionar el PPA de Launchpad desde Arch Linux usando Docker.

---

## 1. Configuración de Identidad (GPG) - Solo una vez
Launchpad requiere que los paquetes estén firmados por una llave GPG registrada.

### Generar la llave en Arch Linux:
```bash
gpg --full-generate-key
# Elegir: RSA (4096 bits), Nombre: Carlos EvCode, Email: programer.cm12@gmail.com
```

### Registrar en Launchpad:
1. **Obtener Fingerprint:** `gpg --fingerprint programer.cm12@gmail.com`
2. **Subir al servidor de Ubuntu:** `gpg --send-keys --keyserver keyserver.ubuntu.com <ID_DE_LLAVE>`
3. **Vincular en Launchpad:** Pega el fingerprint en tu perfil -> *OpenPGP keys*.
4. **Validar Email:** Launchpad enviará un correo cifrado. Cópialo a un archivo `correo.txt` y descífralo:
   ```bash
   gpg --decrypt correo.txt
   ```
   Haz clic en el enlace que aparecerá dentro del texto descifrado.

---

## 2. Preparación del Paquete (En Arch Linux)
Antes de entrar al Docker, prepara los binarios:

1. **Compilar Flutter (Release):**
   ```bash
   flutter build linux --release
   ```
2. **Exportar llave privada:**
   ```bash
   gpg --export-secret-keys --armor "programer.cm12@gmail.com" > mi_llave_privada.asc
   ```

---

## 3. Proceso de Subida (En Docker Ubuntu 24.04)
### Re-construir la imagen (Solo si cambian dependencias):
```bash
docker build -t game-link-debian -f Dockerfile.debian .
```

### Iniciar Contenedor y Proceso Automatizado:
La forma más sencilla de firmar y subir es usando el script automatizado de firma.

Ejecuta este comando único desde la terminal de tu sistema local (Arch Linux):
```bash
docker run -it --rm -v "$(pwd)/..:/build_parent" game-link-debian bash /build_parent/lutris_game_station/scripts/sign_and_upload.sh
```
Introduce la contraseña de tu llave GPG cuando te lo solicite y el script importará la llave, firmará los cambios y los subirá de forma automática.

---

### Proceso Manual (Alternativo):
Si prefieres realizar los pasos de firma y subida de forma manual dentro del contenedor:

1. **Iniciar Contenedor con los montajes correctos**:
   ```bash
   docker run -it --rm -v "$(pwd)/..:/build_parent" game-link-debian bash
   ```

2. **Entrar al directorio del proyecto e importar la Llave GPG**:
   ```bash
   cd /build_parent/lutris_game_station
   gpg --import mi_llave_privada.asc
   ```

3. **Configurar dput en el contenedor**:
   ```bash
   cat > ~/.dput.cf <<EOF
   [my-ppa]
   fqdn = ppa.launchpad.net
   method = ftp
   incoming = ~evcode/ubuntu/game-link/
   login = anonymous
   allow_unsigned_uploads = 0
   EOF
   ```

4. **Firmar el paquete de cambios**:
   ```bash
   debsign -k "programer.cm12@gmail.com" ../game-link_2.17.0-1_source.changes
   ```

5. **Subir a Launchpad**:
   ```bash
   dput my-ppa ../game-link_2.17.0-1_source.changes
   ```

---

## 4. Próximas Versiones
Cuando saques una nueva versión (ej: `2.14.0`):
1. Actualiza `version:` en `pubspec.yaml` y `version.txt`.
2. Actualiza `debian/changelog` (puedes usar `dch -i` o editarlo a mano).
3. Repite el proceso de **Preparación** y **Docker**.

---

## 5. Migración a un Nuevo Sistema (Post-Formateo)
Si cambias de PC o reinstalas tu OS, sigue estos pasos para recuperar tu identidad:

1. **Importar tu llave privada:**
   ```bash
   gpg --import mi_llave_privada.asc
   ```

2. **Darle "Confianza Absoluta" (Ultimate Trust):**
   Sin esto, GPG dirá que la llave es de un origen desconocido y los scripts de firma pueden fallar.
   ```bash
   gpg --edit-key "programer.cm12@gmail.com"
   # Se abrirá un menú interactivo:
   # 1. Escribe: trust
   # 2. Elige la opción: 5 (I trust ultimately)
   # 3. Confirma con: y
   # 4. Sal con: quit
   ```

3. **Re-configurar dput:**
   Recuerda que el archivo `~/.dput.cf` vive en tu HOME, por lo que deberás volver a crearlo (ver Punto 3).

---

## ⚠️ Seguridad
- **Borra `mi_llave_privada.asc`** de la carpeta del proyecto en cuanto termines la subida.
- No añadas nunca archivos `.asc` o `.deb` al repositorio Git.
