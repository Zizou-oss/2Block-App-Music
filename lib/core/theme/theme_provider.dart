import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_theme.dart';

enum ThemeMode { light, dark, system }
enum AccentColor { green, blue, purple, orange, red }

class ThemeProvider extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  static const String _accentColorKey = 'accent_color';
  static const String _customColorKey = 'custom_color';
  
  ThemeMode _themeMode = ThemeMode.system;
  AccentColor _accentColor = AccentColor.green;
  Color? _customAccentColor;
  
  ThemeMode get themeMode => _themeMode;
  AccentColor get accentColor => _accentColor;
  Color? get customAccentColor => _customAccentColor;
  
  // Getters pour les thèmes
  ThemeData get lightTheme {
    if (_customAccentColor != null) {
      return AppTheme.customTheme(_customAccentColor!, isDark: false);
    }
    switch (_accentColor) {
      case AccentColor.green:
        return AppTheme.lightTheme;
      case AccentColor.blue:
        return AppTheme.customTheme(AppTheme.accentBlue, isDark: false);
      case AccentColor.purple:
        return AppTheme.customTheme(AppTheme.accentPurple, isDark: false);
      case AccentColor.orange:
        return AppTheme.customTheme(AppTheme.accentOrange, isDark: false);
      case AccentColor.red:
        return AppTheme.customTheme(AppTheme.accentRed, isDark: false);
    }
  }
  
  ThemeData get darkTheme {
    if (_customAccentColor != null) {
      return AppTheme.customTheme(_customAccentColor!, isDark: true);
    }
    switch (_accentColor) {
      case AccentColor.green:
        return AppTheme.darkTheme;
      case AccentColor.blue:
        return AppTheme.customTheme(AppTheme.accentBlue, isDark: true);
      case AccentColor.purple:
        return AppTheme.customTheme(AppTheme.accentPurple, isDark: true);
      case AccentColor.orange:
        return AppTheme.customTheme(AppTheme.accentOrange, isDark: true);
      case AccentColor.red:
        return AppTheme.customTheme(AppTheme.accentRed, isDark: true);
    }
  }
  
  // Changer le mode de thème
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _updateSystemUI();
    notifyListeners();
    _saveThemeMode();
  }
  
  // Changer la couleur d'accent
  void setAccentColor(AccentColor color) {
    _accentColor = color;
    _customAccentColor = null; // Reset custom color
    _updateSystemUI();
    notifyListeners();
    _saveAccentColor();
  }
  
  // Définir une couleur personnalisée
  void setCustomAccentColor(Color color) {
    _customAccentColor = color;
    _updateSystemUI();
    notifyListeners();
    _saveCustomColor();
  }
  
  // Obtenir la couleur d'accent actuelle
  Color get currentAccentColor {
    if (_customAccentColor != null) return _customAccentColor!;
    
    switch (_accentColor) {
      case AccentColor.green:
        return AppTheme.primaryGreen;
      case AccentColor.blue:
        return AppTheme.accentBlue;
      case AccentColor.purple:
        return AppTheme.accentPurple;
      case AccentColor.orange:
        return AppTheme.accentOrange;
      case AccentColor.red:
        return AppTheme.accentRed;
    }
  }
  
  // Mise à jour de l'UI système
  void _updateSystemUI() {
    final brightness = _getCurrentBrightness();
    
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: brightness == Brightness.dark 
          ? Brightness.light 
          : Brightness.dark,
      statusBarBrightness: brightness,
      systemNavigationBarColor: brightness == Brightness.dark 
          ? AppTheme.darkBackground 
          : AppTheme.lightBackground,
      systemNavigationBarIconBrightness: brightness == Brightness.dark 
          ? Brightness.light 
          : Brightness.dark,
    ));
  }
  
  Brightness _getCurrentBrightness() {
    switch (_themeMode) {
      case ThemeMode.light:
        return Brightness.light;
      case ThemeMode.dark:
        return Brightness.dark;
      case ThemeMode.system:
        return WidgetsBinding.instance.platformDispatcher.platformBrightness;
    }
  }
  
  // Sauvegarde persistante (simulation - remplacer par SharedPreferences)
  void _saveThemeMode() {
    // SharedPreferences.getInstance().then((prefs) {
    //   prefs.setString(_themeModeKey, _themeMode.name);
    // });
  }
  
  void _saveAccentColor() {
    // SharedPreferences.getInstance().then((prefs) {
    //   prefs.setString(_accentColorKey, _accentColor.name);
    // });
  }
  
  void _saveCustomColor() {
    // SharedPreferences.getInstance().then((prefs) {
    //   if (_customAccentColor != null) {
    //     prefs.setInt(_customColorKey, _customAccentColor!.value);
    //   } else {
    //     prefs.remove(_customColorKey);
    //   }
    // });
  }
  
  // Chargement des préférences (simulation)
  Future<void> loadPreferences() async {
    // final prefs = await SharedPreferences.getInstance();
    
    // // Charger le mode de thème
    // final themeModeString = prefs.getString(_themeModeKey);
    // if (themeModeString != null) {
    //   _themeMode = ThemeMode.values.firstWhere(
    //     (mode) => mode.name == themeModeString,
    //     orElse: () => ThemeMode.system,
    //   );
    // }
    
    // // Charger la couleur d'accent
    // final accentColorString = prefs.getString(_accentColorKey);
    // if (accentColorString != null) {
    //   _accentColor = AccentColor.values.firstWhere(
    //     (color) => color.name == accentColorString,
    //     orElse: () => AccentColor.green,
    //   );
    // }
    
    // // Charger la couleur personnalisée
    // final customColorValue = prefs.getInt(_customColorKey);
    // if (customColorValue != null) {
    //   _customAccentColor = Color(customColorValue);
    // }
    
    _updateSystemUI();
    notifyListeners();
  }
  
  // Réinitialiser aux valeurs par défaut
  void resetToDefaults() {
    _themeMode = ThemeMode.system;
    _accentColor = AccentColor.green;
    _customAccentColor = null;
    _updateSystemUI();
    notifyListeners();
    _saveThemeMode();
    _saveAccentColor();
    _saveCustomColor();
  }
  
  // Obtenir le nom de la couleur d'accent
  String get accentColorName {
    if (_customAccentColor != null) return 'Personnalisé';
    
    switch (_accentColor) {
      case AccentColor.green:
        return 'Vert Spotify';
      case AccentColor.blue:
        return 'Bleu';
      case AccentColor.purple:
        return 'Violet';
      case AccentColor.orange:
        return 'Orange';
      case AccentColor.red:
        return 'Rouge';
    }
  }
  
  // Obtenir le nom du mode de thème
  String get themeModeName {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Clair';
      case ThemeMode.dark:
        return 'Sombre';
      case ThemeMode.system:
        return 'Système';
    }
  }
  
  // Animations de transition
  void animateThemeChange(VoidCallback onComplete) {
    // Animation de transition lors du changement de thème
    onComplete();
  }
}