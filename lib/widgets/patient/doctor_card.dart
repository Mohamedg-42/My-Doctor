import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../core/theme/app_theme.dart';
import '../../models/doctor_model.dart';
import '../common/avatar_widget.dart';

class DoctorCard extends StatelessWidget {
  final DoctorModel doctor;
  final VoidCallback onTap;
  final bool showDistance;

  const DoctorCard({
    super.key,
    required this.doctor,
    required this.onTap,
    this.showDistance = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            DoctorAvatar(
              imageUrl: doctor.avatarUrl,
              avatarBase64: doctor.avatarBase64,
              name: doctor.fullName,
              size: 64,
              isOnline: doctor.isOnline,
              isVerified: doctor.isVerified,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          doctor.fullName,
                          style: AppTextStyles.subtitle1.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _RatingBadge(rating: doctor.rating),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    doctor.specialty,
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _InfoChip(
                        icon: LucideIcons.briefcase,
                        label: '${doctor.experienceYears} ans',
                      ),
                      const SizedBox(width: 8),
                      _InfoChip(
                        icon: LucideIcons.users,
                        label: doctor.formattedPatients,
                      ),
                      if (showDistance && doctor.distanceKm != null) ...[
                        const SizedBox(width: 8),
                        _InfoChip(
                          icon: LucideIcons.map_pin,
                          label: doctor.formattedDistance,
                          color: AppColors.accentBlue,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        doctor.formattedPrice,
                        style: AppTextStyles.subtitle1.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: doctor.isAvailable
                              ? AppColors.success.withValues(alpha: 0.12)
                              : AppColors.backgroundGrey,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          doctor.isAvailable ? 'Disponible' : 'Indisponible',
                          style: AppTextStyles.caption.copyWith(
                            color: doctor.isAvailable
                                ? AppColors.success
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
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
    );
  }
}

class _RatingBadge extends StatelessWidget {
  final double rating;
  const _RatingBadge({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.star.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.star, color: AppColors.star, size: 13),
          const SizedBox(width: 3),
          Text(
            rating.toStringAsFixed(1),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: c),
        const SizedBox(width: 3),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: c,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class DoctorCardHorizontal extends StatelessWidget {
  final DoctorModel doctor;
  final VoidCallback onTap;

  const DoctorCardHorizontal({
    super.key,
    required this.doctor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DoctorAvatar(
                  imageUrl: doctor.avatarUrl,
                  avatarBase64: doctor.avatarBase64,
                  name: doctor.fullName,
                  size: 50,
                  isOnline: doctor.isOnline,
                  isVerified: doctor.isVerified,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.textWhite.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.star, color: AppColors.star, size: 12),
                      const SizedBox(width: 3),
                      Text(
                        doctor.formattedRating,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textWhite,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              doctor.fullName,
              style: AppTextStyles.subtitle2.copyWith(
                color: AppColors.textWhite,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              doctor.specialty,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textWhite.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              doctor.formattedPrice,
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textWhite,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
