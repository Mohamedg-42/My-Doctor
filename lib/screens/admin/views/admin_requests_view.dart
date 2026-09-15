// lib/screens/admin/views/admin_requests_view.dart
//
// Vue de supervision des demandes de médecin traitant pour l'administrateur.

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/treating_request_provider.dart';
import '../../../models/treating_doctor_request_model.dart';
import '../components/admin_empty_state.dart';

class AdminRequestsView extends StatefulWidget {
  const AdminRequestsView({super.key});

  @override
  State<AdminRequestsView> createState() => _AdminRequestsViewState();
}

class _AdminRequestsViewState extends State<AdminRequestsView> {
  String _searchQuery = '';
  String _selectedFilter = 'Toutes'; // 'Toutes', 'En attente', 'Acceptées', 'Refusées', 'Annulées'
  final TextEditingController _searchCtrl = TextEditingController();

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showRequestDetails(TreatingDoctorRequest req) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Détail de la demande traitant', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DetailRow('Identifiant demande', req.id),
                _DetailRow('Patient demandeur', req.patientName),
                _DetailRow('Médecin sollicité', 'Dr. ${req.doctorName}'),
                _DetailRow('Spécialité', req.doctorSpecialty),
                _DetailRow('Date création', _dateFormat.format(req.createdAt)),
                _DetailRow('Date mise à jour', _dateFormat.format(req.updatedAt)),
                _DetailRow('Statut', req.status.label.toUpperCase()),
                if (req.message.isNotEmpty)
                  _DetailRow('Message patient', req.message),
                if (req.rejectionReason != null && req.rejectionReason!.isNotEmpty)
                  _DetailRow('Motif du refus', req.rejectionReason!),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final requestProvider = context.watch<TreatingRequestProvider>();
    final allRequests = requestProvider.allRequests;

    final filtered = allRequests.where((r) {
      final matchesFilter = _selectedFilter == 'Toutes' ||
          (_selectedFilter == 'En attente' && r.isPending) ||
          (_selectedFilter == 'Acceptées' && r.isAccepted) ||
          (_selectedFilter == 'Refusées' && r.isRejected) ||
          (_selectedFilter == 'Annulées' && r.isCancelled);

      final q = _searchQuery.toLowerCase();
      final matchesQuery = q.isEmpty ||
          r.patientName.toLowerCase().contains(q) ||
          r.doctorName.toLowerCase().contains(q) ||
          r.doctorSpecialty.toLowerCase().contains(q);

      return matchesFilter && matchesQuery;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                hintText: 'Rechercher par patient, médecin ou spécialité...',
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Toutes', 'En attente', 'Acceptées', 'Refusées', 'Annulées'].map((f) {
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

          Expanded(
            child: filtered.isEmpty
                ? const AdminEmptyState(
                    icon: LucideIcons.user_x,
                    title: 'Aucune demande trouvée',
                    message: 'Aucune demande de médecin traitant ne correspond à vos filtres.',
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final req = filtered[i];

                      Color statusColor = const Color(0xFFEA580C);
                      if (req.isAccepted) statusColor = AppColors.success;
                      if (req.isRejected || req.isCancelled) statusColor = AppColors.error;

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(LucideIcons.user_check, color: statusColor, size: 22),
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
                                          '${req.patientName} ➔ Dr. ${req.doctorName}',
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
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          req.status.label,
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
                                    '${req.doctorSpecialty} • Demandé le ${_dateFormat.format(req.createdAt)}',
                                    style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                  if (req.isRejected && req.rejectionReason != null) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      'Motif refus : ${req.rejectionReason}',
                                      style: const TextStyle(fontSize: 11, color: AppColors.error, fontStyle: FontStyle.italic),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(LucideIcons.eye, size: 18, color: Color(0xFF475569)),
                              tooltip: 'Détails de la demande',
                              onPressed: () => _showRequestDetails(req),
                            ),
                          ],
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        ],
      ),
    );
  }
}
