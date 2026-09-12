import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => context.read<AppProvider>().markAllNotificationsRead(),
            child: const Text(
              'Tout lire',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (_, app, __) {
          if (app.notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_rounded,
                      size: 64, color: AppColors.textLight),
                  SizedBox(height: 16),
                  Text(
                    'Aucune notification',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: app.notifications.length,
            itemBuilder: (_, i) {
              final notif = app.notifications[i];
              return _NotifTile(notif: notif);
            },
          );
        },
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final AppNotification notif;
  const _NotifTile({required this.notif});

  Color get _color {
    switch (notif.type) {
      case NotifType.appointment: return AppColors.primary;
      case NotifType.message: return AppColors.accentBlue;
      case NotifType.payment: return AppColors.success;
      case NotifType.review: return const Color(0xFFFFB800);
      case NotifType.system: return AppColors.textSecondary;
      case NotifType.videoCall: return AppColors.accentBlue;
    }
  }

  IconData get _icon {
    switch (notif.type) {
      case NotifType.appointment: return Icons.calendar_today_rounded;
      case NotifType.message: return Icons.chat_bubble_rounded;
      case NotifType.payment: return Icons.payment_rounded;
      case NotifType.review: return Icons.star_rounded;
      case NotifType.system: return Icons.info_rounded;
      case NotifType.videoCall: return Icons.videocam_rounded;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    return 'Il y a ${diff.inDays} jour(s)';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<AppProvider>().markNotificationRead(notif.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notif.isRead
              ? AppColors.backgroundCard
              : _color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notif.isRead
                ? AppColors.backgroundGrey
                : _color.withValues(alpha: 0.3),
            width: notif.isRead ? 1 : 1.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon, color: _color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notif.title,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: notif.isRead ? FontWeight.w500 : FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notif.body,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _timeAgo(notif.createdAt),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            if (!notif.isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: _color,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
