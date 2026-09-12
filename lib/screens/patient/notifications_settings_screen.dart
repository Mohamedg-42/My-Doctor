// ════════════════════════════════════════════════════════════
//  notifications_settings_screen.dart
//  HELLO DOC - Paramètres des notifications
// ════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  // Préférences de notifications
  bool _rdvReminders = true;
  bool _medicationReminders = true;
  bool _doctorMessages = true;
  bool _healthTips = false;
  bool _promotions = false;
  bool _systemUpdates = true;
  
  // Paramètres de fréquence
  String _reminderTiming = '1h'; // 1h avant le RDV
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rdvReminders = prefs.getBool('notif_rdv') ?? true;
      _medicationReminders = prefs.getBool('notif_medication') ?? true;
      _doctorMessages = prefs.getBool('notif_messages') ?? true;
      _healthTips = prefs.getBool('notif_tips') ?? false;
      _promotions = prefs.getBool('notif_promos') ?? false;
      _systemUpdates = prefs.getBool('notif_system') ?? true;
      _reminderTiming = prefs.getString('reminder_timing') ?? '1h';
      _soundEnabled = prefs.getBool('notif_sound') ?? true;
      _vibrationEnabled = prefs.getBool('notif_vibration') ?? true;
    });
  }

  Future<void> _savePreference(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.warning,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Types de notifications
          const _SectionHeader(
            icon: Icons.notifications_active,
            title: 'Types de notifications',
            color: AppColors.warning,
          ),
          _NotificationTile(
            icon: Icons.calendar_today,
            title: 'Rappels de rendez-vous',
            subtitle: 'Notifications avant vos consultations',
            value: _rdvReminders,
            onChanged: (val) {
              setState(() => _rdvReminders = val);
              _savePreference('notif_rdv', val);
            },
          ),
          _NotificationTile(
            icon: Icons.medication,
            title: 'Rappels de médicaments',
            subtitle: 'Horaires de prise de médicaments',
            value: _medicationReminders,
            onChanged: (val) {
              setState(() => _medicationReminders = val);
              _savePreference('notif_medication', val);
            },
          ),
          _NotificationTile(
            icon: Icons.message,
            title: 'Messages des médecins',
            subtitle: 'Nouveaux messages de vos praticiens',
            value: _doctorMessages,
            onChanged: (val) {
              setState(() => _doctorMessages = val);
              _savePreference('notif_messages', val);
            },
          ),
          _NotificationTile(
            icon: Icons.lightbulb_outline,
            title: 'Conseils santé',
            subtitle: 'Astuces et recommandations',
            value: _healthTips,
            onChanged: (val) {
              setState(() => _healthTips = val);
              _savePreference('notif_tips', val);
            },
          ),
          _NotificationTile(
            icon: Icons.local_offer,
            title: 'Offres et promotions',
            subtitle: 'Promotions sur les consultations',
            value: _promotions,
            onChanged: (val) {
              setState(() => _promotions = val);
              _savePreference('notif_promos', val);
            },
          ),
          _NotificationTile(
            icon: Icons.system_update,
            title: 'Mises à jour système',
            subtitle: 'Nouvelles fonctionnalités de l\'app',
            value: _systemUpdates,
            onChanged: (val) {
              setState(() => _systemUpdates = val);
              _savePreference('notif_system', val);
            },
          ),

          const SizedBox(height: 24),

          // Paramètres de rappel
          const _SectionHeader(
            icon: Icons.schedule,
            title: 'Timing des rappels',
            color: AppColors.primary,
          ),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rappeler avant le rendez-vous',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      _TimingChip(
                        label: '15 min',
                        value: '15m',
                        selected: _reminderTiming == '15m',
                        onSelected: () {
                          setState(() => _reminderTiming = '15m');
                          _savePreference('reminder_timing', '15m');
                        },
                      ),
                      _TimingChip(
                        label: '30 min',
                        value: '30m',
                        selected: _reminderTiming == '30m',
                        onSelected: () {
                          setState(() => _reminderTiming = '30m');
                          _savePreference('reminder_timing', '30m');
                        },
                      ),
                      _TimingChip(
                        label: '1 heure',
                        value: '1h',
                        selected: _reminderTiming == '1h',
                        onSelected: () {
                          setState(() => _reminderTiming = '1h');
                          _savePreference('reminder_timing', '1h');
                        },
                      ),
                      _TimingChip(
                        label: '2 heures',
                        value: '2h',
                        selected: _reminderTiming == '2h',
                        onSelected: () {
                          setState(() => _reminderTiming = '2h');
                          _savePreference('reminder_timing', '2h');
                        },
                      ),
                      _TimingChip(
                        label: '1 jour',
                        value: '1d',
                        selected: _reminderTiming == '1d',
                        onSelected: () {
                          setState(() => _reminderTiming = '1d');
                          _savePreference('reminder_timing', '1d');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Paramètres sonores
          const _SectionHeader(
            icon: Icons.volume_up,
            title: 'Son et vibrations',
            color: AppColors.accentBlue,
          ),
          _NotificationTile(
            icon: Icons.volume_up,
            title: 'Son des notifications',
            subtitle: 'Jouer un son pour les alertes',
            value: _soundEnabled,
            onChanged: (val) {
              setState(() => _soundEnabled = val);
              _savePreference('notif_sound', val);
            },
          ),
          _NotificationTile(
            icon: Icons.vibration,
            title: 'Vibrations',
            subtitle: 'Vibrer lors des notifications',
            value: _vibrationEnabled,
            onChanged: (val) {
              setState(() => _vibrationEnabled = val);
              _savePreference('notif_vibration', val);
            },
          ),

          const SizedBox(height: 24),

          // Bouton test
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🔔 Notification test envoyée !'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.notification_important),
              label: const Text('Tester les notifications'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotificationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        activeThumbColor: AppColors.primary,
      ),
    );
  }
}

class _TimingChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onSelected;

  const _TimingChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      backgroundColor: Colors.grey[100],
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: selected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected ? AppColors.primary : Colors.transparent,
          width: 1.5,
        ),
      ),
    );
  }
}
