import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/appointment_model.dart';
import '../../../services/database_service.dart';

class AdminAppointmentsView extends StatefulWidget {
  const AdminAppointmentsView({super.key});

  @override
  State<AdminAppointmentsView> createState() => _AdminAppointmentsViewState();
}

class _AdminAppointmentsViewState extends State<AdminAppointmentsView> {
  final _db = DatabaseService();
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all'; // 'all', 'confirmed', 'pending', 'completed', 'cancelled'
  String _typeFilter = 'all'; // 'all', 'inPerson', 'teleconsultation'

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppointmentModel>>(
      stream: _db.appointmentsStream,
      initialData: _db.getAllAppointments(),
      builder: (context, snapshot) {
        final all = snapshot.data ?? _db.getAllAppointments();

        final filtered = all.where((a) {
          if (_statusFilter != 'all' && a.status.name != _statusFilter) return false;
          if (_typeFilter != 'all' && a.type.name != _typeFilter) return false;
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            final matchPat = a.patientName.toLowerCase().contains(q);
            final matchDoc = a.doctorName.toLowerCase().contains(q);
            final matchSpec = a.doctorSpecialty.toLowerCase().contains(q);
            final matchReason = (a.reason ?? '').toLowerCase().contains(q);
            return matchPat || matchDoc || matchSpec || matchReason;
          }
          return true;
        }).toList();

        final confirmedCount = all.where((a) => a.status == AppointmentStatus.confirmed).length;
        final pendingCount = all.where((a) => a.status == AppointmentStatus.pending).length;
        final completedCount = all.where((a) => a.status == AppointmentStatus.completed).length;
        final cancelledCount = all.where((a) => a.status == AppointmentStatus.cancelled).length;

        return Column(
          children: [
            // ── Barre de recherche & Filtres ──────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                        hintText: 'Rechercher par patient, praticien, motif...',
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
                        _filterChip('Tous (${all.length})', 'all', AppColors.brandBlue, _statusFilter, (v) => setState(() => _statusFilter = v)),
                        const SizedBox(width: 8),
                        _filterChip('Confirmés ($confirmedCount)', 'confirmed', AppColors.success, _statusFilter, (v) => setState(() => _statusFilter = v)),
                        const SizedBox(width: 8),
                        _filterChip('En attente ($pendingCount)', 'pending', AppColors.warning, _statusFilter, (v) => setState(() => _statusFilter = v)),
                        const SizedBox(width: 8),
                        _filterChip('Terminés ($completedCount)', 'completed', const Color(0xFF6B46C1), _statusFilter, (v) => setState(() => _statusFilter = v)),
                        const SizedBox(width: 8),
                        _filterChip('Annulés ($cancelledCount)', 'cancelled', AppColors.brandCoral, _statusFilter, (v) => setState(() => _statusFilter = v)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Type : ', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                      _typeChip('Tous', 'all'),
                      const SizedBox(width: 6),
                      _typeChip('En cabinet', 'inPerson'),
                      const SizedBox(width: 6),
                      _typeChip('Téléconsultation', 'teleconsultation'),
                    ],
                  ),
                ],
              ),
            ),

            // ── Compteur ─────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.surfaceSubtle,
              child: Text(
                '${filtered.length} consultation(s) trouvée(s)',
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
            ),

            // ── Liste ────────────────────────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.calendar_x, size: 48, color: AppColors.textMuted.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          const Text(
                            'Aucun rendez-vous correspondant',
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _AppointmentAdminCard(
                        appointment: filtered[i],
                        onUpdated: () => setState(() {}),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _filterChip(String label, String value, Color color, String current, Function(String) onSelect) {
    final isSelected = value == current;
    return InkWell(
      onTap: () => onSelect(value),
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

  Widget _typeChip(String label, String value) {
    final isSelected = _typeFilter == value;
    return InkWell(
      onTap: () => setState(() => _typeFilter = value),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandNavy : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? AppColors.brandNavy : AppColors.borderSubtle),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _AppointmentAdminCard extends StatelessWidget {
  final AppointmentModel appointment;
  final VoidCallback onUpdated;

  const _AppointmentAdminCard({required this.appointment, required this.onUpdated});

  @override
  Widget build(BuildContext context) {
    final isVideo = appointment.isTeleconsultation;
    final dateStr = DateFormat('dd/MM/yyyy à HH:mm').format(appointment.scheduledAt);

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (appointment.status) {
      case AppointmentStatus.confirmed:
        statusColor = AppColors.success;
        statusLabel = 'Confirmé';
        statusIcon = LucideIcons.circle_check;
        break;
      case AppointmentStatus.pending:
        statusColor = AppColors.warning;
        statusLabel = 'En attente';
        statusIcon = LucideIcons.clock;
        break;
      case AppointmentStatus.inProgress:
        statusColor = AppColors.brandTurquoise;
        statusLabel = 'En cours';
        statusIcon = LucideIcons.loader;
        break;
      case AppointmentStatus.completed:
        statusColor = const Color(0xFF6B46C1);
        statusLabel = 'Terminé';
        statusIcon = LucideIcons.check_check;
        break;
      case AppointmentStatus.cancelled:
        statusColor = AppColors.brandCoral;
        statusLabel = 'Annulé';
        statusIcon = LucideIcons.circle_x;
        break;
      case AppointmentStatus.noShow:
        statusColor = AppColors.brandCoral;
        statusLabel = 'Non honoré';
        statusIcon = LucideIcons.user_x;
        break;
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isVideo ? AppColors.brandTurquoise : AppColors.brandBlue).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isVideo ? LucideIcons.video : LucideIcons.building_complex, size: 12, color: isVideo ? AppColors.brandTurquoise : AppColors.brandBlue),
                    const SizedBox(width: 4),
                    Text(
                      isVideo ? 'Téléconsultation' : 'En cabinet',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isVideo ? AppColors.brandTurquoise : AppColors.brandBlue,
                      ),
                    ),
                  ],
                ),
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
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Participants
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PATIENT', style: TextStyle(fontFamily: 'Poppins', fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                    const SizedBox(height: 2),
                    Text(
                      appointment.patientName,
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(LucideIcons.arrow_right, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PRATICIEN', style: TextStyle(fontFamily: 'Poppins', fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                    const SizedBox(height: 2),
                    Text(
                      appointment.doctorName,
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      appointment.doctorSpecialty,
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, color: AppColors.brandTurquoise, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.borderSubtle),
          const SizedBox(height: 8),

          Row(
            children: [
              const Icon(LucideIcons.calendar, size: 13, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                dateStr,
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
              const Spacer(),
              Text(
                '${appointment.consultationPrice?.toStringAsFixed(0) ?? "15 000"} FCFA',
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.brandNavy),
              ),
            ],
          ),

          if (appointment.reason != null && appointment.reason!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Motif : ${appointment.reason}',
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textMuted, fontStyle: FontStyle.italic),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: 10),

          // Actions administrateur
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (appointment.status == AppointmentStatus.pending) ...[
                TextButton.icon(
                  onPressed: () async {
                    await DatabaseService().updateAppointmentStatus(appointment.id, AppointmentStatus.confirmed);
                    onUpdated();
                  },
                  icon: const Icon(LucideIcons.circle_check, size: 14, color: AppColors.success),
                  label: const Text('Confirmer', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.success, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 6),
              ],
              if (appointment.status != AppointmentStatus.completed && appointment.status != AppointmentStatus.cancelled) ...[
                TextButton.icon(
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Annuler ce rendez-vous ?', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
                        content: const Text('Le rendez-vous sera marqué comme annulé pour le patient et le médecin.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Non')),
                          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Annuler le RDV')),
                        ],
                      ),
                    );
                    if (ok == true) {
                      await DatabaseService().updateAppointmentStatus(appointment.id, AppointmentStatus.cancelled);
                      onUpdated();
                    }
                  },
                  icon: const Icon(LucideIcons.ban, size: 14, color: AppColors.brandCoral),
                  label: const Text('Annuler', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.brandCoral)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
