// lib/providers/patient_subscription_provider.dart
//
// Provider de gestion de l'abonnement santé patient et persistance par patient.
// Isolation des données par identifiant utilisateur (patient_sub_[patientId]).

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/patient_subscription_model.dart';
import '../models/user_model.dart';

class PatientSubscriptionProvider extends ChangeNotifier {
  static const String _prefPrefix = 'patient_sub_';

  List<PatientSubscriptionPlan> get plans =>
      PatientSubscriptionPlan.defaultPlans;

  PatientSubscription? _currentSubscription;
  PatientSubscription? get currentSubscription => _currentSubscription;

  SubscriptionBillingCycle _selectedCycle = SubscriptionBillingCycle.mensuel;
  SubscriptionBillingCycle get selectedCycle => _selectedCycle;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _currentPatientId;
  String? get currentPatientId => _currentPatientId;

  /// Plan actif courant (par défaut Plan Gratuit si null)
  PatientSubscriptionPlan get currentPlan {
    final activePlanId = _currentSubscription?.planId ?? 'gratuit';
    return plans.firstWhere(
      (p) => p.id == activePlanId,
      orElse: () => plans.first,
    );
  }

  /// Liste des membres de la famille enregistrés
  List<FamilyMember> get familyMembers =>
      _currentSubscription?.familyMembers ?? [];

  /// Capacité maximale de membres autorisée par le plan actif
  int get maxFamilyMembers => currentPlan.maxFamilyMembers;

  /// Nombre de membres famille enregistrés
  int get familyMembersCount => familyMembers.length;

  /// Vérifie si de nouveaux membres peuvent être ajoutés
  bool get canAddFamilyMember =>
      currentPlan.type == PatientPlanType.famille && familyMembers.length < 6;

  // ─── Initialisation ─────────────────────────────────────────────────────────

  /// Initialise l'abonnement pour l'utilisateur connecté
  Future<void> initFromUser(UserModel user) async {
    if (user.role != UserRole.patient) return;
    if (_currentPatientId == user.id && _currentSubscription != null) return;

    _currentPatientId = user.id;
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_prefPrefix${user.id}';
      final storedData = prefs.getString(key);

      if (storedData != null && storedData.isNotEmpty) {
        final decoded = jsonDecode(storedData) as Map<String, dynamic>;
        _currentSubscription = PatientSubscription.fromJson(decoded);
        _selectedCycle = _currentSubscription!.cycle;
      } else {
        // Créer et sauvegarder automatiquement le Plan Gratuit par défaut
        _currentSubscription = _buildDefaultFreeSubscription(user.id);
        await prefs.setString(key, jsonEncode(_currentSubscription!.toJson()));
      }
    } catch (e) {
      debugPrint('⚠️ Erreur chargement abonnement patient: $e');
      _currentSubscription = _buildDefaultFreeSubscription(user.id);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  PatientSubscription _buildDefaultFreeSubscription(String patientId) {
    final now = DateTime.now();
    return PatientSubscription(
      patientId: patientId,
      planId: 'gratuit',
      cycle: SubscriptionBillingCycle.mensuel,
      startDate: now,
      endDate: now.add(const Duration(days: 365 * 99)), // Actif à vie
      isActive: true,
      paymentMethod: 'Gratuit',
      familyMembers: const [],
    );
  }

  /// Réinitialise l'état lors de la déconnexion
  void reset() {
    _currentSubscription = null;
    _currentPatientId = null;
    _selectedCycle = SubscriptionBillingCycle.mensuel;
    _isLoading = false;
    notifyListeners();
  }

  // ─── Sélection du cycle de facturation ─────────────────────────────────────

  void selectCycle(SubscriptionBillingCycle cycle) {
    if (_selectedCycle != cycle) {
      _selectedCycle = cycle;
      notifyListeners();
    }
  }

  // ─── Souscription à un plan ────────────────────────────────────────────────

  Future<bool> subscribeToPlan({
    required String planId,
    required SubscriptionBillingCycle cycle,
    required String paymentMethod,
  }) async {
    if (_currentPatientId == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final durationDays = cycle == SubscriptionBillingCycle.annuel ? 365 : 30;
      final endDate = now.add(Duration(days: durationDays));

      // Conserver les membres existants uniquement si le nouveau plan est Famille
      final targetPlan =
          plans.firstWhere((p) => p.id == planId, orElse: () => plans.first);
      final members = targetPlan.type == PatientPlanType.famille
          ? (_currentSubscription?.familyMembers ?? <FamilyMember>[])
          : <FamilyMember>[];

      _currentSubscription = PatientSubscription(
        patientId: _currentPatientId!,
        planId: planId,
        cycle: cycle,
        startDate: now,
        endDate: endDate,
        isActive: true,
        paymentMethod: paymentMethod,
        familyMembers: members,
      );

      _selectedCycle = cycle;
      await _saveToStorage();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('⚠️ Erreur souscription abonnement: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Retour au Plan Gratuit ────────────────────────────────────────────────

  Future<bool> downgradeToFree() async {
    if (_currentPatientId == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      _currentSubscription = _buildDefaultFreeSubscription(_currentPatientId!);
      _selectedCycle = SubscriptionBillingCycle.mensuel;
      await _saveToStorage();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('⚠️ Erreur retour au plan gratuit: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Gestion des membres famille ───────────────────────────────────────────

  Future<bool> addFamilyMember(FamilyMember member) async {
    if (_currentSubscription == null || _currentPatientId == null) return false;
    if (_currentSubscription!.familyMembers.length >= 6) return false;

    final updatedMembers =
        List<FamilyMember>.from(_currentSubscription!.familyMembers)
          ..add(member);

    _currentSubscription =
        _currentSubscription!.copyWith(familyMembers: updatedMembers);
    await _saveToStorage();
    notifyListeners();
    return true;
  }

  Future<bool> removeFamilyMember(String memberId) async {
    if (_currentSubscription == null || _currentPatientId == null) return false;

    final updatedMembers = _currentSubscription!.familyMembers
        .where((m) => m.id != memberId)
        .toList();

    _currentSubscription =
        _currentSubscription!.copyWith(familyMembers: updatedMembers);
    await _saveToStorage();
    notifyListeners();
    return true;
  }

  // ─── Persistance locale ────────────────────────────────────────────────────

  Future<void> _saveToStorage() async {
    if (_currentPatientId == null || _currentSubscription == null) return;
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefPrefix$_currentPatientId';
    await prefs.setString(key, jsonEncode(_currentSubscription!.toJson()));
  }
}
