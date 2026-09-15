import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/appointment_model.dart';
import '../common/avatar_widget.dart';

/// Carte rendez-vous conforme aux spécifications My Doctor
/// - Mode prioritaire : fond brandBlue, texte blanc, rayon 24px, padding 20px
/// - Mode standard : fond surfaceCard, bordure borderSubtle, rayon 20px
class AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final bool isDoctor;
  final bool isPriority;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;
  final VoidCallback? onJoinCall;
  final VoidCallback? onReschedule;

  const AppointmentCard({
    super.key,
    required this.appointment,
    this.isDoctor = false,
    this.isPriority = false,
    this.onTap,
    this.onCancel,
    this.onJoinCall,
    this.onReschedule,
  });

  Color get _statusColor {
    switch (appointment.status) {
      case AppointmentStatus.confirmed: return AppColors.brandTurquoise;
      case AppointmentStatus.pending:   return const Color(0xFFC05621);
      case AppointmentStatus.cancelled: return AppColors.brandCoral;
      case AppointmentStatus.completed: return AppColors.brandNavy;
      case AppointmentStatus.inProgress: return AppColors.brandBlue;
      case AppointmentStatus.noShow:    return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final personName = isDoctor ? appointment.patientName : appointment.doctorName;
    final personSpecialty = isDoctor ? 'Patient' : appointment.doctorSpecialty;
    final personAvatar = isDoctor ? appointment.patientAvatar : appointment.doctorAvatar;

    if (isPriority) {
      return _buildPriorityCard(context, personName, personSpecialty, personAvatar);
    }

    return _buildStandardCard(context, personName, personSpecialty, personAvatar);
  }

  /// ─── Carte Prioritaire (Spécification Section 7) ───────────────────────────
  Widget _buildPriorityCard(BuildContext context, String personName, String personSpecialty, String? personAvatar) {
    final dateStr = DateFormat('EEEE d MMMM', 'fr_FR').format(appointment.scheduledAt);
    final timeStr = DateFormat('HH:mm').format(appointment.scheduledAt);
    final modeStr = appointment.isTeleconsultation ? 'Téléconsultation vidéo' : 'Consultation en cabinet';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20), // Padding 20px
        decoration: BoxDecoration(
          color: AppColors.brandBlue, // Fond brand-blue
          borderRadius: BorderRadius.circular(24), // Rayon 24px
          boxShadow: [
            BoxShadow(
              color: AppColors.brandBlue.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge Prochain RDV
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.star, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        'PROCHAIN RENDEZ-VOUS',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    appointment.statusLabel,
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 1. Médecin
            Row(
              children: [
                AvatarWidget(
                  imageUrl: personAvatar,
                  initials: _getInitials(personName),
                  size: 48,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        personName,
                        style: AppTextStyles.h3.copyWith(color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        personSpecialty,
                        style: AppTextStyles.body.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 2. Date & 3. Heure & 4. Mode
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(LucideIcons.calendar, size: 16, color: Colors.white),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            dateStr,
                            style: AppTextStyles.body.copyWith(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(LucideIcons.clock, size: 16, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        timeStr,
                        style: AppTextStyles.body.copyWith(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Mode de consultation
            Row(
              children: [
                Icon(
                  appointment.isTeleconsultation ? LucideIcons.video : LucideIcons.map_pin,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                const SizedBox(width: 6),
                Text(
                  modeStr,
                  style: AppTextStyles.caption.copyWith(color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w500),
                ),
              ],
            ),

            // Actions : Rejoindre / Modifier / Annuler
            if (appointment.isTeleconsultation && onJoinCall != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: onJoinCall,
                  icon: const Icon(LucideIcons.video, size: 20),
                  label: const Text('Rejoindre la consultation'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.brandBlue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: AppTextStyles.label.copyWith(color: AppColors.brandBlue),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// ─── Carte Standard ───────────────────────────────────────────────────────
  Widget _buildStandardCard(BuildContext context, String personName, String personSpecialty, String? personAvatar) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(20), // --radius-card
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: AppColors.brandNavy.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                AvatarWidget(
                  imageUrl: personAvatar,
                  initials: _getInitials(personName),
                  size: 46,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        personName,
                        style: AppTextStyles.h3.copyWith(fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        personSpecialty,
                        style: AppTextStyles.caption.copyWith(color: AppColors.brandBlue, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(label: appointment.statusLabel, color: _statusColor),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _InfoItem(
                    icon: LucideIcons.calendar,
                    label: DateFormat('EEE d MMM', 'fr_FR').format(appointment.scheduledAt),
                  ),
                  const SizedBox(width: 16),
                  _InfoItem(
                    icon: LucideIcons.clock,
                    label: DateFormat('HH:mm').format(appointment.scheduledAt),
                  ),
                  const Spacer(),
                  _InfoItem(
                    icon: appointment.isTeleconsultation ? LucideIcons.video : LucideIcons.building_complex,
                    label: appointment.isTeleconsultation ? 'Vidéo' : 'Cabinet',
                    color: appointment.isTeleconsultation ? AppColors.brandTurquoise : AppColors.textSecondary,
                  ),
                ],
              ),
            ),
            if (appointment.isUpcoming && appointment.isTeleconsultation && onJoinCall != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: onJoinCall,
                  icon: const Icon(LucideIcons.video, size: 18),
                  label: const Text('Rejoindre l\'appel vidéo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandBlue,
                    foregroundColor: AppColors.textOnColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'MD';
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoItem({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final itemColor = color ?? AppColors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: itemColor),
        const SizedBox(width: 5),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: itemColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
