import 'package:flutter/material.dart';
import 'package:mon_app/screens/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

/// Point d'entrée de l'application
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '2Block Player',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF000000),
        primaryColor: const Color(0xFF7C4DFF),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF7C4DFF),
          secondary: Color(0xFF00B8D4),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
