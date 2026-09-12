import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/appointment_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_provider.dart';
import '../../providers/doctor_provider.dart';
import '../../providers/treating_request_provider.dart';
import '../../widgets/common/appointment_card.dart';
import '../../widgets/common/avatar_widget.dart';
import '../../widgets/common/profile_photo_picker.dart';
import 'doctor_payment_screen.dart';
import 'doctor_messages_tab.dart';
import 'doctor_requests_screen.dart';
import '../shared/pre_call_screen.dart';
import 'edit_profile_screen.dart';
import 'manage_slots_screen.dart';
import 'subscription_screen.dart';
import 'security_screen.dart';
import 'support_screen.dart';
import 'doctor_notifications_screen.dart';
import 'dashboard_modern_tab.dart';
import '../../widgets/common/health_id_card_widget.dart';
import '../../core/routing/route_persistence_service.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  int _currentIndex = 0;

  void _onSelectTab(int index) {
    if (mounted) {
      setState(() => _currentIndex = index);
    }
    RoutePersistenceService.saveTab('doctor', index);
  }

  void _loadDoctorData() {
    final auth = context.read<AuthProvider>();
    final doctor = context.read<DoctorProvider>();
    final trProvider = context.read<TreatingRequestProvider>();
    final doctorId = auth.doctorProfile?.id ?? auth.currentUser?.id ?? '';
    if (doctorId.isNotEmpty) {
      doctor.loadDoctorData(doctorId, trProvider: trProvider);
    }
  }

  void _onTrProviderChanged() {
    if (mounted) _loadDoctorData();
  }

  @override
  void initState() {
    super.initState();
    final savedTab = RoutePersistenceService.getCachedTab('doctor');
    if (savedTab != null && savedTab >= 0 && savedTab <= 4) {
      _currentIndex = savedTab;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadDoctorDemoNotifications();
      _loadDoctorData();
      context.read<TreatingRequestProvider>().addListener(_onTrProviderChanged);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadDoctorData();
  }

  @override
  void dispose() {
    try {
      context.read<TreatingRequestProvider>().removeListener(_onTrProviderChanged);
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_currentIndex != 0) {
          _onSelectTab(0);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: IndexedStack(
          index: _currentIndex,
          children: [
            const DashboardModernTab(), // ✨ Nouveau tableau de bord moderne
            _AppointmentsTab(onBackToDashboard: () => _onSelectTab(0)),
            const DoctorMessagesTab(),
            _PatientsTab(),
            _DoctorProfileTab(),
          ],
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Consumer2<DoctorProvider, TreatingRequestProvider>(
      builder: (_, doctor, trProvider, __) {
        final auth = context.read<AuthProvider>();
        final doctorId = auth.doctorProfile?.id ?? '';
        // Badge live depuis TreatingRequestProvider (demandes pending)
        final pendingTreatingCount = trProvider.pendingForDoctor(doctorId).length;
        return Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, -5))],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(icon: LucideIcons.layout_dashboard, activeIcon: LucideIcons.layout_dashboard, label: 'Tableau', index: 0, current: _currentIndex, onTap: () => _onSelectTab(0)),
                  _NavItem(icon: LucideIcons.calendar_clock, activeIcon: LucideIcons.calendar_check, label: 'Agenda', index: 1, current: _currentIndex, badge: doctor.pendingAppointments.length, onTap: () => _onSelectTab(1)),
                  _NavItemMessages(index: 2, current: _currentIndex, onTap: () => _onSelectTab(2)),
                  _NavItem(icon: LucideIcons.users, activeIcon: LucideIcons.users, label: 'Demandes', index: 3, current: _currentIndex, badge: pendingTreatingCount, onTap: () => _onSelectTab(3)),
                  _NavItem(icon: LucideIcons.stethoscope, activeIcon: LucideIcons.stethoscope, label: 'Profil', index: 4, current: _currentIndex, onTap: () => _onSelectTab(4)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int current;
  final int badge;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.activeIcon, required this.label, required this.index, required this.current, this.badge = 0, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isActive = index == current;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primaryUltraLight : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(isActive ? activeIcon : icon, color: isActive ? AppColors.primary : AppColors.textLight, size: 22),
                    if (badge > 0)
                      Positioned(
                        top: -4, right: -8,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                          child: Text('$badge', style: const TextStyle(fontFamily: 'Poppins', fontSize: 8, color: AppColors.textWhite, fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal, color: isActive ? AppColors.primary : AppColors.textLight)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Nav Item Messages (avec badge animé) ────────────────────────────────────
class _NavItemMessages extends StatelessWidget {
  final int index;
  final int current;
  final VoidCallback onTap;

  const _NavItemMessages({required this.index, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isActive = index == current;
    // Badge total des non-lus (simulé à 3 pour démo)
    const badge = 3;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primaryUltraLight : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      LucideIcons.message_circle,
                      color: isActive ? AppColors.primary : AppColors.textLight,
                      size: 22,
                    ),
                    if (badge > 0)
                      Positioned(
                        top: -4,
                        right: -8,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                          child: const Text('$badge',
                              style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 8,
                                  color: AppColors.textWhite,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Messages',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    color: isActive ? AppColors.primary : AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ===== DASHBOARD TAB =====
class _DashboardTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final doctor = context.watch<DoctorProvider>();
    final stats = doctor.stats;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 56, 24, 28),
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Stack(
                      children: [
                        ProfileAvatar(
                          base64Data: auth.currentUserAvatarBase64,
                          networkUrl: auth.currentUser?.avatarUrl,
                          initials: auth.userInitials,
                          size: 50,
                          showBorder: true,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: GestureDetector(
                            onTap: () {},
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: AppColors.backgroundCard, shape: BoxShape.circle),
                              child: const Icon(Icons.camera_alt_outlined, color: AppColors.primary, size: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Bonjour,', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textWhite.withValues(alpha: 0.8))),
                          Text('Dr. ${auth.currentUser?.lastName ?? ''}', style: const TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textWhite)),
                          Text(auth.doctorProfile?.specialty ?? '', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textWhite.withValues(alpha: 0.75))),
                        ],
                      ),
                    ),
                    Consumer<AppProvider>(
                      builder: (_, app, __) {
                        final unreadCount = app.notifications.where((n) => !n.isRead).length;
                        
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const DoctorNotificationsScreen(),
                              ),
                            );
                          },
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.textWhite.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.notifications_outlined,
                                  color: AppColors.textWhite,
                                  size: 22,
                                ),
                              ),
                              if (unreadCount > 0)
                                Positioned(
                                  top: -4,
                                  right: -4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.error,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppColors.primary,
                                        width: 2,
                                      ),
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    child: Text(
                                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Stats cards
                Row(
                  children: [
                    _MiniStat(label: 'Patients', value: '${stats.totalPatients}', icon: Icons.people_outline, color: AppColors.textWhite),
                    const SizedBox(width: 12),
                    _MiniStat(label: 'Ce mois', value: '${stats.completedThisMonth}', icon: Icons.check_circle_outline, color: AppColors.textWhite),
                    const SizedBox(width: 12),
                    _MiniStat(label: 'Revenus', value: '${(stats.revenue / 1000).toStringAsFixed(0)}k', icon: Icons.monetization_on_outlined, color: AppColors.textWhite),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pending treating requests — source : TreatingRequestProvider
                Consumer2<AuthProvider, TreatingRequestProvider>(
                  builder: (context, auth, trProvider, _) {
                    final doctorId = auth.doctorProfile?.id ?? '';
                    final pendingReqs = trProvider.pendingForDoctor(doctorId);
                    if (pendingReqs.isEmpty) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeader(title: 'Demandes en attente (${pendingReqs.length})'),
                        const SizedBox(height: 12),
                        ...pendingReqs.map((req) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundCard,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                            boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  AvatarWidget(
                                    imageUrl: req.patientAvatar,
                                    initials: req.patientName.isNotEmpty ? req.patientName[0] : 'P',
                                    size: 44,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(req.patientName, style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.w600)),
                                        Text('Demande médecin traitant', style: AppTextStyles.body2.copyWith(color: AppColors.primary)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                                    child: Text('75 FCFA payés', style: AppTextStyles.caption.copyWith(color: AppColors.success, fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(req.message, style: AppTextStyles.body2, maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => trProvider.respondToRequest(
                                        requestId: req.id,
                                        accept: false,
                                        rejectionReason: 'Refusé par le médecin',
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.error,
                                        side: const BorderSide(color: AppColors.error),
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      child: const Text('Refuser', style: AppTextStyles.buttonSmall),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => trProvider.respondToRequest(
                                        requestId: req.id,
                                        accept: true,
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: AppColors.textWhite,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      child: const Text('Accepter', style: AppTextStyles.buttonSmall),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )),
                        const SizedBox(height: 20),
                      ],
                    );
                  },
                ),

                // Today's appointments
                _SectionHeader(title: 'Consultations aujourd\'hui (${doctor.todayAppointments.length})'),
                const SizedBox(height: 12),
                doctor.todayAppointments.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundCard,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Center(
                          child: Text('Aucune consultation aujourd\'hui', style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary)),
                        ),
                      )
                    : Column(
                        children: doctor.todayAppointments.map((apt) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: AppointmentCard(
                            appointment: apt,
                            isDoctor: true,
                            onTap: () {},
                            onJoinCall: apt.isTeleconsultation ? () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => PreCallScreen(
                                doctorName: apt.patientName,
                                doctorSpecialty: 'Patient',
                                isIncoming: true,
                              )),
                            ) : null,
                          ),
                        )).toList(),
                      ),

                const SizedBox(height: 20),
                // Revenue chart placeholder
                const _SectionHeader(title: 'Statistiques ce mois'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Revenus du mois', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textWhite.withValues(alpha: 0.8))),
                            const SizedBox(height: 4),
                            Text('${(stats.revenue / 1000).toStringAsFixed(0)} 000 F CFA', style: const TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textWhite)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.trending_up_rounded, color: AppColors.textWhite, size: 16),
                                const SizedBox(width: 4),
                                Text('+12% vs mois précédent', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textWhite.withValues(alpha: 0.8))),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          _RevStat(label: 'Consultations', value: '${stats.completedThisMonth}'),
                          const SizedBox(height: 10),
                          _RevStat(label: 'Note moy.', value: stats.averageRating.toStringAsFixed(1)),
                        ],
                      ),
                    ],
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

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStat({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.textWhite.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: color.withValues(alpha: 0.8))),
          ],
        ),
      ),
    );
  }
}

class _RevStat extends StatelessWidget {
  final String label;
  final String value;

  const _RevStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.textWhite.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textWhite)),
          Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: AppColors.textWhite.withValues(alpha: 0.8))),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  const _SectionHeader({required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.heading3),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Text('Voir tout', style: AppTextStyles.body2.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }
}

// ===== APPOINTMENTS TAB =====
class _AppointmentsTab extends StatefulWidget {
  final VoidCallback? onBackToDashboard;
  const _AppointmentsTab({this.onBackToDashboard});

  @override
  State<_AppointmentsTab> createState() => _AppointmentsTabState();
}

class _AppointmentsTabState extends State<_AppointmentsTab> with SingleTickerProviderStateMixin {
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
        leading: IconButton(
          icon: const Icon(LucideIcons.arrow_left, color: AppColors.textPrimary, size: 20),
          tooltip: 'Retour au tableau de bord',
          onPressed: () => widget.onBackToDashboard?.call(),
        ),
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
          _AptList(apts: doctor.appointments, isDoctor: true),
          _AptList(apts: doctor.pendingAppointments, isDoctor: true, showAcceptReject: true),
          _AptList(apts: doctor.confirmedAppointments, isDoctor: true),
        ],
      ),
    );
  }
}

class _AptList extends StatelessWidget {
  final List<AppointmentModel> apts;
  final bool isDoctor;
  final bool showAcceptReject;

  const _AptList({required this.apts, this.isDoctor = false, this.showAcceptReject = false});

  @override
  Widget build(BuildContext context) {
    if (apts.isEmpty) {
      return const Center(child: Text('Aucun rendez-vous', style: TextStyle(fontFamily: 'Poppins', color: AppColors.textSecondary)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: apts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => Column(
        children: [
          AppointmentCard(appointment: apts[i], isDoctor: isDoctor, onTap: () {}),
          if (showAcceptReject) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.read<DoctorProvider>().respondToAppointment(apts[i].id, false),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
                    child: const Text('Refuser'),
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

// ===== PATIENTS TAB (Demandes traitant) =====
// Redirige vers DoctorRequestsScreen embarqué dans l'IndexedStack
class _PatientsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Affiche directement le DoctorRequestsScreen (sans Scaffold dupliqué)
    return const DoctorRequestsScreen();
  }
}

// ===== DOSSIERS PATIENTS TAB (ancien) =====
class _PatientRecordsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final doctor = context.watch<DoctorProvider>();
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Dossiers Patients')),
      body: doctor.patientRecords.isEmpty
          ? const Center(child: Text('Aucun dossier patient', style: TextStyle(fontFamily: 'Poppins', color: AppColors.textSecondary)))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: doctor.patientRecords.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final rec = doctor.patientRecords[i];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AvatarWidget(imageUrl: null, initials: rec.patientName.isNotEmpty ? rec.patientName[0] : 'P', size: 44),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(rec.patientName, style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.w600)),
                                Text(rec.typeLabel, style: AppTextStyles.body2.copyWith(color: AppColors.primary)),
                              ],
                            ),
                          ),
                          Text(
                            DateFormat('d MMM', 'fr_FR').format(rec.consultationDate),
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                      if (rec.title.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(rec.title, style: AppTextStyles.subtitle2.copyWith(fontWeight: FontWeight.w600)),
                      ],
                      if (rec.diagnosis != null) ...[
                        const SizedBox(height: 6),
                        Text('Diagnostic: ${rec.diagnosis}', style: AppTextStyles.body2),
                      ],
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: AppColors.textWhite),
        label: const Text('Nouveau dossier', style: TextStyle(fontFamily: 'Poppins', color: AppColors.textWhite, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ===== DOCTOR PROFILE TAB =====
class _DoctorProfileTab extends StatefulWidget {
  @override
  State<_DoctorProfileTab> createState() => _DoctorProfileTabState();
}

class _DoctorProfileTabState extends State<_DoctorProfileTab> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final doctor = context.watch<DoctorProvider>();
    final stats = doctor.stats;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Mon Profil Médecin')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Carte Praticien officielle My Doctor ─────────────────────
            HealthIdCardWidget(
              isDoctor: true,
              lastName: auth.doctorProfile?.lastName ?? auth.currentUser?.lastName,
              firstName: auth.doctorProfile?.firstName ?? auth.currentUser?.firstName,
              idNumber: (auth.doctorProfile?.orderNumber != null && auth.doctorProfile!.orderNumber.isNotEmpty)
                  ? (auth.doctorProfile!.orderNumber.startsWith('ORD-') || auth.doctorProfile!.orderNumber.startsWith('MED-')
                      ? auth.doctorProfile!.orderNumber
                      : 'ORD-${auth.doctorProfile!.orderNumber}')
                  : 'MED-12345',
              birthDate: auth.currentUser?.birthDate ?? '15/04/1985',
              location: (auth.doctorProfile?.specialty != null && auth.doctorProfile!.specialty.isNotEmpty)
                  ? auth.doctorProfile!.specialty
                  : 'CARDIOLOGIE',
              admissionDate: auth.currentUser?.createdAt,
              avatarBase64: auth.currentUserAvatarBase64,
              avatarUrl: auth.currentUser?.avatarUrl,
              onPhotoUpdated: () => auth.refreshCurrentUser(),
            ),
            const SizedBox(height: 16),

            // ── Statistiques praticien ──────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ProfStat(value: stats.averageRating.toStringAsFixed(1), label: 'Note'),
                  Container(height: 30, width: 1, color: Colors.grey.shade200),
                  _ProfStat(value: '${stats.totalPatients}', label: 'Patients'),
                  Container(height: 30, width: 1, color: Colors.grey.shade200),
                  _ProfStat(value: '${stats.totalAppointments}', label: 'RDV'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _MenuItem(
              icon: LucideIcons.stethoscope,
              title: 'Modifier le profil',
              subtitle: 'Photo, bio, disponibilités',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
            ),
            _MenuItem(
              icon: LucideIcons.calendar_check,
              title: 'Gérer les créneaux',
              subtitle: 'Horaires de disponibilité',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageSlotsScreen())),
            ),
            _MenuItem(
              icon: LucideIcons.wallet,
              title: 'Mes revenus & Paiements',
              subtitle: 'Retrait, bulletin de paie, stats',
              color: AppColors.success,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DoctorPaymentScreen())),
            ),
            _MenuItem(
              icon: LucideIcons.credit_card,
              title: 'Abonnement',
              subtitle: '10 000 F CFA/mois',
              color: Colors.orange,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen())),
            ),
            _MenuItem(
              icon: LucideIcons.shield_check,
              title: 'Sécurité',
              subtitle: 'Mot de passe, 2FA',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SecurityScreen())),
            ),
            _MenuItem(
              icon: LucideIcons.circle_question_mark,
              title: 'Support',
              subtitle: 'Aide et contact',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen())),
            ),
            _MenuItem(
              icon: LucideIcons.shield,
              title: 'Console Administrateur',
              subtitle: 'Supervision & gestion du système',
              color: AppColors.brandNavy,
              onTap: () => Navigator.pushNamed(context, '/admin'),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await context.read<AuthProvider>().logout();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(context, '/welcome', (r) => false);
                  }
                },
                icon: const Icon(LucideIcons.log_out, color: AppColors.error, size: 16),
                label: const Text('Se déconnecter', style: TextStyle(fontFamily: 'Poppins', color: AppColors.error, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfStat extends StatelessWidget {
  final String value;
  final String label;
  const _ProfStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? color;
  final VoidCallback? onTap;
  const _MenuItem({required this.icon, required this.title, required this.subtitle, this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: c, size: 18),
        ),
        title: Text(title, style: AppTextStyles.subtitle2.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        subtitle: Text(subtitle, style: AppTextStyles.caption),
        trailing: const Icon(LucideIcons.chevron_right, size: 16, color: AppColors.textLight),
        onTap: onTap ?? () {},
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
