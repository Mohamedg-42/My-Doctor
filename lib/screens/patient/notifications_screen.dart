import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
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
                      selectedColor: AppColors.primary,
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
                      selectedColor: AppColors.primary,
                      checkmarkColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ],
                ),
              ),

              // Liste
              Expanded(
                child: displayed.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.notifications_none_rounded,
                                size: 64, color: AppColors.textLight),
                            const SizedBox(height: 16),
                            Text(
                              _onlyUnread
                                  ? 'Aucune notification non lue'
                                  : 'Aucune notification',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 15,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: displayed.length,
                        itemBuilder: (_, i) {
                          final notif = displayed[i];
                          return _NotifTile(notif: notif);
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
    if (diff.inSeconds < 60) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays == 1) return 'Hier';
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
                : _color.withValues(alpha: 0.35),
            width: notif.isRead ? 1 : 1.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_icon, color: _color, size: 20),
                ),
                if (!notif.isRead)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: notif.isRead ? FontWeight.w500 : FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (!notif.isRead) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'NON LU',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
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
          ],
        ),
      ),
    );
  }
}
