import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import '../core/lutris/games_repository.dart';
import '../core/lutris/lutris_paths.dart';
import '../core/lutris/rom_cache_repository.dart';
import '../core/steam/steam_detector.dart';
import '../core/steam/steam_export_service.dart';
import 'steam_dependencies_dialog.dart';
import 'steamgriddb_visual_selector.dart';

/// Pantalla de detalle del juego que muestra información completa
/// antes de permitir editar metadata visual
class GameDetailScreen extends StatefulWidget {
  final Game game;
  final Map<String, String?> lutrisPaths;
  final String apiKey;
  final VoidCallback onGameUpdated;

  const GameDetailScreen({
    super.key,
    required this.game,
    required this.lutrisPaths,
    required this.apiKey,
    required this.onGameUpdated,
  });

  @override
  State<GameDetailScreen> createState() => _GameDetailScreenState();

  /// Método estático para mostrar la pantalla como modal
  static Future<void> show(
    BuildContext context,
    Game game,
    Map<String, String?> lutrisPaths,
    String apiKey,
    VoidCallback onGameUpdated,
  ) {
    return showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: GameDetailScreen(
          game: game,
          lutrisPaths: lutrisPaths,
          apiKey: apiKey,
          onGameUpdated: onGameUpdated,
        ),
      ),
    );
  }
}

class _GameDetailScreenState extends State<GameDetailScreen> {
  final RomCacheRepository _romCache = RomCacheRepository();
  final SteamExportService _steamExportService = SteamExportService();
  late final GamesRepository _gamesRepository;
  late final LutrisPaths _lutrisPaths;
  RomCacheEntry? _screenScraperInfo;
  bool _isLoading = true;
  bool _isSteamAvailable = false;
  int _imageVersion = 0;
  late String _currentGameName;

  @override
  void initState() {
    super.initState();
    _lutrisPaths = LutrisPaths.fromMap(widget.lutrisPaths);
    _gamesRepository = GamesRepository(_lutrisPaths.dbPath);
    _currentGameName = widget.game.name;
    _initSteamAvailability();
    _loadScreenScraperInfo();
  }

  Future<void> _initSteamAvailability() async {
    final available = await _detectSteamAvailability();
    if (!mounted) return;
    setState(() {
      _isSteamAvailable = available;
    });
  }

  Future<bool> _detectSteamAvailability() async {
    final detector = SteamDetector();
    final steamPathsOk =
        detector.shortcutsPath() != null && detector.gridPath() != null;
    if (!steamPathsOk) return false;

    return _steamExportService.canExportToSteam();
  }

  @override
  void dispose() {
    _romCache.dispose();
    super.dispose();
  }

  Future<void> _loadScreenScraperInfo() async {
    setState(() => _isLoading = true);

    try {
      // Buscar información de ScreenScraper en el cache por nombre del juego
      final screenScraperInfo = _romCache.findByGameName(_currentGameName);

      setState(() {
        _isLoading = false;
        _screenScraperInfo = screenScraperInfo;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // Rutas de las imágenes del juego
  String get _coverPath => _lutrisPaths.coverPath(widget.game.slug);

  String get _bannerPath => _lutrisPaths.bannerPath(widget.game.slug);

  String get _iconPath => _lutrisPaths.lutrisIconPath(widget.game.slug);

  // Obtener la ruta del ROM desde el configPath
  String? get _romPath {
    try {
      final configFile = File(_resolveConfigFilePath(widget.game.configPath));
      if (configFile.existsSync()) {
        final content = configFile.readAsStringSync();
        final lines = content.split('\n');
        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.startsWith('main_file:') ||
              trimmed.startsWith('path:') ||
              trimmed.startsWith('rom:')) {
            var value = trimmed.split(':').skip(1).join(':').trim();
            if ((value.startsWith('"') && value.endsWith('"')) ||
                (value.startsWith("'") && value.endsWith("'"))) {
              value = value.substring(1, value.length - 1);
            }
            if (value.isNotEmpty) return value;
          }
        }
      }
    } catch (e) {
      // Ignorar errores de lectura
    }
    return null;
  }

  String _resolveConfigFilePath(String configPath) {
    return _lutrisPaths.resolveConfigPath(configPath);
  }

  String? get _romFileName {
    final fullPath = _romPath;
    if (fullPath == null || fullPath.isEmpty) return null;
    return p.basename(fullPath);
  }

  String? get _romExtension {
    final fileName = _romFileName;
    if (fileName == null || fileName.isEmpty) return null;
    final ext = p.extension(fileName);
    if (ext.isEmpty) return null;
    return ext;
  }

  String? get _romDirectory {
    final fullPath = _romPath;
    if (fullPath == null || fullPath.isEmpty) return null;
    return p.dirname(fullPath);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final maxWidth = size.width > 1320 ? 1240.0 : size.width * 0.97;
    final maxHeight = size.height > 980 ? 920.0 : size.height * 0.97;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          minWidth: 320,
          minHeight: 480,
        ),
        child: Material(
          color: Colors.black,
          borderRadius: BorderRadius.circular(4),
          clipBehavior: Clip.antiAlias,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _isLoading
                      ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white24)))
                      : _buildBody(),
                ),
                _buildFooterActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final identified = _screenScraperInfo?.isIdentified == true;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
      decoration: const BoxDecoration(
        color: Color(0xFF020202),
        border: Border(
          bottom: BorderSide(color: Color(0xFF1A1A1A)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DETALLE DEL JUEGO',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _currentGameName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildMinimalChip(
                      widget.game.platform.toUpperCase(),
                      Colors.white,
                    ),
                    _buildMinimalChip(
                      identified ? 'SCREEN SCRAPER OK' : 'SIN IDENTIFICAR',
                      identified ? Colors.white70 : Colors.white24,
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white38, size: 24),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF1A1A1A)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 980;

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: isDesktop ? 7 : 5,
                child: _buildMediaPanel(compact: !isDesktop),
              ),
              const SizedBox(width: 24),
              Expanded(flex: 3, child: _buildInfoPanel()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMediaPanel({required bool compact}) {
    final hasScraperMedia =
        _screenScraperInfo != null &&
        (_screenScraperInfo!.coverUrl != null ||
            _screenScraperInfo!.bannerUrl != null ||
            _screenScraperInfo!.cover3dUrl != null ||
            _screenScraperInfo!.logoUrl != null);
    final tabCount = hasScraperMedia ? 2 : 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('MEDIA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.white38)),
        const SizedBox(height: 16),
        Expanded(
          child: DefaultTabController(
            length: tabCount,
            child: Column(
              children: [
                TabBar(
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white24,
                  indicatorColor: Colors.white,
                  indicatorWeight: 2,
                  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  tabs: [
                    const Tab(text: 'ACTUAL'),
                    if (hasScraperMedia) const Tab(text: 'SCREEN SCRAPER'),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildCurrentMediaContent(compact),
                      if (hasScraperMedia) _buildScreenScraperInfo(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentMediaContent(bool compact) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _buildMediaItem(
                  'COVER',
                  _coverPath,
                  Icons.photo_library_outlined,
                  mediaType: 'cover',
                  aspectRatio: 0.7,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMediaItem(
                      'BANNER',
                      _bannerPath,
                      Icons.panorama_horizontal_outlined,
                      mediaType: 'banner',
                      aspectRatio: 2.8,
                    ),
                    const SizedBox(height: 20),
                    _buildMediaItem(
                      'ICONO',
                      _iconPath,
                      Icons.apps_outlined,
                      mediaType: 'icon',
                      aspectRatio: 1.0,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatusChip('COVER', File(_coverPath).existsSync()),
              _buildStatusChip('BANNER', File(_bannerPath).existsSync()),
              _buildStatusChip('ICONO', File(_iconPath).existsSync() || File(_lutrisPaths.systemIconPath(widget.game.slug)).existsSync()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, bool ok) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ok ? Colors.white.withOpacity(0.05) : Colors.transparent,
        border: Border.all(color: ok ? Colors.white10 : const Color(0xFF1A1A1A)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 6, color: ok ? Colors.white38 : Colors.white10),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: ok ? Colors.white70 : Colors.white24, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('INFORMACIÓN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.white38)),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoSection(
                  title: 'GESTIÓN',
                  children: [_buildEditActions()],
                ),
                const SizedBox(height: 24),
                _buildInfoSection(
                  title: 'SISTEMA',
                  children: [
                    if (_romFileName != null) _buildMinimalInfoRow('ARCHIVO', _romFileName!),
                    _buildMinimalInfoRow('SLUG', widget.game.slug),
                    _buildMinimalInfoRow('ID', widget.game.id.toString()),
                    if (_romPath != null) ...[
                      const SizedBox(height: 12),
                      _buildRomPathBlock(_romPath!),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
                _buildInfoSection(
                  title: 'DATOS',
                  children: [
                    if (_screenScraperInfo?.developer != null) _buildMinimalInfoRow('DEV', _screenScraperInfo!.developer!),
                    if (_screenScraperInfo?.releaseDate != null) _buildMinimalInfoRow('FECHA', _screenScraperInfo!.releaseDate!),
                  ],
                ),
                if (_screenScraperInfo?.synopsis != null && _screenScraperInfo!.synopsis!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildInfoSection(
                    title: 'SINOPSIS',
                    children: [
                      Text(
                        _screenScraperInfo!.synopsis!,
                        style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.6),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildMinimalInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.w500))),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildEditActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildActionHighlightButton(Icons.manage_search, 'CORREGIR METADATOS', _correctGame),
        const SizedBox(height: 12),
        _buildActionHighlightButton(
          Icons.sports_esports_outlined, 
          'EXPORTAR A STEAM', 
          _isSteamAvailable ? _exportToSteam : () => SteamDependenciesDialog.show(context), 
          isDisabled: !_isSteamAvailable
        ),
      ],
    );
  }

  Widget _buildActionHighlightButton(IconData icon, String label, VoidCallback onTap, {bool isDisabled = false}) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: isDisabled ? null : onTap,
        style: TextButton.styleFrom(
          backgroundColor: isDisabled ? Colors.transparent : Colors.white,
          foregroundColor: isDisabled ? Colors.white10 : Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: isDisabled ? const BorderSide(color: Color(0xFF1A1A1A)) : BorderSide.none,
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.centerLeft,
        ),
        icon: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Icon(icon, size: 16),
        ),
        label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
      ),
    );
  }

  Widget _buildRomPathBlock(String fullPath) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF080808),
        border: Border.all(color: const Color(0xFF1A1A1A)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('RUTA ROM', style: TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.bold)),
              const Spacer(),
              InkWell(
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: fullPath));
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copiado.')));
                },
                child: const Text('COPIAR', style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(fullPath, style: const TextStyle(color: Colors.white38, fontSize: 11, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildMediaItem(
    String label,
    String path,
    IconData fallbackIcon, {
    required String mediaType,
    double aspectRatio = 1.0,
  }) {
    final systemPath = _lutrisPaths.systemIconPath(widget.game.slug);
    final finalPath = (mediaType == 'icon' && !File(path).existsSync() && File(systemPath).existsSync()) ? systemPath : path;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: aspectRatio,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF1A1A1A)),
              color: const Color(0xFF050505),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  File(finalPath).existsSync()
                      ? Image.file(
                          File(finalPath),
                          key: ValueKey('$finalPath-$_imageVersion'),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(fallbackIcon),
                        )
                      : _buildPlaceholderImage(fallbackIcon),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: InkWell(
                      onTap: () => _openVisualSelectorForType(mediaType),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.edit_outlined, color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderImage(IconData icon) {
    return Center(child: Icon(icon, color: Colors.white.withOpacity(0.02), size: 32));
  }

  Widget _buildScreenScraperInfo() {
    if (_screenScraperInfo == null) return const SizedBox.shrink();
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (_screenScraperInfo!.coverUrl != null)
                Expanded(child: _buildScreenScraperImagePreview('COVER', _screenScraperInfo!.coverUrl!)),
              if (_screenScraperInfo!.coverUrl != null && _screenScraperInfo!.bannerUrl != null) const SizedBox(width: 16),
              if (_screenScraperInfo!.bannerUrl != null)
                Expanded(child: _buildScreenScraperImagePreview('BANNER', _screenScraperInfo!.bannerUrl!)),
            ],
          ),
          const SizedBox(height: 24),
          const Text('ENLACES EXTERNOS', style: TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (_screenScraperInfo!.coverUrl != null) _buildMediaUrlRow('Cover (2D)', _screenScraperInfo!.coverUrl!),
          if (_screenScraperInfo!.cover3dUrl != null) _buildMediaUrlRow('Cover (3D)', _screenScraperInfo!.cover3dUrl!),
          if (_screenScraperInfo!.bannerUrl != null) _buildMediaUrlRow('Banner', _screenScraperInfo!.bannerUrl!),
          if (_screenScraperInfo!.logoUrl != null) _buildMediaUrlRow('Logo', _screenScraperInfo!.logoUrl!),
        ],
      ),
    );
  }

  Widget _buildScreenScraperImagePreview(String label, String imageUrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _showImagePreview(imageUrl, label),
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF1A1A1A)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(imageUrl, fit: BoxFit.cover),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaUrlRow(String type, String url) {
    return InkWell(
      onTap: () => _showImagePreview(url, type),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            const Icon(Icons.link, size: 14, color: Colors.white24),
            const SizedBox(width: 10),
            Expanded(child: Text(type, style: const TextStyle(color: Colors.white70, fontSize: 12, decoration: TextDecoration.underline))),
          ],
        ),
      ),
    );
  }

  void _showImagePreview(String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white38), onPressed: () => Navigator.of(context).pop()),
                ],
              ),
            ),
            Flexible(child: Image.network(imageUrl, fit: BoxFit.contain)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF020202),
        border: Border(top: BorderSide(color: Color(0xFF1A1A1A))),
      ),
      child: Row(
        children: [
          const Expanded(child: Text('USAR ICONOS DE EDICIÓN PARA CAMBIAR CADA ELEMENTO.', style: TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5))),
          const SizedBox(width: 20),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CERRAR', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _openVisualSelectorForType(String mediaType) {
    _openVisualSelectorInternal(initialMediaType: mediaType);
  }

  Future<void> _openVisualSelectorInternal({String? initialMediaType}) async {
    final changed = await SteamGridDBVisualSelector.show(
      context,
      widget.game,
      widget.lutrisPaths,
      widget.apiKey,
      widget.onGameUpdated,
      initialMediaType: initialMediaType,
      initialQuery: _currentGameName,
    );

    if (!mounted) return;

    if (changed) {
      await _loadScreenScraperInfo();
      if (!mounted) return;
      setState(() {
        _imageVersion++;
      });
      widget.onGameUpdated();
    }
  }

  Future<void> _correctGame() async {
    final controller = TextEditingController(text: _currentGameName);

    final query = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Corregir juego en SteamGridDB'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Texto de busqueda',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Buscar'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;
    if (query == null || query.isEmpty) return;

    String? pendingNameFromMatch;

    final changed = await SteamGridDBVisualSelector.show(
      context,
      widget.game,
      widget.lutrisPaths,
      widget.apiKey,
      widget.onGameUpdated,
      initialQuery: query,
      autoSelectFirstResult: false,
      onGameMatched: (matchedName) {
        pendingNameFromMatch = matchedName;
      },
    );

    if (!mounted) return;

    if (changed &&
        pendingNameFromMatch != null &&
        pendingNameFromMatch!.isNotEmpty &&
        pendingNameFromMatch != _currentGameName) {
      _gamesRepository.updateGameName(widget.game.id, pendingNameFromMatch!);
      setState(() {
        _currentGameName = pendingNameFromMatch!;
      });
      widget.onGameUpdated();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Nombre corregido a "$pendingNameFromMatch".'),
        ),
      );
    }

    if (changed) {
      await _loadScreenScraperInfo();
      if (!mounted) return;
      setState(() {
        _imageVersion++;
      });
      widget.onGameUpdated();
    }
  }

  Future<void> _exportToSteam() async {
    final gameToExport = Game(
      id: widget.game.id,
      slug: widget.game.slug,
      name: _currentGameName,
      platform: widget.game.platform,
      configPath: widget.game.configPath,
      hasCover: widget.game.hasCover,
      hasBanner: widget.game.hasBanner,
      hasIcon: widget.game.hasIcon,
    );

    final result = await _steamExportService.exportGame(
      gameToExport,
      widget.lutrisPaths,
    );
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(result.success ? Icons.check_circle_outline : Icons.error_outline, 
                 size: 18, color: Colors.white70),
            const SizedBox(width: 12),
            Expanded(child: Text(result.message)),
          ],
        ),
      ),
    );
  }
}
