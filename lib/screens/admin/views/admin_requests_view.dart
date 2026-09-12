import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/treating_doctor_request_model.dart';
import '../../../providers/treating_request_provider.dart';

class AdminRequestsView extends StatefulWidget {
  const AdminRequestsView({super.key});

  @override
  State<AdminRequestsView> createState() => _AdminRequestsViewState();
}

class _AdminRequestsViewState extends State<AdminRequestsView> {
  String _filter = 'all'; // 'all', 'pending', 'accepted', 'rejected'
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
    final all = trProvider.allRequests;

    final filtered = all.where((r) {
      if (_filter != 'all' && r.status.name != _filter) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchPatient = r.patientName.toLowerCase().contains(q);
        final matchDoctor = r.doctorName.toLowerCase().contains(q);
        final matchSpecialty = r.doctorSpecialty.toLowerCase().contains(q);
        return matchPatient || matchDoctor || matchSpecialty;
      }
      return true;
    }).toList();

    return Column(
      children: [
        // ── Barre de recherche & Filtres ────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Column(
            children: [
              Container(
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
                    hintText: 'Rechercher patient, médecin, spécialité...',
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
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip('Toutes (${all.length})', 'all', AppColors.brandBlue),
                    const SizedBox(width: 8),
                    _filterChip('En attente (${all.where((r) => r.isPending).length})', 'pending', AppColors.warning),
                    const SizedBox(width: 8),
                    _filterChip('Acceptées (${all.where((r) => r.isAccepted).length})', 'accepted', AppColors.brandTurquoise),
                    const SizedBox(width: 8),
                    _filterChip('Refusées (${all.where((r) => r.status.name == 'rejected').length})', 'rejected', AppColors.brandCoral),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Compteur ───────────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.surfaceSubtle,
          child: Text(
            '${filtered.length} demande(s) enregistrée(s)',
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
        ),

        // ── Liste des demandes ─────────────────────────────────────────
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.inbox, size: 48, color: AppColors.textMuted.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      const Text(
                        'Aucune demande trouvée',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _RequestAdminCard(request: filtered[i]),
                ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, String value, Color color) {
    final isSelected = _filter == value;
    return InkWell(
      onTap: () => setState(() => _filter = value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : AppColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.transparent : AppColors.borderSubtle),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _RequestAdminCard extends StatelessWidget {
  final TreatingDoctorRequest request;

  const _RequestAdminCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(request.createdAt);
    final isPending = request.isPending;
    final isAccepted = request.isAccepted;

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    if (isAccepted) {
      statusColor = AppColors.success;
      statusLabel = 'Acceptée';
      statusIcon = LucideIcons.circle_check;
    } else if (isPending) {
      statusColor = AppColors.warning;
      statusLabel = 'En attente';
      statusIcon = LucideIcons.clock;
    } else {
      statusColor = AppColors.error;
      statusLabel = 'Refusée';
      statusIcon = LucideIcons.circle_x;
    }

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Réf : ${request.id.substring(0, request.id.length > 18 ? 18 : request.id.length)}...',
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, color: AppColors.textMuted),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 12, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Participants
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Patient', style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: AppColors.textMuted)),
                    Text(
                      request.patientName,
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
              const Icon(LucideIcons.arrow_right, size: 16, color: AppColors.textMuted),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Médecin', style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: AppColors.textMuted)),
                    Text(
                      request.doctorName,
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.brandTurquoise),
                      textAlign: TextAlign.end,
                    ),
                    Text(
                      request.doctorSpecialty,
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.borderSubtle),
          const SizedBox(height: 8),

          // Motif / Message d'accompagnement
          Text(
            'Message : "${request.message}"',
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Envoyée le $dateStr',
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, color: AppColors.textMuted),
              ),
              if (request.respondedAt != null)
                Text(
                  'Répondue le ${DateFormat('dd/MM HH:mm').format(request.respondedAt!)}',
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, color: AppColors.textMuted),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
