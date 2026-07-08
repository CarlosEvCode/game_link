class EmulatorInfo {
  final String id;
  final String name; // Nombre legible (ej. "Citra", "Azahar")
  final String runner; // ID del runner en Lutris
  final String? libretroCore; // Nombre del core si el runner es libretro
  final List<String> extensions;
  final List<String>? extensionPriority;
  final bool disableRuntime;
  final Map<String, dynamic>? specialConfig; // Nuevo: Configuración extra para el YAML

  const EmulatorInfo({
    required this.id,
    required this.name,
    required this.runner,
    required this.extensions,
    this.libretroCore,
    this.extensionPriority,
    this.disableRuntime = true,
    this.specialConfig,
  });

  /// Obtiene la prioridad de una extensión (menor número = mayor prioridad)
  int getExtensionPriority(String extension) {
    final ext = extension.toLowerCase();
    if (extensionPriority == null) return 0;
    final index = extensionPriority!.indexOf(ext);
    return index == -1 ? extensionPriority!.length : index;
  }
}

class PlatformInfo {
  final String platformId;
  final String platformName;
  final List<EmulatorInfo> emulators;
  final bool hasSpecialFeatures;
  final String? screenScraperId; // ID del sistema en ScreenScraper API
  final bool hideFromInjector; // Nuevo: Ocultar de la vista de inyección

  const PlatformInfo({
    required this.platformId,
    required this.platformName,
    required this.emulators,
    this.hasSpecialFeatures = false,
    this.screenScraperId,
    this.hideFromInjector = false,
  });

  /// Obtiene todas las extensiones soportadas por los emuladores de esta plataforma
  List<String> get extensions => emulators.expand((e) => e.extensions).toSet().toList();

  /// Obtiene la prioridad de extensión delegando en el primer emulador
  int getExtensionPriority(String extension) {
    if (emulators.isEmpty) return 0;
    return emulators.first.getExtensionPriority(extension);
  }

  /// Constructor de conveniencia para plataformas con un solo emulador
  factory PlatformInfo.single({
    required String platformId,
    required String platformName,
    required String runner,
    required List<String> extensions,
    List<String>? extensionPriority,
    bool disableRuntime = true,
    bool hasSpecialFeatures = false,
    String? screenScraperId,
    Map<String, dynamic>? specialConfig,
    bool hideFromInjector = false,
  }) {
    return PlatformInfo(
      platformId: platformId,
      platformName: platformName,
      hasSpecialFeatures: hasSpecialFeatures,
      screenScraperId: screenScraperId,
      hideFromInjector: hideFromInjector,
      emulators: [
        EmulatorInfo(
          id: 'default',
          name: 'Default',
          runner: runner,
          extensions: extensions,
          extensionPriority: extensionPriority,
          disableRuntime: disableRuntime,
          specialConfig: specialConfig,
        ),
      ],
    );
  }
}

class PlatformRegistry {
  static final Map<String, PlatformInfo> _platforms = {};

  static void initialize() {
    if (_platforms.isNotEmpty) return;

    _platforms['ps1'] = const PlatformInfo(
      platformId: 'ps1',
      platformName: 'Sony PlayStation',
      screenScraperId: '57',
      emulators: [
        EmulatorInfo(
          id: 'duckstation_standalone',
          name: 'DuckStation (Standalone)',
          runner: 'duckstation',
          extensions: ['.bin', '.chd', '.pbp', '.cue'],
          extensionPriority: ['.bin', '.chd', '.pbp', '.cue'],
          disableRuntime: true,
        ),
        EmulatorInfo(
          id: 'beetle_psx_hw_libretro',
          name: 'Beetle PSX HW (Libretro)',
          runner: 'libretro',
          libretroCore: 'beetle_psx_hw',
          extensions: ['.bin', '.chd', '.pbp', '.cue'],
          extensionPriority: ['.bin', '.chd', '.pbp', '.cue'],
          disableRuntime: true,
        ),
        EmulatorInfo(
          id: 'beetle_psx_libretro',
          name: 'Beetle PSX (Libretro)',
          runner: 'libretro',
          libretroCore: 'beetle_psx',
          extensions: ['.bin', '.chd', '.pbp', '.cue'],
          extensionPriority: ['.bin', '.chd', '.pbp', '.cue'],
          disableRuntime: true,
        ),
        EmulatorInfo(
          id: 'swanstation_libretro',
          name: 'SwanStation (Libretro)',
          runner: 'libretro',
          libretroCore: 'swanstation',
          extensions: ['.bin', '.chd', '.pbp', '.cue'],
          extensionPriority: ['.bin', '.chd', '.pbp', '.cue'],
          disableRuntime: true,
        ),
        EmulatorInfo(
          id: 'pcsx_rearmed_libretro',
          name: 'PCSX ReARMed (Libretro)',
          runner: 'libretro',
          libretroCore: 'pcsx_rearmed',
          extensions: ['.bin', '.chd', '.pbp', '.cue'],
          extensionPriority: ['.bin', '.chd', '.pbp', '.cue'],
          disableRuntime: true,
        ),
      ],
    );
    
    _platforms['ps2'] = const PlatformInfo(
      platformId: 'ps2',
      platformName: 'Sony PlayStation 2',
      screenScraperId: '58',
      emulators: [
        EmulatorInfo(
          id: 'pcsx2_standalone',
          name: 'PCSX2 (Standalone)',
          runner: 'pcsx2',
          extensions: ['.iso', '.chd'],
          extensionPriority: ['.iso', '.chd'],
          disableRuntime: true,
        ),
        EmulatorInfo(
          id: 'pcsx2_libretro',
          name: 'PCSX2 (Libretro)',
          runner: 'libretro',
          libretroCore: 'pcsx2',
          extensions: ['.iso', '.chd'],
          extensionPriority: ['.iso', '.chd'],
          disableRuntime: true,
        ),
      ],
    );
    
    _platforms['gamecube'] = const PlatformInfo(
      platformId: 'gamecube',
      platformName: 'Nintendo GameCube',
      screenScraperId: '13',
      emulators: [
        EmulatorInfo(
          id: 'dolphin_standalone',
          name: 'Dolphin (Standalone)',
          runner: 'dolphin',
          extensions: ['.iso', '.gcz', '.rvz'],
          extensionPriority: ['.iso', '.gcz', '.rvz'],
          specialConfig: {'platform': '0'}, // 0 = GameCube
        ),
        EmulatorInfo(
          id: 'dolphin_libretro',
          name: 'Dolphin (Libretro)',
          runner: 'libretro',
          libretroCore: 'dolphin',
          extensions: ['.iso', '.gcz', '.rvz'],
          extensionPriority: ['.iso', '.gcz', '.rvz'],
        ),
      ],
    );
    
    _platforms['wii'] = const PlatformInfo(
      platformId: 'wii',
      platformName: 'Nintendo Wii',
      screenScraperId: '16',
      emulators: [
        EmulatorInfo(
          id: 'dolphin_standalone',
          name: 'Dolphin (Standalone)',
          runner: 'dolphin',
          extensions: ['.iso', '.wbfs', '.rvz'],
          extensionPriority: ['.iso', '.wbfs', '.rvz'],
          specialConfig: {'platform': '1'}, // 1 = Wii
        ),
        EmulatorInfo(
          id: 'dolphin_libretro',
          name: 'Dolphin (Libretro)',
          runner: 'libretro',
          libretroCore: 'dolphin',
          extensions: ['.iso', '.wbfs', '.rvz'],
          extensionPriority: ['.iso', '.wbfs', '.rvz'],
        ),
      ],
    );
    
    _platforms['wii_u'] = PlatformInfo.single(
      platformId: 'wii_u',
      platformName: 'Wii U',
      runner: 'cemu',
      extensions: ['.wud', '.wux', '.rpx', '.wua'],
      extensionPriority: ['.wua', '.rpx', '.wud', '.wux'],
      disableRuntime: true,
      screenScraperId: '18',
    );
    
    _platforms['mame'] = const PlatformInfo(
      platformId: 'mame',
      platformName: 'Arcade',
      hasSpecialFeatures: true,
      screenScraperId: '75',
      emulators: [
        EmulatorInfo(
          id: 'mame_standalone',
          name: 'MAME (Standalone)',
          runner: 'mame',
          extensions: ['.zip', '.7z'],
          extensionPriority: ['.zip', '.7z'],
          disableRuntime: false,
        ),
        EmulatorInfo(
          id: 'mame_libretro',
          name: 'MAME (Libretro)',
          runner: 'libretro',
          libretroCore: 'mame',
          extensions: ['.zip', '.7z'],
          extensionPriority: ['.zip', '.7z'],
          disableRuntime: false,
        ),
        EmulatorInfo(
          id: 'mame2003_plus_libretro',
          name: 'MAME 2003 Plus (Libretro)',
          runner: 'libretro',
          libretroCore: 'mame2003_plus',
          extensions: ['.zip', '.7z'],
          extensionPriority: ['.zip', '.7z'],
          disableRuntime: false,
        ),
        EmulatorInfo(
          id: 'mame2003_libretro',
          name: 'MAME 2003 (Libretro)',
          runner: 'libretro',
          libretroCore: 'mame2003',
          extensions: ['.zip', '.7z'],
          extensionPriority: ['.zip', '.7z'],
          disableRuntime: false,
        ),
        EmulatorInfo(
          id: 'mame2010_libretro',
          name: 'MAME 2010 (Libretro)',
          runner: 'libretro',
          libretroCore: 'mame2010',
          extensions: ['.zip', '.7z'],
          extensionPriority: ['.zip', '.7z'],
          disableRuntime: false,
        ),
        EmulatorInfo(
          id: 'fbneo_libretro',
          name: 'FinalBurn Neo (Libretro)',
          runner: 'libretro',
          libretroCore: 'fbneo',
          extensions: ['.zip', '.7z'],
          extensionPriority: ['.zip', '.7z'],
          disableRuntime: false,
        ),
      ],
    );

    // Nintendo 3DS con múltiples emuladores
    _platforms['3ds'] = const PlatformInfo(
      platformId: '3ds',
      platformName: 'Nintendo 3DS',
      screenScraperId: '17',
      emulators: [
        EmulatorInfo(
          id: 'azahar',
          name: 'Azahar',
          runner: 'azahar',
          extensions: ['.cci'],
          extensionPriority: ['.cci'],
          disableRuntime: true,
        ),
        EmulatorInfo(
          id: 'citra',
          name: 'Citra',
          runner: 'citra',
          extensions: ['.3ds', '.cia', '.cci'],
          extensionPriority: ['.3ds', '.cia', '.cci'],
          disableRuntime: true,
        ),
        EmulatorInfo(
          id: 'citra_libretro',
          name: 'Citra (Libretro)',
          runner: 'libretro',
          libretroCore: 'citra',
          extensions: ['.3ds', '.cia', '.cci'],
          extensionPriority: ['.3ds', '.cia', '.cci'],
          disableRuntime: true,
        ),
      ],
    );

    _platforms['psp'] = const PlatformInfo(
      platformId: 'psp',
      platformName: 'Sony Playstation Portable',
      screenScraperId: '61',
      emulators: [
        EmulatorInfo(
          id: 'ppsspp_standalone',
          name: 'PPSSPP (Standalone)',
          runner: 'ppsspp',
          extensions: ['.iso', '.cso', '.pbp'],
          extensionPriority: ['.iso', '.cso', '.pbp'],
        ),
        EmulatorInfo(
          id: 'ppsspp_libretro',
          name: 'PPSSPP (Libretro)',
          runner: 'libretro',
          libretroCore: 'ppsspp',
          extensions: ['.iso', '.cso', '.pbp'],
          extensionPriority: ['.iso', '.cso', '.pbp'],
        ),
      ],
    );

    _platforms['dreamcast'] = const PlatformInfo(
      platformId: 'dreamcast',
      platformName: 'Sega Dreamcast',
      screenScraperId: '23',
      emulators: [
        EmulatorInfo(
          id: 'flycast',
          name: 'Flycast (Libretro)',
          runner: 'libretro',
          libretroCore: 'flycast',
          extensions: ['.chd', '.gdi', '.cdi'],
          extensionPriority: ['.chd', '.gdi', '.cdi'],
        ),
        EmulatorInfo(
          id: 'redream',
          name: 'Redream',
          runner: 'redream',
          extensions: ['.chd', '.gdi', '.cdi'],
          extensionPriority: ['.chd', '.gdi', '.cdi'],
        ),
        EmulatorInfo(
          id: 'reicast',
          name: 'Reicast',
          runner: 'reicast',
          extensions: ['.chd', '.gdi', '.cdi'],
          extensionPriority: ['.chd', '.gdi', '.cdi'],
        ),
      ],
    );

    _platforms['switch'] = const PlatformInfo(
      platformId: 'switch',
      platformName: 'Nintendo Switch',
      screenScraperId: '157',
      emulators: [
        EmulatorInfo(
          id: 'yuzu',
          name: 'Yuzu',
          runner: 'yuzu',
          extensions: ['.nsp', '.xci', '.nca', '.nso'],
          extensionPriority: ['.nsp', '.xci', '.nca', '.nso'],
        ),
        EmulatorInfo(
          id: 'ryujinx',
          name: 'Ryujinx',
          runner: 'ryujinx',
          extensions: ['.nsp', '.xci', '.nca', '.nso'],
          extensionPriority: ['.nsp', '.xci', '.nca', '.nso'],
        ),
      ],
    );

    _platforms['ds'] = const PlatformInfo(
      platformId: 'ds',
      platformName: 'Nintendo DS',
      screenScraperId: '15',
      emulators: [
        EmulatorInfo(
          id: 'desmume_standalone',
          name: 'DeSmuME (Standalone)',
          runner: 'desmume',
          extensions: ['.nds', '.ds'],
          extensionPriority: ['.nds', '.ds'],
        ),
        EmulatorInfo(
          id: 'melonds_standalone',
          name: 'melonDS (Standalone)',
          runner: 'melonds',
          extensions: ['.nds', '.ds'],
          extensionPriority: ['.nds', '.ds'],
        ),
        EmulatorInfo(
          id: 'desmume_libretro',
          name: 'DeSmuME (Libretro)',
          runner: 'libretro',
          libretroCore: 'desmume',
          extensions: ['.nds', '.ds'],
          extensionPriority: ['.nds', '.ds'],
        ),
        EmulatorInfo(
          id: 'melonds_libretro',
          name: 'melonDS (Libretro)',
          runner: 'libretro',
          libretroCore: 'melonds',
          extensions: ['.nds', '.ds'],
          extensionPriority: ['.nds', '.ds'],
        ),
      ],
    );

    _platforms['gba'] = const PlatformInfo(
      platformId: 'gba',
      platformName: 'Nintendo Game Boy Advance',
      screenScraperId: '24',
      emulators: [
        EmulatorInfo(
          id: 'mgba_standalone',
          name: 'mGBA (Standalone)',
          runner: 'mgba',
          extensions: ['.gba'],
          extensionPriority: ['.gba'],
        ),
        EmulatorInfo(
          id: 'mgba_libretro',
          name: 'mGBA (Libretro)',
          runner: 'libretro',
          libretroCore: 'mgba',
          extensions: ['.gba'],
          extensionPriority: ['.gba'],
        ),
        EmulatorInfo(
          id: 'gpsp_libretro',
          name: 'gpSP (Libretro)',
          runner: 'libretro',
          libretroCore: 'gpsp',
          extensions: ['.gba'],
          extensionPriority: ['.gba'],
        ),
        EmulatorInfo(
          id: 'vba_next_libretro',
          name: 'VBA Next (Libretro)',
          runner: 'libretro',
          libretroCore: 'vba_next',
          extensions: ['.gba'],
          extensionPriority: ['.gba'],
        ),
        EmulatorInfo(
          id: 'vbam_libretro',
          name: 'VBA-M (Libretro)',
          runner: 'libretro',
          libretroCore: 'vbam',
          extensions: ['.gba'],
          extensionPriority: ['.gba'],
        ),
      ],
    );

    _platforms['nes'] = const PlatformInfo(
      platformId: 'nes',
      platformName: 'Nintendo NES',
      screenScraperId: '3',
      emulators: [
        EmulatorInfo(
          id: 'fceumm_libretro',
          name: 'FCEUmm (Libretro)',
          runner: 'libretro',
          libretroCore: 'fceumm',
          extensions: ['.nes', '.zip', '.7z'],
          extensionPriority: ['.nes', '.zip', '.7z'],
        ),
        EmulatorInfo(
          id: 'nestopia_libretro',
          name: 'Nestopia (Libretro)',
          runner: 'libretro',
          libretroCore: 'nestopia',
          extensions: ['.nes', '.zip', '.7z'],
          extensionPriority: ['.nes', '.zip', '.7z'],
        ),
        EmulatorInfo(
          id: 'mesen_libretro',
          name: 'Mesen (Libretro)',
          runner: 'libretro',
          libretroCore: 'mesen',
          extensions: ['.nes', '.zip', '.7z'],
          extensionPriority: ['.nes', '.zip', '.7z'],
        ),
        EmulatorInfo(
          id: 'quicknes_libretro',
          name: 'QuickNES (Libretro)',
          runner: 'libretro',
          libretroCore: 'quicknes',
          extensions: ['.nes', '.zip', '.7z'],
          extensionPriority: ['.nes', '.zip', '.7z'],
        ),
      ],
    );

    _platforms['vita'] = PlatformInfo.single(
      platformId: 'vita',
      platformName: 'Sony PlayStation Vita',
      runner: 'vita3k',
      extensions: ['.vpk', '.zip'],
      extensionPriority: ['.vpk', '.zip'],
      screenScraperId: '63',
      disableRuntime: true,
    );

    _platforms['xbox'] = PlatformInfo.single(
      platformId: 'xbox',
      platformName: 'Xbox',
      runner: 'xemu',
      extensions: ['.iso', '.xiso'],
      extensionPriority: ['.iso', '.xiso'],
      screenScraperId: '32',
      disableRuntime: true,
    );

    _platforms['windows'] = PlatformInfo.single(
      platformId: 'windows',
      platformName: 'Windows',
      runner: 'wine',
      extensions: ['.exe'],
      screenScraperId: '1',
      hideFromInjector: true,
    );
  }

  static PlatformInfo? getPlatform(String id) {
    return _platforms[id];
  }

  static List<PlatformInfo> getAllPlatforms() {
    return _platforms.values.toList();
  }

  static List<PlatformInfo> getInjectorPlatforms() {
    return _platforms.values.where((p) => !p.hideFromInjector).toList();
  }
}
