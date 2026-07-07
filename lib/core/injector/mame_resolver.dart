import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../lutris/config_manager.dart';

class MameResolver {
  /// Localiza el binario de MAME de forma automática.
  static Future<String?> findMameBinary() async {
    // 1. Verificar ruta personalizada en la configuración.
    try {
      final configPath = await ConfigManager.getMameBinaryPath();
      if (configPath.isNotEmpty && File(configPath).existsSync()) {
        return configPath;
      }
    } catch (_) {}

    // 2. Verificar ruta específica del usuario.
    final home = Platform.environment['HOME'] ?? '';
    if (home.isNotEmpty) {
      final appImageSpec = p.join(home, 'AppImages', 'mame_arcade_emulator.appimage');
      if (File(appImageSpec).existsSync()) {
        return appImageSpec;
      }

      // Buscar en el directorio AppImages cualquier archivo con "mame"
      final appImagesDir = Directory(p.join(home, 'AppImages'));
      if (appImagesDir.existsSync()) {
        try {
          final files = appImagesDir.listSync().whereType<File>();
          for (final f in files) {
            final name = p.basename(f.path).toLowerCase();
            if (name.contains('mame') &&
                (name.endsWith('.appimage') || !name.contains('.'))) {
              return f.path;
            }
          }
        } catch (_) {}
      }
    }

    // 3. Rutas comunes del sistema
    final commonPaths = [
      '/usr/games/mame',
      '/usr/bin/mame',
      '/usr/local/bin/mame',
      '/usr/games/mame/mame',
    ];
    for (final path in commonPaths) {
      if (File(path).existsSync()) {
        return path;
      }
    }

    // 4. Buscar con 'which'
    try {
      final result = await Process.run('which', ['mame']);
      if (result.exitCode == 0) {
        final path = result.stdout.toString().trim();
        if (path.isNotEmpty && File(path).existsSync()) {
          return path;
        }
      }
    } catch (_) {}

    return null;
  }

  /// Limpia la descripción obtenida de MAME.
  static String cleanGameName(String description) {
    var name = description.trim();
    // Quitar comillas si están al principio y al final
    if (name.startsWith('"') && name.endsWith('"')) {
      name = name.substring(1, name.length - 1).trim();
    }
    // Eliminar contenido entre paréntesis recursivamente
    name = name.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
    // Eliminar contenido entre corchetes
    name = name.replaceAll(RegExp(r'\s*\[[^\]]*\]'), '').trim();
    return name;
  }

  /// Resuelve los nombres de una lista de ROMs (sin extensiones) usando MAME.
  static Future<Map<String, String>> resolveNames(List<String> romNames) async {
    final Map<String, String> results = {};
    if (romNames.isEmpty) return results;

    final mameBinary = await findMameBinary();
    if (mameBinary == null) {
      print('[  WARN ] No se encontró el binario de MAME para resolver nombres.');
      return results;
    }

    // Procesar en lotes (chunks) de 100 para evitar argumentos demasiado largos
    final chunkSize = 100;
    for (var i = 0; i < romNames.length; i += chunkSize) {
      final chunk = romNames.skip(i).take(chunkSize).toList();
      try {
        final processResult = await Process.run(
          mameBinary,
          ['-listfull', ...chunk],
          stdoutEncoding: utf8,
          stderrEncoding: utf8,
        );

        // Parsear tanto stdout como stderr ya que algunos mensajes/salidas pueden salir por ambos
        final output = '${processResult.stdout}\n${processResult.stderr}';
        final lines = LineSplitter.split(output);

        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.isEmpty || trimmed.startsWith('Name:') || trimmed.startsWith('self updates')) {
            continue;
          }

          // La línea tiene la estructura: slug [espacios] "Descripción"
          // Buscamos el primer espacio/tabulación
          final match = RegExp(r'^([a-zA-Z0-9_-]+)\s+(.+)$').firstMatch(trimmed);
          if (match != null) {
            final slug = match.group(1)!;
            final desc = match.group(2)!;
            results[slug] = cleanGameName(desc);
          }
        }
      } catch (e) {
        print('[  WARN ] Error ejecutando MAME para lote: $e');
      }
    }

    return results;
  }
}
