// lib/screens/admin/views/admin_doctors_view.dart
//
// Vue de gestion des praticiens (validation, suspension, réactivation) pour l'administrateur.

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/database_service.dart';
import '../../../providers/treating_request_provider.dart';
import '../components/admin_empty_state.dart';
import '../../../widgets/doctor/set_patient_capacity_dialog.dart';

class AdminDoctorsView extends StatefulWidget {
  const AdminDoctorsView({super.key});

  @override
  State<AdminDoctorsView> createState() => _AdminDoctorsViewState();
}

class _AdminDoctorsViewState extends State<AdminDoctorsView> {
  String _searchQuery = '';
  String _selectedFilter = 'Tous'; // 'Tous', 'En attente', 'Validés', 'Suspendus'
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _changeDoctorStatus(String doctorId, String doctorName, String newStatus, String actionLabel) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$actionLabel le Dr. $doctorName'),
        content: Text(
          newStatus == 'active'
              ? 'Confirmez-vous la validation de ce médecin ? Il apparaîtra immédiatement dans la liste publique des praticiens.'
              : (newStatus == 'suspended'
                  ? 'Confirmez-vous la suspension de ce médecin ? Il ne pourra plus recevoir de rendez-vous ni accéder à son espace.'
                  : 'Confirmez-vous le rejet de cette candidature ?'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus == 'active'
                  ? AppColors.success
                  : (newStatus == 'suspended' ? AppColors.error : Colors.grey.shade700),
              foregroundColor: Colors.white,
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await DatabaseService().updateUserStatus(doctorId, newStatus);
      if (!mounted) return;

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.circle_check, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Statut du Dr. $doctorName mis à jour avec succès ($newStatus).'),
              ),
            ],
          ),
          backgroundColor: newStatus == 'active' ? AppColors.success : AppColors.brandBlue,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la mise à jour : $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showDoctorDetails(DbUser doc, int requestsReceived, int requestsAccepted) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.brandBlue.withValues(alpha: 0.15),
              child: Text(
                doc.firstName.isNotEmpty ? doc.firstName[0].toUpperCase() : 'D',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.brandBlue),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Dr. ${doc.lastName.toUpperCase()} ${doc.firstName}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(doc.specialty ?? 'Médecin Généraliste',
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
                _DetailRow('Identifiant', doc.id),
                _DetailRow('Numéro d\'Ordre (OPCI)', doc.orderNumber ?? 'Non renseigné'),
                _DetailRow('Téléphone', doc.phone),
                _DetailRow('E-mail', doc.email),
                _DetailRow('Localisation', '${doc.city ?? "Abidjan"} ${doc.commune != null ? "(${doc.commune})" : ""}'),
                _DetailRow('Statut du compte', doc.status.toUpperCase()),
                _DetailRow('Capacité max patientèle', '${doc.patientCapacity} patients'),
                _DetailRow('Demandes reçues', '$requestsReceived'),
                _DetailRow('Demandes acceptées', '$requestsAccepted'),
                if (doc.bio != null && doc.bio!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Text('Biographie / Présentation :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(doc.bio!, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(LucideIcons.settings_2, size: 15),
            label: const Text('Modifier capacité'),
            onPressed: () async {
              Navigator.pop(ctx);
              final res = await SetPatientCapacityDialog.show(
                context,
                doctorId: doc.id,
                currentCapacity: doc.patientCapacity,
              );
              if (res == true && mounted) {
                setState(() {});
              }
            },
          ),
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
    final allDoctors = db.getAllDoctors(onlyActive: false);

    // Filtrage
    final filtered = allDoctors.where((d) {
      final matchesFilter = _selectedFilter == 'Tous' ||
          (_selectedFilter == 'En attente' && d.status == 'pending') ||
          (_selectedFilter == 'Validés' && d.status == 'active') ||
          (_selectedFilter == 'Suspendus' && d.status == 'suspended');

      final q = _searchQuery.toLowerCase();
      final matchesQuery = q.isEmpty ||
          d.lastName.toLowerCase().contains(q) ||
          d.firstName.toLowerCase().contains(q) ||
          (d.specialty != null && d.specialty!.toLowerCase().contains(q)) ||
          (d.orderNumber != null && d.orderNumber!.toLowerCase().contains(q)) ||
          d.phone.toLowerCase().contains(q);

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
                hintText: 'Rechercher par nom, spécialité, n° d\'ordre, téléphone...',
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
              children: ['Tous', 'En attente', 'Validés', 'Suspendus'].map((f) {
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

          // Liste des médecins
          Expanded(
            child: filtered.isEmpty
                ? const AdminEmptyState(
                    icon: LucideIcons.user_x,
                    title: 'Aucun médecin trouvé',
                    message: 'Aucun résultat ne correspond à vos critères de recherche ou de filtre.',
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final doc = filtered[i];
                      final reqs = requestProvider.getRequestsForDoctor(doc.id);
                      final acceptedCount = reqs.where((r) => r.isAccepted).length;

                      final isPending = doc.status == 'pending';
                      final isActive = doc.status == 'active';
                      final isSuspended = doc.status == 'suspended';

                      final statusColor = isActive
                          ? AppColors.success
                          : (isPending ? const Color(0xFFEA580C) : AppColors.error);

                      final statusLabel = isActive
                          ? 'Validé'
                          : (isPending ? 'En attente' : 'Suspendu');

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isPending
                                ? const Color(0xFFFDBA74)
                                : Colors.grey.shade200,
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
                            final isNarrow = constraints.maxWidth < 600;

                            final actionButtons = Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(LucideIcons.eye, size: 18, color: Color(0xFF475569)),
                                  tooltip: 'Consulter profil',
                                  onPressed: () => _showDoctorDetails(doc, reqs.length, acceptedCount),
                                ),
                                if (isPending) ...[
                                  ElevatedButton.icon(
                                    onPressed: () => _changeDoctorStatus(doc.id, doc.lastName, 'active', 'Valider'),
                                    icon: const Icon(LucideIcons.check, size: 14),
                                    label: const Text('Valider'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.success,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                  OutlinedButton(
                                    onPressed: () => _changeDoctorStatus(doc.id, doc.lastName, 'rejected', 'Refuser'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.error,
                                      side: const BorderSide(color: AppColors.error),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: const Text('Refuser'),
                                  ),
                                ],
                                if (isActive)
                                  OutlinedButton.icon(
                                    onPressed: () => _changeDoctorStatus(doc.id, doc.lastName, 'suspended', 'Suspendre'),
                                    icon: const Icon(LucideIcons.ban, size: 14),
                                    label: const Text('Suspendre'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.error,
                                      side: const BorderSide(color: AppColors.error),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                if (isSuspended)
                                  ElevatedButton.icon(
                                    onPressed: () => _changeDoctorStatus(doc.id, doc.lastName, 'active', 'Réactiver'),
                                    icon: const Icon(LucideIcons.rotate_ccw, size: 14),
                                    label: const Text('Réactiver'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.brandBlue,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                              ],
                            );

                            final doctorInfo = Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: AppColors.brandBlue.withValues(alpha: 0.1),
                                  child: Text(
                                    doc.firstName.isNotEmpty ? doc.firstName[0].toUpperCase() : 'D',
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.brandBlue,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              'Dr. ${doc.lastName.toUpperCase()} ${doc.firstName}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF0F172A),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: statusColor.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              statusLabel,
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: statusColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${doc.specialty ?? "Généraliste"} • Ordre : ${doc.orderNumber ?? "Non renseigné"} • Tél : ${doc.phone} • Capacité : ${doc.patientCapacity} patients',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Demandes traitant : ${reqs.length} reçues, $acceptedCount acceptées',
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 11,
                                          color: AppColors.brandBlue,
                                          fontWeight: FontWeight.w500,
                                        ),
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
                                  doctorInfo,
                                  const SizedBox(height: 12),
                                  actionButtons,
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(child: doctorInfo),
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
