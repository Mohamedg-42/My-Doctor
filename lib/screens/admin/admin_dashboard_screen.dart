import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import 'views/admin_overview_view.dart';
import 'views/admin_users_view.dart';
import 'views/admin_doctors_view.dart';
import 'views/admin_patients_view.dart';
import 'views/admin_requests_view.dart';
import 'views/admin_conversations_view.dart';
import 'views/admin_appointments_view.dart';
import '../../services/database_service.dart';
import '../../providers/message_provider.dart';
import '../../providers/treating_request_provider.dart';
import '../../core/routing/route_persistence_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  final int initialTab;

  const AdminDashboardScreen({super.key, this.initialTab = 0});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;
  int _refreshVersion = 0;
  int _messageQuota = 10;
  bool _manualDoctorApproval = true;

  @override
  void initState() {
    super.initState();
    int initial = widget.initialTab;
    if (initial == 0) {
      final savedTab = RoutePersistenceService.getCachedTab('admin');
      if (savedTab != null && savedTab >= 0 && savedTab <= 6) {
        initial = savedTab;
      }
    }
    _currentIndex = initial.clamp(0, 6);
    _tabController = TabController(length: 7, vsync: this, initialIndex: _currentIndex);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && mounted) {
        setState(() => _currentIndex = _tabController.index);
        RoutePersistenceService.saveTab('admin', _tabController.index);
      }
    });

    _loadSystemSettings();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      if (!auth.isAdmin) return;

      try {
        await DatabaseService().seedDemoData();
      } catch (e) {
        debugPrint('seedDemoData note: $e');
      }
      if (mounted) {
        try {
          await context.read<TreatingRequestProvider>().seedDemoRequests();
          await context.read<MessageProvider>().seedDemoConversations();
          setState(() {});
        } catch (_) {}
      }
    });
  }

  Future<void> _loadSystemSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _messageQuota = prefs.getInt(AppConstants.keyAdminMessageQuota) ?? 10;
      _manualDoctorApproval = prefs.getBool(AppConstants.keyAdminManualDoctorApproval) ?? true;
    });
  }

  Future<void> _saveSystemSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.keyAdminMessageQuota, _messageQuota);
    await prefs.setBool(AppConstants.keyAdminManualDoctorApproval, _manualDoctorApproval);
  }

  Future<bool> _confirmAdminAction({required String title, required String message}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: Text(message, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Confirmer')),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _navigateToTab(int index) {
    if (index >= 0 && index < 7) {
      _tabController.animateTo(index);
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // ── Contrôle de sécurité et de permission (Rôle ADMIN strict) ───────────
    if (!auth.isAuthenticated || !auth.isAdmin) {
      return _buildAccessDeniedScreen(context, auth);
    }

    return Scaffold(
      backgroundColor: AppColors.surfaceApp,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrow_left, color: AppColors.textPrimary, size: 20),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/');
            }
          },
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.brandNavy,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(LucideIcons.shield, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'My Doctor Admin',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
          actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'MODE LOCAL',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.warning),
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.refresh_cw, size: 18, color: AppColors.brandBlue),
            tooltip: 'Actualiser les données',
            onPressed: () => setState(() => _refreshVersion++),
          ),
          // Profil Admin
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.brandNavy,
                  child: Text('A', style: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 6),
                Text(
                  auth.userName,
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.settings, size: 18, color: AppColors.brandNavy),
            tooltip: 'Configuration du système',
            onPressed: () => _showSystemSettingsDialog(context),
          ),
          IconButton(
            icon: const Icon(LucideIcons.log_out, size: 18, color: AppColors.brandCoral),
            tooltip: 'Déconnexion',
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: AppColors.brandBlue,
              indicatorWeight: 3,
              labelColor: AppColors.brandBlue,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w500),
              tabs: const [
                Tab(icon: Icon(LucideIcons.layout_dashboard, size: 16), text: 'Tableau de bord'),
                Tab(icon: Icon(LucideIcons.users, size: 16), text: 'Utilisateurs'),
                Tab(icon: Icon(LucideIcons.stethoscope, size: 16), text: 'Médecins'),
                Tab(icon: Icon(LucideIcons.user, size: 16), text: 'Patients'),
                Tab(icon: Icon(LucideIcons.inbox, size: 16), text: 'Demandes'),
                Tab(icon: Icon(LucideIcons.calendar, size: 16), text: 'Rendez-vous'),
                Tab(icon: Icon(LucideIcons.messages_square, size: 16), text: 'Conversations'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        key: ValueKey(_refreshVersion),
        controller: _tabController,
        children: [
          AdminOverviewView(onNavigateTab: _navigateToTab),
          const AdminUsersView(),
          const AdminDoctorsView(),
          const AdminPatientsView(),
          const AdminRequestsView(),
          const AdminAppointmentsView(),
          const AdminConversationsView(),
        ],
      ),
    );
  }

  // ── Écran d'accès refusé pour les utilisateurs non-admin ───────────────────
  Widget _buildAccessDeniedScreen(BuildContext context, AuthProvider auth) {
    return Scaffold(
      backgroundColor: AppColors.surfaceApp,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                elevation: 4,
                shadowColor: Colors.black.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.brandNavy.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.shield_check, color: AppColors.brandNavy, size: 40),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Accès Restreint',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        auth.isAuthenticated
                            ? 'Votre compte actuel (${auth.userName}, rôle: ${auth.currentUser?.role.name}) ne dispose pas des privilèges administrateur.'
                            : 'Authentification requise pour accéder à la console d\'administration.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const _DirectAdminLoginForm(),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          } else {
                            Navigator.pushReplacementNamed(context, '/');
                          }
                        },
                        icon: const Icon(LucideIcons.arrow_left, size: 16, color: AppColors.textMuted),
                        label: const Text(
                          'Retour à l\'application',
                          style: TextStyle(fontFamily: 'Poppins', color: AppColors.textMuted, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAdminLoginDialog(BuildContext context) {

    final identCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    bool isLoading = false;
    String? errorText;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.brandNavy.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.shield_check, color: AppColors.brandNavy, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'Connexion Admin',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Identifiant (Téléphone ou email)',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: identCtrl,
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Téléphone ou email administrateur',
                  filled: true,
                  fillColor: AppColors.surfaceSubtle,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Mot de passe',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: passCtrl,
                obscureText: true,
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Mot de passe administrateur',
                  filled: true,
                  fillColor: AppColors.surfaceSubtle,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              if (errorText != null) ...[
                const SizedBox(height: 8),
                Text(
                  errorText!,
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.error),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Annuler', style: TextStyle(fontFamily: 'Poppins', color: AppColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      setDialogState(() {
                        isLoading = true;
                        errorText = null;
                      });
                      final auth = context.read<AuthProvider>();
                      final ok = await auth.loginAdmin(
                        identifier: identCtrl.text.trim(),
                        password: passCtrl.text.trim(),
                      );
                      if (dialogCtx.mounted) {
                        if (ok) {
                          Navigator.pop(dialogCtx);
                        } else {
                          setDialogState(() {
                            isLoading = false;
                            errorText = auth.errorMessage ?? 'Identifiants invalides';
                          });
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandNavy,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: isLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Se connecter', style: TextStyle(fontFamily: 'Poppins', color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showSystemSettingsDialog(BuildContext context) {
    bool isResetting = false;
    bool isSeedingDemo = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.brandNavy.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.settings, color: AppColors.brandNavy, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'Configuration Système',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MESSAGERIE & QUOTAS',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.brandBlue, letterSpacing: 0.5),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Messages gratuits par patient :', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w500)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.brandNavy.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('$_messageQuota messages', style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.brandNavy)),
                    ),
                  ],
                ),
                Slider(
                  value: _messageQuota.toDouble(),
                  min: 5,
                  max: 50,
                  divisions: 9,
                  activeColor: AppColors.brandNavy,
                  onChanged: (val) => setDialogState(() => _messageQuota = val.round()),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: isResetting
                      ? null
                      : () async {
                          final confirmed = await _confirmAdminAction(
                            title: 'Réinitialiser les quotas ?',
                            message: 'Cette action remettra le quota de tous les patients à $_messageQuota messages.',
                          );
                          if (!confirmed || !dialogCtx.mounted) return;
                          setDialogState(() => isResetting = true);
                          final db = DatabaseService();
                          await db.resetAllPatientsMessageUsage(_messageQuota);
                          setDialogState(() => isResetting = false);
                          if (dialogCtx.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Quotas réinitialisés pour tous les patients ($_messageQuota messages gratuits).'),
                                backgroundColor: AppColors.brandBlue,
                              ),
                            );
                          }
                        },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.brandCoral,
                    side: const BorderSide(color: AppColors.brandCoral),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: isResetting
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandCoral))
                      : const Icon(LucideIcons.rotate_ccw, size: 14),
                  label: const Text('Réinitialiser les quotas de tous les patients', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                const Text(
                  'GESTION DES MÉDECINS',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.brandBlue, letterSpacing: 0.5),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Validation manuelle obligatoire', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w500)),
                  subtitle: const Text('Les médecins inscrits restent en attente jusqu\'à validation par l\'admin', style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: AppColors.textMuted)),
                  value: _manualDoctorApproval,
                  activeColor: AppColors.brandNavy,
                  onChanged: (val) => setDialogState(() => _manualDoctorApproval = val),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                const Text(
                  'PLATEFORME & BASE DE DONNÉES',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.brandBlue, letterSpacing: 0.5),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Version système :', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textMuted)),
                          Text('My Doctor v1.0.0 (Prototype local)', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Moteur de données :', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textMuted)),
                          Text('Hive Local Storage (prototype local)', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: isSeedingDemo
                        ? null
                        : () async {
                            final confirmed = await _confirmAdminAction(
                              title: 'Régénérer les données démo ?',
                              message: 'Les données locales de démonstration seront remplacées. Cette action est réservée au prototype.',
                            );
                            if (!confirmed || !dialogCtx.mounted) return;
                            setDialogState(() => isSeedingDemo = true);
                            await DatabaseService().seedDemoData(force: true);
                            if (context.mounted) {
                              await context.read<TreatingRequestProvider>().seedDemoRequests(force: true);
                              await context.read<MessageProvider>().seedDemoConversations(force: true);
                            }
                            setDialogState(() => isSeedingDemo = false);
                            if (dialogCtx.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Données de démonstration rechargées avec succès !'),
                                  backgroundColor: AppColors.brandTurquoise,
                                ),
                              );
                              setState(() {}); // Actualise le tableau de bord
                            }
                          },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.brandNavy,
                      side: const BorderSide(color: AppColors.brandNavy),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: isSeedingDemo
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandNavy))
                        : const Icon(LucideIcons.database_backup, size: 14),
                    label: const Text('Régénérer toutes les données de démo', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                await _saveSystemSettings();
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandNavy,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Enregistrer et fermer', style: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DirectAdminLoginForm extends StatefulWidget {
  const _DirectAdminLoginForm();

  @override
  State<_DirectAdminLoginForm> createState() => _DirectAdminLoginFormState();
}

class _DirectAdminLoginFormState extends State<_DirectAdminLoginForm> {
  final _identCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _identCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitLogin(String identifier, String password) async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });
    final auth = context.read<AuthProvider>();
    final ok = await auth.loginAdmin(
      identifier: identifier.trim(),
      password: password.trim(),
    );
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _isLoading = false;
        _errorText = auth.errorMessage ?? 'Identifiants administrateur incorrects.';
      });
    } else {
      final db = DatabaseService();
      await db.seedDemoData();
      if (mounted) {
        await context.read<TreatingRequestProvider>().seedDemoRequests();
        await context.read<MessageProvider>().seedDemoConversations();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Identifiant (Téléphone ou email)',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _identCtrl,
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Téléphone ou email administrateur',
            filled: true,
            fillColor: AppColors.surfaceSubtle,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            prefixIcon: const Icon(LucideIcons.user, size: 16, color: AppColors.textMuted),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Mot de passe',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _passCtrl,
          obscureText: true,
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Mot de passe administrateur',
            filled: true,
            fillColor: AppColors.surfaceSubtle,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            prefixIcon: const Icon(LucideIcons.lock, size: 16, color: AppColors.textMuted),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        if (_errorText != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.errorBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.circle_alert, size: 14, color: AppColors.brandCoral),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorText!,
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.brandCoral),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : () => _submitLogin(_identCtrl.text, _passCtrl.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandNavy,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: _isLoading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(LucideIcons.log_in, size: 16, color: Colors.white),
            label: const Text(
              'Connexion Administrateur',
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Bouton Connexion Démo Admin 1-Clic
        SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton.icon(
            onPressed: _isLoading
                ? null
                : () {
                    _identCtrl.text = '0101010101';
                    _passCtrl.text = 'Password123!';
                    _submitLogin('0101010101', 'Password123!');
                  },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.brandBlue,
              side: const BorderSide(color: AppColors.brandBlue, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: AppColors.brandBlue.withValues(alpha: 0.04),
            ),
            icon: const Icon(LucideIcons.zap, size: 16, color: AppColors.brandBlue),
            label: const Text(
              '⚡ Connexion Démo Admin (1-clic)',
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Carte d'aide aux identifiants
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceSubtle,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(LucideIcons.key_round, size: 14, color: AppColors.brandNavy),
                  SizedBox(width: 6),
                  Text(
                    'Identifiants Administrateur Démo :',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.brandNavy),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text('• Téléphone : 0101010101', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textSecondary)),
              const Text('• Email : admin@mydoctor.ci', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textSecondary)),
              const Text('• Mot de passe : Password123!', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),

        // Option déconnexion si déjà connecté avec un autre compte
        Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (!auth.isAuthenticated || auth.isAdmin) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 14),
              child: SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () async {
                    await auth.logout();
                  },
                  icon: const Icon(LucideIcons.log_out, size: 14, color: AppColors.brandCoral),
                  label: Text(
                    'Déconnecter le compte actuel (${auth.userName})',
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.brandCoral),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
