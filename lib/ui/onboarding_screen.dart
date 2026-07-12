import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/lutris/config_manager.dart';
import '../core/lutris/translation_manager.dart';
import 'main_window.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _ssUserController = TextEditingController();
  final TextEditingController _ssPasswordController = TextEditingController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    _apiKeyController.dispose();
    _ssUserController.dispose();
    _ssPasswordController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'No se pudo abrir el enlace: '.t()}$url')),
        );
      }
    }
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    final key = _apiKeyController.text.trim();
    final ssUser = _ssUserController.text.trim();
    final ssPass = _ssPasswordController.text;

    if (key.isNotEmpty) await ConfigManager.saveApiKey(key);
    if (ssUser.isNotEmpty && ssPass.isNotEmpty) {
      await ConfigManager.saveSSCredentials(ssUser, ssPass);
    }

    await ConfigManager.setFirstRunCompleted();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainWindow()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (page) => setState(() => _currentPage = page),
            children: [
              _buildWelcomePage(),
              _buildSetupPage(),
              _buildScreenScraperPage(),
              _buildFinalPage(),
            ],
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: _buildFooter(),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/icon.png', width: 180, height: 180),
          const SizedBox(height: 60),
          Text(
            'Bienvenido a Game Link'.t(),
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            'Tu puente universal para gestionar ROMs, arte visual e integración con launchers.'.t(),
            style: const TextStyle(color: Colors.white38, fontSize: 16, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSetupPage() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configuración de Media'.t(),
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Para descargar carátulas y banners automáticamente, necesitas una API Key de SteamGridDB.'.t(),
            style: const TextStyle(color: Colors.white38, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 32),
          Text('STEAMGRIDDB API KEY (NECESARIO)'.t(), style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 12),
          TextField(
            controller: _apiKeyController,
            obscureText: true,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Pega tu llave aquí...'.t(),
              filled: true,
              fillColor: const Color(0xFF0A0A0A),
              prefixIcon: const Icon(Icons.vpn_key_outlined, color: Colors.white24, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1A1A1A))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1A1A1A))),
            ),
          ),
          const SizedBox(height: 24),
          InkWell(
            onTap: () => _launchUrl('https://www.steamgriddb.com/profile/preferences/api'),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.open_in_new, color: Colors.white70, size: 14),
                  const SizedBox(width: 8),
                  Text(
                    'OBTENER LLAVE EN STEAMGRIDDB.COM'.t(),
                    style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScreenScraperPage() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Alta Precisión (Opcional)'.t(),
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'ScreenScraper permite identificar ROMs por su firma (Hash). Esto aumenta drásticamente la precisión si tus archivos no tienen nombres perfectos.'.t(),
            style: const TextStyle(color: Colors.white38, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 32),
          Text('USUARIO'.t(), style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 12),
          TextField(
            controller: _ssUserController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Usuario...'.t(),
              filled: true,
              fillColor: const Color(0xFF0A0A0A),
              prefixIcon: const Icon(Icons.person_outline, color: Colors.white24, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1A1A1A))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1A1A1A))),
            ),
          ),
          const SizedBox(height: 16),
          Text('CONTRASEÑA'.t(), style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 12),
          TextField(
            controller: _ssPasswordController,
            obscureText: true,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Contraseña...'.t(),
              filled: true,
              fillColor: const Color(0xFF0A0A0A),
              prefixIcon: const Icon(Icons.lock_outline, color: Colors.white24, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1A1A1A))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1A1A1A))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalPage() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.white10, size: 100),
          const SizedBox(height: 40),
          Text(
            '¡Todo listo!'.t(),
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Text(
            'Ya puedes empezar a organizar tu biblioteca de juegos y emuladores.'.t(),
            style: const TextStyle(color: Colors.white38, fontSize: 16, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Indicadores de página
          Row(
            children: List.generate(4, (index) => Container(
              width: 8, height: 8,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentPage == index ? Colors.white : Colors.white10,
              ),
            )),
          ),
          // Botón Siguiente/Empezar
          TextButton(
            onPressed: _nextPage,
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            child: Text(
              _currentPage == 3 ? 'EMPEZAR'.t() : 'CONTINUAR'.t(),
              style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ),
        ],
      ),
    );
  }
}
