// lib/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'masterclass_home_screen.dart'; // Import du nouveau homescreen masterclass

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      splash: Image.asset(
          'assets/images/logo.png'), // Le logo que tu as ajouté dans les assets
      splashIconSize: 400, // La taille de l'icône/logo
      nextScreen:
          const MasterclassHomeScreen(), // Le nouveau homescreen avec toutes les fonctionnalités masterclass
      splashTransition: SplashTransition
          .scaleTransition, // Type de transition (ici un effet de mise à l'échelle)
      backgroundColor:
          Colors.black54, // Couleur d'arrière-plan du splash screen
      duration: 3000, // Durée de l'animation en millisecondes (ici, 3 secondes)
    );
  }
}
