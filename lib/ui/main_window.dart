import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:sqlite3/sqlite3.dart' hide Row;
import '../platforms/platform_registry.dart';
import '../core/lutris/lutris_detector.dart';
import '../core/injector/rom_injector.dart';
import '../core/injector/dat_resolver.dart';
import '../core/metadata/hash_service.dart';
import '../core/metadata/metadata_downloader.dart';
import '../core/metadata/screenscraper_service.dart';
import '../core/lutris/config_manager.dart';
import '../core/lutris/rom_cache_repository.dart';
import 'visual_manager_screen.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart' show rootBundle, Clipboard, ClipboardData;
import '../core/lutris/translation_manager.dart';

class InjectionItem {
  final String filePath;
  String displayName;
  bool isSelected;
  bool wasManuallyEdited;
  bool alreadyExists;

  InjectionItem({
    required this.filePath,
    required this.displayName,
    this.isSelected = true,
    this.wasManuallyEdited = false,
    this.alreadyExists = false,
  });
}

class MainWindow extends StatefulWidget {
  const MainWindow({super.key});

  @override
  State<MainWindow> createState() => _MainWindowState();
}

class _MainWindowState extends State<MainWindow> {
  int _currentIndex = 0;
  LutrisDetector? _detector;
  Map<String, String?>? _lutrisPaths;
  List<String> _availableLutrisModes = [];

  PlatformInfo? _selectedPlatform;
  EmulatorInfo? _selectedEmulator; // Nuevo
  List<String> _selectedExtensions = [];
  String _romFolder = '';
  String _apiKey = '';
  String _ssUser = '';
  String _ssPassword = '';
  String _appVersion = 'v2.9.10';

  List<InjectionItem> _previewItems = [];
  bool _isScanning = false;
  bool _cleanOldGames = false;
  bool _useHighPrecision = false;
  bool _reuseIdentification = true;
  bool _useOfflineId = true;
  bool _isRecursive = false;
  bool _isProcessing = false;

  bool _showApiStats = false;
  Map<String, dynamic>? _apiStats;

  String _logText = '';
  double _progress = 0.0;

  final ScrollController _logScrollController = ScrollController();
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _ssUserController = TextEditingController();
  final TextEditingController _ssPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _detectLutris();
    _loadPersistedConfig();
    _loadAppVersion();
    final platforms = PlatformRegistry.getInjectorPlatforms();
    if (platforms.isNotEmpty) {
      _onPlatformChanged(platforms.first);
    }
  }

  Future<void> _loadPersistedConfig() async {
    final key = await ConfigManager.getApiKey();
    final ssUser = await ConfigManager.getSSUser();
    final ssPass = await ConfigManager.getSSPassword();
    final lang = await ConfigManager.getLanguage();

    setState(() {
      _apiKey = key;
      _apiKeyController.text = key;
      _ssUser = ssUser;
      _ssUserController.text = ssUser;
      _ssPassword = ssPass;
      _ssPasswordController.text = ssPass;
      I18n.setLanguage(lang);
    });

    if (key.isNotEmpty) _log("API Key loaded.");
    if (ssUser.isNotEmpty) _log("ScreenScraper configured.");
  }

  void _onPlatformChanged(PlatformInfo? val) async {
    setState(() {
      _selectedPlatform = val;
      if (val != null) {
        _selectedEmulator = val.emulators.first;
        _selectedExtensions = List.from(_selectedEmulator!.extensions);
        _previewItems = [];
      }
    });

    if (val != null) {
      final savedPath = await ConfigManager.getPlatformPath(val.platformId);
      if (savedPath.isNotEmpty) {
        setState(() {
          _romFolder = savedPath;
        });
        _scanFolder();
      }
    }
  }

  void _onEmulatorChanged(EmulatorInfo? val) {
    if (val == null) return;
    setState(() {
      _selectedEmulator = val;
      _selectedExtensions = List.from(val.extensions);
      _previewItems = [];
    });
    _scanFolder();
  }

  void _detectLutris() {
    try {
      _detector = LutrisDetector(interactive: false);
      _lutrisPaths = _detector?.getPaths();
      _availableLutrisModes = _detector?.getAvailableModes() ?? [];

      if (_lutrisPaths?['mode'] == null || _lutrisPaths!['mode']!.isEmpty) {
        _log('No se detectó Lutris instalado.'.t());
      } else {
        _log('${'Lutris detectado: '.t()}${_lutrisPaths!['mode']}');
      }
    } catch (e) {
      _log('${'Error detectando Lutris: '.t()}$e');
    }
  }

  void _log(String message, [double? progress]) {
    setState(() {
      _logText += "$message\n";
      if (progress != null) {
        _progress = progress;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScrollController.hasClients) {
        _logScrollController.animateTo(
          _logScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearLog() {
    setState(() {
      _logText = '';
      _progress = 0.0;
    });
  }

  void _switchLutrisMode(String newMode) {
    if (_detector == null || _lutrisPaths?['mode'] == newMode) return;

    setState(() {
      _detector!.setMode(newMode);
      _lutrisPaths = _detector!.getPaths();
    });

    _log('${'Cambiado a: '.t()}$newMode');
  }

  void _editItemName(InjectionItem item) {
    final controller = TextEditingController(text: item.displayName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar Nombre'.t()),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Nombre en Lutris'.t(),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'.t()),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                item.displayName = controller.text.trim();
                item.wasManuallyEdited = true;
              });
              Navigator.pop(context);
            },
            child: Text('Guardar'.t()),
          ),
        ],
      ),
    );
  }

  Future<bool> _showQuotaWarningDialog(int available, int total) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
            const SizedBox(width: 8),
            Text('Quota Limitada'.t(), style: const TextStyle(fontSize: 16)),
          ],
        ),
        content: Text(
          '${'Solo tienes '.t()}$available${' requests para '.t()}$total${' ROMs.\n\nLas primeras '.t()}$available${' serán identificadas por ScreenScraper.'.t()}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancelar'.t()),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Continuar'.t()),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _browseFolder() async {
    final String? folderPath = await getDirectoryPath();
    if (folderPath != null) {
      setState(() {
        _romFolder = folderPath;
        _previewItems = [];
      });
      if (_selectedPlatform != null) {
        await ConfigManager.savePlatformPath(
          _selectedPlatform!.platformId,
          folderPath,
        );
      }
      _scanFolder();
    }
  }

  Future<bool> _isWiiUBaseGame(String rpxPath) async {
    try {
      final codeDir = p.dirname(rpxPath);
      final appXmlFile = File(p.join(codeDir, 'app.xml'));
      if (appXmlFile.existsSync()) {
        final content = await appXmlFile.readAsString();
        final match = RegExp(r'<title_id[^>]*>([a-fA-F0-9]{16})</title_id>').firstMatch(content);
        if (match != null) {
          final titleId = match.group(1)!.toLowerCase();
          // 0005000e = Update, 0005000c = DLC
          if (titleId.startsWith('0005000e') || titleId.startsWith('0005000c')) {
            return false;
          }
        }
      }
    } catch (e) {
        _log("[  WARN ] ${'Error al leer app.xml: '.t()}$e");
    }
    return true;
  }

  Future<String> _getWiiUGameName(String rpxPath) async {
    try {
      final codeDir = p.dirname(rpxPath);
      final gameDir = p.dirname(codeDir);
      final metaXmlFile = File(p.join(gameDir, 'meta', 'meta.xml'));

      if (metaXmlFile.existsSync()) {
        final content = await metaXmlFile.readAsString();

        // 1. Intentar longname_es (Idioma principal del usuario)
        final matchEs = RegExp(r'<longname_es[^>]*>([^<]+)</longname_es>').firstMatch(content);
        if (matchEs != null) {
          final name = matchEs.group(1)!.trim().replaceAll(RegExp(r'\s+'), ' ');
          if (name.isNotEmpty) return name;
        }

        // 2. Intentar longname_en
        final matchEn = RegExp(r'<longname_en[^>]*>([^<]+)</longname_en>').firstMatch(content);
        if (matchEn != null) {
          final name = matchEn.group(1)!.trim().replaceAll(RegExp(r'\s+'), ' ');
          if (name.isNotEmpty) return name;
        }

        // 3. Fallback a shortname
        final matchShortEs = RegExp(r'<shortname_es[^>]*>([^<]+)</shortname_es>').firstMatch(content);
        if (matchShortEs != null) {
          final name = matchShortEs.group(1)!.trim().replaceAll(RegExp(r'\s+'), ' ');
          if (name.isNotEmpty) return name;
        }

        final matchShortEn = RegExp(r'<shortname_en[^>]*>([^<]+)</shortname_en>').firstMatch(content);
        if (matchShortEn != null) {
          final name = matchShortEn.group(1)!.trim().replaceAll(RegExp(r'\s+'), ' ');
          if (name.isNotEmpty) return name;
        }
      }

      // Fallback: Nombre de la carpeta que contiene code/content/meta
      final folderName = p.basename(gameDir);
      if (folderName.isNotEmpty && folderName != 'code' && folderName != 'WiiU' && folderName != 'Wii U') {
        // Remover corchetes con IDs de región/versión al final (ej: [ALZE01])
        final cleanedName = folderName.replaceAll(RegExp(r'\s*\[[a-zA-Z0-9]{6}\]\s*$'), '').trim();
        if (cleanedName.isNotEmpty) return cleanedName;
        return folderName;
      }
    } catch (e) {
        _log("[  WARN ] ${'Error al obtener nombre desde meta.xml: '.t()}$e");
    }

    return p.basenameWithoutExtension(rpxPath);
  }

  Future<void> _scanFolder() async {
    if (_romFolder.isEmpty || _selectedPlatform == null || _selectedEmulator == null) return;

    setState(() {
      _isScanning = true;
      _previewItems = [];
    });

    try {
      final dir = Directory(_romFolder);
      final entities = await dir.list(recursive: _isRecursive).toList();

      final List<File> matchingFiles = [];
      for (var entity in entities) {
        if (entity is File) {
          final ext = p.extension(entity.path).toLowerCase();
          if (_selectedExtensions.contains(ext)) {
            final slug = p.basenameWithoutExtension(entity.path);
            if (_selectedPlatform?.platformId == 'mame') {
              if (await DatResolver.isMameGame(slug)) {
                matchingFiles.add(entity);
              }
            } else if (ext == '.rpx') {
              if (await _isWiiUBaseGame(entity.path)) {
                matchingFiles.add(entity);
              }
            } else {
              matchingFiles.add(entity);
            }
          }
        }
      }

      final filteredFiles = RomInjector.filterDuplicatesByPriority(
        matchingFiles,
        _selectedEmulator!,
        (msg, [progress]) => _log(msg),
      );

      final Set<String> existingSlugs = {};
      final Set<String> existingRomPaths = {};
      final dbPath = _lutrisPaths?['db_path'];
      final configDir = _lutrisPaths?['config_dir_main'];

      if (dbPath != null && File(dbPath).existsSync()) {
        try {
          final db = sqlite3.open(dbPath);
          final rows = db.select("SELECT slug FROM games WHERE runner = ?", [_selectedEmulator!.runner]);
          for (final row in rows) {
            existingSlugs.add(row['slug'] as String);
          }
          db.dispose();
        } catch (_) {}
      }

      if (configDir != null && Directory(configDir).existsSync()) {
        try {
          final dir = Directory(configDir);
          final files = dir.listSync();
          for (var f in files) {
            if (f is File && f.path.endsWith('.yml')) {
              final content = f.readAsStringSync();
              final matchMain = RegExp(r"""^\s*main_file:\s*["']?([^"'\r\n]+)["']?$""", multiLine: true).firstMatch(content);
              if (matchMain != null) {
                existingRomPaths.add(p.normalize(matchMain.group(1)!.trim()));
              }
              final matchWua = RegExp(r"""^\s*wua_rom:\s*["']?([^"'\r\n]+)["']?$""", multiLine: true).firstMatch(content);
              if (matchWua != null) {
                existingRomPaths.add(p.normalize(matchWua.group(1)!.trim()));
              }
            }
          }
        } catch (_) {}
      }

      // Pre-calcular slugs que ya tienen su ruta correspondiente agregada en Lutris
      final Set<String> claimedSlugs = {};
      final romCache = RomCacheRepository();
      try {
        for (var file in filteredFiles) {
          final normalizedPath = _getLutrisRomPath(file.path);
          if (existingRomPaths.contains(normalizedPath)) {
            final slug = p.basenameWithoutExtension(file.path);
            final ext = p.extension(file.path).toLowerCase();
            String displayName = slug;

            if (ext == '.rpx') {
              displayName = await _getWiiUGameName(file.path);
            } else if (_useOfflineId) {
              final cached = romCache.shouldProcessRom(file.path);
              if (cached != null && cached.identifiedName != null) {
                displayName = cached.identifiedName!;
              }
            }
            final gameSlug = RomInjector.slugify(displayName);
            claimedSlugs.add(gameSlug);
          }
        }
      } finally {
        romCache.dispose();
      }

      final List<InjectionItem> detected = [];
      if (_useOfflineId) {
        final romCache = RomCacheRepository();
        try {
          for (var file in filteredFiles) {
            final slug = p.basenameWithoutExtension(file.path);
            final ext = p.extension(file.path).toLowerCase();
            String displayName = slug;

            if (ext == '.rpx') {
              displayName = await _getWiiUGameName(file.path);
            } else {
              // Verificar si ya está en la caché local SQLite para cargar al instante
              final cached = romCache.shouldProcessRom(file.path);
              if (cached != null && cached.identifiedName != null) {
                displayName = cached.identifiedName!;
              }
            }

            final gameSlug = RomInjector.slugify(displayName);
            final exists = existingRomPaths.contains(_getLutrisRomPath(file.path)) ||
                (existingSlugs.contains(gameSlug) && !claimedSlugs.contains(gameSlug));

            detected.add(
              InjectionItem(
                filePath: file.path,
                displayName: displayName,
                isSelected: !exists,
                alreadyExists: exists,
              ),
            );
          }
        } finally {
          romCache.dispose();
        }
      } else {
        for (var file in filteredFiles) {
          final slug = p.basenameWithoutExtension(file.path);
          final ext = p.extension(file.path).toLowerCase();
          String displayName = slug;

          if (ext == '.rpx') {
            displayName = await _getWiiUGameName(file.path);
          }

          final gameSlug = RomInjector.slugify(displayName);
          final exists = existingRomPaths.contains(_getLutrisRomPath(file.path)) ||
              (existingSlugs.contains(gameSlug) && !claimedSlugs.contains(gameSlug));

          detected.add(
            InjectionItem(
              filePath: file.path,
              displayName: displayName,
              isSelected: !exists,
              alreadyExists: exists,
            ),
          );
        }
      }

      if (mounted) {
        setState(() {
          _previewItems = detected;
        });
      }

      if (_useOfflineId && _selectedPlatform != null && DatResolver.isPlatformSupported(_selectedPlatform!.platformId) && detected.isNotEmpty) {
        final platformId = _selectedPlatform!.platformId;
        _log('Resolviendo nombres de juegos usando base de datos local No-Intro/Redump/MAME...'.t());
        final chunkSize = 50;
        int processedCount = 0;
        final List<String> unresolvedSlugs = [];

        // Asegurarnos de que el DAT esté listo (si es de GitHub se descarga y se guarda localmente)
        final datFile = await DatResolver.getDatFile(platformId);
        if (datFile == null) {
          _log("[  WARN ] ${'No se pudo cargar la base de datos local para '.t()}$platformId");
        } else {
          final scanRomCache = RomCacheRepository();
          try {
            for (var i = 0; i < filteredFiles.length; i += chunkSize) {
              final chunk = filteredFiles.skip(i).take(chunkSize).toList();
              
              // Filtrar el lote para excluir los archivos que ya fueron resueltos en caché (displayName != slug)
              final List<File> chunkToResolve = [];
              for (final file in chunk) {
                final slug = p.basenameWithoutExtension(file.path);
                final item = _previewItems.firstWhere((item) => item.filePath == file.path);
                if (item.displayName == slug) {
                  chunkToResolve.add(file);
                } else {
                  processedCount++; // Ya resuelto en caché, contar como procesado
                }
              }

              if (chunkToResolve.isEmpty) {
                continue;
              }

              final isNoHashPlatform = (platformId == 'mame' || platformId == 'gamecube' || platformId == 'wii');
              _log("${'Buscando en base de datos local '.t()}$platformId: ${'lote'.t()} ${i ~/ chunkSize + 1} ${'de '.t()}${(filteredFiles.length / chunkSize).ceil()}...");
              
              final Map<String, String> resolvedChunk = {};
              for (final file in chunkToResolve) {
                final slug = p.basenameWithoutExtension(file.path);
                final ext = p.extension(file.path).toLowerCase();
                final isNoHashFormat = (ext == '.chd' || ext == '.cso' || ext == '.pbp' || ext == '.rvz' || ext == '.gcz' || ext == '.wbfs' || ext == '.iso');
                final skipHashes = isNoHashPlatform || isNoHashFormat;
                
                try {
                  String? resolvedName;
                  String? crc32;
                  String? md5;
                  String? sha1;

                  if (skipHashes) {
                    resolvedName = await DatResolver.resolveGameName(
                      platformId: platformId,
                      filePath: file.path,
                    );
                  } else {
                    final hashes = await HashService.calculateHashes(file.path);
                    crc32 = hashes.crc32;
                    md5 = hashes.md5;
                    sha1 = hashes.sha1;
                    resolvedName = await DatResolver.resolveGameName(
                      platformId: platformId,
                      crc32: crc32,
                      md5: md5,
                      sha1: sha1,
                      filePath: file.path,
                    );
                  }
                  if (resolvedName != null) {
                    resolvedChunk[slug] = resolvedName;
                    
                    // Guardar en la caché local
                    final stat = file.statSync();
                    scanRomCache.cacheRomInfo(
                      filePath: file.path,
                      fileSize: stat.size,
                      lastModified: stat.modified,
                      sha1: sha1,
                      md5: md5,
                      crc32: crc32,
                      identifiedName: resolvedName,
                      isIdentified: true,
                    );
                  } else {
                    unresolvedSlugs.add(slug);
                  }
                } catch (_) {
                  unresolvedSlugs.add(slug);
                }
              }

              if (mounted) {
                setState(() {
                  for (var item in _previewItems) {
                    final slug = p.basenameWithoutExtension(item.filePath);
                    if (resolvedChunk.containsKey(slug)) {
                      final resolvedName = resolvedChunk[slug]!;
                      item.displayName = resolvedName;

                      final resolvedSlug = RomInjector.slugify(resolvedName);
                      final exists = existingRomPaths.contains(_getLutrisRomPath(item.filePath)) ||
                          (existingSlugs.contains(resolvedSlug) && !claimedSlugs.contains(resolvedSlug));
                      item.alreadyExists = exists;
                      item.isSelected = !exists;
                    }
                  }
                });
              }
              
              processedCount += chunkToResolve.length;
              _log("${'Progreso offline: '.t()}$processedCount / ${filteredFiles.length} ${'juegos procesados.'.t()}");
            }
          } finally {
            scanRomCache.dispose();
          }

          if (unresolvedSlugs.isNotEmpty) {
            _log("[  WARN ] ${'Base de datos local no pudo identificar '.t()}${unresolvedSlugs.length} juego(s): ${unresolvedSlugs.join(', ')}");
          }
        }
      }

      _log("${detected.length} ${'juegos encontrados.'.t()}");
    } catch (e) {
      _log("Error: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  Future<void> _refreshApiStats({bool force = false}) async {
    final stats = ScreenScraperService.getStats();
    Map<String, dynamic> romCacheStats = {};
    try {
      final romCache = RomCacheRepository();
      romCacheStats = romCache.getStats();
      romCache.dispose();
    } catch (e) {
      romCacheStats = {'totalEntries': 0, 'identifiedEntries': 0};
    }

    ScreenScraperQuota? quota;
    final now = DateTime.now();
    final shouldFetchQuota = force || _lastQuotaFetch == null || now.difference(_lastQuotaFetch!) > Duration(minutes: 5);

    if (shouldFetchQuota) {
      quota = await ScreenScraperService.getQuota();
      _lastQuotaFetch = DateTime.now();
    } else {
      quota = ScreenScraperService.currentQuota;
    }

    setState(() {
      _apiStats = {
        ...stats,
        ...romCacheStats,
        'requestsToday': quota?.requestsToday ?? stats['lastKnownQuota']?['requestsToday'],
        'maxRequestsPerDay': quota?.maxRequestsPerDay ?? stats['lastKnownQuota']?['maxPerDay'],
        'remainingToday': quota?.remainingToday ?? stats['lastKnownQuota']?['remaining'],
        'lastQuotaFetch': _lastQuotaFetch?.toIso8601String(),
      };
    });
  }

  DateTime? _lastQuotaFetch;

  void _showConfigDialog({int initialTabIndex = 0}) {
    _apiKeyController.text = _apiKey;
    _ssUserController.text = _ssUser;
    _ssPasswordController.text = _ssPassword;
    String selectedLangTemp = I18n.currentLang;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return DefaultTabController(
              length: 3,
              initialIndex: initialTabIndex,
              child: AlertDialog(
                backgroundColor: const Color(0xFF0A0A0A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFF1A1A1A)),
                ),
                titlePadding: EdgeInsets.zero,
                title: Container(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CONFIGURACIÓN'.t(), style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      const SizedBox(height: 16),
                      TabBar(
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white24,
                        indicatorColor: Colors.white,
                        indicatorWeight: 2,
                        dividerColor: Colors.transparent,
                        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        tabs: [
                          Tab(text: 'GENERAL'.t()),
                          Tab(text: 'STEAMGRIDDB'.t()),
                          Tab(text: 'SCREEN SCRAPER'.t()),
                        ],
                      ),
                    ],
                  ),
                ),
                content: SizedBox(
                  width: 400,
                  height: 250,
                  child: TabBarView(
                    children: [
                      // Tab General
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('IDIOMA'.t(), style: const TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: selectedLangTemp,
                              dropdownColor: const Color(0xFF0A0A0A),
                              style: const TextStyle(fontSize: 13, color: Colors.white70),
                              decoration: InputDecoration(
                                isDense: true,
                                filled: true,
                                fillColor: Colors.black,
                                prefixIcon: const Icon(Icons.language_outlined, size: 16, color: Colors.white24),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFF1A1A1A))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFF1A1A1A))),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'en', child: Text('English (Default)')),
                                DropdownMenuItem(value: 'es', child: Text('Español')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() {
                                    selectedLangTemp = val;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Selecciona el idioma de la aplicación.'.t(),
                              style: const TextStyle(color: Colors.white24, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      // Tab SteamGridDB
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('API KEY'.t(), style: const TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _apiKeyController,
                              obscureText: true,
                              style: const TextStyle(fontSize: 13, color: Colors.white70),
                              decoration: InputDecoration(
                                hintText: 'Tu API Key...'.t(),
                                isDense: true,
                                filled: true,
                                fillColor: Colors.black,
                                prefixIcon: const Icon(Icons.vpn_key_outlined, size: 16, color: Colors.white24),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFF1A1A1A))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFF1A1A1A))),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildLinkButton(
                              text: 'Obtén tu API Key en SteamGridDB'.t(),
                              url: 'https://www.steamgriddb.com/profile/preferences/api',
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Requerido para descargar carátulas, banners e iconos automáticamente.'.t(),
                              style: const TextStyle(color: Colors.white24, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      // Tab ScreenScraper
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('USUARIO'.t(), style: const TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _ssUserController,
                              style: const TextStyle(fontSize: 13, color: Colors.white70),
                              decoration: InputDecoration(
                                hintText: 'Usuario...'.t(),
                                isDense: true,
                                filled: true,
                                fillColor: Colors.black,
                                prefixIcon: const Icon(Icons.person_outline, size: 16, color: Colors.white24),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFF1A1A1A))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFF1A1A1A))),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text('CONTRASEÑA'.t(), style: const TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _ssPasswordController,
                              obscureText: true,
                              style: const TextStyle(fontSize: 13, color: Colors.white70),
                              decoration: InputDecoration(
                                hintText: 'Contraseña...'.t(),
                                isDense: true,
                                filled: true,
                                fillColor: Colors.black,
                                prefixIcon: const Icon(Icons.lock_outline, size: 16, color: Colors.white24),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFF1A1A1A))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFF1A1A1A))),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildLinkButton(
                              text: 'Regístrate en ScreenScraper'.t(),
                              url: 'https://www.screenscraper.fr/',
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Requerido para la identificación de alta precisión y metadatos.'.t(),
                              style: const TextStyle(color: Colors.white24, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('CANCELAR'.t(), style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () async {
                      final newKey = _apiKeyController.text.trim();
                      final newUser = _ssUserController.text.trim();
                      final newPass = _ssPasswordController.text;
                      setState(() {
                        _apiKey = newKey;
                        _ssUser = newUser;
                        _ssPassword = newPass;
                        I18n.setLanguage(selectedLangTemp);
                      });
                      await ConfigManager.saveApiKey(newKey);
                      await ConfigManager.saveSSCredentials(newUser, newPass);
                      await ConfigManager.saveLanguage(selectedLangTemp);
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    child: Text('GUARDAR'.t(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      _log("${'No se pudo abrir la URL: '.t()}$url");
    }
  }

  Widget _buildLinkButton({required String text, required String url}) {
    final bool isAppImage = Platform.environment.containsKey('APPIMAGE');

    if (isAppImage) {
      return InkWell(
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: url));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${'Link copied to clipboard'.t()}: $url'),
                duration: const Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.grey[900],
              ),
            );
          }
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.copy_rounded, size: 11, color: Colors.white.withOpacity(0.5)),
            const SizedBox(width: 6),
            Text(
              '$text (${'Copy Link'.t()})',
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    } else {
      return InkWell(
        onTap: () => _launchUrl(url),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.open_in_new_rounded, size: 11, color: Colors.white.withOpacity(0.5)),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _startProcess(String action) async {
    if (_isProcessing) return;
    if (_lutrisPaths == null) {
      _log('Rutas de Lutris no detectadas.'.t());
      return;
    }
    if (_selectedPlatform == null || _selectedEmulator == null) {
      _log('Selecciona plataforma y emulador.'.t());
      return;
    }
    if ((action == 'inject' || action == 'full') && _romFolder.isEmpty) {
      _log('Selecciona una carpeta de ROMs.'.t());
      return;
    }
    if ((action == 'inject' || action == 'full') && _selectedExtensions.isEmpty) {
      _log('Selecciona al menos una extensión.'.t());
      return;
    }
    if ((action == 'metadata' || action == 'full') && _apiKey.isEmpty) {
      _log('Configura la API Key de SteamGridDB.'.t());
      _showConfigDialog(initialTabIndex: 1);
      return;
    }

    if (_useHighPrecision && (action == 'inject' || action == 'full')) {
      final selectedCount = _previewItems.where((i) => i.isSelected).length;
      if (_ssUser.isEmpty || _ssPassword.isEmpty) {
        _log('Alta Precisión requiere credenciales de ScreenScraper.'.t());
        _showConfigDialog(initialTabIndex: 2);
        return;
      }

      _log('Verificando quota...'.t());
      final quotaCheck = await ScreenScraperService.canStartMassiveScan(selectedCount);
      if (!quotaCheck.canProceed) {
        _log("Error: ${quotaCheck.message}");
        return;
      }
      if (quotaCheck.remainingRequests != null && quotaCheck.remainingRequests! < selectedCount) {
        final shouldContinue = await _showQuotaWarningDialog(quotaCheck.remainingRequests!, selectedCount);
        if (!shouldContinue) return;
      }
    }

    setState(() {
      _isProcessing = true;
      _clearLog();
    });

    try {
      if (action == 'inject' || action == 'full') {
        final selectedFiles = _previewItems.where((item) => item.isSelected).map((item) => File(item.filePath)).toList();
        if (selectedFiles.isEmpty) {
          _log("[  WARN ] ${'No hay ningún juego seleccionado para inyectar.'.t()}");
          setState(() {
            _isProcessing = false;
          });
          return;
        }
        final Map<String, String> customNames = {
          for (var item in _previewItems.where((i) => i.isSelected && (i.wasManuallyEdited || _selectedPlatform?.platformId == 'mame' || DatResolver.isPlatformSupported(_selectedPlatform!.platformId) || p.basenameWithoutExtension(i.filePath) != i.displayName)))
            item.filePath: item.displayName,
        };
        final List<String> manuallyEditedPaths = _previewItems
            .where((item) => item.isSelected && item.wasManuallyEdited)
            .map((item) => item.filePath)
            .toList();

        final injector = RomInjector(
          lutrisPaths: _lutrisPaths!,
          platformKey: _selectedPlatform!.platformId,
          emulatorId: _selectedEmulator!.id,
          romFolder: _romFolder,
          customExtensions: _selectedExtensions,
          progressCallback: (msg, prog) => _log(msg, prog),
        );

        await injector.injectRoms(
          cleanOld: _cleanOldGames,
          useHighPrecision: _useHighPrecision,
          reuseIdentification: _reuseIdentification,
          useOfflineId: _useOfflineId,
          customFiles: selectedFiles,
          customNames: customNames,
          manuallyEditedPaths: manuallyEditedPaths,
        );
      }

      if (action == 'metadata' || action == 'full') {
        final downloader = MetadataDownloader(
          lutrisPaths: _lutrisPaths!,
          apiKey: _apiKey,
          runner: _selectedEmulator!.runner,
          progressCallback: (msg, prog) => _log(msg, prog),
        );
        await downloader.downloadMetadata(skipExisting: true);
      }
      await _refreshApiStats();
    } catch (e) {
      _log("Error: $e");
    } finally {
      setState(() {
        _isProcessing = false;
        _progress = 1.0;
      });
    }
  }

  Future<void> _loadAppVersion() async {
    try {
      final versionStr = await rootBundle.loadString('version.txt');
      if (mounted) {
        setState(() {
          _appVersion = 'v${versionStr.trim()}';
        });
      }
    } catch (_) {
      try {
        final file = File('version.txt');
        if (file.existsSync()) {
          final content = file.readAsStringSync().trim();
          if (content.isNotEmpty && mounted) {
            setState(() {
              _appVersion = 'v$content';
            });
          }
        }
      } catch (_) {}
    }
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0A0A0A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFF1A1A1A)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/icon.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Game Link',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _appVersion,
              style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const Text(
              'Universal game companion for linking ROMs and managing media.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Software libre desarrollado como complemento para otros lanzadores y gestión de librerías.'.t(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white24, fontSize: 10, height: 1.4),
            ),
            const SizedBox(height: 24),
            const Divider(color: Colors.white10),
            const SizedBox(height: 16),
            const Text(
              '© 2026 CarlosEvCode',
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
            const SizedBox(height: 8),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CERRAR'.t(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Link', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        toolbarHeight: 48,
        actions: [
          _buildLutrisSelector(),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20, color: Colors.white70),
            offset: const Offset(0, 40),
            color: const Color(0xFF0A0A0A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: const BorderSide(color: Color(0xFF1A1A1A)),
            ),
            onSelected: (value) {
              if (value == 'settings') _showConfigDialog();
              if (value == 'about') _showAboutDialog();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    const Icon(Icons.settings_outlined, size: 16, color: Colors.white70),
                    const SizedBox(width: 12),
                    Text('Configuración'.t(), style: const TextStyle(fontSize: 13, color: Colors.white70)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'about',
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Colors.white70),
                    const SizedBox(width: 12),
                    Text('Acerca de'.t(), style: const TextStyle(fontSize: 13, color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: NavigationBar(
        height: 56,
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (index == 0) {
            _scanFolder();
          }
        },
        destinations: [
          NavigationDestination(icon: const Icon(Icons.flash_on, size: 20), label: 'Inyector'.t()),
          NavigationDestination(icon: const Icon(Icons.grid_view, size: 20), label: 'GESTOR VISUAL'.t()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return _currentIndex == 0 ? _buildInjectorView() : _buildVisualManagerView();
  }

  Widget _buildLutrisSelector() {
    final currentMode = _lutrisPaths != null ? _lutrisPaths!['mode']! : "No detectado".t();
    return PopupMenuButton<String>(
      onSelected: _switchLutrisMode,
      itemBuilder: (context) => _availableLutrisModes.map((mode) => PopupMenuItem(value: mode, child: Text(mode, style: const TextStyle(fontSize: 13)))).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF1A1A1A)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(currentMode, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white70)),
            const SizedBox(width: 6),
            const Icon(Icons.keyboard_arrow_down, size: 14, color: Colors.white38),
          ],
        ),
      ),
    );
  }

  Widget _buildVisualManagerView() {
    return _lutrisPaths == null ? Center(child: Text("Lutris no detectado.".t())) : VisualManagerScreen(
      lutrisPaths: _lutrisPaths!,
      apiKey: _apiKey,
      onShowConfig: () => _showConfigDialog(),
      initialPlatformId: _selectedPlatform?.platformId,
    );
  }

  Widget _buildInjectorView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            Container(
              width: 300,
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: Color(0xFF1A1A1A))),
              ),
              child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: _buildConfigSection()),
            ),
            Expanded(
              child: Column(
                children: [
                  Expanded(flex: 3, child: _buildPreviewPanel()),
                  const Divider(),
                  Expanded(flex: 2, child: _buildLogPanel()),
                  const Divider(),
                  _buildActionBar(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildConfigSection() {
    final platforms = PlatformRegistry.getInjectorPlatforms();
    final stepTitleStyle = const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.5);
    final labelStyle = TextStyle(color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.w500, fontSize: 11, letterSpacing: 0.5);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // STEP 01
        _buildStepHeader('01', 'SISTEMA'.t()),
        const SizedBox(height: 16),
        Text('PLATAFORMA'.t(), style: labelStyle),
        const SizedBox(height: 10),
        DropdownButtonFormField<PlatformInfo>(
          value: _selectedPlatform,
          items: platforms.map((p) => DropdownMenuItem(value: p, child: Text(p.platformName, style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: _isProcessing ? null : _onPlatformChanged,
          decoration: _inputDecoration(),
        ),
        if (_selectedPlatform != null && _selectedPlatform!.emulators.length > 1) ...[
          const SizedBox(height: 20),
          Text('EMULADOR'.t(), style: labelStyle),
          const SizedBox(height: 10),
          DropdownButtonFormField<EmulatorInfo>(
            value: _selectedEmulator,
            items: _selectedPlatform!.emulators.map((e) => DropdownMenuItem(value: e, child: Text(e.name, style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: _isProcessing ? null : _onEmulatorChanged,
            decoration: _inputDecoration(),
          ),
        ],


        const SizedBox(height: 32),
        const Divider(color: Colors.white10),
        const SizedBox(height: 32),

        // STEP 02
        _buildStepHeader('02', 'ORIGEN'.t()),
        const SizedBox(height: 16),
        Text('CARPETA ROMS'.t(), style: labelStyle),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _isProcessing ? null : _browseFolder,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A0A),
                    border: Border.all(color: const Color(0xFF1A1A1A)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(_romFolder.isEmpty ? 'Seleccionar...'.t() : _romFolder, style: const TextStyle(fontSize: 12, color: Colors.white70), overflow: TextOverflow.ellipsis)),
                      const Icon(Icons.folder_open, size: 16, color: Colors.white38),
                    ],
                  ),
                ),
              ),
            ),
            if (_romFolder.isNotEmpty) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white70, size: 20),
                onPressed: _isProcessing || _isScanning ? null : _scanFolder,
                tooltip: 'Actualizar carpeta'.t(),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF0A0A0A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side: const BorderSide(color: Color(0xFF1A1A1A)),
                  ),
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ],
        ),
        if (_selectedEmulator != null) ...[
          const SizedBox(height: 20),
          Text('EXTENSIONES'.t(), style: labelStyle),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _selectedEmulator!.extensions.map((ext) {
              final isSelected = _selectedExtensions.contains(ext);
              return InkWell(
                onTap: _isProcessing ? null : () {
                  setState(() {
                    if (isSelected) {
                      _selectedExtensions.remove(ext);
                    } else {
                      _selectedExtensions.add(ext);
                    }
                  });
                  _scanFolder();
                },
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.transparent,
                    border: Border.all(color: isSelected ? Colors.white : const Color(0xFF1A1A1A)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    ext,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.black : Colors.white38,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],

        const SizedBox(height: 32),
        const Divider(color: Colors.white10),
        const SizedBox(height: 32),

        // STEP 03
        _buildStepHeader('03', 'PREFERENCIAS'.t()),
        const SizedBox(height: 16),
        _buildCompactCheckbox('Limpiar antiguos'.t(), _cleanOldGames, (val) => setState(() => _cleanOldGames = val ?? false)),
        _buildCompactCheckbox('Autodetectar nombres (offline)'.t(), _useOfflineId, (val) {
          setState(() => _useOfflineId = val ?? false);
          _scanFolder();
        }),
        if (_useOfflineId)
          _buildCompactCheckbox('Alta Precisión (Hash)'.t(), _useHighPrecision, (val) {
            setState(() => _useHighPrecision = val ?? false);
            _scanFolder();
          }),
        _buildCompactCheckbox('Escaneo recursivo'.t(), _isRecursive, (val) {
          setState(() => _isRecursive = val ?? false);
          _scanFolder();
        }),
      ],
    );
  }

  Widget _buildStepHeader(String number, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white24),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(number, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.5)),
      ],
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      isDense: true, 
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      filled: true,
      fillColor: const Color(0xFF0A0A0A),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFF1A1A1A))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFF1A1A1A))),
    );
  }

  Widget _buildActionBar() {
    final selectedCount = _previewItems.where((i) => i.isSelected).length;
    final canProcess = selectedCount > 0 && !_isProcessing;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Color(0xFF1A1A1A))),
      ),
      child: Row(
        children: [
          if (!_isProcessing) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  canProcess ? (selectedCount == 1 ? 'JUEGO LISTO'.t() : '$selectedCount ${'JUEGOS LISTOS'.t()}') : 'ESPERANDO SELECCIÓN'.t(),
                  style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  'Inyectar en Lutris + Descargar Metadatos'.t(),
                  style: const TextStyle(color: Colors.white24, fontSize: 10),
                ),
              ],
            ),
          ],
          const Spacer(),
          // Botón de opciones avanzadas
          if (canProcess)
            PopupMenuButton<String>(
              tooltip: 'Opciones avanzadas'.t(),
              icon: const Icon(Icons.tune, color: Colors.white38, size: 20),
              offset: const Offset(0, -100),
              color: const Color(0xFF0A0A0A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: const BorderSide(color: Color(0xFF1A1A1A)),
              ),
              onSelected: _startProcess,
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'inject',
                  child: Row(
                    children: [
                      const Icon(Icons.add, size: 16, color: Colors.white70),
                      const SizedBox(width: 12),
                      Text('Solo Inyectar ROMs'.t(), style: const TextStyle(fontSize: 12, color: Colors.white70)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'metadata',
                  child: Row(
                    children: [
                      const Icon(Icons.download_outlined, size: 16, color: Colors.white70),
                      const SizedBox(width: 12),
                      Text('Solo Descargar Metadatos'.t(), style: const TextStyle(fontSize: 12, color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
          const SizedBox(width: 16),
          // Botón Principal
          _buildActionButton(
            _isProcessing ? 'PROCESANDO...'.t() : 'EJECUTAR PROCESO'.t(), 
            Icons.play_arrow_rounded, 
            () => _startProcess('full'), 
            isPrimary: canProcess,
            isEnabled: canProcess,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onPressed, {required bool isPrimary, bool isEnabled = true}) {
    return TextButton.icon(
      onPressed: isEnabled ? onPressed : null,
      style: TextButton.styleFrom(
        backgroundColor: isPrimary ? Colors.white : Colors.transparent,
        foregroundColor: isPrimary ? Colors.black : Colors.white10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: isPrimary ? BorderSide.none : const BorderSide(color: Color(0xFF1A1A1A)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1)),
    );
  }

  Widget _buildCompactCheckbox(String title, bool value, ValueChanged<bool?> onChanged) {
    return InkWell(
      onTap: _isProcessing ? null : () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              height: 24, width: 24,
              child: Checkbox(
                value: value, 
                onChanged: _isProcessing ? null : onChanged,
                side: const BorderSide(color: Color(0xFF333333)),
                activeColor: Colors.white,
                checkColor: Colors.black,
              ),
            ),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewPanel() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            Text('DETECTADOS'.t(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.white38)),
            const Spacer(),
            Text('${_previewItems.where((i) => i.isSelected).length}/${_previewItems.length}', style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ]),
        ),
        Expanded(
          child: _isScanning ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white24))) : ListView.builder(
            itemCount: _previewItems.length,
            itemBuilder: (context, index) {
              final item = _previewItems[index];
              return ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                leading: Checkbox(
                  value: item.isSelected, 
                  onChanged: (val) => setState(() => item.isSelected = val ?? false),
                  side: const BorderSide(color: Color(0xFF1A1A1A)),
                ),
                title: Text(item.displayName, style: TextStyle(fontSize: 12, color: item.alreadyExists ? Colors.white38 : Colors.white70)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item.alreadyExists)
                      Tooltip(
                        message: 'Ya en la biblioteca de Lutris'.t(),
                        child: const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Icon(Icons.check_circle_outline_rounded, size: 14, color: Colors.white38),
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 14, color: Colors.white24), 
                      onPressed: () => _editItemName(item),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLogPanel() {
    return Container(
      color: const Color(0xFF050505),
      child: Column(
        children: [
          if (_progress > 0 && _progress < 1) LinearProgressIndicator(value: _progress, minHeight: 1, backgroundColor: Colors.transparent, color: Colors.white24),
          Expanded(child: ListView(controller: _logScrollController, padding: const EdgeInsets.all(16), children: [
            Text(_logText.isEmpty ? '> ' + 'Listo.'.t() : _logText, style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Color(0xFF888888), height: 1.5)),
          ])),
        ],
      ),
    );
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
