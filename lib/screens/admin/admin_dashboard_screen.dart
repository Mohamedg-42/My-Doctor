// lib/screens/admin/admin_dashboard_screen.dart
//
// Conteneur principal responsive de la console d'administration My Doctor.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/routing/route_persistence_service.dart';
import '../../providers/treating_request_provider.dart';
import '../../services/database_service.dart';
import 'components/admin_header.dart';
import 'components/admin_sidebar.dart';
import 'components/admin_error_view.dart';
import 'views/admin_overview_view.dart';
import 'views/admin_patient_cards_view.dart';
import 'views/admin_withdrawals_view.dart';
import 'views/admin_doctors_view.dart';
import 'views/admin_patients_view.dart';
import 'views/admin_appointments_view.dart';
import 'views/admin_requests_view.dart';
import 'views/admin_conversations_view.dart';
import 'views/admin_settings_view.dart';
import 'views/admin_users_view.dart';

class AdminDashboardScreen extends StatefulWidget {
  final int? initialTab;

  const AdminDashboardScreen({super.key, this.initialTab});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late int _selectedTab;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _hasError = false;
  String? _errorMessage;

  final List<Map<String, String>> _tabTitles = const [
    {
      'title': 'Vue d\'ensemble',
      'subtitle': 'Indicateurs clés et alertes en temps réel de la plateforme',
    },
    {
      'title': 'Cartes patient & CMU-CI',
      'subtitle': 'Vérification, délivrance et conformité des cartes numériques',
    },
    {
      'title': 'Finances & Retraits praticiens',
      'subtitle': 'Gestion des reversements d\'honoraires et commissions',
    },
    {
      'title': 'Gestion des praticiens',
      'subtitle': 'Validation, suspension et supervision des médecins',
    },
    {
      'title': 'Gestion des patients',
      'subtitle': 'Suivi des dossiers, quotas de messagerie et abonnements',
    },
    {
      'title': 'Supervision des rendez-vous',
      'subtitle': 'Consultations présentielles et téléconsultations',
    },
    {
      'title': 'Demandes de médecin traitant',
      'subtitle': 'Supervision des liaisons soignants-familles',
    },
    {
      'title': 'Conversations & Audit',
      'subtitle': 'Respect des quotas et métriques de la messagerie médicale',
    },
    {
      'title': 'Configuration système',
      'subtitle': 'Paramètres de la plateforme et maintenance des démos',
    },
    {
      'title': 'Utilisateurs globaux',
      'subtitle': 'Vue transversale de tous les comptes enregistrés',
    },
  ];

  @override
  void initState() {
    super.initState();
    final savedTab = widget.initialTab ?? RoutePersistenceService.getCachedTab('admin') ?? 0;
    _selectedTab = savedTab.clamp(0, 9).toInt();
  }

  @override
  void didUpdateWidget(covariant AdminDashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != null && widget.initialTab != oldWidget.initialTab) {
      _selectTab(widget.initialTab!, closeDrawer: false);
    }
  }

  void _selectTab(int index, {bool closeDrawer = true}) {
    final safeIndex = index.clamp(0, 9).toInt();

    setState(() {
      _selectedTab = safeIndex;
      _hasError = false;
      _errorMessage = null;
    });

    RoutePersistenceService.saveTab('admin', safeIndex);

    if (closeDrawer && _scaffoldKey.currentState?.isDrawerOpen == true) {
      _scaffoldKey.currentState?.closeDrawer();
    }
  }

  void _refreshCurrentView() {
    setState(() {
      _hasError = false;
      _errorMessage = null;
    });
  }

  Widget _buildActiveView() {
    if (_hasError) {
      return AdminErrorView(
        message: _errorMessage ?? 'Une erreur est survenue lors de l\'affichage de cette section.',
        onRetry: _refreshCurrentView,
        onBackToDashboard: () => _selectTab(0),
      );
    }

    try {
      switch (_selectedTab) {
        case 0:
          return AdminOverviewView(onNavigateToTab: (idx) => _selectTab(idx));
        case 1:
          return const AdminPatientCardsView();
        case 2:
          return const AdminWithdrawalsView();
        case 3:
          return const AdminDoctorsView();
        case 4:
          return const AdminPatientsView();
        case 5:
          return const AdminAppointmentsView();
        case 6:
          return const AdminRequestsView();
        case 7:
          return const AdminConversationsView();
        case 8:
          return const AdminSettingsView();
        case 9:
          return const AdminUsersView();
        default:
          return AdminOverviewView(onNavigateToTab: (idx) => _selectTab(idx));
      }
    } catch (e) {
      return AdminErrorView(
        developerDetails: '$e',
        onRetry: _refreshCurrentView,
        onBackToDashboard: () => _selectTab(0),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestProvider = context.watch<TreatingRequestProvider>();
    final db = DatabaseService();

    // Badges de notification pour la sidebar
    final pendingDocs = db.totalPendingDoctors;
    final pendingReqs = requestProvider.allRequests.where((r) => r.isPending).length;

    final badgeCounts = {
      2: 1, // Retrait en attente
      3: pendingDocs,
      6: pendingReqs,
    };

    final isWideScreen = MediaQuery.of(context).size.width >= 960;
    final tabInfo = _tabTitles[_selectedTab.clamp(0, _tabTitles.length - 1)];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: isWideScreen
          ? null
          : Drawer(
              child: AdminSidebar(
                selectedIndex: _selectedTab,
                onSelectTab: (idx) => _selectTab(idx, closeDrawer: true),
                badgeCounts: badgeCounts,
                isDrawer: true,
              ),
            ),
      body: SafeArea(
        child: Row(
          children: [
            // Sidebar fixe sur grand écran
            if (isWideScreen)
              AdminSidebar(
                selectedIndex: _selectedTab,
                onSelectTab: (idx) => _selectTab(idx, closeDrawer: false),
                badgeCounts: badgeCounts,
              ),

            // Zone de contenu principale
            Expanded(
              child: Column(
                children: [
                  AdminHeader(
                    title: tabInfo['title'] ?? 'Administration',
                    subtitle: tabInfo['subtitle'] ?? '',
                    onRefresh: _refreshCurrentView,
                    onOpenMenu: () => _scaffoldKey.currentState?.openDrawer(),
                    isMobile: !isWideScreen,
                  ),
                  Expanded(
                    child: _buildActiveView(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
