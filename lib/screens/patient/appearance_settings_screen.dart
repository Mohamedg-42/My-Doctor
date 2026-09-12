// ════════════════════════════════════════════════════════════
//  appearance_settings_screen.dart
//  HELLO DOC - Paramètres d'apparence
// ════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';

class AppearanceSettingsScreen extends StatefulWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  State<AppearanceSettingsScreen> createState() => _AppearanceSettingsScreenState();
}

class _AppearanceSettingsScreenState extends State<AppearanceSettingsScreen> {
  String _themeMode = 'light'; // light, dark, auto
  double _textScale = 1.0;
  bool _highContrast = false;
  bool _reducedMotion = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _themeMode = prefs.getString('theme_mode') ?? 'light';
      _textScale = prefs.getDouble('text_scale') ?? 1.0;
      _highContrast = prefs.getBool('high_contrast') ?? false;
      _reducedMotion = prefs.getBool('reduced_motion') ?? false;
    });
  }

  Future<void> _savePreference(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is String) {
      await prefs.setString(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Apparence',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF6C5CE7),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section Thème
          const _SectionHeader(
            icon: Icons.dark_mode,
            title: 'Thème de l\'application',
            color: Color(0xFF6C5CE7),
          ),
          _ThemeCard(
            icon: Icons.light_mode,
            title: 'Clair',
            subtitle: 'Thème lumineux',
            selected: _themeMode == 'light',
            onTap: () {
              setState(() => _themeMode = 'light');
              _savePreference('theme_mode', 'light');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Thème clair activé')),
              );
            },
          ),
          _ThemeCard(
            icon: Icons.dark_mode,
            title: 'Sombre',
            subtitle: 'Thème sombre (à venir)',
            selected: _themeMode == 'dark',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Mode sombre bientôt disponible')),
              );
            },
          ),
          _ThemeCard(
            icon: Icons.brightness_auto,
            title: 'Automatique',
            subtitle: 'Suit les paramètres système',
            selected: _themeMode == 'auto',
            onTap: () {
              setState(() => _themeMode = 'auto');
              _savePreference('theme_mode', 'auto');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Thème automatique activé')),
              );
            },
          ),

          const SizedBox(height: 24),

          // Section Taille du texte
          const _SectionHeader(
            icon: Icons.text_fields,
            title: 'Taille du texte',
            color: AppColors.primary,
          ),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Exemple de texte',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${(_textScale * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Ce texte changera de taille selon votre préférence',
                    style: TextStyle(
                      fontSize: 16 * _textScale,
                      height: 1.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Text('A', style: TextStyle(fontSize: 12)),
                      Expanded(
                        child: Slider(
                          value: _textScale,
                          min: 0.8,
                          max: 1.5,
                          divisions: 7,
                          label: '${(_textScale * 100).toInt()}%',
                          onChanged: (value) {
                            setState(() => _textScale = value);
                            _savePreference('text_scale', value);
                          },
                        ),
                      ),
                      const Text('A', style: TextStyle(fontSize: 20)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ajustez la taille du texte pour améliorer la lisibilité',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Section Accessibilité
          const _SectionHeader(
            icon: Icons.accessibility_new,
            title: 'Accessibilité',
            color: AppColors.success,
          ),
          _AccessibilityTile(
            icon: Icons.contrast,
            title: 'Contraste élevé',
            subtitle: 'Améliore la lisibilité des textes',
            value: _highContrast,
            onChanged: (val) {
              setState(() => _highContrast = val);
              _savePreference('high_contrast', val);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    val ? 'Contraste élevé activé' : 'Contraste normal activé',
                  ),
                ),
              );
            },
          ),
          _AccessibilityTile(
            icon: Icons.motion_photos_off,
            title: 'Réduire les animations',
            subtitle: 'Limite les mouvements à l\'écran',
            value: _reducedMotion,
            onChanged: (val) {
              setState(() => _reducedMotion = val);
              _savePreference('reduced_motion', val);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    val ? 'Animations réduites' : 'Animations normales',
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Aperçu des couleurs
          const _SectionHeader(
            icon: Icons.palette,
            title: 'Palette de couleurs',
            color: AppColors.accentBlue,
          ),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _ColorCircle(color: AppColors.primary, label: 'Principal'),
                  _ColorCircle(color: AppColors.success, label: 'Succès'),
                  _ColorCircle(color: AppColors.error, label: 'Erreur'),
                  _ColorCircle(color: AppColors.warning, label: 'Attention'),
                  _ColorCircle(color: AppColors.accentBlue, label: 'Accent'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Bouton réinitialiser
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _themeMode = 'light';
                  _textScale = 1.0;
                  _highContrast = false;
                  _reducedMotion = false;
                });
                _savePreference('theme_mode', 'light');
                _savePreference('text_scale', 1.0);
                _savePreference('high_contrast', false);
                _savePreference('reduced_motion', false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Paramètres réinitialisés'),
                  ),
                );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Réinitialiser l\'apparence'),
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

class _ThemeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? AppColors.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (selected ? AppColors.primary : Colors.grey[300])?.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: selected ? AppColors.primary : Colors.grey[600],
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: selected
            ? const Icon(Icons.check_circle, color: AppColors.primary)
            : null,
      ),
    );
  }
}

class _AccessibilityTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _AccessibilityTile({
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
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.success, size: 22),
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
        activeThumbColor: AppColors.success,
      ),
    );
  }
}

class _ColorCircle extends StatelessWidget {
  final Color color;
  final String label;

  const _ColorCircle({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey[300]!, width: 2),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
