// lib/screens/admin/views/admin_overview_view.dart
//
// Vue d'ensemble de la console administrateur avec KPIs et alertes rapides.

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/database_service.dart';
import '../../../providers/treating_request_provider.dart';
import '../../../providers/message_provider.dart';
import '../components/admin_kpi_card.dart';

class AdminOverviewView extends StatefulWidget {
  final ValueChanged<int> onNavigateToTab;

  const AdminOverviewView({super.key, required this.onNavigateToTab});

  @override
  State<AdminOverviewView> createState() => _AdminOverviewViewState();
}

class _AdminOverviewViewState extends State<AdminOverviewView> {
  bool _showAllCards = false; // Par défaut, affichage réduit (6 indicateurs essentiels)

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();
    final requestProvider = context.watch<TreatingRequestProvider>();
    final messageProvider = context.watch<MessageProvider>();

    final allUsers = db.getAllUsers();
    final allDoctors = db.getAllDoctors(onlyActive: false);
    final activeDoctors = allDoctors.where((d) => d.status == 'active').length;
    final pendingDoctors = allDoctors.where((d) => d.status == 'pending').length;
    final allPatients = db.getAllPatients();
    final allAppointments = db.getAllAppointments();
    final allRequests = requestProvider.allRequests;
    final pendingRequests = allRequests.where((r) => r.isPending).length;
    final conversations = messageProvider.conversations;
    final totalMessages = conversations.fold<int>(
      0,
      (sum, c) => sum + messageProvider.messagesOf(c.id).length,
    );

    // Patients ayant épuisé leur quota
    int quotaExceededCount = 0;
    for (final p in allPatients) {
      final usage = db.getPatientMessageUsage(p.id);
      if (usage.isLimitReached) quotaExceededCount++;
    }

    // Nombre de cartes (patients avec carte ou numéro CMU)
    final cardsCount = allPatients.where((p) => p.cmuNumber?.isNotEmpty == true).length;

    // Retraits simulés
    const pendingWithdrawalsCount = 1;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section Alertes d'action rapide ──────────────────────────
          if (pendingDoctors > 0 || pendingWithdrawalsCount > 0 || pendingRequests > 0) ...[
            const Text(
              'Actions prioritaires requises',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED), // Ambre léger
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFDBA74)),
              ),
              child: Column(
                children: [
                  if (pendingDoctors > 0)
                    _AlertRow(
                      icon: LucideIcons.user_check,
                      title: '$pendingDoctors médecin(s) en attente de validation administrative',
                      buttonLabel: 'Valider les médecins',
                      color: const Color(0xFFEA580C),
                      onTap: () => widget.onNavigateToTab(3),
                    ),
                  if (pendingWithdrawalsCount > 0) ...[
                    if (pendingDoctors > 0) const Divider(height: 16, color: Color(0xFFFED7AA)),
                    _AlertRow(
                      icon: LucideIcons.wallet,
                      title: '$pendingWithdrawalsCount demande(s) de retrait financier à traiter',
                      buttonLabel: 'Voir les finances',
                      color: AppColors.brandCoral,
                      onTap: () => widget.onNavigateToTab(2),
                    ),
                  ],
                  if (pendingRequests > 0) ...[
                    const Divider(height: 16, color: Color(0xFFFED7AA)),
                    _AlertRow(
                      icon: LucideIcons.clock,
                      title: '$pendingRequests demande(s) de médecin traitant en attente',
                      buttonLabel: 'Consulter',
                      color: AppColors.brandBlue,
                      onTap: () => widget.onNavigateToTab(6),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 22),
          ],

          // ── Titre Grille KPIs avec Toggle Réduit / Complet ──────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Indicateurs clés',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _showAllCards ? 'Affichage complet (12)' : 'Vue réduite (6 cartes clés)',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => setState(() => _showAllCards = !_showAllCards),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF185FA5).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF185FA5).withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showAllCards ? LucideIcons.minimize_2 : LucideIcons.maximize_2,
                        size: 13,
                        color: const Color(0xFF185FA5),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _showAllCards ? 'Réduire' : 'Afficher tout (12)',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF185FA5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Grille responsive compacte
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final int crossAxisCount;
              final double childAspectRatio;

              if (width > 1200) {
                crossAxisCount = 4;
                childAspectRatio = 2.25;
              } else if (width > 850) {
                crossAxisCount = 3;
                childAspectRatio = 2.1;
              } else if (width > 550) {
                crossAxisCount = 2;
                childAspectRatio = 2.0;
              } else if (width > 340) {
                crossAxisCount = 2;
                childAspectRatio = 1.35;
              } else {
                crossAxisCount = 1;
                childAspectRatio = 2.6;
              }

              final keyCards = [
                AdminKpiCard(
                  title: 'Utilisateurs inscrits',
                  value: '${allUsers.length}',
                  icon: LucideIcons.users,
                  accentColor: const Color(0xFF0F172A),
                  subtitle: 'Comptes enregistrés',
                  onTap: () => widget.onNavigateToTab(4),
                ),
                AdminKpiCard(
                  title: 'Médecins actifs',
                  value: '$activeDoctors',
                  icon: LucideIcons.stethoscope,
                  accentColor: AppColors.brandBlue,
                  subtitle: 'Sur ${allDoctors.length} praticiens',
                  onTap: () => widget.onNavigateToTab(3),
                ),
                AdminKpiCard(
                  title: 'Médecins en attente',
                  value: '$pendingDoctors',
                  icon: LucideIcons.user_plus,
                  accentColor: const Color(0xFFEA580C),
                  isAlert: pendingDoctors > 0,
                  subtitle: 'Dossiers à valider',
                  onTap: () => widget.onNavigateToTab(3),
                ),
                AdminKpiCard(
                  title: 'Patients inscrits',
                  value: '${allPatients.length}',
                  icon: LucideIcons.heart_pulse,
                  accentColor: AppColors.brandTurquoise,
                  subtitle: 'Dossiers actifs',
                  onTap: () => widget.onNavigateToTab(4),
                ),
                AdminKpiCard(
                  title: 'Cartes patient & CMU',
                  value: '$cardsCount',
                  icon: LucideIcons.id_card,
                  accentColor: const Color(0xFF185FA5),
                  subtitle: 'Affiliations enregistrées',
                  onTap: () => widget.onNavigateToTab(1),
                ),
                AdminKpiCard(
                  title: 'Retraits en attente',
                  value: '$pendingWithdrawalsCount',
                  icon: LucideIcons.banknote,
                  accentColor: AppColors.brandCoral,
                  isAlert: pendingWithdrawalsCount > 0,
                  subtitle: 'Paiements à transférer',
                  onTap: () => widget.onNavigateToTab(2),
                ),
              ];

              final moreCards = [
                AdminKpiCard(
                  title: 'Total Rendez-vous',
                  value: '${allAppointments.length}',
                  icon: LucideIcons.calendar,
                  accentColor: const Color(0xFF8B5CF6),
                  subtitle: 'Consultations créées',
                  onTap: () => widget.onNavigateToTab(5),
                ),
                AdminKpiCard(
                  title: 'Demandes traitant',
                  value: '${allRequests.length}',
                  icon: LucideIcons.user_check,
                  accentColor: AppColors.brandBlue,
                  subtitle: '$pendingRequests en cours',
                  onTap: () => widget.onNavigateToTab(6),
                ),
                AdminKpiCard(
                  title: 'Conversations ouvertes',
                  value: '${conversations.length}',
                  icon: LucideIcons.message_square,
                  accentColor: const Color(0xFF0284C7),
                  subtitle: 'Fils de discussion',
                  onTap: () => widget.onNavigateToTab(7),
                ),
                AdminKpiCard(
                  title: 'Messages échangés',
                  value: '$totalMessages',
                  icon: LucideIcons.messages_square,
                  accentColor: const Color(0xFF059669),
                  subtitle: 'Trafic messagerie',
                  onTap: () => widget.onNavigateToTab(7),
                ),
                AdminKpiCard(
                  title: 'Quotas messages épuisés',
                  value: '$quotaExceededCount',
                  icon: LucideIcons.circle_alert,
                  accentColor: const Color(0xFFD97706),
                  isAlert: quotaExceededCount > 0,
                  subtitle: 'Patients au plafond gratuit',
                  onTap: () => widget.onNavigateToTab(4),
                ),
                AdminKpiCard(
                  title: 'Configuration',
                  value: 'Opérationnel',
                  icon: LucideIcons.settings_2,
                  accentColor: const Color(0xFF475569),
                  subtitle: 'Services & Démonstration',
                  onTap: () => widget.onNavigateToTab(8),
                ),
              ];

              return Column(
                children: [
                  GridView.count(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: childAspectRatio,
                    children: _showAllCards ? [...keyCards, ...moreCards] : keyCards,
                  ),
                  const SizedBox(height: 12),
                  if (!_showAllCards)
                    Center(
                      child: TextButton.icon(
                        onPressed: () => setState(() => _showAllCards = true),
                        icon: const Icon(LucideIcons.chevron_down, size: 14, color: Color(0xFF185FA5)),
                        label: const Text(
                          'Afficher les 6 autres indicateurs (Rendez-vous, Messages, Quotas...)',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF185FA5),
                          ),
                        ),
                      ),
                    ),
                  if (_showAllCards)
                    Center(
                      child: TextButton.icon(
                        onPressed: () => setState(() => _showAllCards = false),
                        icon: const Icon(LucideIcons.chevron_up, size: 14, color: Color(0xFF185FA5)),
                        label: const Text(
                          'Réduire aux 6 indicateurs clés',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF185FA5),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String buttonLabel;
  final Color color;
  final VoidCallback onTap;

  const _AlertRow({
    required this.icon,
    required this.title,
    required this.buttonLabel,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 440;
        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    buttonLabel,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        return Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                buttonLabel,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
