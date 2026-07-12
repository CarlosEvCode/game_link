import 'dart:io';
import 'package:sqlite3/sqlite3.dart';
import '../../platforms/platform_registry.dart';
import 'package:path/path.dart' as p;
import '../metadata/screenscraper_service.dart';
import '../lutris/rom_cache_repository.dart';
import '../metadata/hash_service.dart';
import 'dat_resolver.dart';

class RomInjector {
  final Map<String, String?> lutrisPaths;
  final String platformKey;
  final String? emulatorId; // ID del emulador seleccionado
  final String romFolder;
  final List<String>? customExtensions;
  final Function(String message, double? progress)? progressCallback;

  late final PlatformInfo platformInfo;
  late final EmulatorInfo emulatorInfo;
  late final String dbPath;
  late final String configDir;
  late final String runner;
  late final List<String> extensions;
  late final String platformName;
  late final bool disableRuntime;
  late final String? screenScraperId;
  late final RomCacheRepository _romCache;

  RomInjector({
    required this.lutrisPaths,
    required this.platformKey,
    this.emulatorId,
    required this.romFolder,
    this.customExtensions,
    this.progressCallback,
  }) {
    final info = PlatformRegistry.getPlatform(platformKey);
    if (info == null) throw Exception("Platform not supported: $platformKey");
    platformInfo = info;

    // Seleccionar el emulador (por defecto el primero si no se especifica)
    if (emulatorId != null) {
      emulatorInfo = platformInfo.emulators.firstWhere(
        (e) => e.id == emulatorId,
        orElse: () => platformInfo.emulators.first,
      );
    } else {
      emulatorInfo = platformInfo.emulators.first;
    }

    dbPath = lutrisPaths['db_path']!;
    configDir = lutrisPaths['config_dir_main']!;
    runner = emulatorInfo.runner;
    extensions = customExtensions ?? emulatorInfo.extensions;
    platformName = platformInfo.platformName;
    disableRuntime = emulatorInfo.disableRuntime;
    screenScraperId = platformInfo.screenScraperId;
    _romCache = RomCacheRepository();
  }

  void _log(String message, [double? progress]) {
    if (progressCallback != null) {
      progressCallback!(message, progress);
    } else {
      print(message);
    }
  }

  /// Valida si un archivo necesita procesamiento de hash
  /// Retorna true si necesita hash, false si puede reutilizar cache
  bool _shouldCalculateHash(
    String filePath, {
    bool reuseIdentification = true,
  }) {
    if (!reuseIdentification) return true;

    // Early exit por extensión - verificar que sea válida antes de hacer hash
    final ext = p.extension(filePath).toLowerCase();
    if (!extensions.contains(ext)) {
      _log("[  SKIP ] Extensión no válida para $platformName: $ext");
      return false;
    }

    final cached = _romCache.shouldProcessRom(filePath);
    if (cached != null && cached.isIdentified) {
      _log(
        "[  INFO ] Usando identificación previa: ${cached.identifiedName ?? p.basenameWithoutExtension(filePath)}",
      );
      return false;
    }

    return true;
  }

  /// Obtiene el nombre identificado desde cache o calcula uno nuevo
  Future<String> _getIdentifiedName(
    String filePath,
    String fallbackName, {
    bool useHighPrecision = false,
    bool reuseIdentification = true,
  }) async {
    final cached = reuseIdentification
        ? _romCache.shouldProcessRom(filePath)
        : null;

    // Si tenemos cache válido, usarlo
    if (cached != null && cached.identifiedName != null) {
      return cached.identifiedName!;
    }

    // Si es una plataforma clásica soportada offline por DAT, intentar resolverla offline primero
    if (DatResolver.isPlatformSupported(platformKey)) {
      try {
        final hashes = await HashService.calculateHashes(filePath);
        final offlineName = await DatResolver.resolveGameName(
          platformId: platformKey,
          crc32: hashes.crc32,
          md5: hashes.md5,
          sha1: hashes.sha1,
          filePath: filePath,
        );
        if (offlineName != null) {
          _log("[  INFO ] Nombre resuelto offline (DAT): $offlineName");
          if (reuseIdentification) {
            final file = File(filePath);
            if (file.existsSync()) {
              final stat = file.statSync();
              _romCache.cacheRomInfo(
                filePath: filePath,
                fileSize: stat.size,
                lastModified: stat.modified,
                sha1: hashes.sha1,
                md5: hashes.md5,
                crc32: hashes.crc32,
                identifiedName: offlineName,
                systemId: screenScraperId,
                isIdentified: true,
              );
            }
          }
          return offlineName;
        }
      } catch (e) {
        _log("[  WARN ] Error al resolver offline (DAT): $e");
      }
    }

    // Si no queremos alta precisión o no tenemos systemId, usar nombre de archivo o MAME local
    if (!useHighPrecision || screenScraperId == null) {
      String finalName = fallbackName;

      // Guardar en cache como no identificado
      if (reuseIdentification) {
        final file = File(filePath);
        if (file.existsSync()) {
          final stat = file.statSync();
          _romCache.cacheRomInfo(
            filePath: filePath,
            fileSize: stat.size,
            lastModified: stat.modified,
            identifiedName: finalName,
            systemId: screenScraperId,
            isIdentified: false,
          );
        }
      }
      return finalName;
    }

    // Calcular hash e identificar con ScreenScraper
    try {
      _log("[ SEARCH ] Identificando con alta precisión: $fallbackName...");

      final file = File(filePath);
      final stat = file.statSync();
      final hashes = await HashService.calculateHashes(filePath);

      final identified = await ScreenScraperService.identifyGameByHash(
        sha1: hashes.sha1,
        md5: hashes.md5,
        crc: hashes.crc32,
        fileSize: stat.size,
        fileName: p.basename(filePath),
        systemId: screenScraperId!,
      );

      String finalName;
      bool wasIdentified = false;

      if (identified != null && identified.name != null) {
        finalName = identified.name!;
        wasIdentified = true;
        _log("[  INFO ] Identificado: $finalName");
      } else {
        finalName = fallbackName;
        _log("[  WARN ] No identificado por ScreenScraper, usando nombre de archivo");
      }

      // Guardar en cache
      if (reuseIdentification) {
        _romCache.cacheRomInfo(
          filePath: filePath,
          fileSize: stat.size,
          lastModified: stat.modified,
          sha1: hashes.sha1,
          md5: hashes.md5,
          crc32: hashes.crc32,
          identifiedName: finalName,
          systemId: screenScraperId,
          isIdentified: wasIdentified,
          // URLs de media de ScreenScraper
          coverUrl: identified?.media['cover'],
          cover3dUrl: identified?.media['cover_3d'],
          bannerUrl: identified?.media['banner'],
          logoUrl: identified?.media['logo'],
          synopsis: identified?.synopsis,
          releaseDate: identified?.releaseDate,
          developer: identified?.developer,
        );
      }

      return finalName;
    } catch (e) {
      _log("[  WARN ] Error de identificación: $e");

      // Guardar error en cache para evitar reintentar (intentando MAME local primero)
      String finalName = fallbackName;
      if (reuseIdentification) {
        final file = File(filePath);
        if (file.existsSync()) {
          final stat = file.statSync();
          _romCache.cacheRomInfo(
            filePath: filePath,
            fileSize: stat.size,
            lastModified: stat.modified,
            identifiedName: finalName,
            systemId: screenScraperId,
            isIdentified: false,
          );
        }
      }

      return finalName;
    }
  }

  /// Filtra archivos duplicados manteniendo solo el de mayor prioridad.
  List<File> _filterDuplicatesByPriority(List<File> files) {
    return filterDuplicatesByPriority(files, emulatorInfo, _log);
  }

  /// Versión estática para usar desde otros lugares (como main_window)
  static List<File> filterDuplicatesByPriority(
    List<File> files,
    EmulatorInfo emulatorInfo, [
    void Function(String message, [double? progress])? logCallback,
  ]) {
    // Agrupar archivos por nombre base (sin extensión)
    final Map<String, List<File>> groupedByName = {};

    for (final file in files) {
      final baseName = p.basenameWithoutExtension(file.path);
      groupedByName.putIfAbsent(baseName, () => []).add(file);
    }

    final List<File> result = [];

    for (final entry in groupedByName.entries) {
      final filesWithSameName = entry.value;

      if (filesWithSameName.length == 1) {
        // Solo hay un archivo con este nombre, lo agregamos directamente
        result.add(filesWithSameName.first);
      } else {
        // Hay múltiples archivos con el mismo nombre, elegimos el de mayor prioridad
        filesWithSameName.sort((a, b) {
          final extA = p.extension(a.path).toLowerCase();
          final extB = p.extension(b.path).toLowerCase();
          final priorityA = emulatorInfo.getExtensionPriority(extA);
          final priorityB = emulatorInfo.getExtensionPriority(extB);
          return priorityA.compareTo(priorityB);
        });

        final selected = filesWithSameName.first;
        final skipped = filesWithSameName
            .skip(1)
            .map((f) => p.extension(f.path))
            .join(', ');
        logCallback?.call(
          "[  FILE ] ${entry.key}: usando ${p.extension(selected.path)} (ignorando: $skipped)",
        );
        result.add(selected);
      }
    }

    return result;
  }

  String _createLutrisYaml(
    String gameSlug,
    String romPath,
    int timestamp, {
    Map<String, dynamic>? specialConfig,
  }) {
    final baseName = "$gameSlug-$timestamp";
    final filenameReal = "$baseName.yml";
    final fullYamlPath = p.join(configDir, filenameReal);

    String yamlContent;

    if (runner == "mame" &&
        specialConfig != null &&
        specialConfig['working_dir'] != null) {
      final romDir = p.dirname(romPath);
      yamlContent =
          '''
game:
  main_file: "$romPath"
  working_dir: "$romDir"
system:
  disable_runtime: ${disableRuntime.toString().toLowerCase()}
  prefer_system_libs: true
''';
    } else if (runner == "cemu") {
      final disableRuntimeStr = disableRuntime ? "true" : "false";
      final ext = p.extension(romPath).toLowerCase();
      String gameSection = '';

      if (ext == '.wua' || ext == '.wux') {
        gameSection = '  wua_rom: "$romPath"';
      } else if (ext == '.rpx') {
        final parentDir = p.dirname(romPath);
        final parentName = p.basename(parentDir).toLowerCase();
        if (parentName == 'code') {
          final gameDir = p.dirname(parentDir);
          gameSection = '  main_file: "$gameDir"';
        } else {
          gameSection = '  main_file: "$romPath"';
        }
      } else {
        gameSection = '  main_file: "$romPath"';
      }

      yamlContent =
          '''
game:
$gameSection
system:
  disable_runtime: $disableRuntimeStr
  prefer_system_libs: true
''';
    } else if (runner == "libretro" && emulatorInfo.libretroCore != null) {
      final disableRuntimeStr = disableRuntime ? "true" : "false";
      yamlContent =
          '''
game:
  core: ${emulatorInfo.libretroCore}
  main_file: $romPath
system:
  disable_runtime: $disableRuntimeStr
  prefer_system_libs: true
''';
    } else {
      final disableRuntimeStr = disableRuntime ? "true" : "false";
      
      // Construir sección game dinámicamente con specialConfig
      String gameSection = '  main_file: $romPath';
      if (emulatorInfo.specialConfig != null) {
        emulatorInfo.specialConfig!.forEach((key, value) {
          gameSection += '\n  $key: $value';
        });
      }

      yamlContent =
          '''
game:
$gameSection
system:
  disable_runtime: $disableRuntimeStr
  prefer_system_libs: true
''';
    }

    final dir = Directory(configDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    File(fullYamlPath).writeAsStringSync(yamlContent.trim());
    return baseName;
  }

  void _cleanOldGames() {
    _log("[ CLEAN ] Limpiando juegos antiguos de $runner...");

    final db = sqlite3.open(dbPath);
    try {
      final results = db.select(
        "SELECT configpath FROM games WHERE runner = ?",
        [runner],
      );
      for (final row in results) {
        final String? configId = row['configpath'] as String?;
        if (configId != null && configId.isNotEmpty) {
          final yamlPath = p.join(configDir, "$configId.yml");
          final file = File(yamlPath);
          if (file.existsSync()) {
            try {
              file.deleteSync();
            } catch (e) {
              _log("[  WARN ] No se pudo borrar $yamlPath: $e");
            }
          }
        }
      }
      db.execute("DELETE FROM games WHERE runner = ?", [runner]);
    } finally {
      db.dispose();
    }
  }

  Future<void> injectRoms({
    bool cleanOld = true,
    Map<String, dynamic>? specialConfig,
    bool useHighPrecision = false,
    bool reuseIdentification = true,
    bool useOfflineId = true,
    List<File>? customFiles,
    Map<String, String>? customNames,
    List<String>? manuallyEditedPaths,
  }) async {
    final folder = Directory(romFolder);
    if (!folder.existsSync()) {
      _log("[  FAIL ] No existe la carpeta: $romFolder");
      return;
    }

    if (cleanOld) {
      _cleanOldGames();
    }

    final db = sqlite3.open(dbPath);
    final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    int count = 0;
    List<String> errors = [];

    // Usar archivos específicos o escanear carpeta
    List<File> romFiles;
    if (customFiles != null) {
      romFiles = _filterDuplicatesByPriority(customFiles);
    } else {
      final files = folder.listSync().whereType<File>().toList();
      final matchingFiles = files.where((f) {
        final ext = p.extension(f.path).toLowerCase();
        return extensions.contains(ext);
      }).toList();
      // Filtrar duplicados por prioridad de extensión
      romFiles = _filterDuplicatesByPriority(matchingFiles);
    }

    final totalFiles = romFiles.length;
    if (totalFiles == 0) {
      _log("[  WARN ] No se encontraron archivos con las extensiones seleccionadas.");
      db.dispose();
      return;
    }

    // Set para evitar duplicados en la misma sesión
    Set<String> processedSlugs = {};

    // Obtener juegos existentes en DB para evitar duplicados si cleanOld es false
    Set<String> existingSlugs = {};
    Set<String> existingRomPaths = {};
    Set<String> claimedSlugs = {};
    if (!cleanOld) {
      final rows = db.select("SELECT slug FROM games WHERE runner = ?", [
        runner,
      ]);
      for (final row in rows) {
        existingSlugs.add(row['slug'] as String);
      }

      if (Directory(configDir).existsSync()) {
        try {
          final files = Directory(configDir).listSync();
          for (var f in files) {
            if (f is File && f.path.endsWith('.yml')) {
              final content = f.readAsStringSync();
              final matchMain = RegExp(r'^\s*main_file:\s*"(.*)"', multiLine: true).firstMatch(content);
              if (matchMain != null) {
                existingRomPaths.add(p.normalize(matchMain.group(1)!));
              }
              final matchWua = RegExp(r'^\s*wua_rom:\s*"(.*)"', multiLine: true).firstMatch(content);
              if (matchWua != null) {
                existingRomPaths.add(p.normalize(matchWua.group(1)!));
              }
            }
          }
        } catch (_) {}
      }

      // Pre-calcular slugs reclamados por archivos ya inyectados
      final romCache = RomCacheRepository();
      try {
        for (var file in romFiles) {
          final normalizedPath = _getLutrisRomPath(file.path);
          if (existingRomPaths.contains(normalizedPath)) {
            final rawName = p.basenameWithoutExtension(file.path);
            String gameName = customNames?[file.path] ?? rawName;
            if (useOfflineId) {
              final cached = romCache.shouldProcessRom(file.path);
              if (cached?.identifiedName != null) {
                gameName = cached!.identifiedName!;
              }
            }
            claimedSlugs.add(slugify(gameName));
          }
        }
      } finally {
        romCache.dispose();
      }
    }

    _log("[ START ] Inyectando juegos desde: $romFolder (Runner: $runner)");

    for (int i = 0; i < romFiles.length; i++) {
      final f = romFiles[i];
      final rawName = p.basenameWithoutExtension(f.path);
      String gameName = customNames?[f.path] ?? rawName;
      final fullRomPath = f.path;

      // Early exit si la extensión no es válida para la plataforma
      final ext = p.extension(f.path).toLowerCase();
      if (!extensions.contains(ext)) {
        _log("[  SKIP ] Extensión no válida para $platformName ($runner): $ext");
        continue;
      }

      final isManuallyEdited = manuallyEditedPaths?.contains(fullRomPath) ?? false;
      final isAlreadyIdentified = gameName != rawName;

      if (useOfflineId && useHighPrecision && !isManuallyEdited && !isAlreadyIdentified) {
        if (_shouldCalculateHash(
          fullRomPath,
          reuseIdentification: reuseIdentification,
        )) {
          gameName = await _getIdentifiedName(
            fullRomPath,
            gameName,
            useHighPrecision: useHighPrecision,
            reuseIdentification: reuseIdentification,
          );
        } else {
          final cached = _romCache.shouldProcessRom(fullRomPath);
          if (cached?.identifiedName != null) {
            gameName = cached!.identifiedName!;
          }
        }
      }

      final gameSlug = slugify(gameName);

      if (processedSlugs.contains(gameSlug)) {
        _log(
          "[  SKIP ] Saltando formato duplicado: $gameSlug (${p.extension(f.path)})",
        );
        continue;
      }
      processedSlugs.add(gameSlug);

      final normalizedRomPath = _getLutrisRomPath(fullRomPath);
      if (!cleanOld && (existingRomPaths.contains(normalizedRomPath) || (existingSlugs.contains(gameSlug) && !claimedSlugs.contains(gameSlug)))) {
        _log("[  SKIP ] Juego ya existe en Lutris: $gameSlug");
        continue;
      }

      final uniqueTime = currentTime + count;
      final configId = _createLutrisYaml(
        gameSlug,
        fullRomPath,
        uniqueTime,
        specialConfig: specialConfig,
      );

      final coversDir = lutrisPaths['covers_dir'];
      final bannersDir = lutrisPaths['banners_dir'];
      final lutrisIconsDir = lutrisPaths['lutris_icons_dir'];
      final systemIconsDir = lutrisPaths['system_icons_dir'];

      final hasCover = coversDir != null && File(p.join(coversDir, "$gameSlug.jpg")).existsSync();
      final hasBanner = bannersDir != null && File(p.join(bannersDir, "$gameSlug.jpg")).existsSync();
      final hasLutrisIcon = lutrisIconsDir != null && File(p.join(lutrisIconsDir, "$gameSlug.png")).existsSync();
      final hasSystemIcon = systemIconsDir != null && File(p.join(systemIconsDir, "lutris_$gameSlug.png")).existsSync();
      final hasIcon = hasLutrisIcon || hasSystemIcon;

      try {
        db.execute(
          '''
          INSERT INTO games (
              name, slug, runner, executable, directory, configpath, 
              installed, installed_at, platform, lastplayed,
              has_custom_banner, has_custom_icon, has_custom_coverart_big, playtime
          )
          VALUES (?, ?, ?, NULL, NULL, ?, 1, ?, ?, 0, ?, ?, ?, 0)
        ''',
          [
            gameName, 
            gameSlug, 
            runner, 
            configId, 
            uniqueTime, 
            platformName,
            hasBanner ? 1 : 0,
            hasIcon ? 1 : 0,
            hasCover ? 1 : 0
          ],
        );

        count++;
        final progress = (i + 1) / totalFiles;
        _log("[  DONE ] Agregado: $gameName", progress);
      } catch (e) {
        final errorMsg = "[  WARN ] Error con $gameName: $e";
        errors.add(errorMsg);
        _log(errorMsg);
      }
    }

    db.dispose();
    _romCache.dispose();

    _log("[  DONE ] Inyección completa! $count juegos nuevos agregados.", 1.0);

    if (errors.isNotEmpty) {
      _log("Se encontraron ${errors.length} errores.");
    }
  }

  Map<String, dynamic> getCacheStats() {
    return _romCache.getStats();
  }

  void clearCache() {
    _romCache.clearCache();
  }

  void dispose() {
    _romCache.dispose();
  }

  static String slugify(String value) {
    String slug = value.toLowerCase();
    
    final accents = {
      'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u',
      'ä': 'a', 'ë': 'e', 'ï': 'i', 'ö': 'o', 'ü': 'u',
      'â': 'a', 'ê': 'e', 'î': 'i', 'ô': 'o', 'û': 'u',
      'à': 'a', 'è': 'e', 'ì': 'i', 'ò': 'o', 'ù': 'u',
      'ñ': 'n', 'ç': 'c'
    };
    accents.forEach((key, val) {
      slug = slug.replaceAll(key, val);
    });

    slug = slug.replaceAll(RegExp(r'[^\w\s\-]'), '');
    slug = slug.replaceAll(RegExp(r'[-\s_]+'), '-');
    slug = slug.trim().replaceAll(RegExp(r'^----+|----+$'), '');
    
    if (slug.isEmpty) {
      slug = 'game';
    }
    return slug;
  }

  String _getLutrisRomPath(String romPath) {
    final ext = p.extension(romPath).toLowerCase();
    if (ext == '.rpx') {
      final parentDir = p.dirname(romPath);
      final parentName = p.basename(parentDir).toLowerCase();
      if (parentName == 'code') {
        return p.normalize(p.dirname(parentDir));
      }
    }
    return p.normalize(romPath);
  }
}
