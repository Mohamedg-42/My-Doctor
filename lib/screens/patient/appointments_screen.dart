import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/patient_provider.dart';
import '../../providers/app_provider.dart';
import '../../models/appointment_model.dart';
import '../../models/doctor_model.dart';
import 'video_call_screen.dart';
import 'payment_screen.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'review_screen.dart';
import 'in_app_itinerary_screen.dart';

class AppointmentsScreen extends StatefulWidget {
  final VoidCallback? onBackToHome;

  const AppointmentsScreen({super.key, this.onBackToHome});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  int _filterIndex = 0; // 0=Tous, 1=Confirmés, 2=En attente, 3=Terminés

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  List<AppointmentModel> _filterAppointments(
      List<AppointmentModel> all, bool upcoming) {
    var filtered = upcoming
        ? all.where((a) => a.isUpcoming).toList()
        : all.where((a) => a.isPast || a.status == AppointmentStatus.cancelled).toList();

    if (_filterIndex == 1) {
      filtered = filtered
          .where((a) => a.status == AppointmentStatus.confirmed)
          .toList();
    } else if (_filterIndex == 2) {
      filtered = filtered
          .where((a) => a.status == AppointmentStatus.pending)
          .toList();
    } else if (_filterIndex == 3) {
      filtered = filtered
          .where((a) => a.status == AppointmentStatus.completed)
          .toList();
    }

    filtered.sort((a, b) => upcoming
        ? a.scheduledAt.compareTo(b.scheduledAt)
        : b.scheduledAt.compareTo(a.scheduledAt));

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrow_left, color: AppColors.textPrimary, size: 20),
          tooltip: 'Retour à l\'accueil',
          onPressed: () {
            if (widget.onBackToHome != null) {
              widget.onBackToHome!();
            } else if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text('Mes Rendez-vous'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Filtres de statut
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _FilterChip(label: 'Tous', index: 0, selected: _filterIndex, onTap: () => setState(() => _filterIndex = 0)),
                    _FilterChip(label: 'Confirmés', index: 1, selected: _filterIndex, onTap: () => setState(() => _filterIndex = 1)),
                    _FilterChip(label: 'En attente', index: 2, selected: _filterIndex, onTap: () => setState(() => _filterIndex = 2)),
                    _FilterChip(label: 'Terminés', index: 3, selected: _filterIndex, onTap: () => setState(() => _filterIndex = 3)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Onglets
              TabBar(
                controller: _tabCtrl,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                labelStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13),
                tabs: const [
                  Tab(text: 'À venir'),
                  Tab(text: 'Historique'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Consumer<PatientProvider>(
        builder: (_, patient, __) => TabBarView(
          controller: _tabCtrl,
          children: [
            _AppointmentList(
              appointments: _filterAppointments(patient.appointments, true),
              isUpcoming: true,
            ),
            _AppointmentList(
              appointments: _filterAppointments(patient.appointments, false),
              isUpcoming: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int index;
  final int selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == selected;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.backgroundGrey,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _AppointmentList extends StatelessWidget {
  final List<AppointmentModel> appointments;
  final bool isUpcoming;

  const _AppointmentList({
    required this.appointments,
    required this.isUpcoming,
  });

  @override
  Widget build(BuildContext context) {
    if (appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUpcoming ? Icons.calendar_today_outlined : Icons.history_rounded,
              size: 64,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 16),
            Text(
              isUpcoming ? 'Aucun rendez-vous à venir' : 'Aucun historique',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            if (isUpcoming)
              const Text(
                'Prenez un RDV avec un médecin',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: AppColors.textLight,
                ),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: appointments.length,
      itemBuilder: (_, i) => _AppointmentCard(
        appointment: appointments[i],
        isUpcoming: isUpcoming,
      ),
    );
  }
}

// ─── Carte RDV complète ───────────────────────────────────────────────────────

class _AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final bool isUpcoming;

  const _AppointmentCard({
    required this.appointment,
    required this.isUpcoming,
  });

  Color get _statusColor {
    switch (appointment.status) {
      case AppointmentStatus.confirmed: return AppColors.success;
      case AppointmentStatus.pending: return AppColors.warning;
      case AppointmentStatus.cancelled: return AppColors.error;
      case AppointmentStatus.completed: return AppColors.primary;
      case AppointmentStatus.inProgress: return AppColors.accentBlue;
      case AppointmentStatus.noShow: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // En-tête couleur
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        appointment.statusLabel,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: _statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Type badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: appointment.isTeleconsultation
                        ? AppColors.accentBlue.withValues(alpha: 0.12)
                        : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        appointment.isTeleconsultation
                            ? Icons.videocam_rounded
                            : Icons.local_hospital_rounded,
                        size: 12,
                        color: appointment.isTeleconsultation
                            ? AppColors.accentBlue
                            : AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        appointment.isTeleconsultation ? 'Téléconsult' : 'Présentiel',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: appointment.isTeleconsultation
                              ? AppColors.accentBlue
                              : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Contenu
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Médecin
                Row(
                  children: [
                    _DoctorAvatar(name: appointment.doctorName),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appointment.doctorName,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            appointment.doctorSpecialty,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (appointment.isPaid)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded,
                                color: AppColors.success, size: 12),
                            SizedBox(width: 3),
                            Text('Payé',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 10,
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w700,
                                )),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Date & Heure
                Row(
                  children: [
                    _InfoChip(
                      icon: Icons.calendar_today_rounded,
                      text: _formatDate(appointment.scheduledAt),
                    ),
                    const SizedBox(width: 8),
                    _InfoChip(
                      icon: Icons.access_time_rounded,
                      text: _formatTime(appointment.scheduledAt),
                    ),
                    const SizedBox(width: 8),
                    _InfoChip(
                      icon: Icons.timer_rounded,
                      text: '${appointment.durationMinutes} min',
                    ),
                  ],
                ),

                if (appointment.reason != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Motif : ${appointment.reason}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                if (appointment.consultationPrice != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Tarif : ${appointment.consultationPrice!.toStringAsFixed(0)} F CFA',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // Actions selon statut
                _buildActions(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    if (!isUpcoming && appointment.status == AppointmentStatus.completed) {
      // RDV terminé → option évaluer + payer si non payé
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReviewScreen(
                    doctor: _fakeDoctor(),
                    appointmentId: appointment.id,
                  ),
                ),
              ),
              icon: const Icon(Icons.star_outline_rounded, size: 16),
              label: const Text('Évaluer', style: TextStyle(fontFamily: 'Poppins', fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFFB800),
                side: const BorderSide(color: Color(0xFFFFB800)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          if (!appointment.isPaid) ...[
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaymentScreen(
                      amount: appointment.consultationPrice ?? 10000,
                      description: 'Consultation - ${appointment.doctorName}',
                      appointmentId: appointment.id,
                      paymentType: PaymentType.appointment,
                    ),
                  ),
                ),
                icon: const Icon(Icons.payment_rounded, size: 16),
                label: const Text('Payer', style: TextStyle(fontFamily: 'Poppins', fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ],
      );
    }

    if (appointment.status == AppointmentStatus.cancelled) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cancel_outlined, color: AppColors.error, size: 16),
            SizedBox(width: 6),
            Text('Rendez-vous annulé',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: AppColors.error,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    if (isUpcoming) {
      return Row(
        children: [
          if (appointment.isTeleconsultation)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VideoCallScreen(
                      doctorName: appointment.doctorName,
                      doctorSpecialty: appointment.doctorSpecialty,
                    ),
                  ),
                ),
                icon: const Icon(Icons.videocam_rounded, size: 16),
                label: const Text('Rejoindre', style: TextStyle(fontFamily: 'Poppins', fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            )
          else
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  DoctorModel? doc;
                  try {
                    final patientProv = context.read<PatientProvider>();
                    for (final d in patientProv.doctors) {
                      if (d.id == appointment.doctorId) {
                        doc = d;
                        break;
                      }
                    }
                  } catch (_) {}

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InAppItineraryScreen(
                        destinationTitle: appointment.doctorName,
                        destinationSubtitle: doc?.specialty ?? appointment.doctorSpecialty,
                        destinationAddress: doc?.address != null && doc!.address!.isNotEmpty
                            ? '${doc.address!}, ${doc.city ?? 'Abidjan'}'
                            : 'Cabinet médical, Abidjan',
                        destinationLatitude: doc?.latitude ?? 5.3599517,
                        destinationLongitude: doc?.longitude ?? -4.0082563,
                        destinationPhone: doc?.phone,
                        destinationCategory: 'Cabinet Médical',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.map_outlined, size: 16),
                label: const Text('Itinéraire', style: TextStyle(fontFamily: 'Poppins', fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          if (!appointment.isPaid) ...[
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaymentScreen(
                      amount: appointment.consultationPrice ?? 10000,
                      description: 'Consultation - ${appointment.doctorName}',
                      appointmentId: appointment.id,
                      paymentType: PaymentType.appointment,
                    ),
                  ),
                ),
                icon: const Icon(Icons.payment_rounded, size: 16),
                label: const Text('Payer', style: TextStyle(fontFamily: 'Poppins', fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: () => _showCancelDialog(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            ),
            child: const Icon(Icons.cancel_outlined, size: 18),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Annuler le rendez-vous ?',
            style: TextStyle(fontFamily: 'Poppins')),
        content: const Text(
          'Êtes-vous sûr de vouloir annuler ce rendez-vous ? Des frais peuvent s\'appliquer.',
          style: TextStyle(fontFamily: 'Poppins', color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Garder', style: TextStyle(fontFamily: 'Poppins')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await context.read<PatientProvider>().cancelAppointment(appointment.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Rendez-vous annulé avec succès'),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Annuler le RDV',
                style: TextStyle(fontFamily: 'Poppins', color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Crée un faux DoctorModel pour le ReviewScreen
  DoctorModel _fakeDoctor() => DoctorModel(
    id: appointment.doctorId,
    userId: appointment.doctorId,
    firstName: appointment.doctorName.split(' ').last,
    lastName: appointment.doctorName.split(' ').first,
    email: '',
    phone: '',
    specialty: appointment.doctorSpecialty,
    orderNumber: '00000',
    bio: '',
    latitude: 0,
    longitude: 0,
    rating: 4.8,
    reviewCount: 100,
    patientCount: 500,
    experienceYears: 5,
    successRate: 98,
    consultationPrice: appointment.consultationPrice ?? 10000,
    isAvailable: true,
    isVerified: true,
    availableDays: [],
    availableSlots: {},
    createdAt: DateTime.now(),
  );

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}h${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ─── Widgets utilitaires ──────────────────────────────────────────────────────

class _DoctorAvatar extends StatelessWidget {
  final String name;
  const _DoctorAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(text,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              )),
        ],
      ),
    );
  }
}
