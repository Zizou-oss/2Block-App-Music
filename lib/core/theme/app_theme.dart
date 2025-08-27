import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // Couleurs principales
  static const Color primaryGreen = Color(0xFF1DB954);
  static const Color primaryGreenDark = Color(0xFF1ed760);
  static const Color primaryGreenLight = Color(0xFF1fdf64);
  
  // Couleurs sombres
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF212121);
  static const Color darkCard = Color(0xFF2A2A2A);
  static const Color darkElement = Color(0xFF3A3A3A);
  
  // Couleurs claires
  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFF5F5F5);
  static const Color lightElement = Color(0xFFE0E0E0);
  
  // Couleurs d'accent
  static const Color accentBlue = Color(0xFF2196F3);
  static const Color accentPurple = Color(0xFF9C27B0);
  static const Color accentOrange = Color(0xFFFF9800);
  static const Color accentRed = Color(0xFFF44336);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryGreen, primaryGreenLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient darkGradient = LinearGradient(
    colors: [darkBackground, darkSurface],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient lightGradient = LinearGradient(
    colors: [lightBackground, lightSurface],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Thème sombre
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryGreen,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: primaryGreen,
        primaryContainer: primaryGreenDark,
        secondary: accentBlue,
        secondaryContainer: accentPurple,
        surface: darkSurface,
        surfaceVariant: darkCard,
        background: darkBackground,
        error: accentRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onBackground: Colors.white,
        onError: Colors.white,
      ),
      
      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: Colors.white),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      
      // Cards
      cardTheme: CardTheme(
        color: darkCard,
        elevation: 8,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      
      // Boutons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: primaryGreen.withOpacity(0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      
      // Texte
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
        bodySmall: TextStyle(color: Colors.white60),
        labelLarge: TextStyle(color: Colors.white),
        labelMedium: TextStyle(color: Colors.white70),
        labelSmall: TextStyle(color: Colors.white60),
      ),
      
      // Sliders
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryGreen,
        inactiveTrackColor: Colors.grey[800],
        thumbColor: primaryGreen,
        overlayColor: primaryGreen.withOpacity(0.2),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        trackHeight: 4,
      ),
      
      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: Colors.grey),
      ),
      
      // Navigation
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: primaryGreen,
        unselectedItemColor: Colors.grey,
        elevation: 8,
      ),
    );
  }

  // Thème clair
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryGreen,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme.light(
        primary: primaryGreen,
        primaryContainer: primaryGreenLight,
        secondary: accentBlue,
        secondaryContainer: accentPurple,
        surface: lightSurface,
        surfaceVariant: lightCard,
        background: lightBackground,
        error: accentRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.black87,
        onBackground: Colors.black87,
        onError: Colors.white,
      ),
      
      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.black87,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: Colors.black87),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      
      // Cards
      cardTheme: CardTheme(
        color: lightCard,
        elevation: 4,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      
      // Boutons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: primaryGreen.withOpacity(0.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      
      // Texte
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        headlineMedium: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: Colors.black87),
        bodyMedium: TextStyle(color: Colors.black54),
        bodySmall: TextStyle(color: Colors.black45),
        labelLarge: TextStyle(color: Colors.black87),
        labelMedium: TextStyle(color: Colors.black54),
        labelSmall: TextStyle(color: Colors.black45),
      ),
      
      // Sliders
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryGreen,
        inactiveTrackColor: Colors.grey[300],
        thumbColor: primaryGreen,
        overlayColor: primaryGreen.withOpacity(0.1),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        trackHeight: 4,
      ),
      
      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: Colors.grey),
      ),
      
      // Navigation
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: lightSurface,
        selectedItemColor: primaryGreen,
        unselectedItemColor: Colors.grey,
        elevation: 8,
      ),
    );
  }

  // Thème personnalisé avec couleur d'accent
  static ThemeData customTheme(Color accentColor, {bool isDark = true}) {
    final baseTheme = isDark ? darkTheme : lightTheme;
    
    return baseTheme.copyWith(
      primaryColor: accentColor,
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: accentColor,
        primaryContainer: accentColor.withOpacity(0.8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: baseTheme.elevatedButtonTheme.style?.copyWith(
          backgroundColor: MaterialStateProperty.all(accentColor),
        ),
      ),
      sliderTheme: baseTheme.sliderTheme.copyWith(
        activeTrackColor: accentColor,
        thumbColor: accentColor,
        overlayColor: accentColor.withOpacity(0.2),
      ),
    );
  }
}

// Extensions pour faciliter l'utilisation
extension ThemeExtension on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  bool get isLight => !isDark;
}