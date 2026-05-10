import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ui/main_window.dart';
import 'ui/onboarding_screen.dart';
import 'core/lutris/config_manager.dart';
import 'platforms/platform_registry.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  PlatformRegistry.initialize();
  runApp(const GameLinkApp());
}

class GameLinkApp extends StatelessWidget {
  const GameLinkApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Game Link',
      debugShowCheckedModeBanner: false,
      theme: FlexThemeData.light(
        scheme: FlexScheme.materialBaseline,
        surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
        blendLevel: 7,
        subThemesData: const FlexSubThemesData(
          blendOnLevel: 10,
          blendOnColors: false,
          useTextTheme: true,
          useM2StyleDividerInM3: true,
        ),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        useMaterial3: true,
        fontFamily: GoogleFonts.notoSans().fontFamily,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          surface: const Color(0xFF000000),
          onSurface: Colors.white,
          surfaceContainerHighest: const Color(0xFF121212),
          primary: Colors.white,
          onPrimary: Colors.black,
          secondary: const Color(0xFF2C2C2C),
          onSecondary: Colors.white,
          outline: const Color(0xFF333333),
          surfaceContainer: const Color(0xFF0A0A0A),
        ),
        scaffoldBackgroundColor: const Color(0xFF000000),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF000000),
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
          iconTheme: IconThemeData(color: Colors.white, size: 20),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF000000),
          indicatorColor: const Color(0xFF222222),
          labelTextStyle: MaterialStateProperty.all(
            const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white70),
          ),
          iconTheme: MaterialStateProperty.all(
            const IconThemeData(size: 20, color: Colors.white70),
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF0A0A0A),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFF1A1A1A)),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFF1A1A1A),
          thickness: 1,
          space: 1,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF121212),
          contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: Color(0xFF222222)),
          ),
          behavior: SnackBarBehavior.floating,
          elevation: 0,
        ),
        fontFamily: GoogleFonts.inter().fontFamily,
      ),
      themeMode: ThemeMode.dark,
      home: FutureBuilder<bool>(
        future: ConfigManager.isFirstRun(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Colors.black,
              body: Center(child: CircularProgressIndicator(color: Colors.white24)),
            );
          }
          if (snapshot.data == true) {
            return const OnboardingScreen();
          }
          return const MainWindow();
        },
      ),
    );
  }
}
