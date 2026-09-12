// ════════════════════════════════════════════════════════════
//  patient_request_screen.dart
//  MédiLink Care — Mes demandes (côté PATIENT)
//  • Liste toutes les demandes envoyées (pending / accepted / refused)
//  • Notifications in-app temps réel via TreatingRequestProvider
//  • Accès aux canaux débloqués depuis cette vue
//  • En cas de refus : médecin réapparaît automatiquement dans la liste
// ════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/treating_request_provider.dart';
import '../../models/treating_doctor_request_model.dart';
import '../../models/doctor_model.dart';
import '../../widgets/common/avatar_widget.dart';
import 'treating_doctor_chat_screen.dart';
import '../shared/pre_call_screen.dart';

class PatientRequestScreen extends StatefulWidget {
  const PatientRequestScreen({super.key});

  @override
  State<PatientRequestScreen> createState() => _PatientRequestScreenState();
}

class _PatientRequestScreenState extends State<PatientRequestScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    // Marquer les notifications comme lues à l'ouverture
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final patientId = auth.currentUser?.id ?? '';
      context.read<TreatingRequestProvider>().markAllReadForPatient(patientId);
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
        final patientId = auth.currentUser?.id ?? '';
        final all = trProvider.requestsForPatient(patientId);

        final pending  = all.where((r) => r.status == TreatingDoctorStatus.pending).toList();
        final accepted = all.where((r) => r.status == TreatingDoctorStatus.accepted).toList();
        final refused  = all.where((r) => r.status == TreatingDoctorStatus.rejected).toList();

        return Scaffold(
          backgroundColor: AppColors.backgroundLight,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context, trProvider, patientId, pending.length),
                _buildTabs(pending.length, accepted.length, refused.length),
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      _RequestList(
                        requests: pending,
                        statut: 'pending',
                        auth: auth,
                        trProvider: trProvider,
                        onOpenChat: (req) => _openChat(context, req, auth),
                        onOpenCall: (req) => _openCall(context, req),
                        onOpenVideo: (req) => _openVideo(context, req),
                      ),
                      _RequestList(
                        requests: accepted,
                        statut: 'accepted',
                        auth: auth,
                        trProvider: trProvider,
                        onOpenChat: (req) => _openChat(context, req, auth),
                        onOpenCall: (req) => _openCall(context, req),
                        onOpenVideo: (req) => _openVideo(context, req),
                      ),
                      _RequestList(
                        requests: refused,
                        statut: 'refused',
                        auth: auth,
                        trProvider: trProvider,
                        onOpenChat: (req) => _openChat(context, req, auth),
                        onOpenCall: (req) => _openCall(context, req),
                        onOpenVideo: (req) => _openVideo(context, req),
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

  // ── Header ────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, TreatingRequestProvider trProvider,
      String patientId, int pendingCount) {
    final unread = trProvider.unreadCountForPatient(patientId);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded,
                color: AppColors.textWhite, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mes demandes',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textWhite,
                  ),
                ),
                Text(
                  'Médecin traitant / de famille',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: AppColors.textWhite.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          // Badge notifications
          if (unread > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.notifications_rounded,
                      color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '$unread',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
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

  // ── Tabs ──────────────────────────────────────────────────
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
            fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600),
        tabs: [
          _TabItem(label: 'En attente', count: pending),
          _TabItem(label: 'Acceptées', count: accepted),
          _TabItem(label: 'Refusées', count: refused),
        ],
      ),
    );
  }

  // ── Navigation vers le chat Firestore temps réel ───────────────────────────────
  void _openChat(BuildContext ctx, TreatingDoctorRequest req, AuthProvider auth) {
    // Créer un objet DoctorModel temporaire à partir de la demande
    final doctor = DoctorModel(
      id: req.doctorId,
      userId: req.doctorId,
      firstName: req.doctorName.split(' ').first,
      lastName: req.doctorName.split(' ').length > 1 
          ? req.doctorName.split(' ').sublist(1).join(' ')
          : '',
      specialty: req.doctorSpecialty,
      email: '',
      phone: '',
      orderNumber: '00000',
      experienceYears: 0,
      consultationPrice: 0,
      rating: 0,
      reviewCount: 0,
      bio: '',
      createdAt: DateTime.now(),
    );
    
    Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (_) => TreatingDoctorChatScreen(doctor: doctor),
      ),
    );
  }

  void _openCall(BuildContext ctx, TreatingDoctorRequest req) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.phone_in_talk_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Connexion avec ${req.doctorName}…'),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openVideo(BuildContext ctx, TreatingDoctorRequest req) {
    Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (_) => PreCallScreen(
          doctorName: req.doctorName,
          doctorSpecialty: req.doctorSpecialty,
          isIncoming: false,
        ),
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
  final AuthProvider auth;
  final TreatingRequestProvider trProvider;
  final Function(TreatingDoctorRequest) onOpenChat;
  final Function(TreatingDoctorRequest) onOpenCall;
  final Function(TreatingDoctorRequest) onOpenVideo;

  const _RequestList({
    required this.requests,
    required this.statut,
    required this.auth,
    required this.trProvider,
    required this.onOpenChat,
    required this.onOpenCall,
    required this.onOpenVideo,
  });

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return _EmptyState(statut: statut);
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      itemCount: requests.length,
      itemBuilder: (_, i) => _RequestCard(
        request: requests[i],
        onOpenChat: onOpenChat,
        onOpenCall: onOpenCall,
        onOpenVideo: onOpenVideo,
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  CARTE DEMANDE
// ════════════════════════════════════════════════════════════
class _RequestCard extends StatelessWidget {
  final TreatingDoctorRequest request;
  final Function(TreatingDoctorRequest) onOpenChat;
  final Function(TreatingDoctorRequest) onOpenCall;
  final Function(TreatingDoctorRequest) onOpenVideo;

  const _RequestCard({
    required this.request,
    required this.onOpenChat,
    required this.onOpenCall,
    required this.onOpenVideo,
  });

  Color get _borderColor {
    switch (request.status) {
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
    final isPending  = request.status == TreatingDoctorStatus.pending;
    final isAccepted = request.status == TreatingDoctorStatus.accepted;
    final isRefused  = request.status == TreatingDoctorStatus.rejected;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _borderColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── En-tête médecin ──────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                DoctorAvatar(
                  name: request.doctorName,
                  size: 52,
                  isOnline: isAccepted,
                  isVerified: isAccepted,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.doctorName,
                        style: AppTextStyles.subtitle1
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        request.doctorSpecialty,
                        style: AppTextStyles.body2
                            .copyWith(color: AppColors.primary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Envoyée le ${DateFormat('d MMM yyyy', 'fr_FR').format(request.createdAt)}',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                _StatusBadge(request.status),
              ],
            ),
          ),

          // ── Montant payé ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: AppColors.success, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        '${request.amount.toInt()} FCFA payés',
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (request.paymentMethod != null)
                  Text(
                    request.paymentMethod!.replaceAll('_', ' ').toUpperCase(),
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),

          // ── Message envoyé ───────────────────────────────
          if (request.message.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '"${request.message}"',
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

          // ── Raison du refus ──────────────────────────────
          if (isRefused && request.rejectionReason != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: AppColors.error, size: 15),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        request.rejectionReason!,
                        style: AppTextStyles.body2
                            .copyWith(color: AppColors.error, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Boutons d'action ─────────────────────────────
          if (isAccepted) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Chat
                  Expanded(
                    child: _ActionBtn(
                      icon: Icons.chat_bubble_rounded,
                      label: 'Message',
                      color: AppColors.primary,
                      onTap: () => onOpenChat(request),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Appel audio
                  Expanded(
                    child: _ActionBtn(
                      icon: Icons.phone_rounded,
                      label: 'Appel',
                      color: AppColors.success,
                      onTap: () => onOpenCall(request),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Appel vidéo
                  Expanded(
                    child: _ActionBtn(
                      icon: Icons.videocam_rounded,
                      label: 'Vidéo',
                      color: AppColors.accent,
                      onTap: () => onOpenVideo(request),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── En attente ───────────────────────────────────
          if (isPending)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.warning),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'En attente de réponse du médecin…',
                      style: AppTextStyles.body2.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),

          // ── Refus : message d'info ───────────────────────
          if (isRefused)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primaryUltraLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.refresh_rounded,
                        color: AppColors.primary, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ce médecin est de nouveau disponible dans votre liste.',
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Bouton d'action (chat / appel / vidéo) ──────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
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
  const _TabItem({required this.label, required this.count});

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
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
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
        icon = Icons.hourglass_empty_rounded;
        message = 'Aucune demande en attente';
        sub = 'Trouvez un médecin et envoyez\nvotre première demande';
        break;
      case 'accepted':
        icon = Icons.check_circle_outline_rounded;
        message = 'Aucune demande acceptée';
        sub = 'Quand un médecin acceptera votre\ndemande, elle apparaîtra ici';
        break;
      default:
        icon = Icons.cancel_outlined;
        message = 'Aucune demande refusée';
        sub = 'Aucune de vos demandes n\'a\nété refusée pour le moment';
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
              style: AppTextStyles.body2
                  .copyWith(color: AppColors.textSecondary, height: 1.6),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
