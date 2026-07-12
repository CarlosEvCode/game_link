import 'dart:io';

import 'package:flutter/material.dart';

import '../core/lutris/games_repository.dart';
import '../core/lutris/lutris_paths.dart';
import '../core/steam/steam_detector.dart';
import '../core/steam/steam_export_service.dart';
import '../platforms/platform_registry.dart';
import 'game_detail_screen.dart';
import 'steam_dependencies_dialog.dart';

class VisualManagerScreen extends StatefulWidget {
  final Map<String, String?> lutrisPaths;
  final String apiKey;
  final VoidCallback? onShowConfig;
  final String? initialPlatformId;

  const VisualManagerScreen({
    super.key,
    required this.lutrisPaths,
    required this.apiKey,
    this.onShowConfig,
    this.initialPlatformId,
  });

  @override
  State<VisualManagerScreen> createState() => _VisualManagerScreenState();
}

class _VisualManagerScreenState extends State<VisualManagerScreen> {
  late GamesRepository _repo;
  late LutrisPaths _lutrisPaths;
  final SteamExportService _steamExportService = SteamExportService();
  List<PlatformInfo> _platforms = [];
  PlatformInfo? _selectedPlatform;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<Game> _games = [];
  bool _isLoading = false;
  bool _isSteamAvailable = false;
  bool _isGridView = true;
  bool _selectionMode = false;

  int _page = 0;
  final int _limit = 24;
  int _totalGames = 0;
  int _totalPages = 1;
  String _searchQuery = '';
  String _filterMode = 'all';
  int _imageVersion = 0;

  GameMediaStats _stats = const GameMediaStats(
    total: 0,
    missingCover: 0,
    missingBanner: 0,
    missingIcon: 0,
  );

  final Set<int> _selectedGameIds = {};

  @override
  void initState() {
    super.initState();
    _lutrisPaths = LutrisPaths.fromMap(widget.lutrisPaths);
    _repo = GamesRepository(_lutrisPaths.dbPath);
    _initSteamAvailability();
    _loadPlatforms();
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
  void didUpdateWidget(covariant VisualManagerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lutrisPaths['db_path'] != widget.lutrisPaths['db_path']) {
      _lutrisPaths = LutrisPaths.fromMap(widget.lutrisPaths);
      _repo = GamesRepository(_lutrisPaths.dbPath);
      _imageVersion++;
      _refreshList();
    }

    if (oldWidget.initialPlatformId != widget.initialPlatformId &&
        widget.initialPlatformId != null) {
      final target = _platforms
          .where((p) => p.platformId == widget.initialPlatformId)
          .firstOrNull;
      if (target != null &&
          target.platformId != _selectedPlatform?.platformId) {
        setState(() {
          _selectedPlatform = target;
          _games = [];
          _page = 0;
          _selectedGameIds.clear();
        });
        _refreshList();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPlatforms() async {
    final platforms = PlatformRegistry.getAllPlatforms();
    setState(() => _platforms = platforms);
    if (platforms.isNotEmpty) {
      final preferred = platforms
          .where((p) => p.platformId == widget.initialPlatformId)
          .firstOrNull;
      setState(() => _selectedPlatform = preferred ?? platforms.first);
      _refreshList();
    }
  }

  List<String> get _selectedRunners => 
      _selectedPlatform?.emulators.map((e) => e.runner).toList() ?? [];

  Future<void> _refreshList() async {
    if (_selectedPlatform == null) return;
    if (!_selectionMode) _selectedGameIds.clear();

    await _syncMetadata();

    final total = _repo.getGamesCountByRunners(
      _selectedRunners,
      platform: _selectedPlatform?.platformName,
      searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      filterMode: _filterMode != 'all' ? _filterMode : null,
    );

    setState(() {
      _page = 0;
      _totalGames = total;
      _totalPages = (total / _limit).ceil();
      if (_totalPages < 1) _totalPages = 1;
      _games = [];
      _stats = _repo.getMediaStatsByRunners(
        _selectedRunners,
        platform: _selectedPlatform?.platformName,
        searchQuery: _searchQuery,
      );
    });

    _loadPageGames();
  }

  Future<void> _syncMetadata() async {
    if (_selectedPlatform == null) return;
    await Future.microtask(() {
      _repo.syncMetadataWithDiskByRunners(
        runners: _selectedRunners,
        platform: _selectedPlatform?.platformName,
        coversDir: _lutrisPaths.coversDir,
        bannersDir: _lutrisPaths.bannersDir,
        iconsDir: _lutrisPaths.systemIconsDir,
        lutrisIconsDir: _lutrisPaths.lutrisIconsDir,
      );
    });
  }

  Future<void> _loadPageGames() async {
    if (_selectedPlatform == null || _isLoading) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 80));

    final offset = _page * _limit;
    final fetchedGames = _repo.getGamesByRunners(
      _selectedRunners,
      platform: _selectedPlatform?.platformName,
      limit: _limit,
      offset: offset,
      filterMode: _filterMode != 'all' ? _filterMode : null,
      searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
    );

    setState(() {
      _isLoading = false;
      _games = fetchedGames;
    });
  }

  void _toggleSelectionMode() {
    setState(() {
      _selectionMode = !_selectionMode;
      if (!_selectionMode) {
        _selectedGameIds.clear();
      }
    });
  }

  void _toggleGameSelection(Game game) {
    if (!_selectionMode) return;
    setState(() {
      if (_selectedGameIds.contains(game.id)) {
        _selectedGameIds.remove(game.id);
      } else {
        _selectedGameIds.add(game.id);
      }
    });
  }

  bool _isGameSelected(Game game) => _selectedGameIds.contains(game.id);

  Future<void> _deleteSelectedGames() async {
    if (_selectedGameIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F0F0F),
        title: const Text('¿Eliminar juegos seleccionados?', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text(
          '¿Estás seguro de que deseas eliminar ${_selectedGameIds.length} juego(s) de la biblioteca de Lutris?\nEsto borrará permanentemente sus registros de base de datos, archivos de configuración (.yml) y archivos multimedia.',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white30, fontSize: 12)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[800], foregroundColor: Colors.white),
            child: const Text('Eliminar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final selectedIds = _selectedGameIds.toList();
      final games = _repo.getGamesByIds(selectedIds);

      // 1. Borrar archivos asociados a cada juego
      for (final game in games) {
        if (game.configPath.isNotEmpty) {
          final configFile = File(_lutrisPaths.resolveConfigPath(game.configPath));
          if (configFile.existsSync()) {
            configFile.deleteSync();
          }
        }

        final cover = File(_lutrisPaths.coverPath(game.slug));
        if (cover.existsSync()) cover.deleteSync();

        final banner = File(_lutrisPaths.bannerPath(game.slug));
        if (banner.existsSync()) banner.deleteSync();

        final lutrisIcon = File(_lutrisPaths.lutrisIconPath(game.slug));
        if (lutrisIcon.existsSync()) lutrisIcon.deleteSync();

        final systemIcon = File(_lutrisPaths.systemIconPath(game.slug));
        if (systemIcon.existsSync()) systemIcon.deleteSync();
      }

      // 2. Eliminar registros en base de datos
      _repo.deleteGames(selectedIds);

      _selectedGameIds.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Juegos eliminados con éxito de la biblioteca'),
            backgroundColor: Color(0xFF0F0F0F),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar juegos: $e'),
            backgroundColor: Colors.red[900],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _refreshList();
      }
    }
  }

  Future<void> _confirmAndExportToSteam({required bool selectedOnly}) async {
    if (_selectedPlatform == null) return;

    final selectedGames = _games
        .where((g) => _selectedGameIds.contains(g.id))
        .toList();
    final allPlatformGames = _repo.getGamesByRunners(
      _selectedRunners,
      platform: _selectedPlatform?.platformName,
    );
    final targetGames = selectedOnly ? selectedGames : allPlatformGames;

    if (targetGames.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay juegos para exportar.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exportar a Steam'),
        content: Text(
          selectedOnly
              ? 'Se exportaran ${targetGames.length} juegos seleccionados a Steam.\n\nSe crearan/actualizaran shortcuts, artwork y colecciones por plataforma.'
              : 'Se sincronizaran ${targetGames.length} juegos de ${_selectedPlatform!.platformName} con Steam.\n\nSe crearan/actualizaran shortcuts, artwork y colecciones por plataforma, y se eliminaran en Steam los shortcuts/media huérfanos de esta plataforma.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Exportar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await _runSteamBatchExport(targetGames, selectedOnly: selectedOnly);
  }

  Future<void> _runSteamBatchExport(
    List<Game> games, {
    required bool selectedOnly,
  }) async {
    var started = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        var done = 0;
        var ok = 0;
        var failed = 0;
        var removedShortcuts = 0;
        var removedArtwork = 0;
        String current = '';

        return StatefulBuilder(
          builder: (context, setLocalState) {
            if (!started) {
              started = true;
              Future.microtask(() async {
                if (!selectedOnly && _selectedPlatform != null) {
                  setLocalState(() {
                    current =
                        'Sincronizando plataforma ${_selectedPlatform!.platformName}';
                  });
                  final result = await _steamExportService.syncPlatformToSteam(
                    platformGames: games,
                    platformName: _selectedPlatform!.platformName,
                    lutrisPaths: widget.lutrisPaths,
                  );
                  setLocalState(() {
                    done = games.length;
                    ok = result.exportedOk;
                    failed = result.exportedFailed;
                    removedShortcuts = result.removedShortcuts;
                    removedArtwork = result.removedArtworkEntries;
                  });
                } else {
                  for (final game in games) {
                    setLocalState(() {
                      current = game.name;
                    });

                    final result = await _steamExportService.exportGame(
                      game,
                      widget.lutrisPaths,
                    );

                    setLocalState(() {
                      done++;
                      if (result.success) {
                        ok++;
                      } else {
                        failed++;
                      }
                    });
                  }
                }

                if (context.mounted) {
                  Navigator.of(context).pop();
                }

                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(failed == 0 ? Icons.check_circle_outline : Icons.warning_amber_outlined, 
                             size: 18, color: failed == 0 ? Colors.white70 : Colors.white38),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            selectedOnly
                                ? 'Exportacion completada. OK: $ok | Fallidos: $failed'
                                : 'Sincronizacion completada. OK: $ok | Fallidos: $failed',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              });
            }

            final progress = games.isEmpty ? 0.0 : done / games.length;
            return AlertDialog(
              title: const Text('Exportando a Steam...'),
              content: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(value: progress),
                    const SizedBox(height: 12),
                    Text('Procesando: $done/${games.length}'),
                    const SizedBox(height: 6),
                    Text('Correctos: $ok | Fallidos: $failed'),
                    if (!selectedOnly)
                      Text(
                        'Depurados: $removedShortcuts shortcuts | $removedArtwork medias',
                      ),
                    if (current.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Actual: $current',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }



  Widget _buildMinimalChoiceChip(String label, bool isSelected, VoidCallback onSelected) {
    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: isSelected ? Colors.white : const Color(0xFF1A1A1A)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.black : Colors.white70,
          ),
        ),
      ),
    );
  }



  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(
          bottom: BorderSide(color: Color(0xFF1A1A1A)),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Platform dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A0A),
                  border: Border.all(color: const Color(0xFF1A1A1A)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<PlatformInfo>(
                    value: _selectedPlatform,
                    dropdownColor: const Color(0xFF0A0A0A),
                    items: _platforms.map((p) {
                      return DropdownMenuItem(
                        value: p,
                        child: Text(
                          p.platformName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedPlatform = val);
                        _refreshList();
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Search bar
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() => _searchQuery = value.trim());
                    _refreshList();
                  },
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Buscar juego...',
                    prefixIcon: const Icon(Icons.search, size: 18, color: Colors.white24),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16, color: Colors.white38),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                              _refreshList();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFF0A0A0A),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Color(0xFF1A1A1A)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Color(0xFF1A1A1A)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // View toggle
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A0A),
                  border: Border.all(color: const Color(0xFF1A1A1A)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    _buildViewToggleButton(Icons.grid_view, _isGridView, () => setState(() => _isGridView = true)),
                    Container(width: 1, height: 20, color: const Color(0xFF1A1A1A)),
                    _buildViewToggleButton(Icons.view_list, !_isGridView, () => setState(() => _isGridView = false)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _buildMinimalHeaderButton(
                icon: Icons.cloud_upload_outlined,
                label: 'Exportar a Steam',
                onPressed: _isSteamAvailable
                    ? () => _confirmAndExportToSteam(selectedOnly: false)
                    : () => SteamDependenciesDialog.show(context),
                isDisabled: !_isSteamAvailable,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 1,
            color: const Color(0xFF1A1A1A),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Wrap(
                spacing: 8,
                children: [
                  _buildMinimalChoiceChip('Todos', _filterMode == 'all', () {
                    setState(() => _filterMode = 'all');
                    _refreshList();
                  }),
                  _buildMinimalChoiceChip('Sin portada (${_stats.missingCover})', _filterMode == 'missingCover', () {
                    setState(() => _filterMode = 'missingCover');
                    _refreshList();
                  }),
                  _buildMinimalChoiceChip('Sin banner (${_stats.missingBanner})', _filterMode == 'missingBanner', () {
                    setState(() => _filterMode = 'missingBanner');
                    _refreshList();
                  }),
                  _buildMinimalChoiceChip('Sin icono (${_stats.missingIcon})', _filterMode == 'missingIcon', () {
                    setState(() => _filterMode = 'missingIcon');
                    _refreshList();
                  }),
                ],
              ),
              const Spacer(),
              Text(
                '${_stats.total} JUEGOS',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: Colors.white38,
                ),
              ),
              const SizedBox(width: 16),
              _buildToolbarActionButton(
                icon: _selectionMode ? Icons.close : Icons.checklist,
                label: _selectionMode ? 'Cancelar' : 'Selección Múltiple',
                onPressed: _toggleSelectionMode,
                isActive: _selectionMode,
              ),
              if (_selectionMode) ...[
                const SizedBox(width: 8),
                Container(width: 1, height: 24, color: const Color(0xFF1A1A1A)),
                const SizedBox(width: 8),
                Text(
                  '${_selectedGameIds.length} SEL.',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(width: 12),
                _buildToolbarActionButton(
                  icon: Icons.done_all,
                  label: 'Todo',
                  onPressed: () {
                    final allIds = _repo.getGameIdsByRunners(
                      _selectedRunners,
                      platform: _selectedPlatform?.platformName,
                      filterMode: _filterMode != 'all' ? _filterMode : null,
                      searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
                    );
                    setState(() {
                      _selectedGameIds
                        ..clear()
                        ..addAll(allIds);
                    });
                  },
                ),
                const SizedBox(width: 8),
                _buildToolbarActionButton(
                  icon: Icons.cloud_upload_outlined,
                  label: 'Exportar',
                  onPressed: _selectedGameIds.isEmpty
                      ? () {}
                      : (_isSteamAvailable
                          ? () => _confirmAndExportToSteam(selectedOnly: true)
                          : () => SteamDependenciesDialog.show(context)),
                  isDisabled: _selectedGameIds.isEmpty || !_isSteamAvailable,
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _selectedGameIds.isEmpty ? null : _deleteSelectedGames,
                  style: TextButton.styleFrom(
                    backgroundColor: _selectedGameIds.isEmpty ? Colors.transparent : Colors.red[900],
                    foregroundColor: _selectedGameIds.isEmpty ? Colors.white24 : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                      side: _selectedGameIds.isEmpty ? const BorderSide(color: Color(0xFF1A1A1A)) : BorderSide.none,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  icon: const Icon(Icons.delete_outline, size: 14),
                  label: const Text('Eliminar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isActive = false,
    bool isDisabled = false,
  }) {
    return TextButton.icon(
      onPressed: isDisabled ? null : onPressed,
      style: TextButton.styleFrom(
        backgroundColor: isDisabled 
            ? Colors.transparent 
            : (isActive ? Colors.white : const Color(0xFF0A0A0A)),
        foregroundColor: isDisabled 
            ? Colors.white24 
            : (isActive ? Colors.black : Colors.white70),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(
            color: isDisabled 
                ? const Color(0xFF1A1A1A) 
                : (isActive ? Colors.white : const Color(0xFF1A1A1A)),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      icon: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildViewToggleButton(IconData icon, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Icon(icon, size: 18, color: isActive ? Colors.white : Colors.white24),
      ),
    );
  }

  Widget _buildMinimalHeaderButton({required IconData icon, required String label, required VoidCallback onPressed, bool isDisabled = false}) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: isDisabled ? Colors.transparent : Colors.white,
        foregroundColor: isDisabled ? Colors.white24 : Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: isDisabled ? const BorderSide(color: Color(0xFF1A1A1A)) : BorderSide.none,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }



  Widget _buildGameGrid() {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 240,
        childAspectRatio: 0.7,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      itemCount: _games.length,
      itemBuilder: (context, index) {
        return _buildGameCard(_games[index]);
      },
    );
  }

  Widget _buildGameList() {
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.all(24),
      itemCount: _games.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return _buildGameListTile(_games[index]);
      },
    );
  }

  Widget _buildGameListTile(Game game) {
    final isSelected = _isGameSelected(game);
    return InkWell(
      onTap: () =>
          _selectionMode ? _toggleGameSelection(game) : _editMetadata(game),
      onLongPress: () {
        if (!_selectionMode) {
          _toggleSelectionMode();
          _toggleGameSelection(game);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected
                ? Colors.white24
                : const Color(0xFF1A1A1A),
          ),
          color: isSelected
              ? Colors.white.withOpacity(0.05)
              : const Color(0xFF0A0A0A),
        ),
        child: Row(
          children: [
            if (_selectionMode)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                  size: 20,
                  color: isSelected ? Colors.white : Colors.white24,
                ),
              ),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: SizedBox(
                width: 48,
                height: 48,
                child: _buildImagePreview(game, 'cover', fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    game.platform.toUpperCase(),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white24, letterSpacing: 0.5),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            _buildMediaStatus(game),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              color: Colors.white38,
              onPressed: () => _editMetadata(game),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaStatus(Game game) {
    Widget buildDot(bool hasAsset, IconData icon) {
      return Icon(
        icon,
        size: 14,
        color: hasAsset ? Colors.white : Colors.white10,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        buildDot(game.hasCover, Icons.photo_library_outlined),
        const SizedBox(width: 8),
        buildDot(game.hasBanner, Icons.panorama_horizontal_outlined),
        const SizedBox(width: 8),
        buildDot(game.hasIcon, Icons.apps_outlined),
      ],
    );
  }

  Widget _buildGameCard(Game game) {
    final isSelected = _isGameSelected(game);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () =>
            _selectionMode ? _toggleGameSelection(game) : _editMetadata(game),
        onLongPress: () {
          if (!_selectionMode) {
            _toggleSelectionMode();
            _toggleGameSelection(game);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isSelected
                  ? Colors.white70
                  : const Color(0xFF1A1A1A),
            ),
            color: const Color(0xFF0A0A0A),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildImagePreview(game, 'cover', fit: BoxFit.cover),
                    if (_selectionMode)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                          child: Icon(
                            isSelected ? Icons.check_circle : Icons.circle_outlined,
                            size: 20,
                            color: isSelected ? Colors.white : Colors.white38,
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 40,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Colors.black87, Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                    if (!game.hasCover || !game.hasBanner || !game.hasIcon)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: _buildBadge('INCOMPLETO'),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.photo_library_outlined, size: 10, color: Colors.white24),
                        const SizedBox(width: 4),
                        Icon(Icons.circle, size: 6, color: game.hasCover ? Colors.white38 : Colors.white10),
                        const SizedBox(width: 8),
                        const Icon(Icons.panorama_horizontal_outlined, size: 10, color: Colors.white24),
                        const SizedBox(width: 4),
                        Icon(Icons.circle, size: 6, color: game.hasBanner ? Colors.white38 : Colors.white10),
                        const SizedBox(width: 8),
                        const Icon(Icons.apps_outlined, size: 10, color: Colors.white24),
                        const SizedBox(width: 4),
                        Icon(Icons.circle, size: 6, color: game.hasIcon ? Colors.white38 : Colors.white10),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildImagePreview(
    Game game,
    String type, {
    BoxFit fit = BoxFit.cover,
  }) {
    String? path;

    if (type == 'cover') {
      path = _lutrisPaths.coverPath(game.slug);
    } else if (type == 'banner') {
      path = _lutrisPaths.bannerPath(game.slug);
    } else if (type == 'icon') {
      path = _lutrisPaths.systemIconPath(game.slug);
    }

    if (path != null && File(path).existsSync()) {
      return Image.file(
        File(path),
        key: ValueKey("$path-$_imageVersion"),
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(type),
      );
    }

    return _buildPlaceholder(type);
  }

  Widget _buildPlaceholder(String type) {
    final icon = type == 'cover'
        ? Icons.photo_library_outlined
        : type == 'banner'
        ? Icons.panorama_horizontal_outlined
        : Icons.apps_outlined;

    return Container(
      color: const Color(0xFF080808),
      child: Center(
        child: Icon(
          icon,
          color: Colors.white.withOpacity(0.03),
          size: type == 'icon' ? 16 : 32,
        ),
      ),
    );
  }

  void _editMetadata(Game game) {
    GameDetailScreen.show(context, game, widget.lutrisPaths, widget.apiKey, widget.onShowConfig, () {
      setState(() => _imageVersion++);
      _refreshList();
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_outlined, size: 48, color: Colors.white10),
          const SizedBox(height: 16),
          const Text(
            'Sin resultados',
            style: TextStyle(color: Colors.white38, fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildContentArea() {
    if (_isLoading && _games.isEmpty) {
      return const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white24)));
    }

    if (_games.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        Expanded(
          child: _isGridView ? _buildGameGrid() : _buildGameList(),
        ),
        _buildPaginationBar(),
      ],
    );
  }

  Widget _buildPaginationBar() {
    if (_totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(
          top: BorderSide(color: Color(0xFF1A1A1A)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: _page > 0
                ? () {
                    setState(() => _page--);
                    _loadPageGames();
                    if (_scrollController.hasClients) {
                      _scrollController.jumpTo(0);
                    }
                  }
                : null,
            icon: const Icon(Icons.arrow_back_ios_new, size: 12),
            label: const Text('Anterior', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white70,
              disabledForegroundColor: Colors.white24,
            ),
          ),
          Text(
            'PÁGINA ${_page + 1} DE $_totalPages  •  $_totalGames JUEGOS',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: Colors.white38,
            ),
          ),
          TextButton.icon(
            onPressed: (_page + 1) < _totalPages
                ? () {
                    setState(() => _page++);
                    _loadPageGames();
                    if (_scrollController.hasClients) {
                      _scrollController.jumpTo(0);
                    }
                  }
                : null,
            icon: const Text('Siguiente', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            label: const Icon(Icons.arrow_forward_ios, size: 12),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white70,
              disabledForegroundColor: Colors.white24,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: _buildContentArea(),
        ),
      ],
    );
  }
}
