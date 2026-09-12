import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common/app_logo.dart';

class ChooseRegisterScreen extends StatelessWidget {
  const ChooseRegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Créer un compte'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 24),
                  child: const AppLogo(
                    height: 64,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ),
              const Text(
                'Quel est votre rôle ?',
                style: AppTextStyles.heading2,
              ),
              const SizedBox(height: 8),
              Text(
                'Choisissez le type de compte que vous souhaitez créer.',
                style: AppTextStyles.body1.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 40),
              _RoleCard(
                icon: LucideIcons.user,
                title: 'Patient',
                description: 'Consultez des médecins, prenez des rendez-vous et gérez votre santé.',
                color: AppColors.primary,
                features: const [
                  'Recherche de médecins',
                  'Prise de rendez-vous',
                  'Téléconsultation vidéo',
                  'Dossier médical',
                ],
                onTap: () => Navigator.pushNamed(context, '/auth/patient/register'),
              ),
              const SizedBox(height: 16),
              _RoleCard(
                icon: LucideIcons.stethoscope,
                title: 'Médecin',
                description: 'Gérez vos patients, consultations et dossiers médicaux.',
                color: AppColors.accentBlue,
                features: const [
                  'Premier mois GRATUIT',
                  'Gestion des RDV',
                  'Dossiers médicaux',
                  'Revenus et statistiques',
                ],
                onTap: () => Navigator.pushNamed(context, '/auth/doctor/register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final List<String> features;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.features,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: color.withValues(alpha: 0.12),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.heading3.copyWith(color: color),
                      ),
                      Text(
                        description,
                        style: AppTextStyles.body2,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                Icon(LucideIcons.chevron_right, color: color, size: 18),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: features.map((f) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.circle_check, color: color, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      f,
                      style: AppTextStyles.caption.copyWith(
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
