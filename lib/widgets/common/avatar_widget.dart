import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AvatarWidget extends StatelessWidget {
  final String? imageUrl;
  final String initials;
  final double size;
  final Color? backgroundColor;
  final bool isOnline;
  final bool showBorder;
  final VoidCallback? onTap;

  const AvatarWidget({
    super.key,
    this.imageUrl,
    required this.initials,
    this.size = 48,
    this.backgroundColor,
    this.isOnline = false,
    this.showBorder = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: showBorder
                  ? Border.all(
                      color: AppColors.backgroundCard,
                      width: 3,
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: size / 2,
              backgroundColor:
                  backgroundColor ?? AppColors.primaryUltraLight,
              backgroundImage:
                  imageUrl != null ? NetworkImage(imageUrl!) : null,
              child: imageUrl == null
                  ? Text(
                      initials,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: size * 0.32,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    )
                  : null,
            ),
          ),
          if (isOnline)
            Positioned(
              right: size > 40 ? 2 : 0,
              bottom: size > 40 ? 2 : 0,
              child: Container(
                width: size > 40 ? 14 : 10,
                height: size > 40 ? 14 : 10,
                decoration: BoxDecoration(
                  color: AppColors.online,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.backgroundCard,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Avatar médecin : supporte imageUrl (réseau), avatarBase64 (local) et initiales.
class DoctorAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? avatarBase64; // ← photo locale en base64
  final String name;
  final double size;
  final bool isOnline;
  final bool isVerified;

  const DoctorAvatar({
    super.key,
    this.imageUrl,
    this.avatarBase64,
    required this.name,
    this.size = 56,
    this.isOnline = false,
    this.isVerified = false,
  });

  String get _initials {
    final parts = name.replaceAll('Dr. ', '').split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : 'M';
  }

  /// Tente de décoder le base64 ; retourne null si invalide.
  Uint8List? get _base64Bytes {
    if (avatarBase64 == null || avatarBase64!.isEmpty) return null;
    try {
      return base64Decode(avatarBase64!);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _base64Bytes;
    return Stack(
      children: [
        // — Avatar principal
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryUltraLight,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.15),
              width: 1.5,
            ),
            image: bytes != null
                ? DecorationImage(image: MemoryImage(bytes), fit: BoxFit.cover)
                : (imageUrl != null && imageUrl!.isNotEmpty)
                    ? DecorationImage(
                        image: NetworkImage(imageUrl!),
                        fit: BoxFit.cover,
                        onError: (_, __) {},
                      )
                    : null,
          ),
          child: (bytes == null && (imageUrl == null || imageUrl!.isEmpty))
              ? Center(
                  child: Text(
                    _initials,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: size * 0.32,
                      color: AppColors.primary,
                    ),
                  ),
                )
              : null,
        ),

        // — Point de présence en ligne
        if (isOnline)
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              width: size * 0.22,
              height: size * 0.22,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.backgroundCard, width: 2),
              ),
            ),
          ),

        // — Badge vérifié
        if (isVerified)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: AppColors.backgroundCard,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified,
                color: AppColors.primary,
                size: 14,
              ),
            ),
          ),
      ],
    );
  }
}
