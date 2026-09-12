import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'treating_doctor_chat_screen.dart';
import '../shared/pre_call_screen.dart';
import '../../core/theme/app_theme.dart';
import '../../models/doctor_model.dart';
import '../../models/appointment_model.dart';
import '../../models/treating_doctor_request_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/patient_provider.dart';
import '../../providers/treating_request_provider.dart';
import '../../widgets/common/avatar_widget.dart';
import '../../widgets/common/health_id_card_widget.dart';

class DoctorProfileScreen extends StatefulWidget {
  final DoctorModel doctor;

  const DoctorProfileScreen({super.key, required this.doctor});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedSlot;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.doctor;
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Consumer2<AuthProvider, TreatingRequestProvider>(
        builder: (context, auth, trProvider, _) {
          final patientId = auth.currentUser?.id ?? '';
          final hasAccess = trProvider.hasAccessTo(patientId, doc.id);
          final isPending = !hasAccess &&
              trProvider.hasPendingOrAccepted(patientId, doc.id);

          return CustomScrollView(
            slivers: [
              // Hero Header
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: AppColors.primaryDark,
                leading: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.textWhite.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textWhite, size: 18),
                  ),
                ),
                actions: [
                  GestureDetector(
                    onTap: () {
                      setState(() => _isFavorite = !_isFavorite);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_isFavorite
                              ? 'Dr. ${doc.lastName} ajouté à vos favoris'
                              : 'Dr. ${doc.lastName} retiré de vos favoris'),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.textWhite.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: _isFavorite ? AppColors.brandCoral : AppColors.textWhite,
                        size: 20,
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                DoctorAvatar(
                                  imageUrl: doc.avatarUrl,
                                  avatarBase64: doc.avatarBase64,
                                  name: doc.fullName,
                                  size: 80,
                                  isOnline: doc.isOnline,
                                  isVerified: doc.isVerified,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.star_rounded, color: AppColors.star, size: 16),
                                          const SizedBox(width: 4),
                                          Text(doc.formattedRating, style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textWhite)),
                                          const SizedBox(width: 4),
                                          Text('(${doc.reviewCount} avis)', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textWhite.withValues(alpha: 0.7))),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(doc.fullName, style: const TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textWhite)),
                                      Text(doc.specialty, style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: AppColors.textWhite.withValues(alpha: 0.85))),
                                      if (doc.address != null) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.location_on_outlined, size: 13, color: AppColors.textWhite.withValues(alpha: 0.7)),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                doc.address!,
                                                style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textWhite.withValues(alpha: 0.7)),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Action buttons — tous actifs et cliquables
                            Row(
                              children: [
                                // Info tab button (active)
                                GestureDetector(
                                  onTap: () => _tabController.animateTo(0),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                                    decoration: BoxDecoration(
                                      color: AppColors.textWhite,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.info_outline, color: AppColors.primary, size: 16),
                                        const SizedBox(width: 6),
                                        Text('Info', style: AppTextStyles.body2.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                _RoundAction(
                                  icon: Icons.phone_outlined,
                                  onTap: () => _callDoctor(),
                                  locked: false,
                                ),
                                const SizedBox(width: 10),
                                _RoundAction(
                                  icon: Icons.videocam_outlined,
                                  onTap: () => _joinVideoCall(),
                                  locked: false,
                                ),
                                const SizedBox(width: 10),
                                _RoundAction(
                                  icon: Icons.chat_bubble_outline_rounded,
                                  onTap: () => _openChat(),
                                  locked: false,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Bandeau statut demande
              if (isPending || hasAccess)
                SliverToBoxAdapter(
                  child: _StatusBanner(hasAccess: hasAccess, isPending: isPending),
                ),

              // Content
              SliverToBoxAdapter(
                child: Column(
                  children: [
                  // Stats
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundCard,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 4))],
                    ),
                    child: Row(
                      children: [
                        _StatItem(value: '${doc.experienceYears} ans', label: 'Expérience', icon: Icons.access_time_outlined),
                        _VerticalDivider(),
                        _StatItem(value: doc.formattedPatients, label: 'Patients', icon: Icons.people_outline),
                        _VerticalDivider(),
                        _StatItem(value: '${doc.successRate.toInt()}%', label: 'Satisfaction', icon: Icons.trending_up_rounded),
                      ],
                    ),
                  ),

                  // Tabs
                  Container(
                    color: AppColors.backgroundCard,
                    child: TabBar(
                      controller: _tabController,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textSecondary,
                      indicatorColor: AppColors.primary,
                      labelStyle: AppTextStyles.body2.copyWith(fontWeight: FontWeight.w600),
                      tabs: const [
                        Tab(text: 'À propos'),
                        Tab(text: 'Prendre RDV'),
                        Tab(text: 'Avis'),
                      ],
                    ),
                  ),

                  SizedBox(
                    height: 500,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _AboutTab(
                          doctor: doc,
                          hasAccess: hasAccess,
                          isPending: isPending,
                          onRequest: () => _sendTreatingRequest(auth),
                          onChat: () => _openChat(),
                          onOpenMap: (d) => _openMap(d),
                        ),
                        _BookingTab(
                          doctor: doc,
                          selectedDate: _selectedDate,
                          selectedSlot: _selectedSlot,
                          onDateSelected: (d) => setState(() { _selectedDate = d; _selectedSlot = null; }),
                          onSlotSelected: (s) => setState(() => _selectedSlot = s),
                          onBook: _bookAppointment,
                        ),
                        _ReviewsTab(doctor: doc),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
        },
      ),
    );
  }

  // ── Appel audio direct ──
  void _callDoctor() {
    final phone = widget.doctor.phone.isNotEmpty ? widget.doctor.phone : '0505050505';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.phone_in_talk_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('Appel audio', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text('Voulez-vous composer le numéro du ${widget.doctor.fullName} ?\n\nTél : $phone'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              Navigator.pop(ctx);
              final uri = Uri.parse('tel:$phone');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Appel en cours vers le $phone...'),
                      backgroundColor: AppColors.primary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.phone, size: 16),
            label: const Text('Appeler'),
          ),
        ],
      ),
    );
  }

  // ── Appel vidéo direct ──
  void _joinVideoCall() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PreCallScreen(
          doctorName: widget.doctor.fullName,
          doctorSpecialty: widget.doctor.specialty,
          isIncoming: false,
        ),
      ),
    );
  }

  // ── Chat direct ──
  void _openChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TreatingDoctorChatScreen(doctor: widget.doctor),
      ),
    );
  }

  // ── Localisation Carte ──
  void _openMap(DoctorModel doctor) async {
    final query = Uri.encodeComponent('${doctor.address ?? 'Abidjan'}, ${doctor.city ?? 'Côte d\'Ivoire'}');
    final googleUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    if (await canLaunchUrl(googleUrl)) {
      await launchUrl(googleUrl, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cabinet médical : ${doctor.address ?? doctor.city ?? 'Abidjan'}'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ── Message d'accès refusé ────────────────────────────────────────────────
  void _showAccessDenied(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.lock_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ── Envoi demande traitant ── via TreatingRequestProvider
  void _sendTreatingRequest(AuthProvider auth) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _TreatingDoctorRequestSheet(
        doctor: widget.doctor,
        patientId: auth.currentUser?.id ?? '',
        patientName: auth.userName,
        onConfirm: (msg, paymentMethod) async {
          final trProvider = context.read<TreatingRequestProvider>();
          final patientId = auth.currentUser?.id ?? '';

          // Masquer le médecin de la liste immédiatement
          final success = await trProvider.sendRequest(
            patientId: patientId,
            patientName: auth.userName,
            patientPhone: auth.currentUser?.phone ?? '',
            patientAvatar: auth.currentUserAvatarBase64,
            doctorId: widget.doctor.id,
            doctorName: widget.doctor.fullName,
            doctorSpecialty: widget.doctor.specialty,
            message: msg,
            paymentMethod: paymentMethod,
          );

          if (context.mounted) {
            Navigator.pop(context);
            if (success) {
              // Mettre à jour la liste du patient pour masquer ce médecin
              final authProvider = context.read<AuthProvider>();
              final patientProvider = context.read<PatientProvider>();
              final excluded = trProvider.allRequests
                  .where((r) =>
                      r.patientId == patientId &&
                      (r.status.name == 'pending' || r.status.name == 'accepted'))
                  .map((r) => r.doctorId)
                  .toSet();
              patientProvider.setDoctors(authProvider.mockDoctors, excludedDoctorIds: excluded);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Demande envoyée ! 500 FCFA débités. En attente de réponse du médecin.'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 4),
                ),
              );
              // Retourner à la liste (médecin retiré)
              if (context.mounted) Navigator.pop(context);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Une demande est déjà en cours avec ce médecin.'),
                  backgroundColor: AppColors.warning,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _bookAppointment() {
    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un créneau horaire'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final timeParts = _selectedSlot!.split(':');
    final scheduledAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ConfirmBookingSheet(
        doctor: widget.doctor,
        scheduledAt: scheduledAt,
        slot: _selectedSlot!,
        onConfirm: () async {
          final patient = context.read<PatientProvider>();
          final appt = AppointmentModel(
            id: 'apt_${DateTime.now().millisecondsSinceEpoch}',
            patientId: auth.currentUser?.id ?? '',
            patientName: auth.userName,
            patientAvatar: auth.currentUser?.avatarBase64 ?? auth.currentUser?.avatarUrl,
            doctorId: widget.doctor.id,
            doctorName: widget.doctor.fullName,
            doctorSpecialty: widget.doctor.specialty,
            doctorAvatar: widget.doctor.avatarUrl,
            scheduledAt: scheduledAt,
            status: AppointmentStatus.pending,
            type: AppointmentType.inPerson,
            reason: 'Consultation ${widget.doctor.specialty}',
            consultationPrice: widget.doctor.consultationPrice,
            createdAt: DateTime.now(),
          );
          await patient.bookAppointment(appt);
          if (context.mounted) {
            Navigator.pop(context);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Rendez-vous réservé avec succès !'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool locked;
  const _RoundAction({required this.icon, required this.onTap, this.locked = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: locked
                  ? AppColors.textWhite.withValues(alpha: 0.08)
                  : AppColors.textWhite.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: locked
                  ? AppColors.textWhite.withValues(alpha: 0.4)
                  : AppColors.textWhite,
              size: 20,
            ),
          ),
          if (locked)
            Positioned(
              bottom: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: AppColors.warning,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock, size: 9, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

// Bandeau de statut de la demande
class _StatusBanner extends StatelessWidget {
  final bool hasAccess;
  final bool isPending;
  const _StatusBanner({required this.hasAccess, required this.isPending});

  @override
  Widget build(BuildContext context) {
    if (hasAccess) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Demande acceptée — Messagerie, appel audio et vidéo débloqués',
                style: AppTextStyles.body2.copyWith(color: AppColors.success, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    }
    // isPending
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.warning),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Demande envoyée — En attente de réponse du médecin',
              style: AppTextStyles.body2.copyWith(color: AppColors.warning, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  const _StatItem({required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 40, color: AppColors.backgroundGrey);
  }
}

// ABOUT TAB
class _AboutTab extends StatelessWidget {
  final DoctorModel doctor;
  final VoidCallback onRequest;
  final VoidCallback? onChat;
  final Function(DoctorModel) onOpenMap;
  final bool hasAccess;
  final bool isPending;
  const _AboutTab({
    required this.doctor,
    required this.onRequest,
    this.onChat,
    required this.onOpenMap,
    this.hasAccess = false,
    this.isPending = false,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Carte Praticien officielle ──
          HealthIdCardWidget(
            isDoctor: true,
            lastName: doctor.lastName,
            firstName: doctor.firstName,
            idNumber: doctor.orderNumber.isNotEmpty ? 'ORD-${doctor.orderNumber}' : 'MED-12345',
            location: doctor.specialty,
            birthDate: 'PRATICIEN INSCRIT',
            avatarUrl: doctor.avatarUrl,
            showActions: false,
          ),
          const SizedBox(height: 24),

          if (doctor.bio != null) ...[
            const Text('À propos', style: AppTextStyles.heading3),
            const SizedBox(height: 8),
            Text(doctor.bio!, style: AppTextStyles.body1.copyWith(height: 1.7)),
            const SizedBox(height: 20),
          ],

          const Text('Informations', style: AppTextStyles.heading3),
          const SizedBox(height: 12),
          _InfoRow(icon: Icons.medical_services_outlined, label: 'Spécialité', value: doctor.specialty),
          _InfoRow(
            icon: Icons.badge_outlined,
            label: 'N° Ordre',
            value: doctor.orderNumber.length >= 2
                ? '${doctor.orderNumber.substring(0, 2)}***'
                : (doctor.orderNumber.isNotEmpty ? doctor.orderNumber : 'Non renseigné'),
          ),
          _InfoRow(icon: Icons.location_on_outlined, label: 'Adresse', value: '${doctor.address ?? ''}, ${doctor.city ?? ''}'),
          _InfoRow(icon: Icons.attach_money_rounded, label: 'Consultation', value: doctor.formattedPrice),
          if (doctor.distanceKm != null)
            _InfoRow(icon: Icons.directions_walk_outlined, label: 'Distance', value: doctor.formattedDistance),

          const SizedBox(height: 20),

          // Bouton Chat — toujours cliquable
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onChat,
              icon: const Icon(Icons.chat_bubble_rounded, size: 18),
              label: const Text('Envoyer un message', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textWhite,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Bouton demande traitant — conditionnel selon statut
          if (!hasAccess && !isPending)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onRequest,
                icon: const Icon(Icons.family_restroom_rounded, size: 18),
                label: const Text('Demander comme médecin traitant\n(500 FCFA)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            )
          else if (isPending)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.warning)),
                  const SizedBox(width: 10),
                  Text('Demande en attente de réponse…', style: AppTextStyles.body2.copyWith(color: AppColors.warning, fontWeight: FontWeight.w500)),
                ],
              ),
            ),

          const SizedBox(height: 16),
          // Bouton Voir sur la carte — cliquable
          InkWell(
            onTap: () => onOpenMap(doctor),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                color: AppColors.backgroundGrey,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.map_outlined, color: AppColors.primary, size: 36),
                    const SizedBox(height: 8),
                    Text('Voir sur la carte', style: AppTextStyles.body2.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                    if (doctor.address != null) ...[
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          doctor.address!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryUltraLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 16),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption),
              Text(value, style: AppTextStyles.subtitle2.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }
}

// BOOKING TAB
class _BookingTab extends StatelessWidget {
  final DoctorModel doctor;
  final DateTime selectedDate;
  final String? selectedSlot;
  final Function(DateTime) onDateSelected;
  final Function(String) onSlotSelected;
  final VoidCallback onBook;

  const _BookingTab({
    required this.doctor,
    required this.selectedDate,
    this.selectedSlot,
    required this.onDateSelected,
    required this.onSlotSelected,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    // Generate next 7 days
    final days = List.generate(7, (i) => DateTime.now().add(Duration(days: i + 1)));

    // Get available slots for selected date
    final dateKey = DateFormat('yyyy-MM-dd').format(selectedDate);
    final slots = doctor.availableSlots[dateKey] ??
        ['08:00', '09:00', '10:00', '14:00', '15:00', '16:00'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sélectionner une date', style: AppTextStyles.heading3),
          const SizedBox(height: 12),

          // Date picker
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: days.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final day = days[i];
                final isSelected = DateFormat('yyyy-MM-dd').format(day) ==
                    DateFormat('yyyy-MM-dd').format(selectedDate);
                return GestureDetector(
                  onTap: () => onDateSelected(day),
                  child: Container(
                    width: 58,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.backgroundCard,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: isSelected ? 0.25 : 0.06),
                          blurRadius: 10, offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('EEE', 'fr_FR').format(day).toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: isSelected ? AppColors.textWhite.withValues(alpha: 0.8) : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('d').format(day),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? AppColors.textWhite : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),
          const Text('Créneaux disponibles', style: AppTextStyles.heading3),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: slots.map((slot) {
              final isSelected = slot == selectedSlot;
              return GestureDetector(
                onTap: () => onSlotSelected(slot),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.brandTurquoise : AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.brandTurquoise : AppColors.borderSubtle,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isSelected ? AppColors.brandTurquoise : AppColors.brandNavy).withValues(alpha: isSelected ? 0.25 : 0.04),
                        blurRadius: 8, offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    slot,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),
          // Notice version de démonstration
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.brandBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Les rendez-vous sont actuellement enregistrés localement dans cette version.',
                    style: AppTextStyles.caption.copyWith(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onBook,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Prendre rendez-vous', style: AppTextStyles.button),
            ),
          ),
        ],
      ),
    );
  }
}

// REVIEWS TAB
class _ReviewsTab extends StatelessWidget {
  final DoctorModel doctor;
  const _ReviewsTab({required this.doctor});

  @override
  Widget build(BuildContext context) {
    final reviews = [
      ('Kouamé Jean', 5.0, 'Médecin très professionnel et attentionné. Très satisfait de la consultation.', DateTime.now().subtract(const Duration(days: 5))),
      ('Akissi Grace', 4.5, 'Excellent docteur, très à l\'écoute. Le rendez-vous était ponctuel.', DateTime.now().subtract(const Duration(days: 12))),
      ('Diallo Ibrahim', 5.0, 'Je recommande vivement Dr. ${doctor.lastName}. Très compétent et humain.', DateTime.now().subtract(const Duration(days: 20))),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Rating summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Column(
                children: [
                  Text(doctor.formattedRating, style: AppTextStyles.heading1.copyWith(color: AppColors.primary, fontSize: 42)),
                  Row(children: List.generate(5, (i) => Icon(i < doctor.rating ? Icons.star_rounded : Icons.star_border_rounded, color: AppColors.star, size: 18))),
                  const SizedBox(height: 4),
                  Text('${doctor.reviewCount} avis', style: AppTextStyles.caption),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [5, 4, 3, 2, 1].map((star) {
                    final percent = star == 5 ? 0.7 : star == 4 ? 0.2 : 0.06;
                    return Row(
                      children: [
                        Text('$star', style: AppTextStyles.caption),
                        const SizedBox(width: 6),
                        const Icon(Icons.star_rounded, size: 12, color: AppColors.star),
                        const SizedBox(width: 6),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: percent,
                            backgroundColor: AppColors.backgroundGrey,
                            color: AppColors.star,
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...reviews.map((r) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primaryUltraLight,
                    child: Text(r.$1[0], style: AppTextStyles.body2.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.$1, style: AppTextStyles.subtitle2.copyWith(fontWeight: FontWeight.w600)),
                        Row(children: List.generate(5, (i) => Icon(i < r.$2 ? Icons.star_rounded : Icons.star_border_rounded, color: AppColors.star, size: 14))),
                      ],
                    ),
                  ),
                  Text(DateFormat('d MMM', 'fr_FR').format(r.$4), style: AppTextStyles.caption),
                ],
              ),
              const SizedBox(height: 8),
              Text(r.$3, style: AppTextStyles.body2.copyWith(height: 1.6)),
            ],
          ),
        )),
      ],
    );
  }
}

// Treating Doctor Request Sheet
class _TreatingDoctorRequestSheet extends StatefulWidget {
  final DoctorModel doctor;
  final String patientId;
  final String patientName;
  final Function(String, String) onConfirm;

  const _TreatingDoctorRequestSheet({
    required this.doctor,
    required this.patientId,
    required this.patientName,
    required this.onConfirm,
  });

  @override
  State<_TreatingDoctorRequestSheet> createState() => _TreatingDoctorRequestSheetState();
}

class _TreatingDoctorRequestSheetState extends State<_TreatingDoctorRequestSheet> {
  final _msgCtrl = TextEditingController(text: TreatingDoctorRequest.defaultMessage);
  String _paymentMethod = 'wave';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.backgroundGrey, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 20),
            const Text('Demande médecin traitant', style: AppTextStyles.heading3),
            const SizedBox(height: 6),
            Text('Envoyez une demande à ${widget.doctor.fullName}', style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            TextField(
              controller: _msgCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Message'),
              style: AppTextStyles.body1,
            ),
            const SizedBox(height: 20),
            Text('Mode de paiement (750 F CFA)', style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              children: ['wave', 'orange_money', 'mtn_money', 'moov_money', 'djamo'].map((pm) {
                final isSelected = _paymentMethod == pm;
                final labels = {'wave': 'Wave', 'orange_money': 'Orange', 'mtn_money': 'MTN', 'moov_money': 'Moov', 'djamo': 'Djamo'};
                return GestureDetector(
                  onTap: () => setState(() => _paymentMethod = pm),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.backgroundGrey,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? AppColors.primary : Colors.transparent),
                    ),
                    child: Text(labels[pm]!, style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: isSelected ? AppColors.textWhite : AppColors.textPrimary, fontWeight: FontWeight.w500)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : () {
                  setState(() => _isLoading = true);
                  widget.onConfirm(_msgCtrl.text, _paymentMethod);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textWhite))
                    : const Text('Confirmer et payer 750 F CFA', style: AppTextStyles.button),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Confirm Booking Sheet
class _ConfirmBookingSheet extends StatelessWidget {
  final DoctorModel doctor;
  final DateTime scheduledAt;
  final String slot;
  final VoidCallback onConfirm;

  const _ConfirmBookingSheet({required this.doctor, required this.scheduledAt, required this.slot, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.backgroundGrey, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          const Text('Confirmer le rendez-vous', style: AppTextStyles.heading3),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.backgroundLight, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                _ConfirmRow(label: 'Médecin', value: doctor.fullName),
                _ConfirmRow(label: 'Spécialité', value: doctor.specialty),
                _ConfirmRow(label: 'Date', value: DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(scheduledAt)),
                _ConfirmRow(label: 'Heure', value: slot),
                _ConfirmRow(label: 'Tarif', value: doctor.formattedPrice),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Confirmer', style: AppTextStyles.button),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  final String label;
  final String value;
  const _ConfirmRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary)),
          Text(value, style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
