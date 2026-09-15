// lib/core/routing/auth_guard.dart
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../screens/patient/patient_home_screen.dart';
import '../../screens/doctor/doctor_home_screen.dart';
import '../../screens/admin/admin_dashboard_screen.dart';

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
        return const AdminDashboardScreen();
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
      // Non connecté : redirection ciblée selon le rôle
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (requiredRole == UserRole.admin) {
          Navigator.pushNamedAndRemoveUntil(context, '/admin/login', (route) => false);
        } else {
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        }
      });
      return const SizedBox.shrink();
    }

    // Compte suspendu ou inactif
    if (auth.currentUser?.status != AccountStatus.active) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.block_rounded, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Compte inactif ou suspendu',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Veuillez contacter le support administratif.'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => auth.logout(),
                child: const Text('Se déconnecter'),
              ),
            ],
          ),
        ),
      );
    }

    // Vérification du rôle requis
    if (requiredRole != null && auth.currentUser?.role != requiredRole) {
      if (auth.isAdmin) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, '/admin');
        });
        return const SizedBox.shrink();
      }

      // Si l'accès est requis pour l'administrateur alors qu'on est connecté avec un autre rôle
      if (requiredRole == UserRole.admin) {
        return Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(32),
                constraints: const BoxConstraints(maxWidth: 460),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.shield_alert, color: AppColors.brandBlue, size: 52),
                    const SizedBox(height: 16),
                    const Text(
                      'Console d\'Administration',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Vous êtes actuellement connecté en tant que ${auth.currentUser?.fullName} (${auth.currentUser?.role == UserRole.doctor ? 'Médecin' : 'Patient'}). Ce compte n\'a pas les droits d\'administrateur.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        icon: const Icon(LucideIcons.log_in, size: 18),
                        label: const Text(
                          'Connexion Administrateur',
                          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          await auth.logout();
                          if (context.mounted) {
                            Navigator.pushNamedAndRemoveUntil(context, '/admin/login', (route) => false);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextButton(
                      onPressed: () {
                        if (auth.isDoctor) {
                          Navigator.pushReplacementNamed(context, '/doctor/home');
                        } else {
                          Navigator.pushReplacementNamed(context, '/patient/home');
                        }
                      },
                      child: const Text(
                        'Retourner à mon espace',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      if (auth.isDoctor) return const DoctorHomeScreen();
      return const PatientHomeScreen();
    }

    return child;
  }
}
