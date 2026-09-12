// ════════════════════════════════════════════════════════════
//  security_privacy_screen.dart
//  HELLO DOC - Sécurité & Confidentialité
// ════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class SecurityPrivacyScreen extends StatefulWidget {
  const SecurityPrivacyScreen({super.key});

  @override
  State<SecurityPrivacyScreen> createState() => _SecurityPrivacyScreenState();
}

class _SecurityPrivacyScreenState extends State<SecurityPrivacyScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Sécurité & Confidentialité',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.error,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section Mot de passe
          const _SectionHeader(
            icon: Icons.lock,
            title: 'Authentification',
            color: AppColors.error,
          ),
          _SecurityMenuItem(
            icon: Icons.password,
            title: 'Changer le mot de passe',
            subtitle: 'Modifiez votre mot de passe actuel',
            onTap: () => _showChangePasswordDialog(context),
          ),
          _SecurityMenuItem(
            icon: Icons.shield,
            title: 'Authentification à deux facteurs',
            subtitle: 'Protection supplémentaire de votre compte',
            trailing: Switch(
              value: false,
              onChanged: (val) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fonctionnalité à venir'),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // Section Confidentialité
          const _SectionHeader(
            icon: Icons.privacy_tip,
            title: 'Confidentialité',
            color: Colors.blue,
          ),
          _SecurityMenuItem(
            icon: Icons.visibility_off,
            title: 'Qui peut voir mon profil',
            subtitle: 'Uniquement mes médecins traitants',
            onTap: () => _showPrivacyOptionsDialog(context),
          ),
          const _SecurityMenuItem(
            icon: Icons.history,
            title: 'Historique des consultations',
            subtitle: 'Visible par mes médecins',
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
          ),
          _SecurityMenuItem(
            icon: Icons.share,
            title: 'Partage de données',
            subtitle: 'Contrôlez qui accède à vos données',
            onTap: () => _showDataSharingDialog(context),
          ),

          const SizedBox(height: 24),

          // Section Données
          const _SectionHeader(
            icon: Icons.storage,
            title: 'Gestion des données',
            color: AppColors.warning,
          ),
          _SecurityMenuItem(
            icon: Icons.download,
            title: 'Télécharger mes données',
            subtitle: 'Exportez toutes vos données médicales',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('📥 Préparation de l\'export...'),
                ),
              );
            },
          ),
          _SecurityMenuItem(
            icon: Icons.delete_forever,
            title: 'Supprimer mon compte',
            subtitle: 'Action irréversible',
            onTap: () => _showDeleteAccountDialog(context),
            isDestructive: true,
          ),

          const SizedBox(height: 24),

          // Section Sessions
          const _SectionHeader(
            icon: Icons.devices,
            title: 'Sessions actives',
            color: AppColors.accentBlue,
          ),
          const _SessionCard(
            device: 'Navigateur Web',
            location: 'Abidjan, Côte d\'Ivoire',
            lastActive: 'Actif maintenant',
            isCurrent: true,
          ),
          _SessionCard(
            device: 'Application Mobile',
            location: 'Abidjan, Côte d\'Ivoire',
            lastActive: 'Il y a 2 heures',
            isCurrent: false,
            onRevoke: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Session révoquée')),
              );
            },
          ),

          const SizedBox(height: 24),

          // Bouton déconnexion
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showLogoutAllDialog(context),
              icon: const Icon(Icons.logout),
              label: const Text('Déconnecter tous les appareils'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
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

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Changer le mot de passe'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mot de passe actuel',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nouveau mot de passe',
                prefixIcon: Icon(Icons.lock_open),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirmer le mot de passe',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implémenter changement de mot de passe
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Mot de passe modifié avec succès'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Modifier'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyOptionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Visibilité du profil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile(
              value: 'doctors',
              groupValue: 'doctors',
              onChanged: (val) {},
              title: const Text('Uniquement mes médecins'),
              subtitle: const Text('Recommandé'),
            ),
            RadioListTile(
              value: 'all',
              groupValue: 'doctors',
              onChanged: (val) {},
              title: const Text('Tous les professionnels'),
              subtitle: const Text('Visible par tous les médecins'),
            ),
            RadioListTile(
              value: 'none',
              groupValue: 'doctors',
              onChanged: (val) {},
              title: const Text('Privé'),
              subtitle: const Text('Profil masqué'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Préférences enregistrées')),
              );
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _showDataSharingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Partage de données'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choisissez les informations à partager :',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: true,
              onChanged: (val) {},
              title: const Text('Antécédents médicaux'),
            ),
            CheckboxListTile(
              value: true,
              onChanged: (val) {},
              title: const Text('Allergies'),
            ),
            CheckboxListTile(
              value: true,
              onChanged: (val) {},
              title: const Text('Vaccinations'),
            ),
            CheckboxListTile(
              value: false,
              onChanged: (val) {},
              title: const Text('Ordonnances'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: AppColors.error),
            SizedBox(width: 8),
            Text('Supprimer le compte'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cette action est irréversible !',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
            SizedBox(height: 12),
            Text('Toutes vos données seront définitivement supprimées :'),
            SizedBox(height: 8),
            Text('• Dossier médical'),
            Text('• Historique de consultations'),
            Text('• Ordonnances et examens'),
            Text('• Carnet de vaccinations'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pour supprimer votre compte, contactez le support'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Confirmer la suppression'),
          ),
        ],
      ),
    );
  }

  void _showLogoutAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnecter tous les appareils'),
        content: const Text(
          'Vous allez être déconnecté de tous vos appareils. Vous devrez vous reconnecter sur chaque appareil.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/welcome', (r) => false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Déconnecter'),
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

class _SecurityMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool isDestructive;

  const _SecurityMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (isDestructive ? AppColors.error : AppColors.primary).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: isDestructive ? AppColors.error : AppColors.primary,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDestructive ? AppColors.error : AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final String device;
  final String location;
  final String lastActive;
  final bool isCurrent;
  final VoidCallback? onRevoke;

  const _SessionCard({
    required this.device,
    required this.location,
    required this.lastActive,
    required this.isCurrent,
    this.onRevoke,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accentBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                device.contains('Mobile') ? Icons.phone_android : Icons.computer,
                color: AppColors.accentBlue,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        device,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Actuel',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    location,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    lastActive,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            if (!isCurrent && onRevoke != null)
              IconButton(
                onPressed: onRevoke,
                icon: const Icon(Icons.close, color: AppColors.error),
                tooltip: 'Révoquer',
              ),
          ],
        ),
      ),
    );
  }
}
