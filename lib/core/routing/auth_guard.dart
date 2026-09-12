// lib/core/routing/auth_guard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../screens/patient/patient_home_screen.dart';
import '../../screens/doctor/doctor_home_screen.dart';
import '../../screens/admin/admin_dashboard_screen.dart';
import 'route_persistence_service.dart';

/// Empêche l'accès aux pages de connexion, d'inscription et d'accueil public
/// dès qu'un utilisateur est authentifié.
/// Restaure automatiquement l'espace de travail correspondant sans scintillement.
class GuestOnlyRoute extends StatelessWidget {
  final Widget child;

  const GuestOnlyRoute({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // ── Si l'utilisateur est connecté, redirection vers son espace actif
    if (auth.isAuthenticated && auth.currentUser != null) {
      if (auth.isAdmin || auth.currentUser?.role == UserRole.admin) {
        final savedTab = RoutePersistenceService.getCachedTab('admin') ?? 0;
        return AdminDashboardScreen(initialTab: savedTab);
      } else if (auth.isDoctor || auth.currentUser?.role == UserRole.doctor) {
        return const DoctorHomeScreen();
      } else {
        return const PatientHomeScreen();
      }
    }

    // ── En cours de chargement initial : zéro écran de chargement clignotant
    if (auth.state == AuthState.loading) {
      return const SizedBox.shrink();
    }

    // ── Non connecté : accès autorisé à la page de connexion / bienvenue
    return child;
  }
}

/// Protège les écrans nécessitant d'être connecté
class AuthenticatedRoute extends StatelessWidget {
  final Widget child;
  final UserRole? requiredRole;

  const AuthenticatedRoute({
    super.key,
    required this.child,
    this.requiredRole,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.state == AuthState.loading) {
      return const SizedBox.shrink();
    }

    if (!auth.isAuthenticated || auth.currentUser == null) {
      // Non connecté : redirection automatique vers la page d'accueil public
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      });
      return const SizedBox.shrink();
    }

    // Vérification du rôle requis
    if (requiredRole != null && auth.currentUser?.role != requiredRole) {
      if (auth.isAdmin) {
        final savedTab = RoutePersistenceService.getCachedTab('admin') ?? 0;
        return AdminDashboardScreen(initialTab: savedTab);
      }
      if (auth.isDoctor) return const DoctorHomeScreen();
      return const PatientHomeScreen();
    }

    return child;
  }
}
