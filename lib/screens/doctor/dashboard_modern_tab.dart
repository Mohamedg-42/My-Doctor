import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../core/theme/app_theme.dart';
import '../../models/appointment_model.dart';
import '../../models/user_model.dart';
import '../../services/database_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_provider.dart';
import '../../providers/doctor_provider.dart';
import '../../providers/treating_request_provider.dart';
import '../../providers/message_provider.dart';
import '../../widgets/common/avatar_widget.dart';
import 'doctor_requests_screen.dart';
import 'doctor_payment_screen.dart';
import 'doctor_notifications_screen.dart';
import 'edit_profile_screen.dart';
import '../../widgets/doctor/set_patient_capacity_dialog.dart';
import 'doctor_appointments_tab.dart';
import '../patient/medical_record_screen.dart';

/// Tableau de bord moderne pour médecin
/// Design inspiré d'applications médicales/assurance modernes
/// Avec cartes arrondies, couleurs pastel et dégradés doux
class DashboardModernTab extends StatelessWidget {
  final VoidCallback? onNavigateToAppointments;

  const DashboardModernTab({super.key, this.onNavigateToAppointments});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header avec avatar et salutation
              _buildHeader(context),
              const SizedBox(height: 20),

              // Bannières de statut et complétion du profil isolées pour éviter les rebuilds globaux
              const _DoctorProfileStatusBanners(),
              
              // Bannière promotionnelle / Info importante
              _buildPromoBanner(context),
              const SizedBox(height: 28),
              
              // Section "Actions Rapides"
              _buildSectionTitle('Actions Rapides'),
              const SizedBox(height: 16),
              _buildQuickActions(context),
              const SizedBox(height: 28),
              
              // Section "Statistiques Aujourd'hui"
              _buildSectionTitle('Statistiques Aujourd\'hui'),
              const SizedBox(height: 16),
              _buildTodayStats(context),
              const SizedBox(height: 28),
              
              // Section "Vue d'ensemble"
              _buildSectionTitle('Vue d\'ensemble'),
              const SizedBox(height: 16),
              _buildOverviewCards(context),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Header avec avatar, salutation et notifications
  Widget _buildHeader(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final doctor = auth.doctorProfile;
        final userName = doctor?.firstName ?? 'Docteur';
        
        return Row(
          children: [
            // Avatar circulaire
            AvatarWidget(
              imageUrl: doctor?.avatarUrl,
              initials: doctor?.firstName.isNotEmpty == true 
                ? doctor!.firstName[0].toUpperCase()
                : 'D',
              size: 48,
            ),
            const SizedBox(width: 12),
            
            // Salutation
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bienvenue !',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Dr. $userName',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            
            // Bouton notifications
            _buildNotificationButton(context),
          ],
        );
      },
    );
  }

  /// Bouton notifications avec badge rouge
  Widget _buildNotificationButton(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, app, _) {
        final unreadCount = app.notifications.where((n) => !n.isRead).length;
        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.borderSubtle,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DoctorNotificationsScreen()),
                );
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Center(
                    child: Icon(
                      LucideIcons.bell,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppColors.logoCrossRed, // Rouge vif
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Center(
                          child: Text(
                            unreadCount > 9 ? '9+' : '$unreadCount',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Bannière promotionnelle avec dégradé
  Widget _buildPromoBanner(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 140),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.logoBlue, AppColors.logoTurquoise],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.logoBlue.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            // Action de la bannière
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Gérez vos consultations',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Accédez rapidement à vos rendez-vous et patients',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Voir tout',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.logoBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Icon(
                      LucideIcons.stethoscope,
                      size: 38,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Titre de section
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  /// Actions rapides (3 cartes)
  Widget _buildQuickActions(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: LucideIcons.calendar_check,
                label: 'Rendez-vous',
                gradient: const LinearGradient(
                  colors: [AppColors.logoBlue, Color(0xFF0056A3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onTap: () {
                  if (onNavigateToAppointments != null) {
                    onNavigateToAppointments!();
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DoctorAppointmentsTab(
                          onBackToDashboard: () => Navigator.pop(context),
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Consumer<TreatingRequestProvider>(
                builder: (context, trProvider, _) {
                  final auth = context.read<AuthProvider>();
                  final doctorId = auth.doctorProfile?.id ?? '';
                  final pendingCount = trProvider.pendingForDoctor(doctorId).length;
                  
                  return _QuickActionCard(
                    icon: LucideIcons.hospital,
                    label: 'Demandes',
                    badge: pendingCount,
                    gradient: const LinearGradient(
                      colors: [AppColors.logoTurquoise, Color(0xFF00897B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const DoctorRequestsScreen()),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: LucideIcons.clipboard_list,
                label: 'Dossiers Médicaux',
                gradient: const LinearGradient(
                  colors: [Color(0xFF0070D2), Color(0xFF00A896)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MedicalRecordScreen(isDoctorView: true),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: LucideIcons.wallet,
                label: 'Paiements',
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF334155)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DoctorPaymentScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Statistiques du jour
  Widget _buildTodayStats(BuildContext context) {
    return Consumer<DoctorProvider>(
      builder: (context, doctorProvider, _) {
        final todayAppointments = doctorProvider.todayAppointments;
        final confirmedToday = todayAppointments.where((a) => a.status == AppointmentStatus.confirmed).length;
        
        return Row(
          children: [
            Expanded(
              child: _StatCard(
                value: '${todayAppointments.length}',
                label: 'Rendez-vous',
                icon: LucideIcons.calendar_days,
                color: AppColors.logoBlue,
                onTap: () {
                  if (onNavigateToAppointments != null) {
                    onNavigateToAppointments!();
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DoctorAppointmentsTab(
                          onBackToDashboard: () => Navigator.pop(context),
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                value: '$confirmedToday',
                label: 'Confirmés',
                icon: LucideIcons.circle_check,
                color: AppColors.logoTurquoise,
                onTap: () {
                  if (onNavigateToAppointments != null) {
                    onNavigateToAppointments!();
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DoctorAppointmentsTab(
                          onBackToDashboard: () => Navigator.pop(context),
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        );
      },
    );
  }

  /// Cartes d'aperçu
  Widget _buildOverviewCards(BuildContext context) {
    return Consumer2<DoctorProvider, MessageProvider>(
      builder: (context, doctorProvider, msgProvider, _) {
        final auth = context.read<AuthProvider>();
        final doctorId = auth.doctorProfile?.id ?? '';
        final stats = doctorProvider.stats;
        final unreadMessages = msgProvider.totalUnreadForDoctor(doctorId);
        final currentCap = auth.currentUser?.patientCapacity ?? 50;
        
        return Column(
          children: [
            _buildOverviewCard(
              title: 'Capacité Patientèle',
              value: '${stats.totalPatients} / $currentCap',
              subtitle: stats.totalPatients >= currentCap 
                  ? 'Plafond atteint • Taper pour modifier' 
                  : 'Patients suivis • Taper pour configurer',
              icon: LucideIcons.users,
              onTap: () async {
                final docId = auth.currentUser?.id;
                if (docId != null) {
                  final updated = await SetPatientCapacityDialog.show(
                    context,
                    doctorId: docId,
                    currentCapacity: currentCap,
                  );
                  if (updated != null) {
                    await auth.refreshCurrentUser();
                  }
                }
              },
              gradient: const LinearGradient(
                colors: [AppColors.logoBlue, Color(0xFF0056A3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            const SizedBox(height: 12),
            _buildOverviewCard(
              title: 'Messages non lus',
              value: '$unreadMessages',
              subtitle: 'Nouveaux messages',
              icon: LucideIcons.message_square,
              gradient: const LinearGradient(
                colors: [AppColors.logoTurquoise, Color(0xFF00897B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            const SizedBox(height: 12),
            _buildOverviewCard(
              title: 'Revenus du mois',
              value: '${NumberFormat('#,###', 'fr_FR').format(stats.revenue)} F',
              subtitle: 'Ce mois-ci',
              icon: LucideIcons.trending_up,
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF334155)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Carte d'aperçu avec dégradé
  Widget _buildOverviewCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Icon(
                icon,
                size: 26,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  ),
);
  }
}

/// Widget pour carte d'action rapide
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int badge;
  final Gradient gradient;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    this.badge = 0,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Icon(
                          icon,
                          size: 22,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (badge > 0)
                      Positioned(
                        right: -6,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Center(
                            child: Text(
                              '$badge',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
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

/// Widget pour carte de statistique
class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 17,
                    color: color,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    ),
  ),
);
  }
}

// ─── Bannière de complétion du profil praticien ───────────────────────────────
class _DoctorProfileCompletionBanner extends StatelessWidget {
  final int completionPercentage;
  final VoidCallback onTap;

  const _DoctorProfileCompletionBanner({
    required this.completionPercentage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0070D2).withValues(alpha: 0.10),
            const Color(0xFF00A896).withValues(alpha: 0.18),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF0070D2).withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0070D2).withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(LucideIcons.stethoscope, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Complétez votre profil praticien',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Profil renseigné à $completionPercentage%',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$completionPercentage%',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Barre de progression
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: completionPercentage / 100.0,
                    backgroundColor: Colors.black.withValues(alpha: 0.06),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Renseignez votre biographie, spécialité, ville et tarifs de consultation pour renforcer votre visibilité auprès des patients.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Compléter mes infos',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(LucideIcons.arrow_right, size: 14, color: Colors.white),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DoctorAdminPendingBanner extends StatelessWidget {
  final VoidCallback onSimulateAdminApproval;

  const _DoctorAdminPendingBanner({
    required this.onSimulateAdminApproval,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    LucideIcons.shield_alert,
                    color: Color(0xFFD97706),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Validation administrative requise',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Profil invisible chez les patients',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.clock_3, size: 12, color: Color(0xFFD97706)),
                      SizedBox(width: 4),
                      Text(
                        'En attente',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Votre compte praticien a été créé avec succès. Complétez vos informations (spécialité, n° d\'ordre, bio) pour que nos équipes valident votre statut praticien.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onSimulateAdminApproval,
                icon: const Icon(LucideIcons.badge_check, size: 16, color: Colors.white),
                label: const Text(
                  'Valider par l\'admin (Mode Démo)',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoctorAdminActiveBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: const Row(
        children: [
          Icon(LucideIcons.badge_check, color: Color(0xFF059669), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profil Praticien Validé & Actif',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF065F46),
                  ),
                ),
                Text(
                  'Vous êtes visible par les patients dans l\'annuaire médical',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: Color(0xFF047857),
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

class _DoctorProfileStatusBanners extends StatelessWidget {
  const _DoctorProfileStatusBanners();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final doctor = auth.doctorProfile;
        final user = auth.currentUser;

        int completionPoints = 0;
        if (doctor != null) {
          if (doctor.lastName.trim().isNotEmpty) completionPoints += 20;
          if (doctor.firstName.trim().isNotEmpty) completionPoints += 20;
          if (doctor.specialty.trim().isNotEmpty) completionPoints += 20;
          if (doctor.orderNumber.trim().length == 5) completionPoints += 15;
          if (doctor.phone.trim().isNotEmpty) completionPoints += 10;
          if (doctor.bio != null && doctor.bio!.trim().length > 10) completionPoints += 15;
        } else if (user != null) {
          if (user.lastName.trim().isNotEmpty) completionPoints += 20;
          if (user.firstName.trim().isNotEmpty) completionPoints += 20;
          if (user.phone.trim().isNotEmpty) completionPoints += 20;
        }
        final bool isProfileIncomplete = completionPoints < 100;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user?.status == AccountStatus.pending) ...[
              _DoctorAdminPendingBanner(
                onSimulateAdminApproval: () async {
                  if (user != null) {
                    await DatabaseService().updateUserStatus(user.id, 'active');
                    await auth.refreshCurrentUser();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Row(
                            children: [
                              Icon(LucideIcons.badge_check, color: Colors.white, size: 20),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text('✅ Compte validé par l\'administration ! Vous êtes désormais visible par les patients.'),
                              ),
                            ],
                          ),
                          backgroundColor: const Color(0xFF059669),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 16),
            ] else if (user?.status == AccountStatus.active) ...[
              _DoctorAdminActiveBadge(),
              const SizedBox(height: 16),
            ],
            if (isProfileIncomplete) ...[
              _DoctorProfileCompletionBanner(
                completionPercentage: completionPoints,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ],
        );
      },
    );
  }
}
