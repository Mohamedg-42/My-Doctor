// ─── Modèle CMU-CI ─────────────────────────────────────────────────────────

class CmuCard {
  final String cmuNumber;
  final String lastName;
  final String firstName;
  final String gender;
  final String profession;
  final String commune;
  final String city;
  final DateTime birthDate;
  final DateTime issueDate;
  final DateTime expiryDate;
  final String? photoUrl;
  final String? photoBase64; // Photo locale en base64 (prioritaire sur photoUrl)
  final bool isActive;

  CmuCard({
    required this.cmuNumber,
    required this.lastName,
    required this.firstName,
    required this.gender,
    required this.profession,
    required this.commune,
    required this.city,
    required this.birthDate,
    required this.issueDate,
    required this.expiryDate,
    this.photoUrl,
    this.photoBase64,
    this.isActive = true,
  });

  String get fullName => '$lastName $firstName';

  String get formattedBirthDate =>
      '${birthDate.day.toString().padLeft(2, '0')}/${birthDate.month.toString().padLeft(2, '0')}/${birthDate.year}';

  String get formattedIssueDate =>
      '${issueDate.day.toString().padLeft(2, '0')}/${issueDate.month.toString().padLeft(2, '0')}/${issueDate.year}';

  String get formattedExpiryDate =>
      '${expiryDate.day.toString().padLeft(2, '0')}/${expiryDate.month.toString().padLeft(2, '0')}/${expiryDate.year}';

  bool get isExpired => expiryDate.isBefore(DateTime.now());
}

// ─── Données de santé ─────────────────────────────────────────────────────────

enum HealthMetricType { bloodPressure, bloodSugar, heartRate, weight, temperature, oxygenSaturation }

class HealthMetric {
  final String id;
  final HealthMetricType type;
  final double value;
  final double? value2; // Pour tension: systolique/diastolique
  final String unit;
  final DateTime recordedAt;
  final String? note;

  HealthMetric({
    required this.id,
    required this.type,
    required this.value,
    this.value2,
    required this.unit,
    required this.recordedAt,
    this.note,
  });

  String get label {
    switch (type) {
      case HealthMetricType.bloodPressure:
        return 'Tension artérielle';
      case HealthMetricType.bloodSugar:
        return 'Glycémie';
      case HealthMetricType.heartRate:
        return 'Fréquence cardiaque';
      case HealthMetricType.weight:
        return 'Poids';
      case HealthMetricType.temperature:
        return 'Température';
      case HealthMetricType.oxygenSaturation:
        return 'Saturation O2';
    }
  }

  String get displayValue {
    if (type == HealthMetricType.bloodPressure && value2 != null) {
      return '${value.toInt()}/${value2!.toInt()}';
    }
    return value.toStringAsFixed(type == HealthMetricType.weight ? 1 : 0);
  }

  String get statusLabel {
    switch (type) {
      case HealthMetricType.bloodPressure:
        if (value < 90 || value2 != null && value2! < 60) return 'Basse';
        if (value <= 120 && (value2 == null || value2! <= 80)) return 'Normale';
        if (value <= 139 || (value2 != null && value2! <= 89)) return 'Élevée';
        return 'Haute';
      case HealthMetricType.bloodSugar:
        if (value < 0.7) return 'Hypoglycémie';
        if (value <= 1.10) return 'Normale';
        if (value <= 1.26) return 'Pré-diabète';
        return 'Diabète';
      case HealthMetricType.heartRate:
        if (value < 60) return 'Bradycardie';
        if (value <= 100) return 'Normale';
        return 'Tachycardie';
      case HealthMetricType.oxygenSaturation:
        if (value >= 95) return 'Normale';
        if (value >= 90) return 'Faible';
        return 'Critique';
      default:
        return 'Enregistré';
    }
  }
}

// ─── Prestation CMU ───────────────────────────────────────────────────────────

class CmuBenefit {
  final String category;
  final String title;
  final String description;
  final double coveragePercent;
  final double? maxAmount;

  CmuBenefit({
    required this.category,
    required this.title,
    required this.description,
    required this.coveragePercent,
    this.maxAmount,
  });
}

// ─── Comparaison de coûts ─────────────────────────────────────────────────────

class CostComparison {
  final String careType;
  final String description;
  final double withoutCmu;
  final double withCmu;
  final String category;

  CostComparison({
    required this.careType,
    required this.description,
    required this.withoutCmu,
    required this.withCmu,
    required this.category,
  });

  double get savings => withoutCmu - withCmu;
  double get savingsPercent => withoutCmu > 0 ? (savings / withoutCmu) * 100 : 0;
}

// ─── Demande/réclamation CMU ──────────────────────────────────────────────────

enum CmuRequestStatus { pending, inProgress, resolved, rejected }

class CmuRequest {
  final String id;
  final String type;
  final String description;
  final CmuRequestStatus status;
  final DateTime createdAt;
  final String? response;

  CmuRequest({
    required this.id,
    required this.type,
    required this.description,
    required this.status,
    required this.createdAt,
    this.response,
  });

  String get statusLabel {
    switch (status) {
      case CmuRequestStatus.pending: return 'En attente';
      case CmuRequestStatus.inProgress: return 'En cours';
      case CmuRequestStatus.resolved: return 'Résolu';
      case CmuRequestStatus.rejected: return 'Rejeté';
    }
  }
}
