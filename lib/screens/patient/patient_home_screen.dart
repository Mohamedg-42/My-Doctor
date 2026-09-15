import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/patient_provider.dart';
import '../../providers/app_provider.dart';
import '../../providers/treating_request_provider.dart';
import '../../models/user_model.dart';
import '../../providers/message_provider.dart';
import '../../models/appointment_model.dart';
import '../../models/treating_doctor_request_model.dart';
import '../../widgets/common/profile_photo_picker.dart';
import '../../widgets/patient/doctor_card.dart';
import 'doctor_search_screen.dart';
import 'doctor_profile_screen.dart';
import 'appointments_screen.dart';
import 'cmu_screen.dart';
import 'notifications_screen.dart';
// import 'chat_screen.dart'; // Deprecated - using treating_doctor_chat_screen.dart with Firestore
import 'patient_request_screen.dart';
import 'medical_record_screen.dart';
import 'vaccination_card_screen.dart';
import 'notifications_settings_screen.dart';
import 'security_privacy_screen.dart';
import 'appearance_settings_screen.dart';
import 'help_faq_screen.dart';
import 'contact_support_screen.dart';
import 'edit_profile_screen.dart';
import '../shared/shared_chat_screen.dart';
import '../shared/pre_call_screen.dart';
import '../../widgets/common/health_id_card_widget.dart';
import '../../widgets/common/appointment_card.dart';

import '../../core/routing/route_persistence_service.dart';
import '../../features/pharmacie/presentation/screens/pharmacie_garde_map_screen.dart';
import '../../features/pharmacie/data/services/pharmacie_location_service.dart';
import '../../features/pharmacie/data/models/pharmacie_model.dart';
import 'in_app_itinerary_screen.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [];

  void _onSelectTab(int index) {
    if (mounted) {
      setState(() => _currentIndex = index);
    }
    RoutePersistenceService.saveTab('patient', index);
  }

  void _loadDoctors() {
    final auth = context.read<AuthProvider>();
    final patient = context.read<PatientProvider>();
    final trProvider = context.read<TreatingRequestProvider>();
    final patientId = auth.currentUser?.id ?? '';

    // 📡 Plus besoin de rafraîchir manuellement - le Stream le fait automatiquement
    // auth.refreshDoctors(); ← SUPPRIMÉ - géré par Stream

    // Masquer les médecins avec demande pending ou accepted
    final excluded = trProvider.allRequests
        .where((r) =>
            r.patientId == patientId &&
            (r.status.name == 'pending' || r.status.name == 'accepted'))
        .map((r) => r.doctorId)
        .toSet();

    // Charger les médecins réels depuis la base de données
    // La liste auth.mockDoctors est automatiquement mise à jour via Stream
    patient.setDoctors(auth.mockDoctors, excludedDoctorIds: excluded);

    // Charger les rendez-vous réels du patient
    if (patientId.isNotEmpty) {
      patient.loadAppointments(patientId);
    }
  }

  @override
  void initState() {
    super.initState();
    final savedTab = RoutePersistenceService.getCachedTab('patient');
    if (savedTab != null && savedTab >= 0 && savedTab <= 4) {
      _currentIndex = savedTab;
    }

    // Chargement initial dès l'ouverture de l'écran
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDoctors();
      // Écouter TreatingRequestProvider : rechargement auto quand statut change
      // (ex. médecin refusé → réapparaît dans la liste)
      context.read<TreatingRequestProvider>().addListener(_onTrProviderChanged);
    });
  }

  void _onTrProviderChanged() {
    // Rechargement de la liste des médecins à chaque changement de demande
    // Cela garantit la réapparition du médecin en cas de refus
    if (mounted) _loadDoctors();
  }

  @override
  void dispose() {
    // Retirer l'écouteur pour éviter les fuites mémoire
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
            _HomeTab(
              onSeeAllDoctors: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const DoctorSearchScreen())),
              onSeeAllAppointments: () => _onSelectTab(1),
            ),
            AppointmentsScreen(onBackToHome: () => _onSelectTab(0)),
            const CmuScreen(),
            _MessagesTab(),
            _ProfileTab(),
          ],
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Consumer2<PatientProvider, TreatingRequestProvider>(
      builder: (context, patient, trProvider, _) {
        final auth = context.read<AuthProvider>();
        final patientId = auth.currentUser?.id ?? '';
        final notifCount = trProvider.unreadCountForPatient(patientId);

        return Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Badge sur Accueil = notifications demandes traitant
                  _NavItemBadge(
                      icon: LucideIcons.house,
                      activeIcon: LucideIcons.house,
                      label: 'Accueil',
                      index: 0,
                      current: _currentIndex,
                      badge: notifCount,
                      onTap: () {
                        _onSelectTab(0);
                        trProvider.markAllReadForPatient(patientId);
                      }),
                  _NavItem(
                      icon: LucideIcons.calendar,
                      activeIcon: LucideIcons.calendar_check,
                      label: 'RDV',
                      index: 1,
                      current: _currentIndex,
                      onTap: () => _onSelectTab(1)),
                  _NavItem(
                      icon: LucideIcons.id_card,
                      activeIcon: LucideIcons.id_card,
                      label: 'Carte CMU',
                      index: 2,
                      current: _currentIndex,
                      onTap: () => _onSelectTab(2)),
                  _NavItemBadge(
                      icon: LucideIcons.message_circle,
                      activeIcon: LucideIcons.message_circle,
                      label: 'Messages',
                      index: 3,
                      current: _currentIndex,
                      badge: 0,
                      onTap: () => _onSelectTab(3)),
                  _NavItem(
                      icon: LucideIcons.user,
                      activeIcon: LucideIcons.user,
                      label: 'Profil',
                      index: 4,
                      current: _currentIndex,
                      onTap: () => _onSelectTab(4)),
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
  final VoidCallback onTap;

  const _NavItem(
      {required this.icon,
      required this.activeIcon,
      required this.label,
      required this.index,
      required this.current,
      required this.onTap});

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
              color:
                  isActive ? AppColors.primaryUltraLight : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(isActive ? activeIcon : icon,
                    color: isActive ? AppColors.primary : AppColors.textLight,
                    size: 22),
                const SizedBox(height: 3),
                Text(label,
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.normal,
                        color: isActive
                            ? AppColors.primary
                            : AppColors.textLight)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemBadge extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int current;
  final int badge;
  final VoidCallback onTap;

  const _NavItemBadge(
      {required this.icon,
      required this.activeIcon,
      required this.label,
      required this.index,
      required this.current,
      required this.badge,
      required this.onTap});

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
              color:
                  isActive ? AppColors.primaryUltraLight : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(isActive ? activeIcon : icon,
                        color:
                            isActive ? AppColors.primary : AppColors.textLight,
                        size: 22),
                    if (badge > 0)
                      Positioned(
                        top: -4,
                        right: -6,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                              color: AppColors.error, shape: BoxShape.circle),
                          child: Text('$badge',
                              style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 8,
                                  color: AppColors.textWhite,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(label,
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.normal,
                        color: isActive
                            ? AppColors.primary
                            : AppColors.textLight)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── CMU Nav Item ────────────────────────────────────────────────────────────
// ─── Bannière de complétion du profil patient ───────────────────────────────
class _ProfileCompletionBanner extends StatelessWidget {
  final int completionPercentage;
  final VoidCallback onTap;

  const _ProfileCompletionBanner({
    required this.completionPercentage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.10),
            AppColors.primaryLight.withValues(alpha: 0.25),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
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
                      child: const Icon(LucideIcons.user_pen,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Complétez votre profil',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Profil complété à $completionPercentage%',
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
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
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Renseignez vos nom, prénom et date de naissance pour faciliter vos consultations, vos ordonnances et votre carte CMU.',
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
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
                          Icon(LucideIcons.arrow_right,
                              size: 14, color: Colors.white),
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

// ===== HOME TAB =====
class _HomeTab extends StatelessWidget {
  final VoidCallback onSeeAllDoctors;
  final VoidCallback onSeeAllAppointments;
  const _HomeTab(
      {required this.onSeeAllDoctors, required this.onSeeAllAppointments});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final patient = context.watch<PatientProvider>();
    final user = auth.currentUser;

    // Calcul de complétion du profil
    int completionPoints = 0;
    if (user != null) {
      if (user.lastName.trim().isNotEmpty) completionPoints += 25;
      if (user.firstName.trim().isNotEmpty && user.firstName != 'Patient')
        completionPoints += 25;
      if (user.phone.trim().isNotEmpty) completionPoints += 15;
      if (user.gender != null && user.gender!.isNotEmpty)
        completionPoints += 15;
      if (user.birthDate != null) completionPoints += 10;
      if (user.city != null && user.city!.trim().isNotEmpty)
        completionPoints += 10;
    }
    final bool isProfileIncomplete = completionPoints < 100;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 56, 24, 28),
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    ProfileAvatar(
                      base64Data: auth.currentUser?.avatarBase64,
                      networkUrl: auth.currentUser?.avatarUrl,
                      initials: auth.userInitials,
                      size: 48,
                      showBorder: true,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bonjour,',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              color: AppColors.textWhite.withValues(alpha: 0.8),
                            ),
                          ),
                          Text(
                            auth.userName,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textWhite,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Consumer2<AppProvider, TreatingRequestProvider>(
                      builder: (ctx, app, trProvider, __) {
                        final patientId = auth.currentUser?.id ?? '';
                        // Total = notifs AppProvider + notifs demandes traitant
                        final total = app.unreadCount +
                            trProvider.unreadCountForPatient(patientId);
                        final trUnread =
                            trProvider.unreadCountForPatient(patientId);
                        return GestureDetector(
                          onTap: () {
                            trProvider.markAllReadForPatient(patientId);
                            // Si notifications de demande traitant → ouvrir PatientRequestScreen
                            if (trUnread > 0) {
                              Navigator.push(
                                  ctx,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const PatientRequestScreen()));
                            } else {
                              Navigator.push(
                                  ctx,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const NotificationsScreen()));
                            }
                          },
                          child: Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.textWhite
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(LucideIcons.bell,
                                    color: AppColors.textWhite, size: 22),
                              ),
                              if (total > 0)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Container(
                                    width: 18,
                                    height: 18,
                                    decoration: const BoxDecoration(
                                        color: AppColors.error,
                                        shape: BoxShape.circle),
                                    child: Center(
                                      child: Text(
                                        '${total > 9 ? '9+' : total}',
                                        style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 9,
                                            color: AppColors.textWhite,
                                            fontWeight: FontWeight.bold),
                                      ),
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
                // Search bar
                GestureDetector(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const DoctorSearchScreen())),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.textWhite,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.search,
                            color: AppColors.textSecondary, size: 20),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Chercher un médecin, spécialité...',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.body2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryUltraLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(LucideIcons.sliders_horizontal,
                              color: AppColors.primary, size: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bannière de complétion de profil si non complet
                if (isProfileIncomplete)
                  _ProfileCompletionBanner(
                    completionPercentage: completionPoints,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const EditProfileScreen()),
                      );
                    },
                  ),

                // Upcoming appointment
                if (patient.upcomingAppointments.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'Prochain RDV',
                    onSeeAll: onSeeAllAppointments,
                    badge: patient.upcomingAppointments.length,
                  ),
                  const SizedBox(height: 12),
                  AppointmentCard(
                    appointment: patient.upcomingAppointments.first,
                    isPriority: true,
                    onTap: onSeeAllAppointments,
                  ),
                  const SizedBox(height: 20),
                ] else ...[
                  _SectionHeader(
                      title: 'Prochain RDV', onSeeAll: onSeeAllAppointments),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: onSeeAllDoctors,
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.borderSubtle),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.brandNavy.withValues(alpha: 0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: AppColors.selectedBg,
                                borderRadius: BorderRadius.circular(12)),
                            child: const Icon(LucideIcons.calendar,
                                color: AppColors.brandBlue, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Aucun RDV à venir',
                                    style: AppTextStyles.label
                                        .copyWith(fontWeight: FontWeight.w600)),
                                Text('Prenez rendez-vous avec un médecin',
                                    style: AppTextStyles.caption),
                              ],
                            ),
                          ),
                          const Icon(LucideIcons.chevron_right,
                              size: 18, color: AppColors.brandBlue),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Quick Actions
                const _SectionHeader(title: 'Services rapides'),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _QuickAction(
                        icon: LucideIcons.calendar_plus,
                        label: 'Prendre\nRDV',
                        color: AppColors.brandBlue,
                        onTap: onSeeAllDoctors),
                    _QuickAction(
                        icon: LucideIcons.video,
                        label: 'Télé-\nconsult',
                        color: AppColors.brandTurquoise,
                        onTap: onSeeAllDoctors),
                    _QuickAction(
                        icon: LucideIcons.phone_call,
                        label: 'Urgences\nSAMU',
                        color: AppColors.brandCoral,
                        onTap: () => _showEmergency(context)),
                  ],
                ),
                const SizedBox(height: 12),
                // Accès direct Carte CMU et Abonnements Santé
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showPharmaciesDeGarde(context),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF059669), Color(0xFF047857)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF059669)
                                    .withValues(alpha: 0.28),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Icon(LucideIcons.pill,
                                      color: Colors.white, size: 20),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      '24h/24',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Pharmacie de garde',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const Text(
                                'Urgences & Nuit',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 10,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pushNamed(
                            context, '/patient/subscription'),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFEA580C), Color(0xFFC2410C)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFEA580C)
                                    .withValues(alpha: 0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Icon(LucideIcons.sparkles,
                                      color: Colors.white, size: 20),
                                  Icon(Icons.arrow_forward_rounded,
                                      color: Colors.white70, size: 16),
                                ],
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Mon abonnement',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Formules & Famille',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 10,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Bouton accès rapide Mes demandes de médecin traitant
                Consumer2<AuthProvider, TreatingRequestProvider>(
                  builder: (ctx, authCtx, trProvider, _) {
                    final patientId = authCtx.currentUser?.id ?? '';
                    final all = trProvider.requestsForPatient(patientId);
                    final pendingCount = all
                        .where((r) => r.status == TreatingDoctorStatus.pending)
                        .length;
                    final acceptedCount = all
                        .where((r) => r.status == TreatingDoctorStatus.accepted)
                        .length;
                    if (all.isEmpty) return const SizedBox.shrink();
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        ctx,
                        MaterialPageRoute(
                            builder: (_) => const PatientRequestScreen()),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.2)),
                          boxShadow: [
                            BoxShadow(
                                color:
                                    AppColors.primary.withValues(alpha: 0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 4))
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primaryUltraLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(LucideIcons.stethoscope,
                                  color: AppColors.primary, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Mes demandes de médecin traitant',
                                    style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary),
                                  ),
                                  Text(
                                    pendingCount > 0
                                        ? '$pendingCount en attente · $acceptedCount acceptée(s)'
                                        : '$acceptedCount acceptée(s)',
                                    style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 11,
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            if (pendingCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                    color: AppColors.warning
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10)),
                                child: Text('$pendingCount',
                                    style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 12,
                                        color: AppColors.warning,
                                        fontWeight: FontWeight.bold)),
                              )
                            else
                              const Icon(LucideIcons.chevron_right,
                                  size: 16, color: AppColors.primary),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Specialties filter
                const _SectionHeader(title: 'Spécialités'),
                const SizedBox(height: 12),
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: [
                      'Tous',
                      'Généraliste',
                      'Cardiologue',
                      'Pédiatre',
                      'Gynécologue',
                      'Dermatologue'
                    ].length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final specs = [
                        'Tous',
                        'Généraliste',
                        'Cardiologue',
                        'Pédiatre',
                        'Gynécologue',
                        'Dermatologue'
                      ];
                      final isSelected =
                          patient.selectedSpecialty == (i == 0 ? '' : specs[i]);
                      return GestureDetector(
                        onTap: () =>
                            patient.filterBySpecialty(i == 0 ? '' : specs[i]),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.backgroundCard,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.primary.withValues(alpha: 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            specs[i],
                            style: AppTextStyles.body2.copyWith(
                              color: isSelected
                                  ? AppColors.textWhite
                                  : AppColors.textSecondary,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Popular doctors
                _SectionHeader(
                    title: 'Médecins populaires', onSeeAll: onSeeAllDoctors),
                const SizedBox(height: 12),
                ...patient.doctors.take(3).map((doc) => DoctorCard(
                      doctor: doc,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          settings: RouteSettings(
                              name: '/patient/doctor-profile',
                              arguments: doc.id),
                          builder: (_) => DoctorProfileScreen(doctor: doc),
                        ),
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEmergency(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.backgroundGrey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.emergency_rounded,
                      color: AppColors.error, size: 24),
                ),
                const SizedBox(width: 12),
                const Text('Numéros d\'urgence', style: AppTextStyles.heading3),
              ],
            ),
            const SizedBox(height: 20),
            ...AppConstants.emergencyNumbers.entries.map((e) => Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      final cleanNumber = e.value.replaceAll(' ', '');
                      final uri = Uri.parse('tel:$cleanNumber');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Appel d\'urgence vers ${e.key} ($cleanNumber)...'),
                            backgroundColor: AppColors.error,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(e.key,
                                    style: AppTextStyles.subtitle2
                                        .copyWith(fontWeight: FontWeight.w600)),
                                Text(e.value,
                                    style: AppTextStyles.body2
                                        .copyWith(color: AppColors.primary)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.phone_rounded,
                                color: AppColors.primary, size: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
                )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ),
  );
  }

  void _showPharmaciesDeGarde(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _PharmaciesDeGardeModal(),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  final int? badge;
  const _SectionHeader({required this.title, this.onSeeAll, this.badge});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: AppTextStyles.heading3,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (badge != null && badge! > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10)),
                  child: Text('$badge',
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        ),
        if (onSeeAll != null) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onSeeAll,
            child: Text('Voir tout',
                style: AppTextStyles.body2.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 6),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== MESSAGES TAB (Patient) — connecté au MessageProvider global =====
class _MessagesTab extends StatefulWidget {
  @override
  State<_MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends State<_MessagesTab> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openChat(BuildContext context, ChatConversation conv) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SharedChatScreen(
          conversationId: conv.id,
          otherPersonName: conv.doctorName,
          otherPersonRole: 'Médecin',
          otherPersonSpecialty: conv.doctorSpecialty,
          isDoctor: false,
          doctorId: conv.doctorId,
          doctorName: conv.doctorName,
          cmuNumber: conv.patientCmu ??
              context.read<AuthProvider>().currentUser?.cmuNumber ??
              '',
          onVideoCall: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PreCallScreen(
                  doctorName: conv.doctorName,
                  doctorSpecialty: conv.doctorSpecialty,
                  isIncoming: false,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundCard,
        elevation: 0,
        title: Consumer<MessageProvider>(
          builder: (_, mp, __) {
            final unread = mp.totalUnreadForPatient;
            return Row(
              children: [
                const Text('Messages',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                if (unread > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10)),
                    child: Text('$unread',
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.backgroundGrey),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) =>
                    setState(() => _searchQuery = v.toLowerCase()),
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Rechercher une conversation...',
                  hintStyle: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: AppColors.textLight),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppColors.textLight, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                          child: const Icon(Icons.close_rounded,
                              color: AppColors.textLight, size: 18),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Consumer<MessageProvider>(
        builder: (_, mp, __) {
          final auth = context.watch<AuthProvider>();
          final patientId = auth.currentUser?.id ?? '';
          final allConvs = mp.conversationsForPatient(patientId);
          final convs = _searchQuery.isEmpty
              ? allConvs
              : allConvs
                  .where((c) =>
                      c.doctorName.toLowerCase().contains(_searchQuery) ||
                      c.doctorSpecialty.toLowerCase().contains(_searchQuery))
                  .toList();

          // Trier par dernier message
          final sorted = [...convs];
          sorted.sort((a, b) {
            final la = mp.lastMessageOf(a.id);
            final lb = mp.lastMessageOf(b.id);
            if (la == null && lb == null) return 0;
            if (la == null) return 1;
            if (lb == null) return -1;
            return lb.time.compareTo(la.time);
          });

          if (sorted.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: const BoxDecoration(
                        color: AppColors.primaryUltraLight,
                        shape: BoxShape.circle),
                    child: const Icon(Icons.chat_bubble_outline_rounded,
                        size: 52, color: AppColors.primary),
                  ),
                  const SizedBox(height: 20),
                  const Text('Aucune conversation',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 17,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  const Text(
                    'Trouvez un médecin et démarrez\nune conversation depuis son profil',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const DoctorSearchScreen())),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    icon: const Icon(Icons.search_rounded, color: Colors.white),
                    label: const Text('Trouver un médecin',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final conv = sorted[i];
              final lastMsg = mp.lastMessageOf(conv.id);
              final unreadCount = mp.unreadCountForPatient(conv.id);

              return GestureDetector(
                onTap: () => _openChat(context, conv),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(18),
                    border: unreadCount > 0
                        ? Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            width: 1.5)
                        : Border.all(color: Colors.transparent),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary
                            .withValues(alpha: unreadCount > 0 ? 0.08 : 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Avatar médecin
                      Stack(
                        children: [
                          _ConvAvatar(name: conv.doctorName),
                          Positioned(
                            right: 2,
                            bottom: 2,
                            child: Container(
                              width: 11,
                              height: 11,
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.backgroundCard, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),

                      // Contenu
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Nom + heure
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    conv.doctorName,
                                    style: AppTextStyles.subtitle2.copyWith(
                                      fontWeight: unreadCount > 0
                                          ? FontWeight.w800
                                          : FontWeight.w700,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (lastMsg != null)
                                  Text(
                                    _timeAgo(lastMsg.time),
                                    style: AppTextStyles.caption.copyWith(
                                      color: unreadCount > 0
                                          ? AppColors.primary
                                          : AppColors.textLight,
                                      fontWeight: unreadCount > 0
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            // Spécialité
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                  color: AppColors.primaryUltraLight,
                                  borderRadius: BorderRadius.circular(8)),
                              child: Text(
                                conv.doctorSpecialty,
                                style: AppTextStyles.caption.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10),
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Dernier message
                            if (lastMsg != null)
                              Row(
                                children: [
                                  // Tick de lecture si envoyé par le patient
                                  if (lastMsg.isFromPatient) ...[
                                    Icon(
                                      lastMsg.isReadByDoctor
                                          ? Icons.done_all_rounded
                                          : Icons.done_rounded,
                                      size: 13,
                                      color: lastMsg.isReadByDoctor
                                          ? AppColors.primary
                                          : AppColors.textLight,
                                    ),
                                    const SizedBox(width: 3),
                                  ],
                                  Expanded(
                                    child: Text(
                                      lastMsg.text,
                                      style: AppTextStyles.caption.copyWith(
                                        color: unreadCount > 0
                                            ? AppColors.textPrimary
                                            : AppColors.textSecondary,
                                        fontWeight: unreadCount > 0
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              )
                            else
                              Text('Démarrer la conversation',
                                  style: AppTextStyles.caption.copyWith(
                                      color: AppColors.primary,
                                      fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Badge non-lus
                      if (unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                              color: AppColors.primary, shape: BoxShape.circle),
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        )
                      else
                        const Icon(Icons.chevron_right_rounded,
                            color: AppColors.textLight, size: 20),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const DoctorSearchScreen())),
        backgroundColor: AppColors.primary,
        elevation: 4,
        icon: const Icon(Icons.add_comment_rounded, color: Colors.white),
        label: const Text('Nouveau message',
            style: TextStyle(
                fontFamily: 'Poppins',
                color: Colors.white,
                fontWeight: FontWeight.w600)),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'maintenant';
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}j';
    return '${dt.day}/${dt.month}';
  }
}

class _ConvAvatar extends StatelessWidget {
  final String name;
  const _ConvAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();
    return Container(
      width: 52,
      height: 52,
      decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient, shape: BoxShape.circle),
      child: Center(
          child: Text(initials,
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white))),
    );
  }
}

// ===== PROFILE TAB =====
class _ProfileTab extends StatelessWidget {
  Future<void> _pickAndUpdateProfilePhoto(BuildContext context) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64Image = base64Encode(bytes);

        final auth = context.read<AuthProvider>();
        final success = await auth.updateProfilePhoto(base64Image);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success
                  ? '✅ Photo de profil mise à jour !'
                  : '❌ Erreur lors de la mise à jour'),
              backgroundColor: success ? AppColors.success : AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sélection de l\'image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 52),

            // ── Carte Patient officielle My Doctor ─────────────────────
            HealthIdCardWidget(
              isDoctor: false,
              lastName: user?.lastName,
              firstName: user?.firstName,
              idNumber: (user?.cmuNumber != null && user!.cmuNumber!.isNotEmpty)
                  ? user.cmuNumber
                  : (user?.id.isNotEmpty == true
                      ? 'PAT-${user!.id.replaceAll(RegExp(r'[^0-9]'), '').padLeft(8, '0')}'
                      : 'PAT-00018427'),
              birthDate: user?.birthDate,
              location: (user?.city != null && user!.city!.isNotEmpty)
                  ? ((user.commune != null && user.commune!.isNotEmpty)
                      ? '${user.city} - ${user.commune}'
                      : user.city)
                  : 'ABIDJAN',
              admissionDate: user?.createdAt,
              avatarBase64: user?.avatarBase64,
              avatarUrl: user?.avatarUrl,
              onPhotoUpdated: () => auth.refreshCurrentUser(),
            ),
            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // ── Mon profil ─────────────────────────────────────────
                  _ProfileSection(
                    title: 'Mon profil',
                    items: [
                      _ProfileMenuItem(
                        icon: LucideIcons.user_pen,
                        title: 'Modifier mes informations',
                        subtitle: 'Nom, prénom, date de naissance, ville...',
                        color: AppColors.primary,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const EditProfileScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ── Menu items ─────────────────────────────────────────
                  _ProfileSection(
                    title: 'Mon espace santé',
                    items: [
                      _ProfileMenuItem(
                        icon: LucideIcons.id_card,
                        title: 'Ma Carte CMU',
                        subtitle: 'Carte digitale, garanties & remboursements',
                        color: const Color(0xFF185FA5),
                        onTap: () {
                          Navigator.pushNamed(context, '/patient/cmu');
                        },
                      ),
                      _ProfileMenuItem(
                        icon: LucideIcons.sparkles,
                        title: 'Mon abonnement',
                        subtitle: 'Du Plan Gratuit au Pack Famille',
                        color: const Color(0xFFEA580C),
                        onTap: () {
                          Navigator.pushNamed(context, '/patient/subscription');
                        },
                      ),
                      _ProfileMenuItem(
                        icon: LucideIcons.file_text,
                        title: 'Dossier médical',
                        subtitle: 'Antécédents, prescriptions, examens',
                        color: const Color(0xFF185FA5),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const MedicalRecordScreen()),
                          );
                        },
                      ),
                      _ProfileMenuItem(
                        icon: LucideIcons.syringe,
                        title: 'Carnet de vaccinations',
                        subtitle: 'Historique et rappels',
                        color: AppColors.success,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const VaccinationCardScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _ProfileSection(
                    title: 'Paramètres',
                    items: [
                      _ProfileMenuItem(
                        icon: LucideIcons.bell,
                        title: 'Notifications',
                        subtitle: 'Alertes, rappels, actualités',
                        color: AppColors.warning,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const NotificationsSettingsScreen()),
                          );
                        },
                      ),
                      _ProfileMenuItem(
                        icon: LucideIcons.shield_check,
                        title: 'Sécurité & Confidentialité',
                        subtitle: 'Mot de passe, 2FA, données',
                        color: AppColors.error,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SecurityPrivacyScreen()),
                          );
                        },
                      ),
                      _ProfileMenuItem(
                        icon: LucideIcons.moon,
                        title: 'Apparence',
                        subtitle: 'Mode sombre, taille du texte',
                        color: const Color(0xFF6C5CE7),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const AppearanceSettingsScreen()),
                          );
                        },
                      ),
                      _ProfileMenuItem(
                        icon: LucideIcons.globe,
                        title: 'Langue',
                        subtitle: "Français (Côte d'Ivoire)",
                        color: AppColors.textSecondary,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Changement de langue bientôt disponible')),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _ProfileSection(
                    title: 'Support',
                    items: [
                      _ProfileMenuItem(
                        icon: LucideIcons.circle_question_mark,
                        title: 'Aide & FAQ',
                        subtitle: 'Questions fréquentes',
                        color: const Color(0xFF185FA5),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const HelpFaqScreen()),
                          );
                        },
                      ),
                      _ProfileMenuItem(
                        icon: LucideIcons.headphones,
                        title: 'Contacter le support',
                        subtitle: 'Chat, email, téléphone',
                        color: AppColors.success,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ContactSupportScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Logout ─────────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await context.read<AuthProvider>().logout();
                        if (context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(
                              context, '/welcome', (r) => false);
                        }
                      },
                      icon: const Icon(LucideIcons.log_out,
                          color: AppColors.error, size: 18),
                      label: const Text(
                        'Se déconnecter',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Allo Docteur v2.0 · © 2025 CMU-CI',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mini CMU card in profile
class _MiniCmuCard extends StatelessWidget {
  final UserModel user;
  const _MiniCmuCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/patient/cmu'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF185FA5), Color(0xFF0D3F73)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF185FA5).withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Ivory Coast flag colors
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      '🇨🇮',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CNAM - CMU',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      'Côte d\'Ivoire',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 9,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.4)),
                  ),
                  child: const Text(
                    '● ACTIF',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                // Photo
                Container(
                  width: 52,
                  height: 62,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white.withValues(alpha: 0.1),
                    border: Border.all(color: Colors.white24),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: ProfileAvatar(
                    base64Data: user.avatarBase64,
                    networkUrl: user.avatarUrl,
                    initials: user.initials,
                    width: 52,
                    height: 62,
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nom: ${user.lastName.toUpperCase()}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        user.lastName.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Prénoms: ${user.firstName}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (user.gender != null)
                        Text(
                          'Sexe: ${user.gender}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            color: Colors.white70,
                          ),
                        ),
                      if (user.birthDate != null)
                        Text(
                          'Né(e) le: ${user.formattedBirthDate ?? ''}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            color: Colors.white70,
                          ),
                        ),
                      if (user.profession != null)
                        Text(
                          'Prof.: ${user.profession}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            color: Colors.white70,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(height: 1, color: Colors.white12),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'N° CMU-CI',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 9,
                        color: Colors.white60,
                      ),
                    ),
                    Text(
                      user.cmuNumber ?? '—',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                // QR Code placeholder
                Container(
                  width: 44,
                  height: 44,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.qr_code_rounded,
                      color: Color(0xFF185FA5), size: 32),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Info grid showing user details
class _InfoGrid extends StatelessWidget {
  final UserModel? user;
  const _InfoGrid({required this.user});

  @override
  Widget build(BuildContext context) {
    final items = [
      if (user?.gender != null)
        _InfoItem('Sexe', user!.gender!, LucideIcons.user),
      if (user?.birthDate != null)
        _InfoItem(
          'Date de naissance',
          () {
            final bd = user!.birthDate!;
            return '${bd.day.toString().padLeft(2, '0')}/${bd.month.toString().padLeft(2, '0')}/${bd.year}';
          }(),
          LucideIcons.calendar,
        ),
      if (user?.commune != null)
        _InfoItem('Commune', user!.commune!, LucideIcons.map_pin),
      if (user?.city != null)
        _InfoItem('Ville', user!.city!, LucideIcons.building),
      if (user?.phone != null)
        _InfoItem('Téléphone', user!.phone, LucideIcons.phone),
      if (user?.profession != null)
        _InfoItem('Profession', user!.profession!, LucideIcons.briefcase),
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  color: Color(0xFF185FA5), size: 18),
              SizedBox(width: 8),
              Text(
                'Informations personnelles',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF185FA5).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(item.icon,
                          color: const Color(0xFF185FA5), size: 14),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.label,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 9,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            item.value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _InfoItem {
  final String label;
  final String value;
  final IconData icon;
  const _InfoItem(this.label, this.value, this.icon);
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final List<_ProfileMenuItem> items;
  const _ProfileSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 1,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: items.asMap().entries.map((e) {
              final isLast = e.key == items.length - 1;
              return Column(
                children: [
                  e.value,
                  if (!isLast)
                    const Divider(height: 1, indent: 56, endIndent: 16),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.color = AppColors.primary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 10,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: const Icon(LucideIcons.chevron_right,
          size: 16, color: AppColors.textLight),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}

// ===== UPCOMING APPOINTMENT CARD =====
class _UpcomingAppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final VoidCallback onTap;
  const _UpcomingAppointmentCard(
      {required this.appointment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isVideo = appointment.isTeleconsultation;
    final statusColor = appointment.status.name == 'confirmed'
        ? AppColors.success
        : AppColors.warning;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isVideo
              ? const LinearGradient(
                  colors: [Color(0xFF2B5BA0), Color(0xFF4A8FD4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight)
              : AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                          isVideo
                              ? Icons.videocam_rounded
                              : Icons.local_hospital_rounded,
                          color: Colors.white,
                          size: 14),
                      const SizedBox(width: 5),
                      Text(isVideo ? 'Téléconsultation' : 'Présentiel',
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(appointment.statusLabel,
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          color: statusColor == AppColors.success
                              ? Colors.greenAccent
                              : Colors.orangeAccent,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle),
                  child: Center(
                    child: Text(
                      appointment.doctorName
                          .split(' ')
                          .where((w) => w.isNotEmpty)
                          .take(2)
                          .map((w) => w[0].toUpperCase())
                          .join(),
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(appointment.doctorName,
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      Text(appointment.doctorSpecialty,
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.8))),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.white70, size: 16),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12)),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                spacing: 12,
                runSpacing: 6,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          color: Colors.white70, size: 15),
                      const SizedBox(width: 8),
                      Text(_formatDate(appointment.scheduledAt),
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time_rounded,
                          color: Colors.white70, size: 15),
                      const SizedBox(width: 6),
                      Text(_formatTime(appointment.scheduledAt),
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(width: 10),
                      Text('${appointment.durationMinutes} min',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.7))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Jun',
      'Jul',
      'Aoû',
      'Sep',
      'Oct',
      'Nov',
      'Déc'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}h${dt.minute.toString().padLeft(2, '0')}';
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.textLight),
          const SizedBox(height: 16),
          Text(message,
              style:
                  AppTextStyles.body1.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  MODAL PHARMACIES DE GARDE
// ════════════════════════════════════════════════════════════

class _PharmacieGardeItem {
  final String name;
  final String commune;
  final String address;
  final String phone;
  final String distance;
  final bool acceptsCmu;
  final String openingHours;
  final double latitude;
  final double longitude;

  const _PharmacieGardeItem({
    required this.name,
    required this.commune,
    required this.address,
    required this.phone,
    required this.distance,
    this.acceptsCmu = true,
    this.openingHours = '24h/24',
    this.latitude = 5.3572,
    this.longitude = -3.9871,
  });
}

class _PharmaciesDeGardeModal extends StatefulWidget {
  const _PharmaciesDeGardeModal();

  @override
  State<_PharmaciesDeGardeModal> createState() => _PharmaciesDeGardeModalState();
}

class _PharmaciesDeGardeModalState extends State<_PharmaciesDeGardeModal> {
  String _selectedCommune = 'Toutes';
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  final List<String> _communes = const [
    'Toutes',
    'Cocody',
    'Plateau',
    'Yopougon',
    'Marcory',
    'Koumassi',
    'Treichville',
    'Port-Bouët',
    'Abobo',
    'Adjamé',
    'Attécoubé',
    'Bingerville',
    'Anyama',
    'Songon',
  ];

  List<_PharmacieGardeItem> get _pharmacies => PharmacieDemo.all
      .map(
        (p) => _PharmacieGardeItem(
          name: p.nomPharmacie,
          commune: p.commune,
          address: p.adresseComplete,
          phone: p.telephone,
          distance: PharmacieLocationService.instance.formatDistance(
            PharmacieLocationService.instance.calculateDistanceInMeters(
              fromLat: PharmacieLocationService.defaultAbidjanLat,
              fromLng: PharmacieLocationService.defaultAbidjanLng,
              toLat: p.latitude ?? PharmacieLocationService.defaultAbidjanLat,
              toLng: p.longitude ?? PharmacieLocationService.defaultAbidjanLng,
            ),
          ),
          acceptsCmu: p.accepteCmu,
          openingHours: '24h/24 • Garde active',
          latitude: p.latitude ?? PharmacieLocationService.defaultAbidjanLat,
          longitude: p.longitude ?? PharmacieLocationService.defaultAbidjanLng,
        ),
      )
      .toList();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_PharmacieGardeItem> get _filteredPharmacies {
    return _pharmacies.where((p) {
      final matchesCommune =
          _selectedCommune == 'Toutes' || p.commune == _selectedCommune;
      final q = _searchQuery.toLowerCase();
      final matchesQuery = q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.address.toLowerCase().contains(q) ||
          p.commune.toLowerCase().contains(q);
      return matchesCommune && matchesQuery;
    }).toList();
  }

  Future<void> _callPharmacy(String phone, String name) async {
    final cleanPhone = phone.replaceAll(' ', '');
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Appel vers $name ($cleanPhone)...'),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredPharmacies;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.backgroundGrey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(LucideIcons.pill,
                      color: Color(0xFF059669), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pharmacies de garde',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFF059669),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Ouvertes 24h/24 • Abidjan (${filtered.length})',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Bouton vers Carte Interactive & GPS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: InkWell(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PharmacieGardeMapScreen()),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF059669), Color(0xFF047857)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF059669).withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(LucideIcons.map, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ouvrir la Carte Interactive & GPS',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 12),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.backgroundGrey),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Rechercher une pharmacie, une commune...',
                  hintStyle: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: AppColors.textLight,
                  ),
                  prefixIcon: const Icon(Icons.search_rounded,
                      size: 18, color: AppColors.textLight),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 16),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Commune filter chips
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _communes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final commune = _communes[idx];
                final isSelected = commune == _selectedCommune;
                return ChoiceChip(
                  label: Text(commune),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedCommune = commune),
                  labelStyle: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                  selectedColor: const Color(0xFF059669),
                  backgroundColor: AppColors.backgroundLight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF059669)
                          : AppColors.backgroundGrey,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Pharmacy List
          Flexible(
            child: filtered.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Aucune pharmacie de garde trouvée pour cette recherche.',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF059669).withValues(alpha: 0.18),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          const Icon(LucideIcons.map_pin,
                                              size: 13,
                                              color: AppColors.textSecondary),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              item.address,
                                              style: const TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 11,
                                                color: AppColors.textSecondary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF059669)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    item.distance,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF059669),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF059669)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(LucideIcons.clock,
                                          size: 11, color: Color(0xFF059669)),
                                      const SizedBox(width: 4),
                                      Text(
                                        item.openingHours,
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF059669),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (item.acceptsCmu) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF185FA5)
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Agrée CMU',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF185FA5),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => InAppItineraryScreen(
                                            destinationTitle: item.name,
                                            destinationSubtitle: 'Pharmacie de garde - ${item.commune}',
                                            destinationAddress: item.address,
                                            destinationLatitude: item.latitude,
                                            destinationLongitude: item.longitude,
                                            destinationPhone: item.phone,
                                            destinationCategory: 'Pharmacie',
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(LucideIcons.navigation,
                                        size: 15),
                                    label: const Text('Itinéraire'),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: AppColors.logoBlue,
                                      side: const BorderSide(
                                          color: AppColors.logoBlue, width: 1.5),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _callPharmacy(
                                        item.phone, item.name),
                                    icon: const Icon(Icons.phone_rounded,
                                        size: 16, color: Colors.white),
                                    label: const Text(
                                      'Appeler',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          const Color(0xFF059669),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
                                    ),
                                  ),
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

