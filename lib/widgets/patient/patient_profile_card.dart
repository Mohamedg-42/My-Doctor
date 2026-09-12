import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../screens/patient/edit_profile_screen.dart';

/// Carte de profil patient inspirée du design CMU Éclat d'Ivoire
/// Affiche les informations du patient avec un design chaleureux et professionnel
class PatientProfileCard extends StatelessWidget {
  final UserModel? user;

  const PatientProfileCard({
    super.key,
    required this.user,
  });

  Future<void> _pickAndUpdateProfilePhoto(BuildContext context) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      
      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64Image = base64Encode(bytes);
        
        final auth = context.read<AuthProvider>();
        final success = await auth.updateProfilePhoto(base64Image);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success 
                  ? '✅ Photo de profil mise à jour !' 
                  : '❌ Erreur lors de la mise à jour'),
              backgroundColor: success ? AppColors.success : AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sélection de l\'image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final initials = auth.userInitials;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bandeau wax coloré
              const _WaxBandeau(height: 14),
              
              // Contenu de la carte
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête République de Côte d'Ivoire
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'RÉPUBLIQUE DE CÔTE D\'IVOIRE',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryDark,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              SizedBox(height: 1),
                              Text(
                                'Union · Discipline · Travail',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Carte Patient MY DOCTOR',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              Text(
                                'Télémédecine · Côte d\'Ivoire',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Logo/Badge HELLO DOC
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: AppColors.primaryLight,
                            border: Border.all(color: AppColors.primary, width: 1.5),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('🇨🇮', style: TextStyle(fontSize: 22)),
                              SizedBox(height: 2),
                              Text(
                                'HELLO',
                                style: TextStyle(
                                  fontSize: 7,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                              Text(
                                'DOC',
                                style: TextStyle(
                                  fontSize: 7,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryDark,
                                  height: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 14),
                    
                    // Titulaire avec photo et infos
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: AppColors.backgroundGrey,
                            width: 1,
                            style: BorderStyle.solid,
                          ),
                          bottom: BorderSide(
                            color: AppColors.backgroundGrey,
                            width: 1,
                            style: BorderStyle.solid,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Avatar avec possibilité de modification
                          GestureDetector(
                            onTap: () => _pickAndUpdateProfilePhoto(context),
                            child: Stack(
                              children: [
                                Container(
                                  width: 62,
                                  height: 62,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    gradient: AppColors.primaryGradient,
                                  ),
                                  child: Center(
                                    child: user?.avatarBase64 != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(10),
                                            child: Image.memory(
                                              base64Decode(user!.avatarBase64!),
                                              width: 62,
                                              height: 62,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : Text(
                                            initials,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                                Positioned(
                                  right: -2,
                                  bottom: -2,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppColors.primary, width: 1.5),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_rounded,
                                      color: AppColors.primary,
                                      size: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Infos patient
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'TITULAIRE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user?.lastName != null && user?.firstName != null && user!.lastName.isNotEmpty
                                      ? '${user!.lastName.toUpperCase()} ${user!.firstName}'
                                      : auth.userName.toUpperCase(),
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                if (user?.gender != null || user?.birthDate != null)
                                  Text(
                                    '${user?.gender ?? ''} · ${_formatBirthDate(user?.birthDate)} · ${user?.city ?? 'Abidjan'}',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                if (user?.phone != null)
                                  Text(
                                    user!.phone,
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // Bouton Modifier profil
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primaryUltraLight,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(LucideIcons.user_pen, size: 14, color: AppColors.primary),
                                  SizedBox(width: 4),
                                  Text(
                                    'Modifier',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 14),
                    
                    // Identifiant patient et QR code
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Numéro d'identifiant
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'N° D\'IDENTIFIANT',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                () {
                                  final rawId = (user?.id ?? '000000000000').replaceAll('_', '');
                                  final safeId = rawId.padRight(12, '0');
                                  final p1 = safeId.substring(0, 4).toUpperCase();
                                  final p2 = safeId.substring(4, 8).toUpperCase();
                                  final p3 = safeId.substring(8, 12).toUpperCase();
                                  return 'HD $p1 $p2 $p3';
                                }(),
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // QR Code
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: AppColors.textPrimary, width: 1.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: QrImageView(
                            data: 'HELLODOC_PATIENT_${user?.id ?? 'unknown'}',
                            version: QrVersions.auto,
                            size: 46,
                            padding: const EdgeInsets.all(4),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 10),
                    
                    // Date d'inscription et statut
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Inscrit : ${_formatDate(user?.createdAt)}',
                          style: const TextStyle(fontSize: 10),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F7EF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppColors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'ACTIF',
                                style: TextStyle(
                                  color: AppColors.green,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatBirthDate(DateTime? date) {
    if (date == null) return '--/--/----';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '--/----';
    final months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'];
    return '${months[date.month - 1]} ${date.year}';
  }
}

/// Bandeau wax coloré en haut de la carte
class _WaxBandeau extends StatelessWidget {
  final double height;

  const _WaxBandeau({required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        children: [
          Expanded(flex: 1, child: Container(color: AppColors.primary)),
          Expanded(flex: 1, child: Container(color: AppColors.yellow)),
          Expanded(flex: 1, child: Container(color: AppColors.accentBlue)),
          Expanded(flex: 1, child: Container(color: AppColors.green)),
          Expanded(flex: 1, child: Container(color: AppColors.primary)),
          Expanded(
            flex: 1,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  left: BorderSide(color: AppColors.primaryDark, width: 3, style: BorderStyle.solid),
                  right: BorderSide(color: AppColors.primaryDark, width: 3, style: BorderStyle.solid),
                ),
              ),
            ),
          ),
          Expanded(flex: 1, child: Container(color: AppColors.primaryDark)),
        ],
      ),
    );
  }
}
