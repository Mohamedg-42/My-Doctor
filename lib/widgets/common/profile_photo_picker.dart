// lib/widgets/common/profile_photo_picker.dart
//
// Widget réutilisable de sélection de photo de profil.
// Fonctionne sur Web (galerie uniquement) et Mobile (camera + galerie).
// Stocke en Uint8List → base64 pour la persistance Hive.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';

/// Widget circulaire permettant de choisir / afficher une photo de profil.
/// [onPhotoSelected] reçoit les bytes bruts de l'image.
/// [photoBytes] optionnel pour afficher une photo déjà choisie.
class ProfilePhotoPicker extends StatelessWidget {
  final Uint8List? photoBytes;
  final String? existingBase64;
  final void Function(Uint8List bytes, String base64) onPhotoSelected;
  final double size;
  final String label;

  const ProfilePhotoPicker({
    super.key,
    required this.onPhotoSelected,
    this.photoBytes,
    this.existingBase64,
    this.size = 100,
    this.label = 'Photo de profil',
  });

  Uint8List? get _displayBytes {
    if (photoBytes != null) return photoBytes;
    if (existingBase64 != null && existingBase64!.isNotEmpty) {
      try { return base64Decode(existingBase64!); } catch (_) {}
    }
    return null;
  }

  bool get _hasPhoto => _displayBytes != null;

  Future<void> _pick(BuildContext context, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 80,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final b64 = base64Encode(bytes);
      onPhotoSelected(bytes, b64);
    } catch (e) {
      debugPrint('Photo picker error: $e');
    }
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PhotoSourceSheet(
        onGallery: () { Navigator.pop(context); _pick(context, ImageSource.gallery); },
        onCamera: kIsWeb ? null : () { Navigator.pop(context); _pick(context, ImageSource.camera); },
        onRemove: _hasPhoto ? () { Navigator.pop(context); onPhotoSelected(Uint8List(0), ''); } : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _displayBytes;

    return GestureDetector(
      onTap: () => _showOptions(context),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Cercle principal
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _hasPhoto
                  ? Colors.transparent
                  : AppColors.primaryUltraLight,
              border: Border.all(
                color: _hasPhoto ? AppColors.primary : AppColors.backgroundGrey,
                width: 2.5,
              ),
              image: bytes != null && bytes.isNotEmpty
                  ? DecorationImage(
                      image: MemoryImage(bytes),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: bytes == null || bytes.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_add_alt_1_rounded,
                        size: size * 0.35,
                        color: AppColors.primary.withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: size * 0.10,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                : null,
          ),
          // Badge caméra
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: size * 0.30,
              height: size * 0.30,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(
                _hasPhoto ? Icons.edit_rounded : Icons.camera_alt_rounded,
                color: Colors.white,
                size: size * 0.15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Feuille de choix de source ───────────────────────────────────────────────

class _PhotoSourceSheet extends StatelessWidget {
  final VoidCallback onGallery;
  final VoidCallback? onCamera;
  final VoidCallback? onRemove;

  const _PhotoSourceSheet({
    required this.onGallery,
    this.onCamera,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Choisir une photo',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          // Galerie
          _SheetTile(
            icon: Icons.photo_library_rounded,
            iconColor: const Color(0xFF185FA5),
            title: 'Choisir depuis la galerie',
            subtitle: 'Sélectionner une photo existante',
            onTap: onGallery,
          ),
          // Caméra (mobile seulement)
          if (onCamera != null)
            _SheetTile(
              icon: Icons.camera_alt_rounded,
              iconColor: const Color(0xFF1A7A5A),
              title: 'Prendre une photo',
              subtitle: 'Utiliser l\'appareil photo',
              onTap: onCamera!,
            ),
          // Supprimer
          if (onRemove != null)
            _SheetTile(
              icon: Icons.delete_outline_rounded,
              iconColor: AppColors.error,
              title: 'Supprimer la photo',
              subtitle: 'Revenir aux initiales',
              onTap: onRemove!,
            ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Annuler',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SheetTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SheetTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          color: AppColors.textSecondary,
        ),
      ),
      onTap: onTap,
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

/// Affiche une image depuis bytes, base64 ou URL réseau.
/// Mode rond (défaut) ou carré avec coins arrondis via [borderRadius].
/// Utilisé sur la carte CMU, les cartes professionnelles et le profil.
class ProfileAvatar extends StatelessWidget {
  final Uint8List? bytes;
  final String? base64Data;
  final String? networkUrl;
  final String initials;
  final double size;
  final bool showBorder;
  /// Si non-null → mode carré avec ClipRRect (coins arrondis = borderRadius).
  /// Si null → mode cercle avec ClipOval (comportement d'origine).
  final BorderRadius? borderRadius;
  /// Largeur explicite (utile pour les photos rectangulaires type carte d'identité).
  final double? width;
  /// Hauteur explicite.
  final double? height;

  const ProfileAvatar({
    super.key,
    this.bytes,
    this.base64Data,
    this.networkUrl,
    required this.initials,
    this.size = 60,
    this.showBorder = false,
    this.borderRadius,
    this.width,
    this.height,
  });

  Uint8List? get _effectiveBytes {
    if (bytes != null && bytes!.isNotEmpty) return bytes;
    if (base64Data != null && base64Data!.isNotEmpty) {
      try { return base64Decode(base64Data!); } catch (_) {}
    }
    return null;
  }

  bool get _isSquare => borderRadius != null;

  @override
  Widget build(BuildContext context) {
    final b = _effectiveBytes;
    final w = width ?? size;
    final h = height ?? size;
    final initialsSize = (w < h ? w : h) * 0.3;

    // ── Contenu de l'image ──────────────────────────────────────────────────
    Widget imageChild;
    if (b != null) {
      imageChild = Image.memory(b, fit: BoxFit.cover, width: w, height: h);
    } else if (networkUrl != null && networkUrl!.isNotEmpty) {
      imageChild = Image.network(
        networkUrl!,
        fit: BoxFit.cover,
        width: w,
        height: h,
        errorBuilder: (_, __, ___) => _InitialsAvatar(initials: initials, size: w < h ? w : h, color: null),
      );
    } else {
      imageChild = _InitialsAvatar(initials: initials, size: w < h ? w : h, color: null);
    }

    // ── Clip selon le mode ──────────────────────────────────────────────────
    Widget clipped;
    if (_isSquare) {
      clipped = ClipRRect(
        borderRadius: borderRadius!,
        child: SizedBox(width: w, height: h, child: imageChild),
      );
    } else {
      clipped = ClipOval(
        child: SizedBox(width: w, height: h, child: imageChild),
      );
    }

    // ── Bordure optionnelle ─────────────────────────────────────────────────
    if (showBorder) {
      return Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          shape: _isSquare ? BoxShape.rectangle : BoxShape.circle,
          borderRadius: _isSquare ? borderRadius : null,
          border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2),
        ),
        child: clipped,
      );
    }

    return SizedBox(width: w, height: h, child: clipped);
  }
}

class _InitialsAvatar extends StatelessWidget {
  final String initials;
  final double size;
  final Color? color;
  const _InitialsAvatar({required this.initials, required this.size, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: (color ?? AppColors.primary).withValues(alpha: 0.15),
      child: Center(
        child: Text(
          initials.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: size * 0.3,
            fontWeight: FontWeight.bold,
            color: color ?? AppColors.primary,
          ),
        ),
      ),
    );
  }
}

// ─── ProfilePhotoPickerSquare ─────────────────────────────────────────────────
/// Variante carrée du ProfilePhotoPicker.
/// Affiche la photo en format rectangulaire (comme une carte d'identité).
/// Utilisé sur la carte professionnelle du médecin.
class ProfilePhotoPickerSquare extends StatelessWidget {
  final Uint8List? photoBytes;
  final String? existingBase64;
  final void Function(Uint8List bytes, String base64) onPhotoSelected;
  final double width;
  final double height;
  final double cornerRadius;

  const ProfilePhotoPickerSquare({
    super.key,
    required this.onPhotoSelected,
    this.photoBytes,
    this.existingBase64,
    this.width = 90,
    this.height = 110,
    this.cornerRadius = 10,
  });

  Uint8List? get _displayBytes {
    if (photoBytes != null && photoBytes!.isNotEmpty) return photoBytes;
    if (existingBase64 != null && existingBase64!.isNotEmpty) {
      try { return base64Decode(existingBase64!); } catch (_) {}
    }
    return null;
  }

  bool get _hasPhoto => _displayBytes != null;

  Future<void> _pick(BuildContext context, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final b64 = base64Encode(bytes);
      onPhotoSelected(bytes, b64);
    } catch (e) {
      debugPrint('Photo picker error: $e');
    }
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PhotoSourceSheet(
        onGallery: () { Navigator.pop(context); _pick(context, ImageSource.gallery); },
        onCamera: kIsWeb ? null : () { Navigator.pop(context); _pick(context, ImageSource.camera); },
        onRemove: _hasPhoto ? () { Navigator.pop(context); onPhotoSelected(Uint8List(0), ''); } : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _displayBytes;

    return GestureDetector(
      onTap: () => _showOptions(context),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Cadre principal carré
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(cornerRadius),
              color: _hasPhoto ? Colors.transparent : Colors.white.withValues(alpha: 0.15),
              border: Border.all(
                color: _hasPhoto
                    ? Colors.white.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.35),
                width: 2,
              ),
            ),
            clipBehavior: Clip.hardEdge,
            child: bytes != null
                ? Image.memory(bytes, fit: BoxFit.cover, width: width, height: height)
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo_rounded,
                        color: Colors.white.withValues(alpha: 0.8),
                        size: width * 0.32,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Photo',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: width * 0.12,
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
          // Badge caméra
          Positioned(
            bottom: -6,
            right: -6,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 13),
            ),
          ),
        ],
      ),
    );
  }
}
