import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

/// Carte d'identité médicale numérique (Patient ou Médecin)
/// Conçue fidèlement d'après la maquette officielle :
/// - Bandeau supérieur bleu vif avec logo "my doctor", assurance/ordre et type de carte
/// - Cadre photo avec silhouette ou photo réelle
/// - Champs typographiques bicolores (labels cyan et valeurs marine en majuscules)
/// - Ondulations fluides bicolores en bas de carte
class HealthIdCardWidget extends StatelessWidget {
  final bool isDoctor;
  final String? lastName;
  final String? firstName;
  final String? idNumber;
  final dynamic birthDate;
  final String? location;
  final DateTime? admissionDate;
  final String? avatarBase64;
  final String? avatarUrl;
  final VoidCallback? onPhotoUpdated;
  final bool showActions;

  const HealthIdCardWidget({
    super.key,
    required this.isDoctor,
    this.lastName,
    this.firstName,
    this.idNumber,
    this.birthDate,
    this.location,
    this.admissionDate,
    this.avatarBase64,
    this.avatarUrl,
    this.onPhotoUpdated,
    this.showActions = true,
  });

  Future<void> _pickAndChangePhoto(BuildContext context) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64Image = base64Encode(bytes);

        if (!context.mounted) return;
        final auth = context.read<AuthProvider>();
        final success = await auth.updateProfilePhoto(base64Image);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success
                  ? '✅ Photo de la carte mise à jour !'
                  : '❌ Erreur lors de la mise à jour'),
              backgroundColor: success ? AppColors.success : AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          if (success && onPhotoUpdated != null) {
            onPhotoUpdated!();
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showQrCodeModal(BuildContext context) {
    final fullName = '${lastName ?? ''} ${firstName ?? ''}'.trim();
    final number = idNumber ?? (isDoctor ? 'MED-00000000' : 'PAT-00000000');
    final qrData = 'MYDOCTOR|${isDoctor ? "DOCTOR" : "PATIENT"}|$number|$fullName';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0288D1).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.qr_code, color: Color(0xFF0288D1), size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  isDoctor ? 'Vérification Praticien' : 'Vérification Patient',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Flashez ce QR Code pour vérifier l\'authenticité de la carte',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF0288D1).withValues(alpha: 0.3), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0288D1).withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 200.0,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Color(0xFF0288D1),
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.shield_check, color: Color(0xFF0288D1), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '$number • $fullName',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0288D1),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0288D1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Fermer', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calcul des valeurs
    final cleanLastName = (lastName != null && lastName!.trim().isNotEmpty)
        ? lastName!.trim().toUpperCase()
        : (isDoctor ? 'TOURE' : 'KOUASSI');

    final cleanFirstName = (firstName != null && firstName!.trim().isNotEmpty)
        ? firstName!.trim().toUpperCase()
        : (isDoctor ? 'SARAH' : 'JEAN');

    final cleanNumber = (idNumber != null && idNumber!.trim().isNotEmpty)
        ? idNumber!.trim().toUpperCase()
        : (isDoctor ? 'MED-12345' : 'PAT-00018427');

    String cleanBirthDate;
    if (birthDate is DateTime) {
      cleanBirthDate = DateFormat('dd/MM/yyyy').format(birthDate as DateTime);
    } else if (birthDate is String && (birthDate as String).trim().isNotEmpty) {
      cleanBirthDate = (birthDate as String).trim();
    } else {
      cleanBirthDate = isDoctor ? '15/04/1985' : '12/05/1990';
    }

    final cleanLocation = (location != null && location!.trim().isNotEmpty)
        ? location!.trim().toUpperCase()
        : (isDoctor ? 'CARDIOLOGIE' : 'ABIDJAN');

    final admissionFormatted = admissionDate != null
        ? DateFormat('dd/MM/yyyy').format(admissionDate!)
        : '01/09/2026';

    return Column(
      children: [
        // ── LA CARTE OFFICIELLE ──────────────────────────────────────────────
        Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0288D1).withValues(alpha: 0.18),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── BANDEAU SUPÉRIEUR BLEU ──────────────────────────────────
                  _buildHeaderBar(),

                  // ── CORPS DE LA CARTE AVEC PHOTO ET DONNÉES ─────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // CADRE PHOTO À GAUCHE
                        _buildPhotoBox(context),

                        const SizedBox(width: 14),

                        // INFORMATIONS EN 2 COLONNES
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Ligne 1 : Nom de famille | N° de patient / ordre
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 6,
                                    child: _buildDataField(
                                      label: 'Nom de famille',
                                      value: cleanLastName,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    flex: 5,
                                    child: _buildDataField(
                                      label: isDoctor ? 'N° d\'Ordre' : 'N° de patient',
                                      value: cleanNumber,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Ligne 2 : Prénoms | Date de naissance / validation
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 6,
                                    child: _buildDataField(
                                      label: 'Prénoms',
                                      value: cleanFirstName,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    flex: 5,
                                    child: _buildDataField(
                                      label: isDoctor ? 'Date validation' : 'Date de naissance',
                                      value: cleanBirthDate,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Ligne 3 : Lieu de naissance / Spécialité | Date d'admission
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 6,
                                    child: _buildDataField(
                                      label: isDoctor ? 'Spécialité' : 'Lieu de naissance',
                                      value: cleanLocation,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    flex: 5,
                                    child: _buildDataField(
                                      label: 'Date d\'admission',
                                      value: admissionFormatted,
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

                  // ── ONDULATIONS VAGUES BLEUES EN BAS ─────────────────────────
                  CustomPaint(
                    size: const Size(double.infinity, 44),
                    painter: _CardWavesPainter(),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── BOUTONS D'ACTION RAPIDE SOUS LA CARTE ────────────────────────────
        if (showActions) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ActionButton(
                  icon: LucideIcons.camera,
                  label: 'Changer photo',
                  color: const Color(0xFF0288D1),
                  onTap: () => _pickAndChangePhoto(context),
                ),
                const SizedBox(width: 12),
                _ActionButton(
                  icon: LucideIcons.qr_code,
                  label: 'Voir QR Code',
                  color: const Color(0xFF0D9488),
                  onTap: () => _showQrCodeModal(context),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Bandeau supérieur bleu identique à l'image
  Widget _buildHeaderBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF0288D1), // Bleu vif officiel de la carte
      ),
      child: Row(
        children: [
          // Logo circulaire "my doctor" (mains blanches + croix médicale)
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    LucideIcons.heart_handshake,
                    color: Color(0xFF00A896),
                    size: 20,
                  ),
                  Positioned(
                    top: 5,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444), // Croix rouge
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          '+',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 7),

          // Texte "my doctor"
          const Text(
            'my doctor',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(width: 8),

          // Séparateur vertical |
          Container(
            height: 18,
            width: 1.5,
            color: Colors.white.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 8),

          // Sous-titre institutionnel (Assurance ou Ordre)
          Expanded(
            child: Text(
              isDoctor ? 'ORDRE NATIONAL DES MÉDECINS' : 'ASSURANCE SANTÉ MY DOCTOR',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.95),
                letterSpacing: 0.3,
              ),
            ),
          ),

          // Titre à droite : CARTE PATIENT / CARTE PRATICIEN
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isDoctor ? 'CARTE PRATICIEN' : 'CARTE PATIENT',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Boîte photo avec l'avatar ou silhouette bleue fidèle à la maquette
  Widget _buildPhotoBox(BuildContext context) {
    Widget imageContent;

    if (avatarBase64 != null && avatarBase64!.isNotEmpty) {
      try {
        final cleanBase64 = avatarBase64!.contains(',')
            ? avatarBase64!.split(',').last
            : avatarBase64!;
        final bytes = base64Decode(cleanBase64);
        imageContent = Image.memory(
          bytes,
          width: 92,
          height: 104,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildDefaultSilhouette(),
        );
      } catch (_) {
        imageContent = _buildDefaultSilhouette();
      }
    } else if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      imageContent = Image.network(
        avatarUrl!,
        width: 92,
        height: 104,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildDefaultSilhouette(),
      );
    } else {
      imageContent = _buildDefaultSilhouette();
    }

    return Stack(
      children: [
        Container(
          width: 92,
          height: 104,
          decoration: BoxDecoration(
            color: const Color(0xFFDDF2FD), // Fond pastel bleu identique à la maquette
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFBAE6FD), width: 1.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: imageContent,
          ),
        ),
        // Badge icône caméra
        Positioned(
          bottom: 2,
          right: 2,
          child: GestureDetector(
            onTap: () => _pickAndChangePhoto(context),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF0288D1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                LucideIcons.camera,
                color: Colors.white,
                size: 11,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Silhouette bleue par défaut de la carte officielle
  Widget _buildDefaultSilhouette() {
    return Container(
      width: 92,
      height: 104,
      color: const Color(0xFFDDF2FD),
      child: Center(
        child: Icon(
          Icons.person,
          size: 68,
          color: const Color(0xFF0288D1).withValues(alpha: 0.9),
        ),
      ),
    );
  }

  /// Champ de donnée bicolore (label en cyan, valeur en bleu marine fort)
  Widget _buildDataField({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF00ACC1), // Cyan clair fidèle à la maquette
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0288D1), // Bleu vif officiel de la maquette
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

/// Bouton d'action sous la carte
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 2,
      shadowColor: color.withValues(alpha: 0.2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.25), width: 1.2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Peintre personnalisé pour générer les vagues inférieures bleues ondulées fidèles à l'image
class _CardWavesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── VAGUE 1 : Cyan clair en arrière-plan ─────────────────────────────────
    final paint1 = Paint()
      ..color = const Color(0xFF80DEEA).withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    final path1 = Path();
    path1.moveTo(0, h * 0.45);
    path1.cubicTo(w * 0.25, h * 0.15, w * 0.65, h * 0.85, w, h * 0.35);
    path1.lineTo(w, h);
    path1.lineTo(0, h);
    path1.close();
    canvas.drawPath(path1, paint1);

    // ── VAGUE 2 : Turquoise intermédiaire ────────────────────────────────────
    final paint2 = Paint()
      ..color = const Color(0xFF26C6DA)
      ..style = PaintingStyle.fill;

    final path2 = Path();
    path2.moveTo(0, h * 0.65);
    path2.cubicTo(w * 0.30, h * 0.35, w * 0.70, h * 0.95, w, h * 0.45);
    path2.lineTo(w, h);
    path2.lineTo(0, h);
    path2.close();
    canvas.drawPath(path2, paint2);

    // ── VAGUE 3 : Bleu océan principal (en premier plan à gauche) ───────────
    final paint3 = Paint()
      ..color = const Color(0xFF0288D1)
      ..style = PaintingStyle.fill;

    final path3 = Path();
    path3.moveTo(0, h * 0.20);
    path3.cubicTo(w * 0.35, h * 0.60, w * 0.60, h * 0.98, w, h * 0.60);
    path3.lineTo(w, h);
    path3.lineTo(0, h);
    path3.close();
    canvas.drawPath(path3, paint3);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
