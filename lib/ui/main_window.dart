import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import '../platforms/platform_registry.dart';
import '../core/lutris/lutris_detector.dart';
import '../core/injector/rom_injector.dart';
import '../core/injector/mame_resolver.dart';
import '../core/injector/dat_resolver.dart';
import '../core/metadata/hash_service.dart';
import '../core/metadata/metadata_downloader.dart';
import '../core/metadata/screenscraper_service.dart';
import '../core/lutris/config_manager.dart';
import '../core/lutris/rom_cache_repository.dart';
import 'visual_manager_screen.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

class InjectionItem {
  final String filePath;
  String displayName;
  bool isSelected;
  bool wasManuallyEdited;

  InjectionItem({
    required this.filePath,
    required this.displayName,
    this.isSelected = true,
    this.wasManuallyEdited = false,
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
  String _mameBinaryPath = '';

  List<InjectionItem> _previewItems = [];
  bool _isScanning = false;
  bool _cleanOldGames = true;
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
    final platforms = PlatformRegistry.getInjectorPlatforms();
    if (platforms.isNotEmpty) {
      _onPlatformChanged(platforms.first);
    }
  }

  Future<void> _loadPersistedConfig() async {
    final key = await ConfigManager.getApiKey();
    final ssUser = await ConfigManager.getSSUser();
    final ssPass = await ConfigManager.getSSPassword();
    final mamePath = await ConfigManager.getMameBinaryPath();

    if (mamePath.isEmpty) {
      final autoPath = await MameResolver.findMameBinary();
      if (autoPath != null) {
        setState(() {
          _mameBinaryPath = autoPath;
        });
        await ConfigManager.saveMameBinaryPath(autoPath);
        _log("MAME detectado automáticamente en: $autoPath");
      }
    } else {
      setState(() {
        _mameBinaryPath = mamePath;
      });
    }

    setState(() {
      _apiKey = key;
      _apiKeyController.text = key;
      _ssUser = ssUser;
      _ssUserController.text = ssUser;
      _ssPassword = ssPass;
      _ssPasswordController.text = ssPass;
    });

    if (key.isNotEmpty) _log("API Key cargada.");
    if (ssUser.isNotEmpty) _log("ScreenScraper configurado.");
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
        _log("No se detectó Lutris instalado.");
      } else {
        _log("Lutris detectado: ${_lutrisPaths!['mode']}");
      }
    } catch (e) {
      _log("Error detectando Lutris: $e");
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

    _log("Cambiado a: $newMode");
  }

  void _editItemName(InjectionItem item) {
    final controller = TextEditingController(text: item.displayName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Nombre'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nombre en Lutris',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                item.displayName = controller.text.trim();
                item.wasManuallyEdited = true;
              });
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<bool> _showQuotaWarningDialog(int available, int total) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
            SizedBox(width: 8),
            Text('Quota Limitada', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Text(
          'Solo tienes $available requests para $total ROMs.\n\n'
          'Las primeras $available serán identificadas por ScreenScraper.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continuar'),
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

  Future<void> _browseMameBinary() async {
    final XFile? file = await openFile(
      acceptedTypeGroups: [
        const XTypeGroup(
          label: 'Binarios/AppImages',
          extensions: ['appimage', 'bin', 'sh'],
        ),
      ],
    );
    if (file != null) {
      setState(() {
        _mameBinaryPath = file.path;
      });
      await ConfigManager.saveMameBinaryPath(file.path);
      _log("Ejecutable de MAME seleccionado: ${file.path}");
      if (_selectedPlatform?.platformId == 'mame') {
        _scanFolder();
      }
    }
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

      final List<InjectionItem> detected = [];
      if (_useOfflineId) {
        final romCache = RomCacheRepository();
        try {
          for (var file in filteredFiles) {
            final slug = p.basenameWithoutExtension(file.path);
            String displayName = slug;

            // Verificar si ya está en la caché local SQLite para cargar al instante
            final cached = romCache.shouldProcessRom(file.path);
            if (cached != null && cached.identifiedName != null) {
              displayName = cached.identifiedName!;
            }

            detected.add(
              InjectionItem(
                filePath: file.path,
                displayName: displayName,
              ),
            );
          }
        } finally {
          romCache.dispose();
        }
      } else {
        for (var file in filteredFiles) {
          final slug = p.basenameWithoutExtension(file.path);
          detected.add(
            InjectionItem(
              filePath: file.path,
              displayName: slug,
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
        _log("Resolviendo nombres de juegos usando base de datos local No-Intro/Redump/MAME...");
        final chunkSize = 50;
        int processedCount = 0;
        final List<String> unresolvedSlugs = [];

        // Asegurarnos de que el DAT esté listo (si es de GitHub se descarga y se guarda localmente)
        final datFile = await DatResolver.getDatFile(platformId);
        if (datFile == null) {
          _log("[  WARN ] No se pudo cargar la base de datos local para $platformId");
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
              _log("Buscando en base de datos local $platformId: lote ${i ~/ chunkSize + 1} de ${(filteredFiles.length / chunkSize).ceil()}...");
              
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
                      item.displayName = resolvedChunk[slug]!;
                    }
                  }
                });
              }
              
              processedCount += chunkToResolve.length;
              _log("Progreso offline: $processedCount / ${filteredFiles.length} juegos procesados.");
            }
          } finally {
            scanRomCache.dispose();
          }

          if (unresolvedSlugs.isNotEmpty && platformId != 'mame') {
            _log("[  WARN ] Base de datos local no pudo identificar ${unresolvedSlugs.length} juego(s): ${unresolvedSlugs.join(', ')}");
          }
        }
      }

      if (_useOfflineId && _selectedPlatform?.platformId == 'mame' && detected.isNotEmpty) {
        // Recolectamos únicamente los archivos que MAME.dat no pudo identificar (displayName igual al slug)
        final List<File> unresolvedMameFiles = [];
        for (var item in _previewItems) {
          final slug = p.basenameWithoutExtension(item.filePath);
          if (item.displayName == slug) {
            unresolvedMameFiles.add(File(item.filePath));
          }
        }

        if (unresolvedMameFiles.isNotEmpty) {
          _log("MAME.dat no identificó ${unresolvedMameFiles.length} juegos. Intentando resolución con binario MAME...");
          final romNames = unresolvedMameFiles.map((file) => p.basenameWithoutExtension(file.path)).toList();
          final chunkSize = 50;
          int processedCount = 0;
          final List<String> unresolvedSlugs = [];

          final scanRomCache = RomCacheRepository();
          try {
            for (var i = 0; i < romNames.length; i += chunkSize) {
              final chunk = romNames.skip(i).take(chunkSize).toList();
              _log("Resolviendo lote MAME fallback ${i ~/ chunkSize + 1} de ${(romNames.length / chunkSize).ceil()} (${chunk.length} ROMs)...");
              
              final resolvedChunk = await MameResolver.resolveNames(chunk);

              for (final slug in chunk) {
                if (!resolvedChunk.containsKey(slug)) {
                  unresolvedSlugs.add(slug);
                } else {
                  final resolvedName = resolvedChunk[slug]!;
                  final item = _previewItems.firstWhere((i) => p.basenameWithoutExtension(i.filePath) == slug);
                  final file = File(item.filePath);
                  if (file.existsSync()) {
                    final stat = file.statSync();
                    scanRomCache.cacheRomInfo(
                      filePath: file.path,
                      fileSize: stat.size,
                      lastModified: stat.modified,
                      identifiedName: resolvedName,
                      isIdentified: true,
                    );
                  }
                }
              }
              
              if (mounted) {
                setState(() {
                  for (var item in _previewItems) {
                    final slug = p.basenameWithoutExtension(item.filePath);
                    if (resolvedChunk.containsKey(slug)) {
                      item.displayName = resolvedChunk[slug]!;
                    }
                  }
                });
              }
              
              processedCount += chunk.length;
              _log("Progreso MAME fallback: $processedCount / ${romNames.length} juegos procesados.");
            }
          } finally {
            scanRomCache.dispose();
          }

          if (unresolvedSlugs.isNotEmpty) {
            _log("[  WARN ] MAME local (fallback) no pudo identificar ${unresolvedSlugs.length} juego(s): ${unresolvedSlugs.join(', ')}");
          }
        }
      }

      _log("${detected.length} juegos encontrados.");
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

  void _showConfigDialog() {
    _apiKeyController.text = _apiKey;
    _ssUserController.text = _ssUser;
    _ssPasswordController.text = _ssPassword;

    showDialog(
      context: context,
      builder: (context) {
        return DefaultTabController(
          length: 2,
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
                  const Text('CONFIGURACIÓN', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 16),
                  const TabBar(
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white24,
                    indicatorColor: Colors.white,
                    indicatorWeight: 2,
                    dividerColor: Colors.transparent,
                    labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    tabs: [
                      Tab(text: 'STEAMGRIDDB'),
                      Tab(text: 'SCREEN SCRAPER'),
                    ],
                  ),
                ],
              ),
            ),
            content: SizedBox(
              width: 400,
              height: 220,
              child: TabBarView(
                children: [
                  // Tab SteamGridDB
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('API KEY', style: TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _apiKeyController,
                          obscureText: true,
                          style: const TextStyle(fontSize: 13, color: Colors.white70),
                          decoration: InputDecoration(
                            hintText: 'Tu API Key...',
                            isDense: true,
                            filled: true,
                            fillColor: Colors.black,
                            prefixIcon: const Icon(Icons.vpn_key_outlined, size: 16, color: Colors.white24),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFF1A1A1A))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFF1A1A1A))),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Requerido para descargar carátulas, banners e iconos automáticamente.',
                          style: TextStyle(color: Colors.white24, fontSize: 11),
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
                        const Text('USUARIO', style: TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _ssUserController,
                          style: const TextStyle(fontSize: 13, color: Colors.white70),
                          decoration: InputDecoration(
                            hintText: 'Usuario...',
                            isDense: true,
                            filled: true,
                            fillColor: Colors.black,
                            prefixIcon: const Icon(Icons.person_outline, size: 16, color: Colors.white24),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFF1A1A1A))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFF1A1A1A))),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text('CONTRASEÑA', style: TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _ssPasswordController,
                          obscureText: true,
                          style: const TextStyle(fontSize: 13, color: Colors.white70),
                          decoration: InputDecoration(
                            hintText: 'Contraseña...',
                            isDense: true,
                            filled: true,
                            fillColor: Colors.black,
                            prefixIcon: const Icon(Icons.lock_outline, size: 16, color: Colors.white24),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFF1A1A1A))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFF1A1A1A))),
                          ),
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
                child: const Text('CANCELAR', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
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
                  });
                  await ConfigManager.saveApiKey(newKey);
                  await ConfigManager.saveSSCredentials(newUser, newPass);
                  if (context.mounted) Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: const Text('GUARDAR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _startProcess(String action) async {
    if (_isProcessing) return;
    if (_lutrisPaths == null) {
      _log("Rutas de Lutris no detectadas.");
      return;
    }
    if (_selectedPlatform == null || _selectedEmulator == null) {
      _log("Selecciona plataforma y emulador.");
      return;
    }
    if ((action == 'inject' || action == 'full') && _romFolder.isEmpty) {
      _log("Selecciona una carpeta de ROMs.");
      return;
    }
    if ((action == 'inject' || action == 'full') && _selectedExtensions.isEmpty) {
      _log("Selecciona al menos una extensión.");
      return;
    }
    if ((action == 'metadata' || action == 'full') && _apiKey.isEmpty) {
      _log("Configura la API Key de SteamGridDB.");
      _showConfigDialog();
      return;
    }

    if (_useHighPrecision && (action == 'inject' || action == 'full')) {
      final selectedCount = _previewItems.where((i) => i.isSelected).length;
      if (_ssUser.isEmpty || _ssPassword.isEmpty) {
        _log("Alta Precisión requiere credenciales de ScreenScraper.");
        _showConfigDialog();
        return;
      }

      _log("Verificando quota...");
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
        final Map<String, String> customNames = {
          for (var item in _previewItems.where((i) => i.isSelected && (i.wasManuallyEdited || _selectedPlatform?.platformId == 'mame' || DatResolver.isPlatformSupported(_selectedPlatform!.platformId))))
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
          customFiles: selectedFiles.isNotEmpty ? selectedFiles : null,
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
            const Text(
              'v2.9.10',
              style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const Text(
              'Universal game companion for linking ROMs and managing media.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            const Text(
              'Software libre desarrollado como complemento para otros lanzadores y gestión de librerías.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white24, fontSize: 10, height: 1.4),
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
            child: const Text('CERRAR', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
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
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined, size: 16, color: Colors.white70),
                    SizedBox(width: 12),
                    Text('Configuración', style: TextStyle(fontSize: 13, color: Colors.white70)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'about',
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.white70),
                    SizedBox(width: 12),
                    Text('Acerca de', style: TextStyle(fontSize: 13, color: Colors.white70)),
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
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.flash_on, size: 20), label: 'Inyector'),
          NavigationDestination(icon: Icon(Icons.grid_view, size: 20), label: 'Gestor Visual'),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return _currentIndex == 0 ? _buildInjectorView() : _buildVisualManagerView();
  }

  Widget _buildLutrisSelector() {
    final currentMode = _lutrisPaths != null ? _lutrisPaths!['mode']! : "No detectado";
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
    return _lutrisPaths == null ? const Center(child: Text("Lutris no detectado.")) : VisualManagerScreen(
      lutrisPaths: _lutrisPaths!,
      apiKey: _apiKey,
      onShowConfig: _showConfigDialog,
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
        _buildStepHeader('01', 'SISTEMA'),
        const SizedBox(height: 16),
        Text('PLATAFORMA', style: labelStyle),
        const SizedBox(height: 10),
        DropdownButtonFormField<PlatformInfo>(
          value: _selectedPlatform,
          items: platforms.map((p) => DropdownMenuItem(value: p, child: Text(p.platformName, style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: _isProcessing ? null : _onPlatformChanged,
          decoration: _inputDecoration(),
        ),
        if (_selectedPlatform != null && _selectedPlatform!.emulators.length > 1) ...[
          const SizedBox(height: 20),
          Text('EMULADOR', style: labelStyle),
          const SizedBox(height: 10),
          DropdownButtonFormField<EmulatorInfo>(
            value: _selectedEmulator,
            items: _selectedPlatform!.emulators.map((e) => DropdownMenuItem(value: e, child: Text(e.name, style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: _isProcessing ? null : _onEmulatorChanged,
            decoration: _inputDecoration(),
          ),
        ],

        if (_selectedPlatform?.platformId == 'mame') ...[
          const SizedBox(height: 20),
          Text('EJECUTABLE DE MAME', style: labelStyle),
          const SizedBox(height: 10),
          InkWell(
            onTap: _isProcessing ? null : _browseMameBinary,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                border: Border.all(color: const Color(0xFF1A1A1A)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _mameBinaryPath.isEmpty
                          ? 'Auto-detectar o seleccionar binario...'
                          : _mameBinaryPath,
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.file_open, size: 16, color: Colors.white38),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 32),
        const Divider(color: Colors.white10),
        const SizedBox(height: 32),

        // STEP 02
        _buildStepHeader('02', 'ORIGEN'),
        const SizedBox(height: 16),
        Text('CARPETA DE ROMS', style: labelStyle),
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
                      Expanded(child: Text(_romFolder.isEmpty ? 'Seleccionar...' : _romFolder, style: const TextStyle(fontSize: 12, color: Colors.white70), overflow: TextOverflow.ellipsis)),
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
                tooltip: 'Actualizar carpeta',
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
          Text('EXTENSIONES', style: labelStyle),
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
        _buildStepHeader('03', 'PREFERENCIAS'),
        const SizedBox(height: 16),
        _buildCompactCheckbox('Limpiar juegos previos', _cleanOldGames, (val) => setState(() => _cleanOldGames = val ?? false)),
        _buildCompactCheckbox('Autodetectar nombres (offline)', _useOfflineId, (val) {
          setState(() => _useOfflineId = val ?? false);
          _scanFolder();
        }),
        _buildCompactCheckbox('Alta Precisión (Hash)', _useHighPrecision, (val) => setState(() => _useHighPrecision = val ?? false)),
        _buildCompactCheckbox('Escaneo recursivo', _isRecursive, (val) {
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
                  canProcess ? '$selectedCount JUEGOS LISTOS' : 'ESPERANDO SELECCIÓN',
                  style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Inyectar en Lutris + Descargar Metadatos',
                  style: TextStyle(color: Colors.white24, fontSize: 10),
                ),
              ],
            ),
          ],
          const Spacer(),
          // Botón de opciones avanzadas
          if (canProcess)
            PopupMenuButton<String>(
              tooltip: 'Opciones avanzadas',
              icon: const Icon(Icons.tune, color: Colors.white38, size: 20),
              offset: const Offset(0, -100),
              color: const Color(0xFF0A0A0A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: const BorderSide(color: Color(0xFF1A1A1A)),
              ),
              onSelected: _startProcess,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'inject',
                  child: Row(
                    children: [
                      Icon(Icons.add, size: 16, color: Colors.white70),
                      SizedBox(width: 12),
                      Text('Solo Inyectar ROMs', style: TextStyle(fontSize: 12, color: Colors.white70)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'metadata',
                  child: Row(
                    children: [
                      Icon(Icons.download_outlined, size: 16, color: Colors.white70),
                      SizedBox(width: 12),
                      Text('Solo Descargar Metadatos', style: TextStyle(fontSize: 12, color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
          const SizedBox(width: 16),
          // Botón Principal
          _buildActionButton(
            _isProcessing ? 'PROCESANDO...' : 'EJECUTAR PROCESO', 
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
            const Text('DETECTADOS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.white38)),
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
                title: Text(item.displayName, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                trailing: IconButton(icon: const Icon(Icons.edit_outlined, size: 14, color: Colors.white24), onPressed: () => _editItemName(item)),
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
            Text(_logText.isEmpty ? '> Ready.' : _logText, style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Color(0xFF888888), height: 1.5)),
          ])),
        ],
      ),
    );
  }
}
