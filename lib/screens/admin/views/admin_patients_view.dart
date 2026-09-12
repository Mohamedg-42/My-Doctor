import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/treating_request_provider.dart';
import '../../../services/database_service.dart';

class AdminPatientsView extends StatefulWidget {
  const AdminPatientsView({super.key});

  @override
  State<AdminPatientsView> createState() => _AdminPatientsViewState();
}

class _AdminPatientsViewState extends State<AdminPatientsView> {
  final _db = DatabaseService();
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trProvider = context.watch<TreatingRequestProvider>();
    final allPatients = _db.getAllPatients();

    final filtered = allPatients.where((p) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchName = '${p.firstName} ${p.lastName}'.toLowerCase().contains(q);
        final matchPhone = p.phone.toLowerCase().contains(q);
        final matchCmu = (p.cmuNumber ?? '').toLowerCase().contains(q);
        return matchName || matchPhone || matchCmu;
      }
      return true;
    }).toList();

    return Column(
      children: [
        // ── Barre de recherche ──────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v.trim()),
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Rechercher patient par nom, CMU, téléphone...',
                hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textMuted),
                prefixIcon: const Icon(LucideIcons.search, size: 18, color: AppColors.textMuted),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(LucideIcons.x, size: 16),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 11),
              ),
            ),
          ),
        ),

        // ── Compteur ───────────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.surfaceSubtle,
          child: Text(
            '${filtered.length} patient(s) inscrit(s)',
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
        ),

        // ── Liste ──────────────────────────────────────────────────────
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.user_x, size: 48, color: AppColors.textMuted.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      const Text(
                        'Aucun patient trouvé',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final patient = filtered[i];
                    final requests = trProvider.requestsForPatient(patient.id);
                    final usage = _db.getPatientMessageUsage(patient.id);

                    return _PatientAdminCard(
                      patient: patient,
                      requestsCount: requests.length,
                      usage: usage,
                      onUpdated: () => setState(() {}),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _PatientAdminCard extends StatelessWidget {
  final DbUser patient;
  final int requestsCount;
  final PatientMessageUsage usage;
  final VoidCallback onUpdated;

  const _PatientAdminCard({
    required this.patient,
    required this.requestsCount,
    required this.usage,
    required this.onUpdated,
  });

  Future<bool> _confirm(BuildContext context, String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
            content: Text(message, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Annuler')),
              FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Confirmer')),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd/MM/yyyy').format(patient.createdAt);
    final isBlocked = usage.remaining <= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.brandBlue.withValues(alpha: 0.12),
                child: Text(
                  patient.firstName.isNotEmpty ? patient.firstName[0].toUpperCase() : 'P',
                  style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: AppColors.brandBlue, fontSize: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${patient.lastName.toUpperCase()} ${patient.firstName}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(LucideIcons.phone, size: 12, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(patient.phone, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textSecondary)),
                        if (patient.cmuNumber != null) ...[
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(color: AppColors.brandBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                            child: Text(patient.cmuNumber!, style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, color: AppColors.brandBlue, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Quota Messages Gratuits (10 messages) ──────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isBlocked ? AppColors.errorBg : AppColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isBlocked ? AppColors.error.withValues(alpha: 0.2) : AppColors.borderSubtle),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isBlocked ? LucideIcons.lock : LucideIcons.message_square,
                          size: 14,
                          color: isBlocked ? AppColors.error : AppColors.brandBlue,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Quota messages gratuits :',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isBlocked ? AppColors.error : AppColors.brandTurquoise,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${usage.freeMessagesUsed} / ${usage.freeMessagesLimit} (${usage.remaining} restants)',
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (usage.freeMessagesUsed / usage.freeMessagesLimit).clamp(0.0, 1.0),
                    backgroundColor: Colors.black.withValues(alpha: 0.06),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isBlocked ? AppColors.error : (usage.remaining <= 3 ? AppColors.warning : AppColors.brandTurquoise),
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Footer info + Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Inscrit le $dateStr • $requestsCount demande(s)',
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textMuted),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz, size: 18, color: AppColors.textMuted),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (action) async {
                  final db = DatabaseService();
                  if (action == 'reset_quota') {
                    if (!await _confirm(context, 'Réinitialiser le quota ?', 'Le compteur de messages gratuits de ce patient reviendra à 10.')) return;
                    await db.resetPatientMessageUsage(patient.id, 10);
                    onUpdated();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Le quota de ${patient.firstName} a été réinitialisé à 10 messages gratuits.'),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } else if (action == 'suspend') {
                    if (!await _confirm(context, 'Suspendre ce patient ?', 'Le patient ne pourra plus se connecter tant que son compte est suspendu.')) return;
                    await db.updateUserStatus(patient.id, 'suspended');
                    onUpdated();
                  } else if (action == 'activate') {
                    await db.updateUserStatus(patient.id, 'active');
                    onUpdated();
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'reset_quota',
                    child: Row(children: [Icon(LucideIcons.rotate_ccw, size: 16, color: AppColors.brandBlue), SizedBox(width: 8), Text('Réinitialiser les 10 messages')]),
                  ),
                  if (patient.status == 'active')
                    const PopupMenuItem(
                      value: 'suspend',
                      child: Row(children: [Icon(LucideIcons.ban, size: 16, color: AppColors.error), SizedBox(width: 8), Text('Suspendre le compte')]),
                    )
                  else
                    const PopupMenuItem(
                      value: 'activate',
                      child: Row(children: [Icon(LucideIcons.circle_check, size: 16, color: AppColors.success), SizedBox(width: 8), Text('Activer le compte')]),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
