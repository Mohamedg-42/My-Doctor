import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';

class RoutePersistenceService {
  static const String _keyLastRoute = 'last_active_route';
  static const String _keyLastDoctorId = 'last_active_doctor_id';
  static const String _keyPatientTab = 'patient_active_tab';
  static const String _keyDoctorTab = 'doctor_active_tab';
  static const String _keyAdminTab = 'admin_active_tab';

  static SharedPreferences? _prefs;

  // Cache synchrone en mémoire pour un accès immédiat dès le premier frame
  static int? _cachedPatientTab;
  static int? _cachedDoctorTab;
  static int? _cachedAdminTab;
  static String? _cachedLastRoute;
  static String? _cachedDoctorId;

  /// Initialisation appelée dans `main()` AVANT `runApp()`
  static Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _cachedPatientTab = _prefs?.getInt(_keyPatientTab);
      _cachedDoctorTab = _prefs?.getInt(_keyDoctorTab);
      _cachedAdminTab = _prefs?.getInt(_keyAdminTab);
      _cachedLastRoute = _prefs?.getString(_keyLastRoute);
      _cachedDoctorId = _prefs?.getString(_keyLastDoctorId);
      debugPrint('📍 RoutePersistenceService initialisé: lastRoute=$_cachedLastRoute, pTab=$_cachedPatientTab, dTab=$_cachedDoctorTab, aTab=$_cachedAdminTab');
    } catch (e) {
      debugPrint('⚠️ Erreur init RoutePersistenceService: $e');
    }
  }

  static int? getCachedTab(String role) {
    if (role == 'patient') return _cachedPatientTab;
    if (role == 'doctor') return _cachedDoctorTab;
    if (role == 'admin') {
      final tab = _cachedAdminTab;
      if (tab == null || tab < 0 || tab > 9) return 0;
      return tab;
    }
    return null;
  }

  static Future<void> saveTab(String role, int index) async {
    if (role == 'patient') {
      _cachedPatientTab = index;
      await _prefs?.setInt(_keyPatientTab, index);
    } else if (role == 'doctor') {
      _cachedDoctorTab = index;
      await _prefs?.setInt(_keyDoctorTab, index);
    } else if (role == 'admin') {
      final safeIndex = (index).clamp(0, 9).toInt();
      _cachedAdminTab = safeIndex;
      await _prefs?.setInt(_keyAdminTab, safeIndex);
    }
  }

  static Future<void> saveActiveRoute(String route, {String? doctorId}) async {
    if (route == '/' || route == '/welcome' || route == '/splash' || route.startsWith('/auth')) {
      return;
    }
    _cachedLastRoute = route;
    await _prefs?.setString(_keyLastRoute, route);
    if (doctorId != null && doctorId.isNotEmpty) {
      _cachedDoctorId = doctorId;
      await _prefs?.setString(_keyLastDoctorId, doctorId);
    }
  }

  static String? getLastRoute() => _cachedLastRoute;
  static String? getCachedDoctorId() => _cachedDoctorId;

  /// Détermine la route initiale sur laquelle rester après un rafraîchissement (F5)
  static String getInitialRoute(AuthProvider auth) {
    if (!auth.isAuthenticated || auth.currentUser == null) {
      return kIsWeb ? '/welcome' : '/';
    }

    final role = auth.currentUser?.role;
    final lastRoute = _cachedLastRoute;

    if (lastRoute != null && lastRoute.isNotEmpty) {
      // Vérifier que la route sauvegardée correspond au rôle de l'utilisateur
      if (role == UserRole.admin && (lastRoute.startsWith('/admin') || lastRoute == '/admin')) {
        return lastRoute;
      }
      if (role == UserRole.patient && lastRoute.startsWith('/patient')) {
        return lastRoute;
      }
      if (role == UserRole.doctor && lastRoute.startsWith('/doctor')) {
        return lastRoute;
      }
    }

    // Par défaut, retourner l'écran d'accueil correspondant au rôle
    if (role == UserRole.admin) return '/admin';
    if (role == UserRole.doctor) return '/doctor/home';
    return '/patient/home';
  }

  /// Efface les informations de persistance lors de la déconnexion
  static Future<void> clearOnLogout() async {
    _cachedPatientTab = null;
    _cachedDoctorTab = null;
    _cachedAdminTab = null;
    _cachedLastRoute = null;
    _cachedDoctorId = null;

    await _prefs?.remove(_keyLastRoute);
    await _prefs?.remove(_keyLastDoctorId);
    await _prefs?.remove(_keyPatientTab);
    await _prefs?.remove(_keyDoctorTab);
    await _prefs?.remove(_keyAdminTab);
  }
}

/// Observe les navigations pour enregistrer la route active en temps réel
class AppRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _recordRoute(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) _recordRoute(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) _recordRoute(previousRoute);
  }

  void _recordRoute(Route<dynamic> route) {
    final name = route.settings.name;
    if (name != null && name.isNotEmpty && name != '/' && name != '/welcome' && name != '/splash' && !name.startsWith('/auth')) {
      String? doctorId;
      if (route.settings.arguments is String) {
        doctorId = route.settings.arguments as String;
      }
      RoutePersistenceService.saveActiveRoute(name, doctorId: doctorId);
    }
  }
}
