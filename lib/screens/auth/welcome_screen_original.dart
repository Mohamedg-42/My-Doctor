// ════════════════════════════════════════════════════════════
//  welcome_screen_original.dart
//  Écran d'accueil officiel My Doctor
// ════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common/app_logo.dart';
import 'patient_login_screen.dart';
import 'doctor_login_screen.dart';

class WelcomeScreenOriginal extends StatelessWidget {
  const WelcomeScreenOriginal({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceApp,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // ═══════════════════════════════════════════════════════════
                // LOGO OFFICIEL MY DOCTOR
                // ═══════════════════════════════════════════════════════════
                const AppLogo(
                  width: 220,
                  height: 140,
                ),
                const SizedBox(height: 24),

                Text(
                  'Votre santé, connectée',
                  style: AppTextStyles.bodyLg.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),

                // ═══════════════════════════════════════════════════════════
                // CHOIX DU PROFIL
                // ═══════════════════════════════════════════════════════════
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.borderSubtle),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brandNavy.withValues(alpha: 0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choisissez votre profil',
                        style: AppTextStyles.h2,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Accédez à votre espace sécurisé en tant que patient ou praticien.',
                        style: AppTextStyles.caption.copyWith(fontSize: 13),
                      ),
                      const SizedBox(height: 24),

                      // Bouton Patient
                      _buildProfileCard(
                        context: context,
                        title: 'Je suis Patient',
                        subtitle: 'Consultez, prenez RDV et suivez votre santé',
                        icon: LucideIcons.user,
                        color: AppColors.brandBlue,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PatientLoginScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 14),

                      // Bouton Médecin
                      _buildProfileCard(
                        context: context,
                        title: 'Je suis Médecin',
                        subtitle: 'Gérez vos consultations et vos patients',
                        icon: LucideIcons.stethoscope,
                        color: AppColors.brandNavy,
                        isSecondary: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DoctorLoginScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Lien Inscription corrigé (renvoie directement vers ChooseRegisterScreen)
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/auth/choose-register');
                  },
                  child: RichText(
                    text: TextSpan(
                      text: 'Nouveau sur My Doctor ? ',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                      children: [
                        TextSpan(
                          text: 'Créer un compte',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.brandBlue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Bouton d'accès direct à l'administration
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/admin'),
                    icon: const Icon(LucideIcons.shield_check, size: 16, color: AppColors.brandNavy),
                    label: const Text(
                      'Portail Administrateur',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brandNavy,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.brandNavy,
                      side: BorderSide(color: AppColors.brandNavy.withValues(alpha: 0.3), width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      backgroundColor: AppColors.brandNavy.withValues(alpha: 0.04),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    bool isSecondary = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSecondary ? AppColors.surfaceSubtle : color,
          borderRadius: BorderRadius.circular(16),
          border: isSecondary ? Border.all(color: AppColors.borderSubtle, width: 1.2) : null,
          boxShadow: !isSecondary
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSecondary ? color.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 22,
                color: isSecondary ? color : Colors.white,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.h3.copyWith(
                      fontSize: 16,
                      color: isSecondary ? AppColors.textPrimary : Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 12,
                      color: isSecondary ? AppColors.textMuted : Colors.white.withValues(alpha: 0.85),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevron_right,
              size: 18,
              color: isSecondary ? AppColors.textMuted : Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
