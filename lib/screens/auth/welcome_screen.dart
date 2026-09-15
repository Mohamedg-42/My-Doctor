// ════════════════════════════════════════════════════════════
//  welcome_screen.dart
//  My Doctor - Écran de connexion unifié officiel
// ════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  final UserRole initialRole;
  final bool isDemoMode;

  const WelcomeScreen({
    super.key,
    this.initialRole = UserRole.patient,
    this.isDemoMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return LoginScreen(
      initialRole: initialRole,
      isDemoMode: isDemoMode,
    );
  }
}
