// ════════════════════════════════════════════════════════════
//  patient_login_screen.dart
//  My Doctor - Écran de connexion patient
//  Délègue vers l'écran de connexion officiel LoginScreen
// ════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import 'login_screen.dart';

class PatientLoginScreen extends StatelessWidget {
  final bool isDemoMode;
  const PatientLoginScreen({super.key, this.isDemoMode = false});

  @override
  Widget build(BuildContext context) {
    return LoginScreen(
      initialRole: UserRole.patient,
      isDemoMode: isDemoMode,
    );
  }
}
