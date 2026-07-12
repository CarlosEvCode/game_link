import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;
import '../lutris/translation_manager.dart';

class DatParser {
  final Map<String, String> hashToName = {};
  final Map<String, String> serialToName = {};
  final Map<String, String> cleanNameToName = {};
  final Map<String, String> romSlugToName = {};

  DatParser(String datContent) {
    final lines = LineSplitter.split(datContent);
    String? currentGameName;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('game (')) {
        currentGameName = null;
      } else if (trimmed.startsWith('name "')) {
        final match = RegExp(r'^name\s+"([^"]+)"').firstMatch(trimmed);
        if (match != null) {
          currentGameName = match.group(1);
          final cleaned = DatResolver.cleanGameName(currentGameName!);
          if (cleaned.isNotEmpty) {
            // Preferir versiones que no sean de Japón para la búsqueda por nombre
            if (!cleanNameToName.containsKey(cleaned) || !cleaned.contains('japan')) {
              cleanNameToName[cleaned] = currentGameName;
            }
          }
        }
      } else if (trimmed.startsWith('serial "')) {
        if (currentGameName != null) {
          final match = RegExp(r'^serial\s+"([^"]+)"').firstMatch(trimmed);
          if (match != null) {
            final normalized = match.group(1)!.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
            serialToName[normalized] = currentGameName;
          }
        }
      } else if (trimmed.startsWith('rom (')) {
        if (currentGameName != null) {
          final crcMatch = RegExp(r'\bcrc\s+([a-fA-F0-9]{8})\b').firstMatch(trimmed);
          final md5Match = RegExp(r'\bmd5\s+([a-fA-F0-9]{32})\b').firstMatch(trimmed);
          final sha1Match = RegExp(r'\bsha1\s+([a-fA-F0-9]{40})\b').firstMatch(trimmed);
          final serialMatch = RegExp(r'\bserial\s+"([^"]+)"').firstMatch(trimmed);
          final romNameMatch = RegExp(r'\bname\s+["' "'" r']?([a-zA-Z0-9_\-\.]+)').firstMatch(trimmed);

          if (crcMatch != null) hashToName[crcMatch.group(1)!.toLowerCase()] = currentGameName;
          if (md5Match != null) hashToName[md5Match.group(1)!.toLowerCase()] = currentGameName;
          if (sha1Match != null) hashToName[sha1Match.group(1)!.toLowerCase()] = currentGameName;

          if (serialMatch != null) {
            final normalized = serialMatch.group(1)!.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
            serialToName[normalized] = currentGameName;
          }

          if (romNameMatch != null) {
            final romFile = romNameMatch.group(1)!;
            final romSlug = p.basenameWithoutExtension(romFile).toLowerCase();
            romSlugToName[romSlug] = currentGameName;
          }
        }
      }
    }
  }
}

class DatResolver {
  static final Map<String, DatParser> _parsedDatCache = {};

  // Mapeo de platformId de la app a la ruta relativa del archivo .dat en el repositorio de libretro-database.
  static const Map<String, String> platformToDatPath = {
    'gba': 'no-intro/Nintendo - Game Boy Advance.dat',
    'ds': 'no-intro/Nintendo - Nintendo DS.dat',
    '3ds': 'no-intro/Nintendo - Nintendo 3DS.dat',
    'psp': 'no-intro/Sony - PlayStation Portable.dat',
    'ps1': 'redump/Sony - PlayStation.dat',
    'ps2': 'redump/Sony - PlayStation 2.dat',
    'gamecube': 'redump/Nintendo - GameCube.dat',
    'wii': 'redump/Nintendo - Wii.dat',
    'dreamcast': 'redump/Sega - Dreamcast.dat',
    'vita': 'no-intro/Sony - PlayStation Vita.dat',
    'xbox': 'redump/Microsoft - Xbox.dat',
    'mame': 'mame/MAME.dat',
    
    // Adicionales para futuras expansiones
    'nes': 'no-intro/Nintendo - Nintendo Entertainment System.dat',
    'snes': 'no-intro/Nintendo - Super Nintendo Entertainment System.dat',
    'n64': 'no-intro/Nintendo - Nintendo 64.dat',
    'gb': 'no-intro/Nintendo - Game Boy.dat',
    'gbc': 'no-intro/Nintendo - Game Boy Color.dat',
    'genesis': 'no-intro/Sega - Mega Drive - Genesis.dat',
    'megadrive': 'no-intro/Sega - Mega Drive - Genesis.dat',
  };

  /// Limpia la caché en memoria de archivos DAT parseados.
  static void clearCache() {
    _parsedDatCache.clear();
  }

  /// Verifica si una plataforma tiene soporte para resolución offline por base de datos DAT.
  static bool isPlatformSupported(String platformId) {
    return platformToDatPath.containsKey(platformId);
  }

  /// Limpia y normaliza el nombre del juego para búsquedas laxas.
  static String cleanGameName(String name) {
    String clean = name.toLowerCase();
    // Eliminar contenido de paréntesis y corchetes recursivamente
    clean = clean.replaceAll(RegExp(r'\[[^\]]*\]|\([^\)]*\)'), '');
    // Reemplazar caracteres especiales y no alfanuméricos por espacios
    clean = clean.replaceAll(RegExp(r'[^a-z0-9]'), ' ');
    // Limpiar espacios múltiples y finales
    return clean.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Extrae el serial (DISC_ID/GameCode) de archivos ROM/ISO/CSO conocidos (GBA, NDS, PS1/PS2/PSP).
  static Future<String?> getRomSerial(String filePath, String platformId) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) return null;

      final ext = p.extension(filePath).toLowerCase();

      // 1. Soporte para Nintendo DS
      if (platformId == 'ds') {
        final bytes = await file.open();
        await bytes.setPosition(0x0C);
        final buffer = await bytes.read(4);
        await bytes.close();
        final serial = ascii.decode(buffer.where((b) => b >= 32 && b <= 126).toList()).trim();
        return serial.isNotEmpty ? serial : null;
      }

      // 2. Soporte para Game Boy Advance
      if (platformId == 'gba') {
        final bytes = await file.open();
        await bytes.setPosition(0xAC);
        final buffer = await bytes.read(4);
        await bytes.close();
        final serial = ascii.decode(buffer.where((b) => b >= 32 && b <= 126).toList()).trim();
        return serial.isNotEmpty ? serial : null;
      }

      // 3. Soporte para archivos CSO (Compressed ISO) de PSP
      if (ext == '.cso') {
        final raf = await file.open();
        try {
          final headerBytes = await raf.read(24);
          if (headerBytes.length < 24) return null;
          final magic = ascii.decode(headerBytes.sublist(0, 4));
          if (magic != "CISO") return null;

          final headerData = ByteData.sublistView(Uint8List.fromList(headerBytes));
          final totalSize = headerData.getUint64(8, Endian.little);
          final blockSize = headerData.getUint32(16, Endian.little);
          final indexShift = headerBytes[21];
          final numBlocks = totalSize ~/ blockSize;

          // Helper local para leer y descomprimir un sector on-demand
          Future<Uint8List?> readSector(int sector) async {
            if (sector >= numBlocks) return null;
            
            // Cada entrada del índice es de 4 bytes, ubicada a partir de la posición 24
            await raf.setPosition(24 + sector * 4);
            final indexBytes = await raf.read(8);
            if (indexBytes.length < 8) return null;

            final indexData = ByteData.sublistView(Uint8List.fromList(indexBytes));
            final entryCurrent = indexData.getUint32(0, Endian.little);
            final entryNext = indexData.getUint32(4, Endian.little);

            final isUncompressed = (entryCurrent & 0x80000000) != 0;
            final offset = (entryCurrent & 0x7FFFFFFF) << indexShift;
            final nextOffset = (entryNext & 0x7FFFFFFF) << indexShift;
            final size = nextOffset - offset;

            if (size <= 0) return null;

            await raf.setPosition(offset);
            final data = await raf.read(size);

            if (!isUncompressed) {
              try {
                return Uint8List.fromList(ZLibDecoder(raw: true).convert(data));
              } catch (_) {
                return null;
              }
            } else {
              return Uint8List.fromList(data);
            }
          }

          final pvd = await readSector(16);
          if (pvd != null && pvd.length >= 2048) {
            final pvdMagic = ascii.decode(pvd.sublist(1, 6));
            if (pvdMagic == "CD001") {
              final rootRecord = pvd.sublist(156, 156 + 34);
              final rootData = ByteData.sublistView(rootRecord);
              final rootExtent = rootData.getUint32(2, Endian.little);
              final rootSize = rootData.getUint32(10, Endian.little);

              final rootSectors = (rootSize + 2047) ~/ 2048;
              final List<int> rootDirBytes = [];
              for (int i = 0; i < rootSectors; i++) {
                final sectorData = await readSector(rootExtent + i);
                if (sectorData != null) {
                  rootDirBytes.addAll(sectorData);
                }
              }

              int offset = 0;
              int? umdExtent;
              while (offset < rootDirBytes.length) {
                final len = rootDirBytes[offset];
                if (len == 0) {
                  offset = ((offset + 2048) ~/ 2048) * 2048;
                  continue;
                }
                final recordData = ByteData.sublistView(Uint8List.fromList(rootDirBytes.sublist(offset, offset + len)));
                final extent = recordData.getUint32(2, Endian.little);
                final nameLen = rootDirBytes[offset + 32];
                final nameBytes = rootDirBytes.sublist(offset + 33, offset + 33 + nameLen);
                final name = ascii.decode(nameBytes.where((b) => b != 0).toList());

                if (name.startsWith("UMD_DATA.BIN")) {
                  umdExtent = extent;
                  break;
                }
                offset += len;
              }

              if (umdExtent != null) {
                final umdData = await readSector(umdExtent);
                if (umdData != null) {
                  final text = ascii.decode(umdData.where((b) => b >= 32 && b <= 126).toList());
                  final match = RegExp(
                    r'\b(SC[U|E|D]S|SL[U|E|P|M|K|T]S|SLED|SCED|SLKA|SIPS|UL[U|E|J|A]S|UC[U|E|J][S|B]|NP[U|E|J|H][G|H])[-_\s]?(\d{5})\b',
                    caseSensitive: false,
                  ).firstMatch(text);
                  if (match != null) {
                    return "${match.group(1)}${match.group(2)}".toUpperCase();
                  }
                }
              }
            }
          }
        } finally {
          await raf.close();
        }
      }

      // 4. Soporte para archivos ISO standard (PS1, PS2, PSP)
      if (ext == '.iso') {
        final raf = await file.open();
        try {
          Future<Uint8List?> readSector(int sector) async {
            await raf.setPosition(sector * 2048);
            final data = await raf.read(2048);
            return Uint8List.fromList(data);
          }

          final pvd = await readSector(16);
          if (pvd != null && pvd.length >= 2048) {
            final pvdMagic = ascii.decode(pvd.sublist(1, 6));
            if (pvdMagic == "CD001") {
              final rootRecord = pvd.sublist(156, 156 + 34);
              final rootData = ByteData.sublistView(rootRecord);
              final rootExtent = rootData.getUint32(2, Endian.little);
              final rootSize = rootData.getUint32(10, Endian.little);

              final rootSectors = (rootSize + 2047) ~/ 2048;
              final List<int> rootDirBytes = [];
              for (int i = 0; i < rootSectors; i++) {
                final sectorData = await readSector(rootExtent + i);
                if (sectorData != null) {
                  rootDirBytes.addAll(sectorData);
                }
              }

              int offset = 0;
              int? targetExtent;
              int? targetSize;

              while (offset < rootDirBytes.length) {
                final len = rootDirBytes[offset];
                if (len == 0) {
                  offset = ((offset + 2048) ~/ 2048) * 2048;
                  continue;
                }
                final recordData = ByteData.sublistView(Uint8List.fromList(rootDirBytes.sublist(offset, offset + len)));
                final extent = recordData.getUint32(2, Endian.little);
                final size = recordData.getUint32(10, Endian.little);
                final nameLen = rootDirBytes[offset + 32];
                final nameBytes = rootDirBytes.sublist(offset + 33, offset + 33 + nameLen);
                final name = ascii.decode(nameBytes.where((b) => b != 0).toList()).toUpperCase();

                if (name.startsWith("UMD_DATA.BIN")) {
                  targetExtent = extent;
                  targetSize = size;
                  break;
                } else if (name.startsWith("SYSTEM.CNF")) {
                  targetExtent = extent;
                  targetSize = size;
                }
                offset += len;
              }

              if (targetExtent != null && targetSize != null) {
                await raf.setPosition(targetExtent * 2048);
                final targetData = await raf.read(targetSize);
                final text = ascii.decode(targetData.where((b) => b >= 32 && b <= 126).toList());
                final match = RegExp(
                  r'\b(SC[U|E|D]S|SL[U|E|P|M|K|T]S|SLED|SCED|SLKA|SIPS|UL[U|E|J|A]S|UC[U|E|J][S|B]|NP[U|E|J|H][G|H])[-_\s]?(\d{5})\b',
                  caseSensitive: false,
                ).firstMatch(text);
                if (match != null) {
                  return "${match.group(1)}${match.group(2)}".toUpperCase();
                }
              }
            }
          }
        } finally {
          await raf.close();
        }
      }

      // 5. Soporte para GameCube y Wii (.iso y .wbfs)
      if (platformId == 'gamecube' || platformId == 'wii') {
        if (ext == '.iso') {
          final bytes = await file.open();
          try {
            final buffer = await bytes.read(6);
            final serial = ascii.decode(buffer.where((b) => b >= 32 && b <= 126).toList()).trim();
            if (serial.length == 6) {
              return serial;
            }
          } finally {
            await bytes.close();
          }
        } else if (ext == '.wbfs') {
          final bytes = await file.open();
          try {
            await bytes.setPosition(0x200);
            final buffer = await bytes.read(6);
            final serial = ascii.decode(buffer.where((b) => b >= 32 && b <= 126).toList()).trim();
            if (serial.length == 6) {
              return serial;
            }
          } finally {
            await bytes.close();
          }
        }
      }

      // 6. Fallback para contenedores/EBOOTs/PBPs (primeros 2KB, regex de patrón de ID de disco)
      final bytes = await file.open();
      final buffer = await bytes.read(2048);
      await bytes.close();
      final text = ascii.decode(buffer.map((b) => (b >= 32 && b <= 126) ? b : 46).toList());
      final regex = RegExp(
        r'\b(SC[U|E|D]S|SL[U|E|P|M|K|T]S|SLED|SCED|SLKA|SIPS|UL[U|E|J|A]S|UC[U|E|J][S|B]|NP[U|E|J|H][G|H])[-_\s]?(\d{5})\b',
        caseSensitive: false,
      );
      final match = regex.firstMatch(text);
      if (match != null) {
        return "${match.group(1)}${match.group(2)}".toUpperCase();
      }
    } catch (_) {}
    return null;
  }

  /// Localiza u obtiene el archivo .dat para la plataforma dada.
  /// Intenta buscar en el clon local en desarrollo, de lo contrario en caché local o descarga desde GitHub.
  static Future<File?> getDatFile(String platformId) async {
    final relativePath = platformToDatPath[platformId];
    if (relativePath == null) return null;

    // 1. Intentar buscar en tu repositorio clonado localmente para pruebas de desarrollo rápido
    final localRepoDir = '/home/carlos/Proyectos/libretro-databases/metadat';
    final localFile = File(p.join(localRepoDir, relativePath));
    if (localFile.existsSync()) {
      return localFile;
    }

    // 2. Ruta de caché local de la app
    final home = Platform.environment['HOME'] ?? '';
    final cacheDir = p.join(home, '.config', 'game_link', 'databases');
    final cachedFile = File(p.join(cacheDir, relativePath));

    if (cachedFile.existsSync()) {
      return cachedFile;
    }

    // 3. Descargar desde GitHub de forma automatizada
    try {
      final rawUrl = 'https://raw.githubusercontent.com/libretro/libretro-database/master/metadat/$relativePath';
      print('${'[  INFO ] Descargando base de datos para '.t()}$platformId ${'desde GitHub...'.t()}');
      final response = await http.get(Uri.parse(rawUrl));
      if (response.statusCode == 200) {
        // Crear directorios si no existen
        final parentDir = Directory(p.dirname(cachedFile.path));
        if (!parentDir.existsSync()) {
          parentDir.createSync(recursive: true);
        }
        // Guardar el archivo en caché
        await cachedFile.writeAsString(response.body);
        print('${'[  DONE ] Base de datos de '.t()}$platformId ${'guardada localmente.'.t()}');
        return cachedFile;
      } else {
        print('${'[  FAIL ] Error al descargar base de datos de GitHub (status: '.t()}${response.statusCode})');
      }
    } catch (e) {
      print('${'[  FAIL ] Error de red descargando base de datos: '.t()}$e');
    }

    return null;
  }

  /// Resuelve el nombre del juego de forma local y offline comparando hashes, serial y nombre limpio contra el DAT.
  static Future<String?> resolveGameName({
    required String platformId,
    String? crc32,
    String? md5,
    String? sha1,
    required String filePath,
  }) async {
    // 1. Asegurar la carga de la base de datos en caché
    if (!_parsedDatCache.containsKey(platformId)) {
      if (platformId == 'gb') {
        try {
          final datFileGb = await getDatFile('gb');
          final datFileGbc = await getDatFile('gbc');
          
          String content = '';
          if (datFileGb != null && datFileGb.existsSync()) {
            content += await datFileGb.readAsString();
          }
          if (datFileGbc != null && datFileGbc.existsSync()) {
            content += '\n' + await datFileGbc.readAsString();
          }
          
          if (content.isNotEmpty) {
            _parsedDatCache[platformId] = DatParser(content);
          } else {
            return null;
          }
        } catch (e) {
          print('${'[  FAIL ] Error leyendo/parseando archivos DAT combinados para GB: '.t()}$e');
          return null;
        }
      } else {
        final datFile = await getDatFile(platformId);
        if (datFile == null || !datFile.existsSync()) {
          return null;
        }
        try {
          final content = await datFile.readAsString();
          _parsedDatCache[platformId] = DatParser(content);
        } catch (e) {
          print('${'[  FAIL ] Error leyendo/parseando el archivo DAT para '.t()}$platformId: $e');
          return null;
        }
      }
    }

    final parser = _parsedDatCache[platformId]!;

    // 2. Intentar buscar coincidencia por Serial (Game ID)
    final serial = await getRomSerial(filePath, platformId);
    if (serial != null && serial.isNotEmpty) {
      final normalized = serial.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
      if (parser.serialToName.containsKey(normalized)) {
        return parser.serialToName[normalized];
      }
    }

    // 3. Intentar buscar coincidencia por Hashes
    if (sha1 != null && parser.hashToName.containsKey(sha1.toLowerCase())) {
      return parser.hashToName[sha1.toLowerCase()];
    }
    if (md5 != null && parser.hashToName.containsKey(md5.toLowerCase())) {
      return parser.hashToName[md5.toLowerCase()];
    }
    if (crc32 != null && parser.hashToName.containsKey(crc32.toLowerCase())) {
      return parser.hashToName[crc32.toLowerCase()];
    }

    // 4. Fallback: Intentar buscar coincidencia por Nombre Limpio del archivo
    final fileSlug = p.basenameWithoutExtension(filePath);
    final cleanedSlug = cleanGameName(fileSlug);
    if (cleanedSlug.isNotEmpty && parser.cleanNameToName.containsKey(cleanedSlug)) {
      return parser.cleanNameToName[cleanedSlug];
    }

    // 5. Fallback especial para MAME/Arcade: buscar por el slug de ROM en romSlugToName
    final lowerSlug = fileSlug.toLowerCase();
    if (platformId == 'mame') {
      if (lowerSlug == 'cvs2') {
        return 'Capcom Vs. SNK 2 Millionaire Fighting 2001';
      }
      if (lowerSlug == 'cvs') {
        return 'Capcom Vs. SNK Millenium Fight 2000';
      }
    }
    if (parser.romSlugToName.containsKey(lowerSlug)) {
      return parser.romSlugToName[lowerSlug];
    }

    return null;
  }

  static const Set<String> _commonMameBios = {
    'neogeo', 'qsound', 'qsound_hle', 'pgm', 'naomi', 'naomi2', 'awbios', 
    'cpzn1', 'cpzn2', 'decocass', 'konamih', 'playch10', 'skns', 'stvbios', 
    'taito_h', 'taitofx1', 'tpgm', 'triforce', 'ym2608', 'bios', 'hikaru', 
    'islands', 'hng64', 'maxaflex', 'megaplay', 'megatech', 'nss', 'nps', 
    'namcoc74', 'namcoc75', 'namcoc76', 'suprnova', 'sys24', 'sys573', 'taito_g',
    'taitotz', 'cchip', 'k052109', 'k053246', 'k053260', 'k055555', 'kondev',
    'namcoc148', 'namcops2', 'namcopsx', 'stv', 'sys141b', 'sys142b', 'sys246',
    'sys256', 't5182', 'taito68705', 'taitosjsecmcu', 'tourvis', 'v4bios',
    'ymf281', 'z8671', 'z8682', 'zorba_kbd', 'zorro_a2091', 'zorro_a2232', 'zorro_a590',
    'zorro_ar1', 'zorro_ar2', 'zorro_ar3', 'zorro_buddha', 'cvs2gd'
  };

  /// Verifica si el slug de un archivo ROM de Arcade corresponde a un juego jugable en lugar de una BIOS/dispositivo.
  static Future<bool> isMameGame(String slug) async {
    final lowerSlug = slug.toLowerCase();
    if (lowerSlug == 'cvs2' || lowerSlug == 'cvs') {
      return true;
    }
    if (_commonMameBios.contains(lowerSlug)) {
      return false;
    }

    if (!_parsedDatCache.containsKey('mame')) {
      final datFile = await getDatFile('mame');
      if (datFile == null || !datFile.existsSync()) {
        return true; // Fallback si no se puede cargar el DAT
      }
      try {
        final content = await datFile.readAsString();
        _parsedDatCache['mame'] = DatParser(content);
      } catch (_) {
        return true;
      }
    }
    
    final parser = _parsedDatCache['mame']!;
    return parser.romSlugToName.containsKey(lowerSlug);
  }
}
