import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/theme_provider.dart' as theme_provider;
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configuration de l'interface système
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  
  // Orientations supportées
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const MyApp());
}

/// Application principale avec gestionnaire de thèmes avancé
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final theme_provider.ThemeProvider _themeProvider = theme_provider.ThemeProvider();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _themeProvider.loadPreferences();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _themeProvider,
      builder: (context, child) {
        return MaterialApp(
          title: '2Block Player - Masterclass Edition',
          debugShowCheckedModeBanner: false,
          
          // Thèmes dynamiques
          theme: _themeProvider.lightTheme,
          darkTheme: _themeProvider.darkTheme,
          themeMode: _getThemeMode(),
          
          // Configuration de l'app
          home: const SplashScreen(),
          
          // Configuration du router (pour les futures routes)
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/':
                return MaterialPageRoute(
                  builder: (context) => const SplashScreen(),
                );
              default:
                return MaterialPageRoute(
                  builder: (context) => const SplashScreen(),
                );
            }
          },
          
          // Configuration globale
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaleFactor: MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.2),
              ),
              child: child!,
            );
          },
        );
      },
    );
  }

  ThemeMode _getThemeMode() {
    switch (_themeProvider.themeMode) {
      case theme_provider.ThemeMode.light:
        return ThemeMode.light;
      case theme_provider.ThemeMode.dark:
        return ThemeMode.dark;
      case theme_provider.ThemeMode.system:
        return ThemeMode.system;
    }
  }
}
