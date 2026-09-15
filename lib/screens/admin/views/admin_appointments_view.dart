// lib/screens/admin/views/admin_appointments_view.dart
//
// Vue de supervision des rendez-vous pour l'administrateur.

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/database_service.dart';
import '../../../models/appointment_model.dart';
import '../components/admin_empty_state.dart';

class AdminAppointmentsView extends StatefulWidget {
  const AdminAppointmentsView({super.key});

  @override
  State<AdminAppointmentsView> createState() => _AdminAppointmentsViewState();
}

class _AdminAppointmentsViewState extends State<AdminAppointmentsView> {
  String _searchQuery = '';
  String _selectedFilter = 'Tous'; // 'Tous', 'Aujourd\'hui', 'Confirmés', 'En attente', 'Annulés'
  final TextEditingController _searchCtrl = TextEditingController();

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  final NumberFormat _currencyFormat = NumberFormat('#,###');

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _cancelAppointment(AppointmentModel appt) async {
    final motifCtrl = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annulation administrative du rendez-vous'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rendez-vous entre ${appt.patientName} et le Dr. ${appt.doctorName} prévu le ${_dateFormat.format(appt.scheduledAt)}.'),
            const SizedBox(height: 12),
            const Text('Motif de l\'annulation :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 6),
            TextField(
              controller: motifCtrl,
              decoration: const InputDecoration(
                hintText: 'Ex: Indisponibilité praticien, demande patient...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Retour'),
          ),
          ElevatedButton(
            onPressed: () {
              if (motifCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Confirmer l\'annulation'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await DatabaseService().updateAppointmentStatus(appt.id, AppointmentStatus.cancelled);
      if (!mounted) return;
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le rendez-vous a été annulé.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: AppColors.error),
      );
    }
  }

  void _showAppointmentDetails(AppointmentModel appt) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Détail du rendez-vous', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DetailRow('ID', appt.id),
                _DetailRow('Patient', appt.patientName),
                _DetailRow('Médecin', 'Dr. ${appt.doctorName}'),
                _DetailRow('Spécialité', appt.doctorSpecialty),
                _DetailRow('Date et Heure', _dateFormat.format(appt.scheduledAt)),
                _DetailRow('Type de consultation', appt.type == AppointmentType.teleconsultation ? 'Téléconsultation' : 'Présentiel'),
                _DetailRow('Tarif', '${_currencyFormat.format(appt.consultationPrice ?? 0)} FCFA'),
                _DetailRow('Statut', appt.status.name.toUpperCase()),
                if (appt.notes != null && appt.notes!.isNotEmpty)
                  _DetailRow('Motif médical', appt.notes!),
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
    final db = DatabaseService();
    final allAppointments = db.getAllAppointments();
    final now = DateTime.now();

    final filtered = allAppointments.where((a) {
      final isToday = a.scheduledAt.year == now.year &&
          a.scheduledAt.month == now.month &&
          a.scheduledAt.day == now.day;

      final matchesFilter = _selectedFilter == 'Tous' ||
          (_selectedFilter == 'Aujourd\'hui' && isToday) ||
          (_selectedFilter == 'Confirmés' && a.status == AppointmentStatus.confirmed) ||
          (_selectedFilter == 'En attente' && a.status == AppointmentStatus.pending) ||
          (_selectedFilter == 'Annulés' && a.status == AppointmentStatus.cancelled);

      final q = _searchQuery.toLowerCase();
      final matchesQuery = q.isEmpty ||
          a.patientName.toLowerCase().contains(q) ||
          a.doctorName.toLowerCase().contains(q) ||
          a.doctorSpecialty.toLowerCase().contains(q);

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
                hintText: 'Rechercher par patient, médecin, spécialité...',
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
              children: ['Tous', 'Aujourd\'hui', 'Confirmés', 'En attente', 'Annulés'].map((f) {
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
                    icon: LucideIcons.calendar_x,
                    title: 'Aucun rendez-vous trouvé',
                    message: 'Aucun rendez-vous ne correspond à vos critères.',
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final appt = filtered[i];

                      Color statusColor = AppColors.brandBlue;
                      String statusLabel = 'Confirmé';
                      if (appt.status == AppointmentStatus.pending) {
                        statusColor = const Color(0xFFEA580C);
                        statusLabel = 'En attente';
                      } else if (appt.status == AppointmentStatus.cancelled) {
                        statusColor = AppColors.error;
                        statusLabel = 'Annulé';
                      } else if (appt.status == AppointmentStatus.completed) {
                        statusColor = AppColors.success;
                        statusLabel = 'Effectué';
                      }

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
                              child: Icon(
                                appt.type == AppointmentType.teleconsultation ? LucideIcons.video : LucideIcons.calendar,
                                color: statusColor,
                                size: 22,
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
                                          '${appt.patientName} ➔ Dr. ${appt.doctorName}',
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
                                    '${appt.doctorSpecialty} • Date : ${_dateFormat.format(appt.scheduledAt)} • ${_currencyFormat.format(appt.consultationPrice ?? 0)} FCFA',
                                    style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(LucideIcons.eye, size: 18, color: Color(0xFF475569)),
                                  tooltip: 'Détails',
                                  onPressed: () => _showAppointmentDetails(appt),
                                ),
                                if (appt.status != AppointmentStatus.cancelled && appt.status != AppointmentStatus.completed)
                                  IconButton(
                                    icon: const Icon(LucideIcons.circle_x, size: 18, color: AppColors.error),
                                    tooltip: 'Annuler administrativement',
                                    onPressed: () => _cancelAppointment(appt),
                                  ),
                              ],
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
