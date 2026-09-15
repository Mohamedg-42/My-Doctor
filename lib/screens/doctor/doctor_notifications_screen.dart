import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_provider.dart';

class DoctorNotificationsScreen extends StatefulWidget {
  const DoctorNotificationsScreen({super.key});

  @override
  State<DoctorNotificationsScreen> createState() => _DoctorNotificationsScreenState();
}

class _DoctorNotificationsScreenState extends State<DoctorNotificationsScreen> {
  bool _onlyUnread = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.arrow_left, size: 18, color: AppColors.textPrimary),
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Consumer<AppProvider>(
          builder: (_, app, __) {
            final unreadCount = app.notifications.where((n) => !n.isRead).length;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                if (unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          Consumer<AppProvider>(
            builder: (_, app, __) {
              final unreadCount = app.notifications.where((n) => !n.isRead).length;
              if (unreadCount == 0) return const SizedBox.shrink();
              
              return TextButton.icon(
                onPressed: () => app.markAllNotificationsRead(),
                icon: const Icon(Icons.done_all, size: 16, color: AppColors.primary),
                label: const Text(
                  'Tout lire',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (_, app, __) {
          final allNotifications = app.notifications
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          final unreadCount = allNotifications.where((n) => !n.isRead).length;
          final displayed = _onlyUnread
              ? allNotifications.where((n) => !n.isRead).toList()
              : allNotifications;

          return Column(
            children: [
              // Barre de filtres avec compteurs
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
                ),
                child: Row(
                  children: [
                    FilterChip(
                      selected: !_onlyUnread,
                      onSelected: (_) => setState(() => _onlyUnread = false),
                      label: Text('Toutes (${allNotifications.length})'),
                      labelStyle: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: !_onlyUnread ? FontWeight.w700 : FontWeight.w500,
                        color: !_onlyUnread ? Colors.white : AppColors.textSecondary,
                      ),
                      backgroundColor: AppColors.surfaceSubtle,
                      selectedColor: const Color(0xFF0F172A),
                      checkmarkColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      selected: _onlyUnread,
                      onSelected: (_) => setState(() => _onlyUnread = true),
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Non lues',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: _onlyUnread ? FontWeight.w700 : FontWeight.w500,
                              color: _onlyUnread ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                          if (unreadCount > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$unreadCount',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      backgroundColor: AppColors.surfaceSubtle,
                      selectedColor: const Color(0xFF0F172A),
                      checkmarkColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ],
                ),
              ),

              // Liste des notifications
              Expanded(
                child: displayed.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.notifications_none_rounded,
                                size: 64,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              _onlyUnread
                                  ? 'Aucune notification non lue'
                                  : 'Aucune notification',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _onlyUnread
                                  ? 'Toutes vos notifications sont à jour.'
                                  : 'Vous n\'avez pas encore de notifications',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                color: AppColors.textSecondary.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: displayed.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, index) {
                          final notification = displayed[index];
                          return _NotificationTile(notification: notification);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;

  const _NotificationTile({required this.notification});

  Color get _color {
    switch (notification.type) {
      case NotifType.appointment:
        return const Color(0xFF4DD0E1); // Turquoise
      case NotifType.message:
        return const Color(0xFF2196F3); // Blue
      case NotifType.payment:
        return const Color(0xFF4CAF50); // Green
      case NotifType.review:
        return const Color(0xFFFFB800); // Orange/Yellow
      case NotifType.system:
        return const Color(0xFF9E9E9E); // Grey
      case NotifType.videoCall:
        return const Color(0xFFE91E63); // Pink
    }
  }

  IconData get _icon {
    switch (notification.type) {
      case NotifType.appointment:
        return Icons.event_available_rounded;
      case NotifType.message:
        return Icons.chat_bubble_rounded;
      case NotifType.payment:
        return Icons.payment_rounded;
      case NotifType.review:
        return Icons.star_rounded;
      case NotifType.system:
        return Icons.notifications_active_rounded;
      case NotifType.videoCall:
        return Icons.videocam_rounded;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} jours';
    if (diff.inDays < 30) return 'Il y a ${(diff.inDays / 7).floor()} semaines';
    return 'Il y a ${(diff.inDays / 30).floor()} mois';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Marquer comme lu
        context.read<AppProvider>().markNotificationRead(notification.id);
        
        // Navigation si une route est définie
        if (notification.routeOnTap != null) {
          // TODO: Implémenter la navigation vers la route spécifiée
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Navigation vers: ${notification.routeOnTap}'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead 
              ? Colors.white 
              : _color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notification.isRead
                ? Colors.grey[200]!
                : _color.withValues(alpha: 0.3),
            width: notification.isRead ? 1 : 2,
          ),
          boxShadow: [
            if (!notification.isRead)
              BoxShadow(
                color: _color.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icône avec badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_icon, color: _color, size: 24),
                ),
                if (!notification.isRead)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            // Contenu
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            fontWeight: notification.isRead 
                                ? FontWeight.w500 
                                : FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Badge "NON LU"
                      if (!notification.isRead)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'NON LU',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.body,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: AppColors.textSecondary.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _timeAgo(notification.createdAt),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: AppColors.textSecondary.withValues(alpha: 0.7),
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
