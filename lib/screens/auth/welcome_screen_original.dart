// ════════════════════════════════════════════════════════════
//  welcome_screen_original.dart
//  My Doctor - Écran d'accueil officiel
// ════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import 'login_screen.dart';

class WelcomeScreenOriginal extends StatelessWidget {
  final UserRole initialRole;
  final bool isDemoMode;

  const WelcomeScreenOriginal({
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
