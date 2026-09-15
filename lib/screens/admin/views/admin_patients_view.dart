// lib/screens/admin/views/admin_patients_view.dart
//
// Vue de gestion des patients pour l'administrateur (quotas, abonnements, suspensions).

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/database_service.dart';
import '../../../providers/treating_request_provider.dart';
import '../components/admin_empty_state.dart';

class AdminPatientsView extends StatefulWidget {
  const AdminPatientsView({super.key});

  @override
  State<AdminPatientsView> createState() => _AdminPatientsViewState();
}

class _AdminPatientsViewState extends State<AdminPatientsView> {
  String _searchQuery = '';
  String _selectedFilter = 'Tous'; // 'Tous', 'Actifs', 'Suspendus'
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _togglePatientStatus(DbUser patient) async {
    final willSuspend = patient.status == 'active';
    final action = willSuspend ? 'Suspendre' : 'Réactiver';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$action le compte patient'),
        content: Text(
          willSuspend
              ? 'Voulez-vous suspendre le compte de ${patient.fullName} ? Le patient ne pourra plus se connecter.'
              : 'Voulez-vous réactiver le compte de ${patient.fullName} ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: willSuspend ? AppColors.error : AppColors.brandBlue,
              foregroundColor: Colors.white,
            ),
            child: Text(action),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      final newStatus = willSuspend ? 'suspended' : 'active';
      await DatabaseService().updateUserStatus(patient.id, newStatus);
      if (!mounted) return;

      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Statut de ${patient.fullName} mis à jour ($newStatus).'),
          backgroundColor: willSuspend ? AppColors.error : AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _resetQuota(DbUser patient) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Réinitialiser le quota de messagerie'),
        content: Text(
          'Voulez-vous recharger le quota de messages gratuits pour ${patient.fullName} à 10 messages ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Recharger le quota (10 msgs)'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await DatabaseService().resetPatientMessageUsage(patient.id, 10);
      if (!mounted) return;

      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Quota de messages réinitialisé pour ${patient.fullName} (10 messages disponibles).'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur réinitialisation : $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showPatientDetails(DbUser patient, PatientMessageUsage usage, int requestsCount) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.brandTurquoise.withValues(alpha: 0.15),
              child: Text(
                patient.firstName.isNotEmpty ? patient.firstName[0].toUpperCase() : 'P',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.brandTurquoise),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(patient.fullName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('Inscrit le ${patient.createdAt.day}/${patient.createdAt.month}/${patient.createdAt.year}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _DetailRow('Identifiant', patient.id),
                _DetailRow('Numéro CMU', patient.cmuNumber ?? 'Non affilié'),
                _DetailRow('Téléphone', patient.phone),
                _DetailRow('E-mail', patient.email),
                _DetailRow('Date de naissance', patient.birthDate ?? 'Non renseignée'),
                _DetailRow('Genre', patient.gender == 'M' ? 'Masculin' : (patient.gender == 'F' ? 'Féminin' : 'Non spécifié')),
                _DetailRow('Profession', patient.profession ?? 'Non renseignée'),
                _DetailRow('Localisation', '${patient.city ?? "Abidjan"} ${patient.commune != null ? "(${patient.commune})" : ""}'),
                _DetailRow('Statut du compte', patient.status.toUpperCase()),
                _DetailRow('Messages gratuits consommés', '${usage.freeMessagesUsed} / ${usage.freeMessagesLimit}'),
                _DetailRow('Demandes traitant', '$requestsCount'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();
    final requestProvider = context.watch<TreatingRequestProvider>();
    final allPatients = db.getAllPatients();

    // Filtrage
    final filtered = allPatients.where((p) {
      final matchesFilter = _selectedFilter == 'Tous' ||
          (_selectedFilter == 'Actifs' && p.status == 'active') ||
          (_selectedFilter == 'Suspendus' && p.status == 'suspended');

      final q = _searchQuery.toLowerCase();
      final matchesQuery = q.isEmpty ||
          p.lastName.toLowerCase().contains(q) ||
          p.firstName.toLowerCase().contains(q) ||
          (p.cmuNumber != null && p.cmuNumber!.toLowerCase().contains(q)) ||
          p.phone.toLowerCase().contains(q) ||
          p.email.toLowerCase().contains(q);

      return matchesFilter && matchesQuery;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barre de recherche
          Container(
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Rechercher par nom, téléphone, e-mail, n° CMU...',
                hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey.shade400),
                prefixIcon: const Icon(LucideIcons.search, size: 18, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Filtres statut
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Tous', 'Actifs', 'Suspendus'].map((f) {
                final isSel = _selectedFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f),
                    selected: isSel,
                    onSelected: (_) => setState(() => _selectedFilter = f),
                    selectedColor: AppColors.brandBlue,
                    labelStyle: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                      color: isSel ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Liste des patients
          Expanded(
            child: filtered.isEmpty
                ? const AdminEmptyState(
                    icon: LucideIcons.user_x,
                    title: 'Aucun patient trouvé',
                    message: 'Aucun patient ne correspond à vos filtres de recherche.',
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final p = filtered[i];
                      final usage = db.getPatientMessageUsage(p.id);
                      final reqs = requestProvider.getRequestsForPatient(p.id);

                      final isSuspended = p.status == 'suspended';
                      final hasCmu = p.cmuNumber?.isNotEmpty == true;

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSuspended ? const Color(0xFFFECACA) : Colors.grey.shade200,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isNarrow = constraints.maxWidth < 560;

                            final actionButtons = Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(LucideIcons.eye, size: 18, color: Color(0xFF475569)),
                                  tooltip: 'Consulter profil',
                                  onPressed: () => _showPatientDetails(p, usage, reqs.length),
                                ),
                                IconButton(
                                  icon: const Icon(LucideIcons.rotate_ccw, size: 18, color: AppColors.brandBlue),
                                  tooltip: 'Recharger quota (10 msgs)',
                                  onPressed: () => _resetQuota(p),
                                ),
                                IconButton(
                                  icon: Icon(
                                    isSuspended ? LucideIcons.user_check : LucideIcons.ban,
                                    size: 18,
                                    color: isSuspended ? AppColors.success : AppColors.error,
                                  ),
                                  tooltip: isSuspended ? 'Réactiver' : 'Suspendre',
                                  onPressed: () => _togglePatientStatus(p),
                                ),
                              ],
                            );

                            final patientInfo = Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: AppColors.brandTurquoise.withValues(alpha: 0.12),
                                  child: Text(
                                    p.firstName.isNotEmpty ? p.firstName[0].toUpperCase() : 'P',
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.brandTurquoise,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              p.fullName,
                                              style: const TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF0F172A),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          if (isSuspended)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.error.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Text(
                                                'Suspendu',
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.error,
                                                ),
                                              ),
                                            ),
                                          if (hasCmu) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF185FA5).withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                p.cmuNumber!,
                                                style: const TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF185FA5),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${p.phone} • ${p.email} • Né(e) le : ${p.birthDate ?? "N/R"}',
                                        style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey.shade600),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 2,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          Text(
                                            'Quota messages : ${usage.freeMessagesUsed} / ${usage.freeMessagesLimit}',
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: usage.isLimitReached ? AppColors.error : AppColors.brandBlue,
                                            ),
                                          ),
                                          if (usage.isLimitReached)
                                            const Text('(Plafond atteint)', style: TextStyle(fontSize: 11, color: AppColors.error)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );

                            if (isNarrow) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  patientInfo,
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: actionButtons,
                                  ),
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(child: patientInfo),
                                const SizedBox(width: 12),
                                actionButtons,
                              ],
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF0F172A))),
          ),
        ],
      ),
    );
  }
}
