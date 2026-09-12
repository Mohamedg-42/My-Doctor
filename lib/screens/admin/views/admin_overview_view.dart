import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/message_provider.dart';
import '../../../providers/treating_request_provider.dart';
import '../../../services/database_service.dart';

class AdminOverviewView extends StatelessWidget {
  final Function(int) onNavigateTab;

  const AdminOverviewView({super.key, required this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();
    final trProvider = context.watch<TreatingRequestProvider>();
    final msgProvider = context.watch<MessageProvider>();

    final totalUsers = db.totalUsers;
    final totalPatients = db.totalPatients;
    final totalDoctors = db.totalDoctors;
    final pendingDoctors = db.totalPendingDoctors;
    final activeDoctors = db.totalActiveDoctors;

    final allRequests = trProvider.allRequests;
    final pendingRequests = allRequests.where((r) => r.isPending).length;
    final acceptedRequests = allRequests.where((r) => r.isAccepted).length;
    final rejectedRequests = allRequests.where((r) => r.status.name == 'rejected').length;

    final totalConvs = msgProvider.allConversations.length;
    final totalMsgs = msgProvider.totalMessagesCount;
    final totalAppointments = db.totalAppointments;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Bannière de bienvenue ──────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.brandNavy, Color(0xFF2C5282)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandNavy.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.shield_check, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Panneau d\'Administration',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Supervision globale du système My Doctor • $totalUsers comptes enregistrés',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Section 1 : Utilisateurs ──────────────────────────────────
          const Text(
            'Utilisateurs & Professionnels',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 700;
              final crossAxisCount = isDesktop ? 4 : 2;

              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.35,
                children: [
                  _StatCard(
                    title: 'Patients',
                    value: '$totalPatients',
                    subtitle: 'Comptes actifs',
                    icon: LucideIcons.users,
                    color: AppColors.brandBlue,
                    onTap: () => onNavigateTab(3), // Tab Patients
                  ),
                  _StatCard(
                    title: 'Médecins',
                    value: '$totalDoctors',
                    subtitle: '$activeDoctors actifs / $pendingDoctors en attente',
                    icon: LucideIcons.stethoscope,
                    color: AppColors.brandTurquoise,
                    onTap: () => onNavigateTab(2), // Tab Médecins
                  ),
                  _StatCard(
                    title: 'Validation requise',
                    value: '$pendingDoctors',
                    subtitle: 'Médecins à valider',
                    icon: LucideIcons.user_check,
                    color: pendingDoctors > 0 ? AppColors.warning : AppColors.textMuted,
                    onTap: () => onNavigateTab(2),
                  ),
                  _StatCard(
                    title: 'Total Comptes',
                    value: '$totalUsers',
                    subtitle: 'Inscriptions',
                    icon: LucideIcons.layout_grid,
                    color: AppColors.brandNavy,
                    onTap: () => onNavigateTab(1), // Tab Utilisateurs
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // ── Section 2 : Demandes & Flux Médical ──────────────────────
          const Text(
            'Demandes de mise en relation',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 700;
              final crossAxisCount = isDesktop ? 4 : 2;

              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.35,
                children: [
                  _StatCard(
                    title: 'Demandes totales',
                    value: '${allRequests.length}',
                    subtitle: 'Patient ↔ Médecin',
                    icon: LucideIcons.send,
                    color: AppColors.brandBlue,
                    onTap: () => onNavigateTab(4),
                  ),
                  _StatCard(
                    title: 'En attente',
                    value: '$pendingRequests',
                    subtitle: 'Attente réponse doc',
                    icon: LucideIcons.clock,
                    color: AppColors.warning,
                    onTap: () => onNavigateTab(4),
                  ),
                  _StatCard(
                    title: 'Acceptées',
                    value: '$acceptedRequests',
                    subtitle: 'Conversations ouvertes',
                    icon: LucideIcons.circle_check,
                    color: AppColors.brandTurquoise,
                    onTap: () => onNavigateTab(4),
                  ),
                  _StatCard(
                    title: 'Refusées',
                    value: '$rejectedRequests',
                    subtitle: 'Demandes déclinées',
                    icon: LucideIcons.circle_x,
                    color: AppColors.brandCoral,
                    onTap: () => onNavigateTab(4),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // ── Section 3 : Messagerie & Quotas ───────────────────────────
          const Text(
            'Activité de Messagerie & Quotas (10 messages)',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 700;
              final crossAxisCount = isDesktop ? 3 : 1;

              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: isDesktop ? 1.8 : 2.2,
                children: [
                  _StatCardLarge(
                    title: 'Conversations Actives',
                    value: '$totalConvs',
                    detail: 'Canaux ouverts après acceptation de demandes',
                    icon: LucideIcons.messages_square,
                    color: AppColors.brandBlue,
                    onTap: () => onNavigateTab(6),
                  ),
                  _StatCardLarge(
                    title: 'Messages Échangés',
                    value: '$totalMsgs',
                    detail: 'Total des messages transmis avec respect du quota',
                    icon: LucideIcons.message_circle,
                    color: AppColors.brandTurquoise,
                    onTap: () => onNavigateTab(6),
                  ),
                  _StatCardLarge(
                    title: 'Rendez-vous Planifiés',
                    value: '$totalAppointments',
                    detail: 'Consultations en cabinet et téléconsultations',
                    icon: LucideIcons.calendar_check,
                    color: const Color(0xFF6B46C1),
                    onTap: () => onNavigateTab(5),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // ── Section 4 : Alertes & Actions Rapides ─────────────────────
          if (pendingDoctors > 0) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warningBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.circle_alert, color: AppColors.warning, size: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$pendingDoctors médecin(s) en attente de validation',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.warning,
                          ),
                        ),
                        const Text(
                          'Les comptes médecins doivent être validés par l\'administration avant d\'apparaître aux patients.',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => onNavigateTab(2),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warning,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    child: const Text('Valider', style: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.brandNavy.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.database, color: AppColors.brandNavy, size: 20),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Données de démonstration',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Générer ou réinitialiser 6 médecins (actifs, en attente, suspendu), 4 patients avec quotas, demandes et conversations.',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Générer les données démo ?', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
                        content: const Text('Les données locales de démonstration seront remplacées.', style: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Annuler')),
                          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Confirmer')),
                        ],
                      ),
                    );
                    if (confirmed != true) return;
                    await DatabaseService().seedDemoData(force: true);
                    if (context.mounted) {
                      await context.read<TreatingRequestProvider>().seedDemoRequests(force: true);
                      await context.read<MessageProvider>().seedDemoConversations(force: true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Données de démonstration chargées avec succès !'),
                          backgroundColor: AppColors.brandTurquoise,
                        ),
                      );
                    }
                  },
                  icon: const Icon(LucideIcons.sparkles, size: 14, color: Colors.white),
                  label: const Text('Générer', style: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandNavy,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
              ],
            ),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                color: AppColors.textMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCardLarge extends StatelessWidget {
  final String title;
  final String value;
  final String detail;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StatCardLarge({
    required this.title,
    required this.value,
    required this.detail,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  Text(
                    detail,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevron_right, color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}
