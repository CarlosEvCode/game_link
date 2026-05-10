import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import '../platforms/platform_registry.dart';
import '../core/lutris/lutris_detector.dart';
import '../core/injector/rom_injector.dart';
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

  List<InjectionItem> _previewItems = [];
  bool _isScanning = false;
  bool _cleanOldGames = true;
  bool _useHighPrecision = false;
  bool _reuseIdentification = true;
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
            matchingFiles.add(entity);
          }
        }
      }

      final filteredFiles = RomInjector.filterDuplicatesByPriority(
        matchingFiles,
        _selectedEmulator!,
        (msg, [progress]) => _log(msg),
      );

      final List<InjectionItem> detected = [];
      for (var file in filteredFiles) {
        detected.add(
          InjectionItem(
            filePath: file.path,
            displayName: p.basenameWithoutExtension(file.path),
          ),
        );
      }

      setState(() {
        _previewItems = detected;
      });
      _log("${detected.length} juegos encontrados.");
    } catch (e) {
      _log("Error: $e");
    } finally {
      setState(() {
        _isScanning = false;
      });
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
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.settings, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text('Configuración', style: TextStyle(fontSize: 16)),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SteamGridDB API Key:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _apiKeyController,
                    obscureText: true,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'API Key...',
                      isDense: true,
                      prefixIcon: const Icon(Icons.vpn_key, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('ScreenScraper:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _ssUserController,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Usuario',
                      isDense: true,
                      prefixIcon: const Icon(Icons.person, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _ssPasswordController,
                    obscureText: true,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Contraseña',
                      isDense: true,
                      prefixIcon: const Icon(Icons.lock, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
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
              child: const Text('Guardar'),
            ),
          ],
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
          for (var item in _previewItems.where((i) => i.isSelected && i.wasManuallyEdited))
            item.filePath: item.displayName,
        };

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
          customFiles: selectedFiles.isNotEmpty ? selectedFiles : null,
          customNames: customNames,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Link', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        toolbarHeight: 48,
        actions: [
          _buildLutrisSelector(),
          IconButton(
            icon: const Icon(Icons.settings, size: 20),
            onPressed: _showConfigDialog,
            tooltip: 'Configuración',
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
    final labelStyle = TextStyle(color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.w500, fontSize: 11, letterSpacing: 0.5);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PLATAFORMA', style: labelStyle),
        const SizedBox(height: 10),
        DropdownButtonFormField<PlatformInfo>(
          value: _selectedPlatform,
          items: platforms.map((p) => DropdownMenuItem(value: p, child: Text(p.platformName, style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: _isProcessing ? null : _onPlatformChanged,
          decoration: InputDecoration(
            isDense: true, 
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            filled: true,
            fillColor: const Color(0xFF0A0A0A),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFF1A1A1A))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFF1A1A1A))),
          ),
        ),
        if (_selectedPlatform != null && _selectedPlatform!.emulators.length > 1) ...[
          const SizedBox(height: 20),
          Text('EMULADOR', style: labelStyle),
          const SizedBox(height: 10),
          DropdownButtonFormField<EmulatorInfo>(
            value: _selectedEmulator,
            items: _selectedPlatform!.emulators.map((e) => DropdownMenuItem(value: e, child: Text(e.name, style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: _isProcessing ? null : _onEmulatorChanged,
            decoration: InputDecoration(
              isDense: true, 
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              filled: true,
              fillColor: const Color(0xFF0A0A0A),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFF1A1A1A))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFF1A1A1A))),
            ),
          ),
        ],
        const SizedBox(height: 20),
        Text('CARPETA DE ROMS', style: labelStyle),
        const SizedBox(height: 10),
        InkWell(
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
        const SizedBox(height: 20),
        Text('OPCIONES', style: labelStyle),
        const SizedBox(height: 8),
        _buildCompactCheckbox('Limpiar juegos', _cleanOldGames, (val) => setState(() => _cleanOldGames = val ?? false)),
        _buildCompactCheckbox('Alta Precisión', _useHighPrecision, (val) => setState(() => _useHighPrecision = val ?? false)),
        _buildCompactCheckbox('Escaneo recursivo', _isRecursive, (val) {
          setState(() => _isRecursive = val ?? false);
          _scanFolder();
        }),
      ],
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

  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.black,
      child: Row(
        children: [
          _buildActionButton('Inyectar', Icons.add, () => _startProcess('inject'), isPrimary: false),
          const SizedBox(width: 12),
          _buildActionButton('Metadatos', Icons.download_outlined, () => _startProcess('metadata'), isPrimary: false),
          const Spacer(),
          _buildActionButton(_isProcessing ? 'Procesando...' : 'Ejecutar Todo', Icons.play_arrow_rounded, () => _startProcess('full'), isPrimary: true),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onPressed, {required bool isPrimary}) {
    return TextButton.icon(
      onPressed: _isProcessing ? null : onPressed,
      style: TextButton.styleFrom(
        backgroundColor: isPrimary ? Colors.white : Colors.transparent,
        foregroundColor: isPrimary ? Colors.black : Colors.white70,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: isPrimary ? BorderSide.none : const BorderSide(color: Color(0xFF1A1A1A)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
