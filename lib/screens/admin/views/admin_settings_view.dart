// lib/screens/admin/views/admin_settings_view.dart
//
// Vue de configuration système et gestion contrôlée de la plateforme pour l'administrateur.

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/database_service.dart';

class AdminSettingsView extends StatefulWidget {
  const AdminSettingsView({super.key});

  @override
  State<AdminSettingsView> createState() => _AdminSettingsViewState();
}

class _AdminSettingsViewState extends State<AdminSettingsView> {
  int _freeMessagesLimit = 10;
  double _withdrawalCommission = 10.0;
  bool _enableTeleconsultation = true;
  bool _enableCmuVerification = true;
  bool _enableNotifications = true;
  bool _isResetting = false;

  Future<void> _handleResetDemoData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(LucideIcons.triangle_alert, color: AppColors.error),
            const SizedBox(width: 8),
            Text('Réinitialisation des données de test'),
          ],
        ),
        content: const Text(
          'ATTENTION : Cette action va réinitialiser les comptes de démonstration (médecins, patients, quotas et rendez-vous d\'exemple) à leur état initial.\n\nLes comptes réels ne sont pas affectés.\n\nVoulez-vous continuer ?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Réinitialiser les démos'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isResetting = true);

    try {
      await DatabaseService().seedDemoData(force: true);
      await DatabaseService().resetAllPatientsMessageUsage(_freeMessagesLimit);
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;
      setState(() => _isResetting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Données de démonstration réinitialisées avec succès.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isResetting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Paramètres & Configuration Système',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 6),
          Text(
            'Gérez les règles métier, les quotas de messagerie et la maintenance de la plateforme.',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),

          // ── Carte 1 : Paramètres Quotas et Tarification ──────────────
          _SettingsSection(
            title: 'Messagerie & Quotas gratuits',
            icon: LucideIcons.message_circle,
            children: [
              ListTile(
                title: const Text('Nombre de messages gratuits par patient'),
                subtitle: const Text('Limite allouée avant de proposer un forfait ou abonnement'),
                trailing: DropdownButton<int>(
                  value: _freeMessagesLimit,
                  items: [5, 10, 15, 20].map((v) => DropdownMenuItem(value: v, child: Text('$v messages'))).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _freeMessagesLimit = v);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Limite mise à jour : $v messages.'), duration: const Duration(seconds: 1)),
                      );
                    }
                  },
                ),
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Commission sur retraits praticiens'),
                subtitle: const Text('Pourcentage prélevé sur les consultations encaissées'),
                trailing: DropdownButton<double>(
                  value: _withdrawalCommission,
                  items: [5.0, 10.0, 15.0, 20.0].map((v) => DropdownMenuItem(value: v, child: Text('$v%'))).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _withdrawalCommission = v);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Commission ajustée à $v%.'), duration: const Duration(seconds: 1)),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Carte 2 : Fonctionnalités de la plateforme ───────────────
          _SettingsSection(
            title: 'Fonctionnalités & Modules actifs',
            icon: LucideIcons.toggle_right,
            children: [
              SwitchListTile(
                title: const Text('Téléconsultation vidéo active'),
                subtitle: const Text('Permet les rendez-vous en visio consultation sécurisée'),
                value: _enableTeleconsultation,
                activeThumbColor: AppColors.brandBlue,
                onChanged: (v) => setState(() => _enableTeleconsultation = v),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Vérification automatique CNAM / CMU-CI'),
                subtitle: const Text('Contrôle la validité des numéros de carte CMU lors de l\'enregistrement'),
                value: _enableCmuVerification,
                activeThumbColor: AppColors.brandBlue,
                onChanged: (v) => setState(() => _enableCmuVerification = v),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Notifications in-app & alertes SMS'),
                subtitle: const Text('Envoi automatique des rappels de RDV et alertes praticiens'),
                value: _enableNotifications,
                activeThumbColor: AppColors.brandBlue,
                onChanged: (v) => setState(() => _enableNotifications = v),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Carte 3 : Maintenance & Données Démo ────────────────────
          _SettingsSection(
            title: 'Environnement & Données de démonstration',
            icon: LucideIcons.database,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Données de démonstration actives',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Initialise 6 médecins (3 actifs, 2 en attente, 1 suspendu), 4 patients tests, 4 rendez-vous et 4 demandes traitant.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isResetting ? null : _handleResetDemoData,
                      icon: _isResetting
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(LucideIcons.refresh_cw, size: 16),
                      label: Text(_isResetting ? 'Réinitialisation en cours...' : 'Régénérer les données de démo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEA580C),
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Carte 4 : Informations Système ──────────────────────────
          _SettingsSection(
            title: 'Informations système & Version',
            icon: LucideIcons.info,
            children: [
              _InfoListTile('Version de l\'application', 'My Doctor v2.0 (Build 2026.09)'),
              _InfoListTile('Moteur de données local', 'Hive NoSQL (Chiffré localement)'),
              _InfoListTile('Synchronisation cloud', 'Supabase PostgreSQL (Optionnel)'),
              _InfoListTile('Fuseau horaire système', 'GMT / Côte d\'Ivoire (Abidjan)'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.brandBlue),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }
}

class _InfoListTile extends StatelessWidget {
  final String label;
  final String value;
  const _InfoListTile(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 480) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            );
          }
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
