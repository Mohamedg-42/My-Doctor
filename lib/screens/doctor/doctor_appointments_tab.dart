import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/appointment_model.dart';
import '../../providers/doctor_provider.dart';
import '../../widgets/common/appointment_card.dart';
import '../patient/medical_record_screen.dart';

/// Onglet et écran de consultation des rendez-vous pour le praticien
class DoctorAppointmentsTab extends StatefulWidget {
  final VoidCallback? onBackToDashboard;

  const DoctorAppointmentsTab({super.key, this.onBackToDashboard});

  @override
  State<DoctorAppointmentsTab> createState() => _DoctorAppointmentsTabState();
}

class _DoctorAppointmentsTabState extends State<DoctorAppointmentsTab> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doctor = context.watch<DoctorProvider>();
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        leading: widget.onBackToDashboard != null
            ? IconButton(
                icon: const Icon(LucideIcons.arrow_left, color: AppColors.textPrimary, size: 20),
                tooltip: 'Retour au tableau de bord',
                onPressed: widget.onBackToDashboard,
              )
            : null,
        title: const Text('Mes Rendez-vous'),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [Tab(text: 'Tous'), Tab(text: 'En attente'), Tab(text: "Confirmés")],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          DoctorAptList(apts: doctor.appointments, isDoctor: true),
          DoctorAptList(apts: doctor.pendingAppointments, isDoctor: true, showAcceptReject: true),
          DoctorAptList(apts: doctor.confirmedAppointments, isDoctor: true),
        ],
      ),
    );
  }
}

class DoctorAptList extends StatelessWidget {
  final List<AppointmentModel> apts;
  final bool isDoctor;
  final bool showAcceptReject;

  const DoctorAptList({super.key, required this.apts, this.isDoctor = false, this.showAcceptReject = false});

  @override
  Widget build(BuildContext context) {
    if (apts.isEmpty) {
      return const Center(
        child: Text(
          'Aucun rendez-vous',
          style: TextStyle(fontFamily: 'Poppins', color: AppColors.textSecondary),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: apts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => Column(
        children: [
          AppointmentCard(
            appointment: apts[i],
            isDoctor: isDoctor,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MedicalRecordScreen(
                    patientName: apts[i].patientName,
                    patientId: apts[i].patientId,
                    patientAvatar: apts[i].patientAvatar,
                    isDoctorView: true,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MedicalRecordScreen(
                          patientName: apts[i].patientName,
                          patientId: apts[i].patientId,
                          patientAvatar: apts[i].patientAvatar,
                          isDoctorView: true,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(LucideIcons.clipboard_list, size: 14),
                  label: const Text(
                    'Consulter Dossier Médical',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.brandNavy,
                    side: const BorderSide(color: AppColors.brandNavy),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
          if (showAcceptReject) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: const Row(
                            children: [
                              Icon(LucideIcons.share_2, color: Color(0xFF8B5CF6), size: 20),
                              SizedBox(width: 8),
                              Text('Référer le rendez-vous', style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          content: const Text(
                            'Ce rendez-vous sera réorienté afin qu\'un autre médecin disponible puisse prendre en charge le patient.',
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 13),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Annuler'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8B5CF6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Confirmer', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true && context.mounted) {
                        await context.read<DoctorProvider>().respondToAppointment(apts[i].id, false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Le rendez-vous a été réorienté.'),
                              backgroundColor: const Color(0xFF8B5CF6),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(LucideIcons.user_round_cog, size: 14),
                    label: const Text('Référer'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF8B5CF6),
                      side: const BorderSide(color: Color(0xFF8B5CF6)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.read<DoctorProvider>().respondToAppointment(apts[i].id, true),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, elevation: 0),
                    child: const Text('Accepter', style: TextStyle(fontFamily: 'Poppins', color: AppColors.textWhite)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
