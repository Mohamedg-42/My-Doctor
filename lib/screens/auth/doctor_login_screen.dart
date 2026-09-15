// ════════════════════════════════════════════════════════════
//  doctor_login_screen.dart
//  My Doctor - Écran de connexion médecin
//  Délègue vers l'écran de connexion officiel LoginScreen
// ════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import 'login_screen.dart';

class DoctorLoginScreen extends StatelessWidget {
  final bool isDemoMode;
  const DoctorLoginScreen({super.key, this.isDemoMode = false});

  @override
  Widget build(BuildContext context) {
    return LoginScreen(
      initialRole: UserRole.doctor,
      isDemoMode: isDemoMode,
    );
  }
}
