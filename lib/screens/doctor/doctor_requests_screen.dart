// ════════════════════════════════════════════════════════════
//  doctor_requests_screen.dart
//  MédiLink Care — Demandes patients (côté MÉDECIN)
//  • 3 onglets : En attente / Acceptées / Refusées
//  • Données depuis TreatingRequestProvider (Hive — pas Firebase)
//  • Accepter → notifie patient + débloque messagerie + appels
//  • Refuser → notifie patient, médecin réapparaît dans sa liste
// ════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/treating_request_provider.dart';
import '../../models/treating_doctor_request_model.dart';
import '../../models/user_model.dart';
import '../../providers/message_provider.dart';
import '../../widgets/common/avatar_widget.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../widgets/doctor/refer_patient_dialog.dart';
import 'patient_chat_screen.dart';

class DoctorRequestsScreen extends StatefulWidget {
  final VoidCallback? onBackToDashboard;

  const DoctorRequestsScreen({super.key, this.onBackToDashboard});

  @override
  State<DoctorRequestsScreen> createState() => _DoctorRequestsScreenState();
}

class _DoctorRequestsScreenState extends State<DoctorRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    // Marquer les notifications du médecin comme lues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final doctorId = auth.doctorProfile?.id ?? '';
      context.read<TreatingRequestProvider>().markAllReadForDoctor(doctorId);
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, TreatingRequestProvider>(
      builder: (context, auth, trProvider, _) {
        final doctorId = auth.doctorProfile?.id ?? '';
        final all = trProvider.requestsForDoctor(doctorId);

        final pending = all
            .where((r) => r.status == TreatingDoctorStatus.pending)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final accepted = all
            .where((r) => r.status == TreatingDoctorStatus.accepted)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final referred = all
            .where((r) =>
                r.status == TreatingDoctorStatus.rejected ||
                r.status == TreatingDoctorStatus.referred ||
                r.referredToDoctorId != null)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return Scaffold(
          backgroundColor: AppColors.backgroundLight,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context, pending.length),
                _buildTabs(pending.length, accepted.length, referred.length),
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      _RequestList(
                        requests: pending,
                        statut: 'pending',
                        trProvider: trProvider,
                        doctorName: auth.doctorProfile?.fullName ??
                            auth.currentUser?.fullName ?? 'le médecin',
                      ),
                      _RequestList(
                        requests: accepted,
                        statut: 'accepted',
                        trProvider: trProvider,
                        doctorName: auth.doctorProfile?.fullName ??
                            auth.currentUser?.fullName ?? 'le médecin',
                      ),
                      _RequestList(
                        requests: referred,
                        statut: 'referred',
                        trProvider: trProvider,
                        doctorName: auth.doctorProfile?.fullName ??
                            auth.currentUser?.fullName ?? 'le médecin',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleBack(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else if (widget.onBackToDashboard != null) {
      widget.onBackToDashboard!();
    } else {
      Navigator.maybePop(context);
    }
  }

  // ── Header ─────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, int pendingCount) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Tooltip(
            message: 'Retour',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _handleBack(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.textWhite.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.textWhite,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Demandes patients',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textWhite,
                  ),
                ),
                Text(
                  'Gérez vos demandes de médecin traitant',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: AppColors.textWhite.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          // Badge live demandes en attente
          if (pendingCount > 0)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.pending_actions_rounded,
                      color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '$pendingCount',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── TabBar ─────────────────────────────────────────────────
  Widget _buildTabs(int pending, int accepted, int refused) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabs,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w600),
        tabs: [
          _TabItem(label: 'En attente', count: pending, color: AppColors.warning),
          _TabItem(label: 'Acceptées', count: accepted, color: AppColors.success),
          _TabItem(label: 'Référées', count: refused, color: const Color(0xFF185FA5)),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  LISTE DES DEMANDES
// ════════════════════════════════════════════════════════════
class _RequestList extends StatelessWidget {
  final List<TreatingDoctorRequest> requests;
  final String statut; // 'pending' | 'accepted' | 'refused'
  final TreatingRequestProvider trProvider;
  final String doctorName;

  const _RequestList({
    required this.requests,
    required this.statut,
    required this.trProvider,
    required this.doctorName,
  });

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return _EmptyState(statut: statut);
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      itemCount: requests.length,
      itemBuilder: (_, i) => _RequestCard(
        request: requests[i],
        trProvider: trProvider,
        doctorName: doctorName,
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  CARTE DEMANDE PATIENT (côté médecin)
// ════════════════════════════════════════════════════════════
class _RequestCard extends StatefulWidget {
  final TreatingDoctorRequest request;
  final TreatingRequestProvider trProvider;
  final String doctorName;

  const _RequestCard({
    required this.request,
    required this.trProvider,
    required this.doctorName,
  });

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  bool _loading = false;

  // ── Accepter ───────────────────────────────────────────────
  Future<void> _accept() async {
    setState(() => _loading = true);
    final msgProvider = context.read<MessageProvider>();
    await widget.trProvider.respondToRequest(
      requestId: widget.request.id,
      accept: true,
      messageProvider: msgProvider,
    );
    if (mounted) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${widget.request.patientName} a été notifié(e) de votre acceptation.',
                  style: const TextStyle(fontFamily: 'Poppins'),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  // ── Référer à un confrère (remplace le refus) ────────────────
  Future<void> _refer() async {
    final result = await ReferPatientDialog.show(
      context,
      requestId: widget.request.id,
      patientName: widget.request.patientName,
      currentDoctorId: widget.request.doctorId,
    );
    if (result == true && mounted) {
      setState(() {});
    }
  }

  // ── Ouvrir le chat avec le patient ───────────────────────
  void _openPatientChat() {
    // Convertir les données de la demande en UserModel pour le patient
    final patientNameParts = widget.request.patientName.split(' ');
    final patient = UserModel(
      id: widget.request.patientId,
      firstName: patientNameParts.length > 1
          ? patientNameParts.sublist(1).join(' ')
          : widget.request.patientName,
      lastName: patientNameParts.isNotEmpty ? patientNameParts[0] : '',
      email: 'patient@medilink.care', // Email placeholder
      phone: '', // Téléphone non disponible dans la demande
      role: UserRole.patient,
      status: AccountStatus.active,
      avatarUrl: widget.request.patientAvatar,
      createdAt: widget.request.createdAt,
      cmuNumber: 'Patient',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PatientChatScreen(patient: patient),
      ),
    );
  }

  Color get _borderColor {
    switch (widget.request.status) {
      case TreatingDoctorStatus.pending:
        return AppColors.warning;
      case TreatingDoctorStatus.accepted:
        return AppColors.success;
      case TreatingDoctorStatus.rejected:
        return AppColors.error;
      default:
        return AppColors.backgroundGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPending = widget.request.status == TreatingDoctorStatus.pending;
    final isAccepted = widget.request.status == TreatingDoctorStatus.accepted;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: _borderColor.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _borderColor.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── En-tête patient ───────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar du patient
                AvatarWidget(
                  imageUrl: widget.request.patientAvatar,
                  initials: widget.request.patientName.isNotEmpty
                      ? widget.request.patientName[0].toUpperCase()
                      : 'P',
                  size: 48,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              widget.request.patientName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.subtitle1
                                  .copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusBadge(widget.request.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.medical_services_outlined,
                              color: AppColors.primary, size: 13),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Demande de médecin traitant',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Envoyée le ${DateFormat('d MMM yyyy', 'fr_FR').format(widget.request.createdAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Paiement ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.2)),
              ),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 15),
                  const SizedBox(width: 6),
                  Text(
                    '${widget.request.amount.toInt()} FCFA payés',
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600),
                  ),
                  if (widget.request.paymentMethod != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      '• ${widget.request.paymentMethod!.toUpperCase()}',
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── Message du patient ─────────────────────────────
          if (widget.request.message.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.backgroundGrey),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.format_quote_rounded,
                            color: AppColors.primary, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Message du patient',
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.request.message,
                      style: AppTextStyles.body2.copyWith(
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                          height: 1.5),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

          // ── Information de recommandation / référence ───────
          if (widget.request.isReferred)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.share_2,
                            color: Color(0xFF8B5CF6), size: 15),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.request.referredFromDoctorName != null
                                ? 'Référé par Dr. ${widget.request.referredFromDoctorName}'
                                : 'Patient référé à un confrère',
                            style: AppTextStyles.caption.copyWith(
                                color: const Color(0xFF8B5CF6),
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    if (widget.request.referralNote != null &&
                        widget.request.referralNote!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Note : "${widget.request.referralNote}"',
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic),
                      ),
                    ],
                  ],
                ),
              ),
            ),

          // ── Canaux débloqués (si accepté) ─────────────────
          if (isAccepted) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lock_open_rounded,
                            color: AppColors.success, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Canaux de communication débloqués',
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _ChannelChip(
                            icon: Icons.chat_bubble_rounded,
                            label: 'Message',
                            color: AppColors.primary,
                            onTap: _openPatientChat),
                        const _ChannelChip(
                            icon: Icons.phone_rounded,
                            label: 'Appel',
                            color: AppColors.success),
                        const _ChannelChip(
                            icon: Icons.videocam_rounded,
                            label: 'Vidéo',
                            color: AppColors.accent),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],

          // ── Boutons Accepter / Refuser (pending uniquement) ─
          if (isPending)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _loading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: CircularProgressIndicator(
                            color: AppColors.primary, strokeWidth: 2),
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _refer,
                            icon: const Icon(LucideIcons.user_round_cog,
                                size: 16, color: Color(0xFF8B5CF6)),
                            label: const Text(
                              'Référer',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                color: Color(0xFF8B5CF6),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF8B5CF6)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: _accept,
                            icon: const Icon(Icons.check_rounded,
                                size: 17, color: Colors.white),
                            label: const Text(
                              'Accepter',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              elevation: 0,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
        ],
      ),
    );
  }
}

// ─── Chip canal débloqué ──────────────────────────────────────────────────────
class _ChannelChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ChannelChip({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 13),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Badge de statut ─────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final TreatingDoctorStatus status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    final IconData icon;

    switch (status) {
      case TreatingDoctorStatus.pending:
        color = AppColors.warning;
        label = 'En attente';
        icon = Icons.hourglass_top_rounded;
        break;
      case TreatingDoctorStatus.accepted:
        color = AppColors.success;
        label = 'Acceptée';
        icon = Icons.check_circle_rounded;
        break;
      case TreatingDoctorStatus.referred:
        color = const Color(0xFF8B5CF6);
        label = 'Référée';
        icon = LucideIcons.share_2;
        break;
      case TreatingDoctorStatus.rejected:
        color = AppColors.error;
        label = 'Refusée';
        icon = Icons.cancel_rounded;
        break;
      default:
        color = AppColors.textSecondary;
        label = 'Annulée';
        icon = Icons.remove_circle_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab item avec compteur ───────────────────────────────────────────────────
class _TabItem extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _TabItem(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          if (count > 0) ...[
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                    fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── État vide ────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String statut;
  const _EmptyState({required this.statut});

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final String message;
    final String sub;

    switch (statut) {
      case 'pending':
        icon = Icons.pending_actions_rounded;
        message = 'Aucune demande en attente';
        sub = 'Les nouvelles demandes de vos patients\napparaîtront ici en temps réel';
        break;
      case 'accepted':
        icon = Icons.check_circle_outline_rounded;
        message = 'Aucune demande acceptée';
        sub = 'Les demandes que vous avez acceptées\napparaîtront dans cette liste';
        break;
      default:
        icon = Icons.cancel_outlined;
        message = 'Aucune demande refusée';
        sub = 'Aucune de vos demandes\nn\'a été refusée pour le moment';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.primaryUltraLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: AppTextStyles.heading3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              sub,
              style: AppTextStyles.body2.copyWith(
                  color: AppColors.textSecondary, height: 1.6),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
