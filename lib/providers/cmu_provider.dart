// lib/providers/cmu_provider.dart
//
// Fournit la carte CMU et les données de santé de l'utilisateur connecté.
// Les informations personnelles proviennent du UserModel (AuthProvider),
// pas de données codées en dur.

import 'package:flutter/foundation.dart';
import '../models/cmu_model.dart';
import '../models/user_model.dart';

class CmuProvider extends ChangeNotifier {
  CmuCard? _card;
  List<HealthMetric> _healthMetrics = [];
  List<CmuBenefit> _benefits = [];
  List<CostComparison> _costComparisons = [];
  List<CmuRequest> _requests = [];
  final bool _isLoading = false;

  // Getters
  CmuCard? get card => _card;
  List<HealthMetric> get healthMetrics => _healthMetrics;
  List<HealthMetric> getMetricsByType(HealthMetricType type) =>
      _healthMetrics.where((m) => m.type == type).toList()
        ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
  HealthMetric? getLatestMetric(HealthMetricType type) {
    final list = getMetricsByType(type);
    return list.isNotEmpty ? list.last : null;
  }
  List<CmuBenefit> get benefits => _benefits;
  List<CostComparison> get costComparisons => _costComparisons;
  List<CmuRequest> get requests => _requests;
  bool get isLoading => _isLoading;
  bool get hasCard => _card != null;

  CmuProvider() {
    _initStaticData();
  }

  // ─── Initialisation dynamique depuis le UserModel ──────────────────────────

  /// Appelé dès qu'un utilisateur se connecte pour construire sa carte CMU.
  void initFromUser(UserModel user) {
    if (user.role != UserRole.patient) return;

    _card = CmuCard(
      cmuNumber: user.cmuNumber ?? 'CMU-CI000000000',
      lastName: user.lastName.toUpperCase(),
      firstName: user.firstName,
      gender: user.gender ?? 'Non renseigné',
      profession: user.profession ?? 'Non renseignée',
      commune: user.commune ?? 'Non renseignée',
      city: user.city ?? 'Abidjan',
      birthDate: user.birthDate ?? DateTime(1990, 1, 1),
      issueDate: user.createdAt,
      expiryDate: user.createdAt.add(const Duration(days: 365 * 2)),
      photoUrl: user.avatarUrl,
      photoBase64: user.avatarBase64,  // Photo locale (prise à l'inscription)
      isActive: user.status == AccountStatus.active,
    );

    notifyListeners();
    debugPrint('✅ CmuCard initialisée pour: ${user.fullName} (${user.cmuNumber})');
  }

  /// Réinitialise la carte lors de la déconnexion
  void reset() {
    _card = null;
    notifyListeners();
  }

  // ─── Données de santé (métriques génériques pour tout utilisateur) ──────────

  void _initStaticData() {
    final now = DateTime.now();

    _healthMetrics = [
      // Tension artérielle (7 derniers jours)
      HealthMetric(id: 'hm_001', type: HealthMetricType.bloodPressure, value: 120, value2: 80, unit: 'mmHg', recordedAt: now.subtract(const Duration(days: 6))),
      HealthMetric(id: 'hm_002', type: HealthMetricType.bloodPressure, value: 118, value2: 78, unit: 'mmHg', recordedAt: now.subtract(const Duration(days: 5))),
      HealthMetric(id: 'hm_003', type: HealthMetricType.bloodPressure, value: 125, value2: 82, unit: 'mmHg', recordedAt: now.subtract(const Duration(days: 4))),
      HealthMetric(id: 'hm_004', type: HealthMetricType.bloodPressure, value: 122, value2: 79, unit: 'mmHg', recordedAt: now.subtract(const Duration(days: 3))),
      HealthMetric(id: 'hm_005', type: HealthMetricType.bloodPressure, value: 119, value2: 77, unit: 'mmHg', recordedAt: now.subtract(const Duration(days: 2))),
      HealthMetric(id: 'hm_006', type: HealthMetricType.bloodPressure, value: 117, value2: 76, unit: 'mmHg', recordedAt: now.subtract(const Duration(days: 1))),
      HealthMetric(id: 'hm_007', type: HealthMetricType.bloodPressure, value: 121, value2: 80, unit: 'mmHg', recordedAt: now),
      // Glycémie
      HealthMetric(id: 'hm_008', type: HealthMetricType.bloodSugar, value: 0.95, unit: 'g/L', recordedAt: now.subtract(const Duration(days: 6))),
      HealthMetric(id: 'hm_009', type: HealthMetricType.bloodSugar, value: 0.98, unit: 'g/L', recordedAt: now.subtract(const Duration(days: 4))),
      HealthMetric(id: 'hm_010', type: HealthMetricType.bloodSugar, value: 1.02, unit: 'g/L', recordedAt: now.subtract(const Duration(days: 2))),
      HealthMetric(id: 'hm_011', type: HealthMetricType.bloodSugar, value: 0.97, unit: 'g/L', recordedAt: now),
      // Fréquence cardiaque
      HealthMetric(id: 'hm_012', type: HealthMetricType.heartRate, value: 72, unit: 'bpm', recordedAt: now.subtract(const Duration(days: 5))),
      HealthMetric(id: 'hm_013', type: HealthMetricType.heartRate, value: 75, unit: 'bpm', recordedAt: now.subtract(const Duration(days: 3))),
      HealthMetric(id: 'hm_014', type: HealthMetricType.heartRate, value: 70, unit: 'bpm', recordedAt: now.subtract(const Duration(days: 1))),
      HealthMetric(id: 'hm_015', type: HealthMetricType.heartRate, value: 73, unit: 'bpm', recordedAt: now),
      // Poids
      HealthMetric(id: 'hm_016', type: HealthMetricType.weight, value: 78.5, unit: 'kg', recordedAt: now.subtract(const Duration(days: 14))),
      HealthMetric(id: 'hm_017', type: HealthMetricType.weight, value: 78.2, unit: 'kg', recordedAt: now.subtract(const Duration(days: 7))),
      HealthMetric(id: 'hm_018', type: HealthMetricType.weight, value: 77.9, unit: 'kg', recordedAt: now),
      // Saturation O2
      HealthMetric(id: 'hm_019', type: HealthMetricType.oxygenSaturation, value: 98, unit: '%', recordedAt: now.subtract(const Duration(days: 3))),
      HealthMetric(id: 'hm_020', type: HealthMetricType.oxygenSaturation, value: 97, unit: '%', recordedAt: now.subtract(const Duration(days: 1))),
      HealthMetric(id: 'hm_021', type: HealthMetricType.oxygenSaturation, value: 98, unit: '%', recordedAt: now),
    ];

    _benefits = [
      CmuBenefit(category: 'Consultations', title: 'Consultation généraliste', description: 'Consultation chez un médecin généraliste', coveragePercent: 70, maxAmount: 10000),
      CmuBenefit(category: 'Consultations', title: 'Consultation spécialiste', description: 'Consultation chez un médecin spécialiste', coveragePercent: 60, maxAmount: 15000),
      CmuBenefit(category: 'Hospitalisation', title: 'Frais de séjour', description: 'Frais d\'hospitalisation en chambre commune', coveragePercent: 80, maxAmount: 500000),
      CmuBenefit(category: 'Hospitalisation', title: 'Actes chirurgicaux', description: 'Interventions chirurgicales couvertes', coveragePercent: 75, maxAmount: 800000),
      CmuBenefit(category: 'Médicaments', title: 'Médicaments essentiels', description: 'Médicaments sur la liste CMU', coveragePercent: 80, maxAmount: 50000),
      CmuBenefit(category: 'Médicaments', title: 'Médicaments chroniques', description: 'Traitements longue durée', coveragePercent: 90, maxAmount: 100000),
      CmuBenefit(category: 'Examens', title: 'Analyses biologiques', description: 'Examens de laboratoire prescrits', coveragePercent: 70, maxAmount: 30000),
      CmuBenefit(category: 'Examens', title: 'Radiologie / Imagerie', description: 'Radio, échographie, scanner', coveragePercent: 65, maxAmount: 80000),
      CmuBenefit(category: 'Maternité', title: 'Suivi de grossesse', description: 'Consultations prénatales et accouchement', coveragePercent: 100, maxAmount: 300000),
      CmuBenefit(category: 'Urgences', title: 'Soins d\'urgence', description: 'Urgences médicales et SAMU', coveragePercent: 100, maxAmount: 200000),
    ];

    _costComparisons = [
      CostComparison(careType: 'Consultation généraliste', description: 'Visite chez le médecin traitant', withoutCmu: 10000, withCmu: 3000, category: 'Consultation'),
      CostComparison(careType: 'Consultation cardiologue', description: 'Spécialiste cardiologie', withoutCmu: 25000, withCmu: 10000, category: 'Consultation'),
      CostComparison(careType: 'Consultation pédiatre', description: 'Spécialiste enfants', withoutCmu: 20000, withCmu: 8000, category: 'Consultation'),
      CostComparison(careType: 'Hospitalisation 3 jours', description: 'Séjour en chambre commune', withoutCmu: 150000, withCmu: 30000, category: 'Hospitalisation'),
      CostComparison(careType: 'Appendicite (opération)', description: 'Chirurgie + hospitalisation', withoutCmu: 500000, withCmu: 125000, category: 'Hospitalisation'),
      CostComparison(careType: 'Paracétamol 500mg x30', description: 'Antalgique courant', withoutCmu: 2000, withCmu: 400, category: 'Médicaments'),
      CostComparison(careType: 'Amoxicilline 500mg x21', description: 'Antibiotique', withoutCmu: 8000, withCmu: 1600, category: 'Médicaments'),
      CostComparison(careType: 'Prise de sang complète', description: 'NFS + bilan métabolique', withoutCmu: 25000, withCmu: 7500, category: 'Examens'),
      CostComparison(careType: 'Échographie abdominale', description: 'Imagerie médicale', withoutCmu: 40000, withCmu: 14000, category: 'Examens'),
      CostComparison(careType: 'Accouchement normal', description: 'Maternité + séjour 3j', withoutCmu: 200000, withCmu: 0, category: 'Maternité'),
    ];

    _requests = [
      CmuRequest(
        id: 'req_001',
        type: 'Remboursement',
        description: 'Demande de remboursement consultation du 15/01/2025',
        status: CmuRequestStatus.resolved,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        response: 'Remboursement de 7 000 F CFA effectué sur Orange Money le 25/01/2025',
      ),
      CmuRequest(
        id: 'req_002',
        type: 'Mise à jour dossier',
        description: 'Changement d\'adresse suite à déménagement',
        status: CmuRequestStatus.inProgress,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];
  }

  // ─── Méthodes ───────────────────────────────────────────────────────────────

  void addHealthMetric(HealthMetric metric) {
    _healthMetrics.add(metric);
    notifyListeners();
  }

  void addRequest(CmuRequest request) {
    _requests.insert(0, request);
    notifyListeners();
  }

  Map<String, double> getHealthSummary() {
    final bp     = getLatestMetric(HealthMetricType.bloodPressure);
    final sugar  = getLatestMetric(HealthMetricType.bloodSugar);
    final hr     = getLatestMetric(HealthMetricType.heartRate);
    final weight = getLatestMetric(HealthMetricType.weight);
    return {
      'systolic':   bp?.value ?? 0,
      'diastolic':  bp?.value2 ?? 0,
      'bloodSugar': sugar?.value ?? 0,
      'heartRate':  hr?.value ?? 0,
      'weight':     weight?.value ?? 0,
    };
  }

  double get totalSavings =>
      _costComparisons.fold(0, (sum, c) => sum + c.savings);

  Map<String, double> get savingsByCategory {
    final map = <String, double>{};
    for (final c in _costComparisons) {
      map[c.category] = (map[c.category] ?? 0) + c.savings;
    }
    return map;
  }
}
