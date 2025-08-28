// lib/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'home_screen.dart'; // Assure-toi d'importer ton HomeScreen correctement

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      splash: Image.asset(
          'assets/images/logo.png'), // Le logo que tu as ajouté dans les assets
      splashIconSize: 400, // La taille de l'icône/logo
      nextScreen:
          const HomeScreen(), // L'écran qui sera affiché après l'animation (ici, ton HomeScreen)
      splashTransition: SplashTransition
          .scaleTransition, // Type de transition (ici un effet de mise à l'échelle)
      backgroundColor:
          Colors.black54, // Couleur d'arrière-plan du splash screen
      duration: 3000, // Durée de l'animation en millisecondes (ici, 3 secondes)
    );
  }
}
