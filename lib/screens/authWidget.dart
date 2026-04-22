import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// Remplacez par vos propres chemins de fichiers
import 'package:mobil_audio_app/screens/statistique.dart'; 
import 'package:mobil_audio_app/authentification/login_screen.dart';

class AuthWidget extends StatelessWidget {
  const AuthWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Le StreamBuilder écoute en temps réel si l'utilisateur est connecté à Firebase [cite: 9]
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Si la connexion est établie avec succès
        if (snapshot.hasData) {
          // L'utilisateur accède à l'interface principale des statistiques [cite: 14]
          return const StatistiqueScreen(); 
        }
        // Sinon, l'utilisateur est redirigé vers le système d'authentification [cite: 9]
        return const LoginScreen();
      },
    );
  }
}