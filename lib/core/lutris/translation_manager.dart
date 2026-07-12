class I18n {
  static String _currentLang = 'en'; // Default to English

  static String get currentLang => _currentLang;

  static void setLanguage(String lang) {
    if (lang == 'es' || lang == 'en') {
      _currentLang = lang;
    }
  }

  static String translate(String key) {
    final translations = _data[key];
    if (translations == null) return key;
    return translations[_currentLang] ?? key;
  }

  static final Map<String, Map<String, String>> _data = {
    // Config Dialog
    'CONFIGURACIÓN': {
      'en': 'SETTINGS',
      'es': 'CONFIGURACIÓN',
    },
    'STEAMGRIDDB': {
      'en': 'STEAMGRIDDB',
      'es': 'STEAMGRIDDB',
    },
    'SCREEN SCRAPER': {
      'en': 'SCREEN SCRAPER',
      'es': 'SCREEN SCRAPER',
    },
    'GENERAL': {
      'en': 'GENERAL',
      'es': 'GENERAL',
    },
    'IDIOMA': {
      'en': 'LANGUAGE',
      'es': 'IDIOMA',
    },
    'CANCELAR': {
      'en': 'CANCEL',
      'es': 'CANCELAR',
    },
    'GUARDAR': {
      'en': 'SAVE',
      'es': 'GUARDAR',
    },
    'API KEY': {
      'en': 'API KEY',
      'es': 'API KEY',
    },
    'USUARIO': {
      'en': 'USER',
      'es': 'USUARIO',
    },
    'CONTRASEÑA': {
      'en': 'PASSWORD',
      'es': 'CONTRASEÑA',
    },
    'Obtén tu API Key en SteamGridDB': {
      'en': 'Get your API Key on SteamGridDB',
      'es': 'Obtén tu API Key en SteamGridDB',
    },
    'Regístrate en ScreenScraper': {
      'en': 'Register on ScreenScraper',
      'es': 'Regístrate en ScreenScraper',
    },
    'Requerido para descargar carátulas, banners e iconos automáticamente.': {
      'en': 'Required to download covers, banners, and icons automatically.',
      'es': 'Requerido para descargar carátulas, banners e iconos automáticamente.',
    },
    'Requerido para la identificación de alta precisión y metadatos.': {
      'en': 'Required for high-precision identification and metadata.',
      'es': 'Requerido para la identificación de alta precisión y metadatos.',
    },
    'Selecciona el idioma de la aplicación.': {
      'en': 'Select the application language.',
      'es': 'Selecciona el idioma de la aplicación.',
    },

    // MainWindow Sidebar
    'SISTEMA': {
      'en': 'SYSTEM',
      'es': 'SISTEMA',
    },
    'PLATAFORMA': {
      'en': 'PLATFORM',
      'es': 'PLATAFORMA',
    },
    'EMULADOR': {
      'en': 'EMULATOR',
      'es': 'EMULADOR',
    },
    'ORIGEN': {
      'en': 'SOURCE',
      'es': 'ORIGEN',
    },
    'CARPETA ROMS': {
      'en': 'ROMS FOLDER',
      'es': 'CARPETA ROMS',
    },
    'Seleccionar...': {
      'en': 'Select...',
      'es': 'Seleccionar...',
    },
    'Actualizar carpeta': {
      'en': 'Refresh folder',
      'es': 'Actualizar carpeta',
    },
    'EXTENSIONES': {
      'en': 'EXTENSIONS',
      'es': 'EXTENSIONES',
    },
    'PREFERENCIAS': {
      'en': 'PREFERENCES',
      'es': 'PREFERENCIAS',
    },
    'OPCIONES': {
      'en': 'OPTIONS',
      'es': 'OPCIONES',
    },
    'Autodetectar nombres (offline)': {
      'en': 'Autodetect names (offline)',
      'es': 'Autodetectar nombres (offline)',
    },
    'Alta Precisión (Hash)': {
      'en': 'High Precision (Hash)',
      'es': 'Alta Precisión (Hash)',
    },
    'Escaneo recursivo': {
      'en': 'Recursive scan',
      'es': 'Escaneo recursivo',
    },
    'Limpiar antiguos': {
      'en': 'Clean old games',
      'es': 'Limpiar antiguos',
    },
    'ACCIONES': {
      'en': 'ACTIONS',
      'es': 'ACCIONES',
    },
    'INYECTAR JUEGOS': {
      'en': 'INJECT GAMES',
      'es': 'INYECTAR JUEGOS',
    },
    'DESCARGAR METADATOS': {
      'en': 'DOWNLOAD METADATA',
      'es': 'DESCARGAR METADATOS',
    },
    'PROCESO COMPLETO': {
      'en': 'FULL PROCESS',
      'es': 'PROCESO COMPLETO',
    },
    'EJECUTAR PROCESO': {
      'en': 'RUN PROCESS',
      'es': 'EJECUTAR PROCESO',
    },
    'PROCESANDO...': {
      'en': 'PROCESSING...',
      'es': 'PROCESANDO...',
    },

    // MainWindow Injector List & Logs
    'DETECTADOS': {
      'en': 'DETECTED',
      'es': 'DETECTADOS',
    },
    'Ya en la biblioteca de Lutris': {
      'en': 'Already in Lutris library',
      'es': 'Ya en la biblioteca de Lutris',
    },
    'Selecciona una carpeta de ROMs para escanear...': {
      'en': 'Select a ROM folder to scan...',
      'es': 'Selecciona una carpeta de ROMs para escanear...',
    },
    'No se encontraron archivos en la carpeta de ROMs': {
      'en': 'No files found in the ROM folder',
      'es': 'No se encontraron archivos en la carpeta de ROMs',
    },
    'Editar nombre': {
      'en': 'Edit name',
      'es': 'Editar nombre',
    },
    'Nombre del juego': {
      'en': 'Game name',
      'es': 'Nombre del juego',
    },
    'Renombrar': {
      'en': 'Rename',
      'es': 'Renombrar',
    },

    // Logs & Warnings
    'Rutas de Lutris no detectadas.': {
      'en': 'Lutris paths not detected.',
      'es': 'Rutas de Lutris no detectadas.',
    },
    'Selecciona plataforma y emulador.': {
      'en': 'Select platform and emulator.',
      'es': 'Selecciona plataforma y emulador.',
    },
    'Selecciona una carpeta de ROMs.': {
      'en': 'Select a ROM folder.',
      'es': 'Selecciona una carpeta de ROMs.',
    },
    'Selecciona al menos una extensión.': {
      'en': 'Select at least one extension.',
      'es': 'Selecciona al menos una extensión.',
    },
    'Configura la API Key de SteamGridDB.': {
      'en': 'Configure the SteamGridDB API Key.',
      'es': 'Configura la API Key de SteamGridDB.',
    },
    'Alta Precisión requiere credenciales de ScreenScraper.': {
      'en': 'High Precision requires ScreenScraper credentials.',
      'es': 'Alta Precisión requiere credenciales de ScreenScraper.',
    },
    'Verificando quota...': {
      'en': 'Checking quota...',
      'es': 'Verificando quota...',
    },
    'Advertencia de Cuota': {
      'en': 'Quota Warning',
      'es': 'Advertencia de Cuota',
    },
    'Tienes ': {
      'en': 'You have ',
      'es': 'Tienes ',
    },
    ' peticiones restantes en ScreenScraper hoy. Intentas procesar ': {
      'en': ' requests remaining on ScreenScraper today. You are trying to process ',
      'es': ' peticiones restantes en ScreenScraper hoy. Intentas procesar ',
    },
    ' juegos.\n\n¿Deseas continuar? (Las primeras ': {
      'en': ' games.\n\nDo you want to continue? (The first ',
      'es': ' juegos.\n\n¿Deseas continuar? (Las primeras ',
    },
    ' serán identificadas por ScreenScraper)': {
      'en': ' will be identified by ScreenScraper)',
      'es': ' serán identificadas por ScreenScraper)',
    },
    'CONTINUAR': {
      'en': 'CONTINUE',
      'es': 'CONTINUAR',
    },
    'ESPERANDO SELECCIÓN': {
      'en': 'WAITING FOR SELECTION',
      'es': 'ESPERANDO SELECCIÓN',
    },
    'JUEGOS LISTOS': {
      'en': 'GAMES READY',
      'es': 'JUEGOS LISTOS',
    },
    'JUEGO LISTO': {
      'en': 'GAME READY',
      'es': 'JUEGO LISTO',
    },
    'Inyectar en Lutris + Descargar Metadatos': {
      'en': 'Inject into Lutris + Download Metadata',
      'es': 'Inyectar en Lutris + Descargar Metadatos',
    },
    'Opciones avanzadas': {
      'en': 'Advanced options',
      'es': 'Opciones avanzadas',
    },
    'Solo Inyectar ROMs': {
      'en': 'Inject ROMs Only',
      'es': 'Solo Inyectar ROMs',
    },
    'Solo Descargar Metadatos': {
      'en': 'Download Metadata Only',
      'es': 'Solo Descargar Metadatos',
    },
    'Listo.': {
      'en': 'Ready.',
      'es': 'Listo.',
    },
    'API Key cargada.': {
      'en': 'API Key loaded.',
      'es': 'API Key cargada.',
    },
    'ScreenScraper configurado.': {
      'en': 'ScreenScraper configured.',
      'es': 'ScreenScraper configurado.',
    },

    // About Dialog
    'Acerca de': {
      'en': 'About',
      'es': 'Acerca de',
    },
    'Un compañero universal de Lutris para inyectar ROMs y gestionar portadas.': {
      'en': 'A universal Lutris companion for injecting ROMs and managing media.',
      'es': 'Un compañero universal de Lutris para inyectar ROMs y gestionar portadas.',
    },
    'Desarrollado con Flutter': {
      'en': 'Developed with Flutter',
      'es': 'Desarrollado con Flutter',
    },
    'CERRAR': {
      'en': 'CLOSE',
      'es': 'CERRAR',
    },

    // Visual Manager Header & View Toolbar
    'Inyector': {
      'en': 'Injector',
      'es': 'Inyector',
    },
    'GESTOR VISUAL': {
      'en': 'VISUAL MANAGER',
      'es': 'GESTOR VISUAL',
    },
    'Buscar juego...': {
      'en': 'Search game...',
      'es': 'Buscar juego...',
    },
    'Exportar a Steam': {
      'en': 'Export to Steam',
      'es': 'Exportar a Steam',
    },
    'Exportar Seleccionados': {
      'en': 'Export Selected',
      'es': 'Exportar Seleccionados',
    },
    'Selección Múltiple': {
      'en': 'Multiple Selection',
      'es': 'Selección Múltiple',
    },
    'Juegos': {
      'en': 'Games',
      'es': 'Juegos',
    },
    'Juego': {
      'en': 'Game',
      'es': 'Juego',
    },
    'JUEGOS': {
      'en': 'GAMES',
      'es': 'JUEGOS',
    },
    'JUEGO': {
      'en': 'GAME',
      'es': 'JUEGO',
    },
    'No hay juegos para exportar.': {
      'en': 'No games to export.',
      'es': 'No hay juegos para exportar.',
    },
    'Se exportaran': {
      'en': 'Will export',
      'es': 'Se exportaran',
    },
    'juegos seleccionados a Steam.': {
      'en': 'selected games to Steam.',
      'es': 'juegos seleccionados a Steam.',
    },
    'Se crearan/actualizaran shortcuts, artwork y colecciones por plataforma.': {
      'en': 'Shortcuts, artwork, and collections will be created/updated per platform.',
      'es': 'Se crearan/actualizaran shortcuts, artwork y colecciones por plataforma.',
    },
    'Se sincronizaran': {
      'en': 'Will synchronize',
      'es': 'Se sincronizaran',
    },
    'juegos de': {
      'en': 'games of',
      'es': 'juegos de',
    },
    'con Steam.': {
      'en': 'with Steam.',
      'es': 'con Steam.',
    },
    'Exportación completada. OK: ': {
      'en': 'Export completed. OK: ',
      'es': 'Exportación completada. OK: ',
    },
    'Sincronización completada. OK: ': {
      'en': 'Synchronization completed. OK: ',
      'es': 'Sincronización completada. OK: ',
    },
    'Procesando:': {
      'en': 'Processing:',
      'es': 'Procesando:',
    },
    'Correctos:': {
      'en': 'Success:',
      'es': 'Correctos:',
    },
    'Depurados:': {
      'en': 'Cleaned:',
      'es': 'Depurados:',
    },
    'Actual:': {
      'en': 'Current:',
      'es': 'Actual:',
    },
    'Se crearan/actualizaran shortcuts, artwork y colecciones por plataforma, y se eliminaran en Steam los shortcuts/media huérfanos de esta plataforma.': {
      'en': 'Shortcuts, artwork, and collections will be created/updated per platform, and orphan shortcuts/media from this platform will be removed in Steam.',
      'es': 'Se crearan/actualizaran shortcuts, artwork y colecciones por plataforma, y se eliminaran en Steam los shortcuts/media huérfanos de esta plataforma.',
    },
    'Todos': {
      'en': 'All',
      'es': 'Todos',
    },
    'Sin portada': {
      'en': 'Missing cover',
      'es': 'Sin portada',
    },
    'Sin banner': {
      'en': 'Missing banner',
      'es': 'Sin banner',
    },
    'Sin icono': {
      'en': 'Missing icon',
      'es': 'Sin icono',
    },
    'Seleccionar Todo': {
      'en': 'Select All',
      'es': 'Seleccionar Todo',
    },
    'Desmarcar Todo': {
      'en': 'Deselect All',
      'es': 'Desmarcar Todo',
    },
    'Eliminar seleccionados': {
      'en': 'Delete selected',
      'es': 'Eliminar seleccionados',
    },
    '¿Estás seguro de eliminar los juegos seleccionados?': {
      'en': 'Are you sure you want to delete the selected games?',
      'es': '¿Estás seguro de eliminar los juegos seleccionados?',
    },
    'Esta acción eliminará permanentemente los juegos de la base de datos de Lutris y sus configuraciones. Las ROMs físicas no serán eliminadas.': {
      'en': 'This action will permanently delete the games from the Lutris database and their configurations. Physical ROMs will not be deleted.',
      'es': 'Esta acción eliminará permanentemente los juegos de la base de datos de Lutris y sus configuraciones. Las ROMs físicas no serán eliminadas.',
    },
    'Eliminar de Lutris': {
      'en': 'Delete from Lutris',
      'es': 'Eliminar de Lutris',
    },

    // Game Detail Dialog
    'DETALLE DEL JUEGO': {
      'en': 'GAME DETAIL',
      'es': 'DETALLE DEL JUEGO',
    },
    'SCREEN SCRAPER OK': {
      'en': 'SCREEN SCRAPER OK',
      'es': 'SCREEN SCRAPER OK',
    },
    'MEDIA COMPLETO': {
      'en': 'MEDIA COMPLETE',
      'es': 'MEDIA COMPLETO',
    },
    'SIN IDENTIFICAR': {
      'en': 'UNIDENTIFIED',
      'es': 'SIN IDENTIFICAR',
    },
    'PORTADA': {
      'en': 'COVER',
      'es': 'PORTADA',
    },
    'BANNER': {
      'en': 'BANNER',
      'es': 'BANNER',
    },
    'ICONO': {
      'en': 'ICON',
      'es': 'ICONO',
    },
    'RUTA ARCHIVO': {
      'en': 'FILE PATH',
      'es': 'RUTA ARCHIVO',
    },
    'Copiar': {
      'en': 'Copy',
      'es': 'Copiar',
    },
    'Ruta de la ROM copiada al portapapeles': {
      'en': 'ROM path copied to clipboard',
      'es': 'Ruta de la ROM copiada al portapapeles',
    },
    'Cerrar': {
      'en': 'Close',
      'es': 'Cerrar',
    },
    'Guardar cambios': {
      'en': 'Save changes',
      'es': 'Guardar cambios',
    },
    'Buscar en SteamGridDB': {
      'en': 'Search on SteamGridDB',
      'es': 'Buscar en SteamGridDB',
    },
    'Buscar en ScreenScraper': {
      'en': 'Search on ScreenScraper',
      'es': 'Buscar en ScreenScraper',
    },
    'Subir imagen local': {
      'en': 'Upload local image',
      'es': 'Subir imagen local',
    },
    'Eliminar imagen': {
      'en': 'Delete image',
      'es': 'Eliminar imagen',
    },
    'Cambios guardados': {
      'en': 'Changes saved',
      'es': 'Cambios guardados',
    },
    'Error al guardar cambios': {
      'en': 'Error saving changes',
      'es': 'Error al guardar cambios',
    },

    // Popup Menu (AppBar)
    'Configuración': {
      'en': 'Settings',
      'es': 'Configuración',
    },

    // Lutris Detection
    'No detectado': {
      'en': 'Not detected',
      'es': 'No detectado',
    },
    'No se detectó Lutris instalado.': {
      'en': 'Lutris not detected.',
      'es': 'No se detectó Lutris instalado.',
    },
    'Lutris detectado: ': {
      'en': 'Lutris detected: ',
      'es': 'Lutris detectado: ',
    },
    'Error detectando Lutris: ': {
      'en': 'Error detecting Lutris: ',
      'es': 'Error detectando Lutris: ',
    },
    'Cambiado a: ': {
      'en': 'Switched to: ',
      'es': 'Cambiado a: ',
    },
    'Lutris no detectado.': {
      'en': 'Lutris not detected.',
      'es': 'Lutris no detectado.',
    },

    // Edit Name Dialog
    'Editar Nombre': {
      'en': 'Edit Name',
      'es': 'Editar Nombre',
    },
    'Nombre en Lutris': {
      'en': 'Name in Lutris',
      'es': 'Nombre en Lutris',
    },
    'Cancelar': {
      'en': 'Cancel',
      'es': 'Cancelar',
    },
    'Guardar': {
      'en': 'Save',
      'es': 'Guardar',
    },

    // Quota Warning Dialog
    'Quota Limitada': {
      'en': 'Limited Quota',
      'es': 'Quota Limitada',
    },
    'Solo tienes ': {
      'en': 'You only have ',
      'es': 'Solo tienes ',
    },
    ' requests para ': {
      'en': ' requests for ',
      'es': ' requests para ',
    },
    ' ROMs.\n\nLas primeras ': {
      'en': ' ROMs.\n\nThe first ',
      'es': ' ROMs.\n\nLas primeras ',
    },
    ' serán identificadas por ScreenScraper.': {
      'en': ' will be identified by ScreenScraper.',
      'es': ' serán identificadas por ScreenScraper.',
    },
    'Continuar': {
      'en': 'Continue',
      'es': 'Continuar',
    },

    // Hint Texts
    'Tu API Key...': {
      'en': 'Your API Key...',
      'es': 'Tu API Key...',
    },
    'Usuario...': {
      'en': 'Username...',
      'es': 'Usuario...',
    },
    'Contraseña...': {
      'en': 'Password...',
      'es': 'Contraseña...',
    },

    // About Dialog
    'Software libre desarrollado como complemento para otros lanzadores y gestión de librerías.': {
      'en': 'Free software developed as a companion for other launchers and library management.',
      'es': 'Software libre desarrollado como complemento para otros lanzadores y gestión de librerías.',
    },

    // Game Detail - Header
    'MEDIA': {
      'en': 'MEDIA',
      'es': 'MEDIA',
    },
    'ACTUAL': {
      'en': 'CURRENT',
      'es': 'ACTUAL',
    },
    'ESTADO EN DISCO': {
      'en': 'DISK STATUS',
      'es': 'ESTADO EN DISCO',
    },
    'INFORMACIÓN': {
      'en': 'INFORMATION',
      'es': 'INFORMACIÓN',
    },
    'GESTIÓN': {
      'en': 'MANAGEMENT',
      'es': 'GESTIÓN',
    },
    'ARCHIVO': {
      'en': 'FILE',
      'es': 'ARCHIVO',
    },
    'SLUG': {
      'en': 'SLUG',
      'es': 'SLUG',
    },
    'ID': {
      'en': 'ID',
      'es': 'ID',
    },
    'RUTA ROM': {
      'en': 'ROM PATH',
      'es': 'RUTA ROM',
    },
    'DATOS': {
      'en': 'DATA',
      'es': 'DATOS',
    },
    'DEV': {
      'en': 'DEV',
      'es': 'DEV',
    },
    'FECHA': {
      'en': 'DATE',
      'es': 'FECHA',
    },
    'SINOPSIS': {
      'en': 'SYNOPSIS',
      'es': 'SINOPSIS',
    },
    'CORREGIR METADATOS': {
      'en': 'CORRECT METADATA',
      'es': 'CORREGIR METADATOS',
    },
    'EXPORTAR A STEAM': {
      'en': 'EXPORT TO STEAM',
      'es': 'EXPORTAR A STEAM',
    },
    'Copiado.': {
      'en': 'Copied.',
      'es': 'Copiado.',
    },
    'USAR ICONOS DE EDICIÓN PARA CAMBIAR CADA ELEMENTO.': {
      'en': 'USE EDIT ICONS TO CHANGE EACH ELEMENT.',
      'es': 'USAR ICONOS DE EDICIÓN PARA CAMBIAR CADA ELEMENTO.',
    },
    'Se requiere API Key de SteamGridDB para esta accion.': {
      'en': 'SteamGridDB API Key required for this action.',
      'es': 'Se requiere API Key de SteamGridDB para esta accion.',
    },
    'Corregir juego en SteamGridDB': {
      'en': 'Correct game on SteamGridDB',
      'es': 'Corregir juego en SteamGridDB',
    },
    'Texto de busqueda': {
      'en': 'Search text',
      'es': 'Texto de busqueda',
    },
    'Buscar': {
      'en': 'Search',
      'es': 'Buscar',
    },
    'Nombre corregido a ': {
      'en': 'Name corrected to ',
      'es': 'Nombre corregido a ',
    },
    'ENLACES EXTERNOS': {
      'en': 'EXTERNAL LINKS',
      'es': 'ENLACES EXTERNOS',
    },

    // Game Detail - SnackBar messages
    '[  DONE ] Nombre corregido a ': {
      'en': '[  DONE ] Name corrected to ',
      'es': '[  DONE ] Nombre corregido a ',
    },

    // Visual Manager - Additional
    'INCOMPLETO': {
      'en': 'INCOMPLETE',
      'es': 'INCOMPLETO',
    },
    'Sin resultados': {
      'en': 'No results',
      'es': 'Sin resultados',
    },
    'Anterior': {
      'en': 'Previous',
      'es': 'Anterior',
    },
    'Siguiente': {
      'en': 'Next',
      'es': 'Siguiente',
    },
    'PÁGINA ': {
      'en': 'PAGE ',
      'es': 'PÁGINA ',
    },
    ' DE ': {
      'en': ' OF ',
      'es': ' DE ',
    },
    'Fallidos: ': {
      'en': 'Failed: ',
      'es': 'Fallidos: ',
    },
    ' | Fallidos: ': {
      'en': ' | Failed: ',
      'es': ' | Fallidos: ',
    },
    'Exportando a Steam...': {
      'en': 'Exporting to Steam...',
      'es': 'Exportando a Steam...',
    },
    'Sincronizando plataforma ': {
      'en': 'Syncing platform ',
      'es': 'Sincronizando plataforma ',
    },
    'Exportar': {
      'en': 'Export',
      'es': 'Exportar',
    },
    'Eliminar': {
      'en': 'Delete',
      'es': 'Eliminar',
    },
    'Juegos eliminados con éxito de la biblioteca': {
      'en': 'Games successfully deleted from library',
      'es': 'Juegos eliminados con éxito de la biblioteca',
    },
    'Error al eliminar juegos:': {
      'en': 'Error deleting games:',
      'es': 'Error al eliminar juegos:',
    },
    '¿Eliminar juegos seleccionados?': {
      'en': 'Delete selected games?',
      'es': '¿Eliminar juegos seleccionados?',
    },

    // Steam Dependencies Dialog
    'Requerimientos de Steam Export': {
      'en': 'Steam Export Requirements',
      'es': 'Requerimientos de Steam Export',
    },
    'Para exportar tus juegos a Steam se necesitan dependencias adicionales en tu sistema:': {
      'en': 'To export your games to Steam, additional dependencies are needed on your system:',
      'es': 'Para exportar tus juegos a Steam se necesitan dependencias adicionales en tu sistema:',
    },
    'Motor para ejecutar los scripts de sincronización.': {
      'en': 'Engine to run synchronization scripts.',
      'es': 'Motor para ejecutar los scripts de sincronización.',
    },
    'Permite leer y escribir el formato de archivos de Steam.': {
      'en': 'Allows reading and writing Steam file format.',
      'es': 'Permite leer y escribir el formato de archivos de Steam.',
    },
    'Necesaria para procesar y convertir las imágenes de carátulas.': {
      'en': 'Needed to process and convert cover images.',
      'es': 'Necesaria para procesar y convertir las imágenes de carátulas.',
    },
    'Comandos de instalación por distribución:': {
      'en': 'Installation commands by distribution:',
      'es': 'Comandos de instalación por distribución:',
    },
    'Nota: Actualmente solo se detecta la versión Nativa de Steam. Si usas Steam vía Flatpak, el soporte se añadirá próximamente.': {
      'en': 'Note: Currently only the Native version of Steam is detected. Flatpak Steam support will be added soon.',
      'es': 'Nota: Actualmente solo se detecta la versión Nativa de Steam. Si usas Steam vía Flatpak, el soporte se añadirá próximamente.',
    },
    'Entendido': {
      'en': 'Understood',
      'es': 'Entendido',
    },
    'Comando copiado': {
      'en': 'Command copied',
      'es': 'Comando copiado',
    },

    // SteamGridDB Visual Selector
    'Configura tu API Key primero.': {
      'en': 'Configure your API Key first.',
      'es': 'Configura tu API Key primero.',
    },
    'Gestor Visual para: ': {
      'en': 'Visual Manager for: ',
      'es': 'Gestor Visual para: ',
    },
    '1. Buscar Juego': {
      'en': '1. Search Game',
      'es': '1. Buscar Juego',
    },
    'Nombre del juego en SteamGridDB': {
      'en': 'Game name on SteamGridDB',
      'es': 'Nombre del juego en SteamGridDB',
    },
    'No hay resultados.': {
      'en': 'No results.',
      'es': 'No hay resultados.',
    },
    'Primero selecciona un juego en la pestaña de búsqueda.': {
      'en': 'First select a game in the search tab.',
      'es': 'Primero selecciona un juego en la pestaña de búsqueda.',
    },
    'No se encontraron imágenes para este tipo.': {
      'en': 'No images found for this type.',
      'es': 'No se encontraron imágenes para este tipo.',
    },
    'Descargando y aplicando ': {
      'en': 'Downloading and applying ',
      'es': 'Descargando y aplicando ',
    },
    ' aplicado correctamente en Lutris.': {
      'en': ' applied successfully in Lutris.',
      'es': ' aplicado correctamente en Lutris.',
    },
    ' actualizado.': {
      'en': ' updated.',
      'es': ' actualizado.',
    },
    'No se pudo descargar ': {
      'en': 'Could not download ',
      'es': 'No se pudo descargar ',
    },
    'Error aplicando ': {
      'en': 'Error applying ',
      'es': 'Error aplicando ',
    },

    // Onboarding Screen
    'No se pudo abrir el enlace: ': {
      'en': 'Could not open link: ',
      'es': 'No se pudo abrir el enlace: ',
    },
    'Bienvenido a Game Link': {
      'en': 'Welcome to Game Link',
      'es': 'Bienvenido a Game Link',
    },
    'Tu puente universal para gestionar ROMs, arte visual e integración con launchers.': {
      'en': 'Your universal bridge for managing ROMs, visual art, and launcher integration.',
      'es': 'Tu puente universal para gestionar ROMs, arte visual e integración con launchers.',
    },
    'Configuración de Media': {
      'en': 'Media Settings',
      'es': 'Configuración de Media',
    },
    'Para descargar carátulas y banners automáticamente, necesitas una API Key de SteamGridDB.': {
      'en': 'To download covers and banners automatically, you need a SteamGridDB API Key.',
      'es': 'Para descargar carátulas y banners automáticamente, necesitas una API Key de SteamGridDB.',
    },
    'STEAMGRIDDB API KEY (NECESARIO)': {
      'en': 'STEAMGRIDDB API KEY (REQUIRED)',
      'es': 'STEAMGRIDDB API KEY (NECESARIO)',
    },
    'Pega tu llave aquí...': {
      'en': 'Paste your key here...',
      'es': 'Pega tu llave aquí...',
    },
    'OBTENER LLAVE EN STEAMGRIDDB.COM': {
      'en': 'GET KEY AT STEAMGRIDDB.COM',
      'es': 'OBTENER LLAVE EN STEAMGRIDDB.COM',
    },
    'Alta Precisión (Opcional)': {
      'en': 'High Precision (Optional)',
      'es': 'Alta Precisión (Opcional)',
    },
    'ScreenScraper permite identificar ROMs por su firma (Hash). Esto aumenta drásticamente la precisión si tus archivos no tienen nombres perfectos.': {
      'en': 'ScreenScraper allows identifying ROMs by hash signature. This drastically increases accuracy if your files don\'t have perfect names.',
      'es': 'ScreenScraper permite identificar ROMs por su firma (Hash). Esto aumenta drásticamente la precisión si tus archivos no tienen nombres perfectos.',
    },
    '¡Todo listo!': {
      'en': 'All set!',
      'es': '¡Todo listo!',
    },
    'Ya puedes empezar a organizar tu biblioteca de juegos y emuladores.': {
      'en': 'You can now start organizing your game and emulator library.',
      'es': 'Ya puedes empezar a organizar tu biblioteca de juegos y emuladores.',
    },
    'EMPEZAR': {
      'en': 'START',
      'es': 'EMPEZAR',
    },

    // Injector Log Messages
    '[  WARN ] No hay ningún juego seleccionado para inyectar.': {
      'en': '[  WARN ] No games selected for injection.',
      'es': '[  WARN ] No hay ningún juego seleccionado para inyectar.',
    },
    '[  WARN ] Error al leer app.xml: ': {
      'en': '[  WARN ] Error reading app.xml: ',
      'es': '[  WARN ] Error al leer app.xml: ',
    },
    '[  WARN ] Error al obtener nombre desde meta.xml: ': {
      'en': '[  WARN ] Error getting name from meta.xml: ',
      'es': '[  WARN ] Error al obtener nombre desde meta.xml: ',
    },
    'Resolviendo nombres de juegos usando base de datos local No-Intro/Redump/MAME...': {
      'en': 'Resolving game names using local No-Intro/Redump/MAME database...',
      'es': 'Resolviendo nombres de juegos usando base de datos local No-Intro/Redump/MAME...',
    },
    '[  WARN ] No se pudo cargar la base de datos local para ': {
      'en': '[  WARN ] Could not load local database for ',
      'es': '[  WARN ] No se pudo cargar la base de datos local para ',
    },
    'Buscando en base de datos local ': {
      'en': 'Searching local database ',
      'es': 'Buscando en base de datos local ',
    },
    'lote': {
      'en': 'batch',
      'es': 'lote',
    },
    'de ': {
      'en': 'of ',
      'es': 'de ',
    },
    'Progreso offline: ': {
      'en': 'Offline progress: ',
      'es': 'Progreso offline: ',
    },
    'juegos procesados.': {
      'en': ' games processed.',
      'es': 'juegos procesados.',
    },
    '[  WARN ] Base de datos local no pudo identificar ': {
      'en': '[  WARN ] Local database could not identify ',
      'es': '[  WARN ] Base de datos local no pudo identificar ',
    },
    'juegos encontrados.': {
      'en': ' games found.',
      'es': 'juegos encontrados.',
    },
    'No se pudo abrir la URL: ': {
      'en': 'Could not open URL: ',
      'es': 'No se pudo abrir la URL: ',
    },

    // ROM Injector Log Messages
    '[  SKIP ] Extensión no válida para ': {
      'en': '[  SKIP ] Invalid extension for ',
      'es': '[  SKIP ] Extensión no válida para ',
    },
    '[  INFO ] Usando identificación previa: ': {
      'en': '[  INFO ] Using previous identification: ',
      'es': '[  INFO ] Usando identificación previa: ',
    },
    '[  INFO ] Nombre resuelto offline (DAT): ': {
      'en': '[  INFO ] Name resolved offline (DAT): ',
      'es': '[  INFO ] Nombre resuelto offline (DAT): ',
    },
    '[  WARN ] Error al resolver offline (DAT): ': {
      'en': '[  WARN ] Error resolving offline (DAT): ',
      'es': '[  WARN ] Error al resolver offline (DAT): ',
    },
    '[ SEARCH ] Identificando con alta precisión: ': {
      'en': '[ SEARCH ] Identifying with high precision: ',
      'es': '[ SEARCH ] Identificando con alta precisión: ',
    },
    '[  INFO ] Identificado: ': {
      'en': '[  INFO ] Identified: ',
      'es': '[  INFO ] Identificado: ',
    },
    '[  WARN ] No identificado por ScreenScraper, usando nombre de archivo': {
      'en': '[  WARN ] Not identified by ScreenScraper, using filename',
      'es': '[  WARN ] No identificado por ScreenScraper, usando nombre de archivo',
    },
    '[  WARN ] Error de identificación: ': {
      'en': '[  WARN ] Identification error: ',
      'es': '[  WARN ] Error de identificación: ',
    },
    '[ CLEAN ] Limpiando juegos antiguos de ': {
      'en': '[ CLEAN ] Cleaning old games from ',
      'es': '[ CLEAN ] Limpiando juegos antiguos de ',
    },
    '[  WARN ] No se pudo borrar ': {
      'en': '[  WARN ] Could not delete ',
      'es': '[  WARN ] No se pudo borrar ',
    },
    '[  FAIL ] No existe la carpeta: ': {
      'en': '[  FAIL ] Folder does not exist: ',
      'es': '[  FAIL ] No existe la carpeta: ',
    },
    '[  WARN ] No se encontraron archivos con las extensiones seleccionadas.': {
      'en': '[  WARN ] No files found with selected extensions.',
      'es': '[  WARN ] No se encontraron archivos con las extensiones seleccionadas.',
    },
    '[ START ] Inyectando juegos desde: ': {
      'en': '[ START ] Injecting games from: ',
      'es': '[ START ] Inyectando juegos desde: ',
    },
    '[  SKIP ] Saltando formato duplicado: ': {
      'en': '[  SKIP ] Skipping duplicate format: ',
      'es': '[  SKIP ] Saltando formato duplicado: ',
    },
    '[  SKIP ] Juego ya existe en Lutris: ': {
      'en': '[  SKIP ] Game already exists in Lutris: ',
      'es': '[  SKIP ] Juego ya existe en Lutris: ',
    },
    '[  DONE ] Agregado: ': {
      'en': '[  DONE ] Added: ',
      'es': '[  DONE ] Agregado: ',
    },
    '[  WARN ] Error con ': {
      'en': '[  WARN ] Error with ',
      'es': '[  WARN ] Error con ',
    },
    '[  DONE ] Inyección completa! ': {
      'en': '[  DONE ] Injection complete! ',
      'es': '[  DONE ] Inyección completa! ',
    },
    'juegos nuevos agregados.': {
      'en': 'new games added.',
      'es': 'juegos nuevos agregados.',
    },
    'Se encontraron ': {
      'en': 'Found ',
      'es': 'Se encontraron ',
    },
    'errores': {
      'en': 'errors',
      'es': 'errores',
    },
    '[  FILE ] ': {
      'en': '[  FILE ] ',
      'es': '[  FILE ] ',
    },
    ' usando ': {
      'en': ' using ',
      'es': ' usando ',
    },
    ' (ignorando: ': {
      'en': ' (ignoring: ',
      'es': ' (ignorando: ',
    },

    // Metadata Downloader Log Messages
    '[  WARN ] Error creando directorio ': {
      'en': '[  WARN ] Error creating directory ',
      'es': '[  WARN ] Error creando directorio ',
    },
    '[  WARN ] Error descargando ': {
      'en': '[  WARN ] Error downloading ',
      'es': '[  WARN ] Error descargando ',
    },
    '[  FAIL ] No hay API Key configurada': {
      'en': '[  FAIL ] No API Key configured',
      'es': '[  FAIL ] No hay API Key configurada',
    },
    '[ SEARCH ] Descargando metadatos para: ': {
      'en': '[ SEARCH ] Downloading metadata for: ',
      'es': '[ SEARCH ] Descargando metadatos para: ',
    },
    '[  WARN ] No se encontraron juegos instalados para ': {
      'en': '[  WARN ] No installed games found for ',
      'es': '[  WARN ] No se encontraron juegos instalados para ',
    },
    '[  SKIP ] Saltando ': {
      'en': '[  SKIP ] Skipping ',
      'es': '[  SKIP ] Saltando ',
    },
    ' (Ya existe)': {
      'en': ' (Already exists)',
      'es': ' (Ya existe)',
    },
    '[ SEARCH ] Procesando: ': {
      'en': '[ SEARCH ] Processing: ',
      'es': '[ SEARCH ] Procesando: ',
    },
    '   [  DONE ] Encontrado: ': {
      'en': '   [  DONE ] Found: ',
      'es': '   [  DONE ] Encontrado: ',
    },
    '   [  FAIL ] No se encontró en SteamGridDB': {
      'en': '   [  FAIL ] Not found on SteamGridDB',
      'es': '   [  FAIL ] No se encontró en SteamGridDB',
    },
    '[  DONE ] ¡Completado!': {
      'en': '[  DONE ] Completed!',
      'es': '[  DONE ] ¡Completado!',
    },

    // ScreenScraper Service Messages
    'Tu aplicación ha sido bloqueada por ScreenScraper. Contacta con soporte.': {
      'en': 'Your application has been blocked by ScreenScraper. Contact support.',
      'es': 'Tu aplicación ha sido bloqueada por ScreenScraper. Contacta con soporte.',
    },
    'Demasiadas peticiones simultáneas. Reduciendo velocidad...': {
      'en': 'Too many simultaneous requests. Reducing speed...',
      'es': 'Demasiadas peticiones simultáneas. Reduciendo velocidad...',
    },
    'Has excedido tu límite diario de peticiones. Intenta mañana.': {
      'en': 'You have exceeded your daily request limit. Try again tomorrow.',
      'es': 'Has excedido tu límite diario de peticiones. Intenta mañana.',
    },
    'Demasiadas ROMs no reconocidas. Verifica tus archivos.': {
      'en': 'Too many unrecognized ROMs. Check your files.',
      'es': 'Demasiadas ROMs no reconocidas. Verifica tus archivos.',
    },
    '[  WARN ] ScreenScraper: Credenciales de desarrollador no configuradas en .env': {
      'en': '[  WARN ] ScreenScraper: Developer credentials not configured in .env',
      'es': '[  WARN ] ScreenScraper: Credenciales de desarrollador no configuradas en .env',
    },
    '[  FAIL ] Error obteniendo quota: ': {
      'en': '[  FAIL ] Error getting quota: ',
      'es': '[  FAIL ] Error obteniendo quota: ',
    },
    'Credenciales de desarrollador no configuradas': {
      'en': 'Developer credentials not configured',
      'es': 'Credenciales de desarrollador no configuradas',
    },
    'No se pudo verificar tu quota. Verifica tus credenciales.': {
      'en': 'Could not verify your quota. Check your credentials.',
      'es': 'No se pudo verificar tu quota. Verifica tus credenciales.',
    },
    'Has excedido tu límite diario (': {
      'en': 'You have exceeded your daily limit (',
      'es': 'Has excedido tu límite diario (',
    },
    ' requests disponibles para ': {
      'en': ' requests available for ',
      'es': ' requests disponibles para ',
    },
    ' ROMs. Algunas no serán identificadas.': {
      'en': ' ROMs. Some will not be identified.',
      'es': ' ROMs. Algunas no serán identificadas.',
    },
    ' requests disponibles': {
      'en': ' requests available',
      'es': ' requests disponibles',
    },
    'Petición inválida. Verifica los parámetros.': {
      'en': 'Invalid request. Check the parameters.',
      'es': 'Petición inválida. Verifica los parámetros.',
    },
    'API temporalmente cerrada por saturación del servidor.': {
      'en': 'API temporarily closed due to server overload.',
      'es': 'API temporalmente cerrada por saturación del servidor.',
    },
    'Credenciales incorrectas. Verifica tu usuario y contraseña.': {
      'en': 'Incorrect credentials. Check your username and password.',
      'es': 'Credenciales incorrectas. Verifica tu usuario y contraseña.',
    },
    'API caída temporalmente. Intenta más tarde.': {
      'en': 'API temporarily down. Try again later.',
      'es': 'API caída temporalmente. Intenta más tarde.',
    },
    'Error del servidor ScreenScraper (': {
      'en': 'ScreenScraper server error (',
      'es': 'Error del servidor ScreenScraper (',
    },
    'Error desconocido: ': {
      'en': 'Unknown error: ',
      'es': 'Error desconocido: ',
    },
    '[  WARN ] Error ': {
      'en': '[  WARN ] Error ',
      'es': '[  WARN ] Error ',
    },
    ', reintentando en ': {
      'en': ', retrying in ',
      'es': ', reintentando en ',
    },
    's (intento ': {
      'en': 's (attempt ',
      'es': 's (intento ',
    },
    '[  WARN ] Error de conexión, reintentando en ': {
      'en': '[  WARN ] Connection error, retrying in ',
      'es': '[  WARN ] Error de conexión, reintentando en ',
    },
    'Credenciales de desarrollador no configuradas. Verifica el archivo .env': {
      'en': 'Developer credentials not configured. Check the .env file',
      'es': 'Credenciales de desarrollador no configuradas. Verifica el archivo .env',
    },
    '[  SKIP ] Saltando request a ScreenScraper (falló recientemente)': {
      'en': '[  SKIP ] Skipping ScreenScraper request (recently failed)',
      'es': '[  SKIP ] Saltando request a ScreenScraper (falló recientemente)',
    },
    '[  INFO ] Cache en memoria para ': {
      'en': '[  INFO ] Memory cache for ',
      'es': '[  INFO ] Cache en memoria para ',
    },
    '[  DISK ] Cache en disco (miss) para ': {
      'en': '[  DISK ] Disk cache (miss) for ',
      'es': '[  DISK ] Cache en disco (miss) para ',
    },
    '[  DISK ] Cache en disco para ': {
      'en': '[  DISK ] Disk cache for ',
      'es': '[  DISK ] Cache en disco para ',
    },
    '[  FAIL ] Error identificando juego: ': {
      'en': '[  FAIL ] Error identifying game: ',
      'es': '[  FAIL ] Error identificando juego: ',
    },
    'Archivo no encontrado: ': {
      'en': 'File not found: ',
      'es': 'Archivo no encontrado: ',
    },
    '[  FAIL ] Error identificando archivo ': {
      'en': '[  FAIL ] Error identifying file ',
      'es': '[  FAIL ] Error identificando archivo ',
    },
    '[ CLEAN ] Cache de ScreenScraper limpiado': {
      'en': '[ CLEAN ] ScreenScraper cache cleared',
      'es': '[ CLEAN ] Cache de ScreenScraper limpiado',
    },

    // Config Manager
    'Error leyendo configuración: ': {
      'en': 'Error reading configuration: ',
      'es': 'Error leyendo configuración: ',
    },

    // ROM Batch Service
    '[  WARN ] Plataforma no soportada: ': {
      'en': '[  WARN ] Unsupported platform: ',
      'es': '[  WARN ] Plataforma no soportada: ',
    },
    '[  WARN ] Carpeta no existe: ': {
      'en': '[  WARN ] Folder does not exist: ',
      'es': '[  WARN ] Carpeta no existe: ',
    },
    '[  WARN ] No hay items seleccionados para procesar': {
      'en': '[  WARN ] No items selected for processing',
      'es': '[  WARN ] No hay items seleccionados para procesar',
    },
    '[ START ] Procesando ': {
      'en': '[ START ] Processing ',
      'es': '[ START ] Procesando ',
    },
    ' ROMs en batch...': {
      'en': ' ROMs in batch...',
      'es': ' ROMs en batch...',
    },
    '[  SKIP ] Archivo no existe: ': {
      'en': '[  SKIP ] File does not exist: ',
      'es': '[  SKIP ] Archivo no existe: ',
    },
    'Progreso: ': {
      'en': 'Progress: ',
      'es': 'Progreso: ',
    },
    '[  SKIP ] Plataforma sin soporte ScreenScraper: ': {
      'en': '[  SKIP ] Platform without ScreenScraper support: ',
      'es': '[  SKIP ] Plataforma sin soporte ScreenScraper: ',
    },
    '[ SEARCH ] Identificando: ': {
      'en': '[ SEARCH ] Identifying: ',
      'es': '[ SEARCH ] Identificando: ',
    },
    '[  WARN ] No identificado: ': {
      'en': '[  WARN ] Not identified: ',
      'es': '[  WARN ] No identificado: ',
    },
    '[  FAIL ] Error procesando ': {
      'en': '[  FAIL ] Error processing ',
      'es': '[  FAIL ] Error procesando ',
    },
    '[  DONE ] Procesamiento batch completado: ': {
      'en': '[  DONE ] Batch processing completed: ',
      'es': '[  DONE ] Procesamiento batch completado: ',
    },

    // DAT Resolver
    '[  INFO ] Descargando base de datos para ': {
      'en': '[  INFO ] Downloading database for ',
      'es': '[  INFO ] Descargando base de datos para ',
    },
    ' desde GitHub...': {
      'en': ' from GitHub...',
      'es': ' desde GitHub...',
    },
    '[  DONE ] Base de datos de ': {
      'en': '[  DONE ] Database for ',
      'es': '[  DONE ] Base de datos de ',
    },
    ' guardada localmente.': {
      'en': ' saved locally.',
      'es': ' guardada localmente.',
    },
    '[  FAIL ] Error al descargar base de datos de GitHub (status: ': {
      'en': '[  FAIL ] Error downloading database from GitHub (status: ',
      'es': '[  FAIL ] Error al descargar base de datos de GitHub (status: ',
    },
    '[  FAIL ] Error de red descargando base de datos: ': {
      'en': '[  FAIL ] Network error downloading database: ',
      'es': '[  FAIL ] Error de red descargando base de datos: ',
    },
    '[  FAIL ] Error leyendo/parseando archivos DAT combinados para GB: ': {
      'en': '[  FAIL ] Error reading/parsing combined DAT files for GB: ',
      'es': '[  FAIL ] Error leyendo/parseando archivos DAT combinados para GB: ',
    },
    '[  FAIL ] Error leyendo/parseando el archivo DAT para ': {
      'en': '[  FAIL ] Error reading/parsing DAT file for ',
      'es': '[  FAIL ] Error leyendo/parseando el archivo DAT para ',
    },

    // ROM Cache Repository
    '[  WARN ] Error verificando cache ROM: ': {
      'en': '[  WARN ] Error checking ROM cache: ',
      'es': '[  WARN ] Error verificando cache ROM: ',
    },
    '[  WARN ] Error guardando cache ROM: ': {
      'en': '[  WARN ] Error saving ROM cache: ',
      'es': '[  WARN ] Error guardando cache ROM: ',
    },
    '[  WARN ] Error buscando por nombre: ': {
      'en': '[  WARN ] Error searching by name: ',
      'es': '[  WARN ] Error buscando por nombre: ',
    },
    '[  WARN ] Error limpiando cache ROM: ': {
      'en': '[  WARN ] Error cleaning ROM cache: ',
      'es': '[  WARN ] Error limpiando cache ROM: ',
    },

    // SteamGridDB Service
    'SteamGridDB API Key inválida o sin permisos': {
      'en': 'SteamGridDB API Key invalid or without permissions',
      'es': 'SteamGridDB API Key inválida o sin permisos',
    },

    // Steam Shortcuts Service
    'No se pudo actualizar shortcuts.vdf: ': {
      'en': 'Could not update shortcuts.vdf: ',
      'es': 'No se pudo actualizar shortcuts.vdf: ',
    },
    'No hubo respuesta al actualizar shortcuts.vdf.': {
      'en': 'No response when updating shortcuts.vdf.',
      'es': 'No hubo respuesta al actualizar shortcuts.vdf.',
    },
    'No se pudo leer shortcuts.vdf: ': {
      'en': 'Could not read shortcuts.vdf: ',
      'es': 'No se pudo leer shortcuts.vdf: ',
    },
    'No se pudo depurar shortcuts.vdf: ': {
      'en': 'Could not debug shortcuts.vdf: ',
      'es': 'No se pudo depurar shortcuts.vdf: ',
    },

    // Steam Collections Service
    'Formato inesperado en cloud-storage-namespace-1.json': {
      'en': 'Unexpected format in cloud-storage-namespace-1.json',
      'es': 'Formato inesperado en cloud-storage-namespace-1.json',
    },
    'Coleccion con formato invalido: ': {
      'en': 'Collection with invalid format: ',
      'es': 'Coleccion con formato invalido: ',
    },

    // Steam Export Service
    'No se detecto una instalacion valida de Steam.': {
      'en': 'No valid Steam installation detected.',
      'es': 'No se detecto una instalacion valida de Steam.',
    },
    'Falta dependencia python-vdf. Instala con: pip install vdf': {
      'en': 'Missing dependency python-vdf. Install with: pip install vdf',
      'es': 'Falta dependencia python-vdf. Instala con: pip install vdf',
    },
    'Falta dependencia Pillow. Instala con: pip install pillow': {
      'en': 'Missing dependency Pillow. Install with: pip install pillow',
      'es': 'Falta dependencia Pillow. Instala con: pip install pillow',
    },
    'Exportado a Steam: ': {
      'en': 'Exported to Steam: ',
      'es': 'Exportado a Steam: ',
    },
    'Error exportando ': {
      'en': 'Error exporting ',
      'es': 'Error exportando ',
    },

    // Steam Dependencies Dialog
    'Librería vdf': {
      'en': 'vdf library',
      'es': 'Librería vdf',
    },
    'Librería Pillow (PIL)': {
      'en': 'Pillow library (PIL)',
      'es': 'Librería Pillow (PIL)',
    },
    'Ningún item requiere identificación - usando solo cache': {
      'en': 'No item requires identification - using only cache',
      'es': 'Ningún item requiere identificación - usando solo cache',
    },
    '[  INFO ] Encontrados ': {
      'en': '[  INFO ] Found ',
      'es': '[  INFO ] Encontrados ',
    },
    ' ROMs en ': {
      'en': ' ROMs in ',
      'es': ' ROMs en ',
    },
    ' plataformas': {
      'en': ' platforms',
      'es': ' plataformas',
    },
  };
}

extension StringI18n on String {
  String t() => I18n.translate(this);
}
