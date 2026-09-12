import 'package:flutter/material.dart';

// ─── Statut Ordonnance ────────────────────────────────────────────────────────
enum StatutOrdonnance {
  enAttente,
  validee,
  refusee,
  payee,
  prete,
  livree,
}

extension StatutOrdonnanceExt on StatutOrdonnance {
  String get label {
    switch (this) {
      case StatutOrdonnance.enAttente: return 'En attente';
      case StatutOrdonnance.validee:   return 'Validée';
      case StatutOrdonnance.refusee:   return 'Refusée';
      case StatutOrdonnance.payee:     return 'Payée';
      case StatutOrdonnance.prete:     return 'Prête';
      case StatutOrdonnance.livree:    return 'Livrée';
    }
  }

  Color get color {
    switch (this) {
      case StatutOrdonnance.enAttente: return const Color(0xFFF39C12);
      case StatutOrdonnance.validee:   return const Color(0xFF2196F3);
      case StatutOrdonnance.refusee:   return const Color(0xFFE74C3C);
      case StatutOrdonnance.payee:     return const Color(0xFF9C27B0);
      case StatutOrdonnance.prete:     return const Color(0xFF2E7D32);
      case StatutOrdonnance.livree:    return const Color(0xFF607D8B);
    }
  }

  IconData get icon {
    switch (this) {
      case StatutOrdonnance.enAttente: return Icons.hourglass_empty_rounded;
      case StatutOrdonnance.validee:   return Icons.check_circle_outline_rounded;
      case StatutOrdonnance.refusee:   return Icons.cancel_outlined;
      case StatutOrdonnance.payee:     return Icons.payment_rounded;
      case StatutOrdonnance.prete:     return Icons.medication_rounded;
      case StatutOrdonnance.livree:    return Icons.done_all_rounded;
    }
  }
}

// ─── Médicament prescrit ──────────────────────────────────────────────────────
class MedicamentPrescrit {
  final String nom;
  final String dosage;
  final String posologie;
  final int dureeJours;
  final String? instructions;
  final bool disponible;
  final double? prixUnitaire;

  const MedicamentPrescrit({
    required this.nom,
    required this.dosage,
    required this.posologie,
    required this.dureeJours,
    this.instructions,
    this.disponible = true,
    this.prixUnitaire,
  });

  Map<String, dynamic> toJson() => {
    'nom': nom,
    'dosage': dosage,
    'posologie': posologie,
    'duree_jours': dureeJours,
    'instructions': instructions,
    'disponible': disponible,
    'prix_unitaire': prixUnitaire,
  };
}

// ─── Modèle Ordonnance ────────────────────────────────────────────────────────
class OrdonnanceModel {
  final String id;
  final String patientId;
  final String patientNom;
  final String patientPrenom;
  final String? patientTelephone;
  final String? patientCmuNumber;
  final String medecinId;
  final String medecinNom;
  final String medecinSpecialite;
  final String? pharmacieId;
  final List<MedicamentPrescrit> medicaments;
  final String instructionsGenerales;
  final DateTime dateEmission;
  final DateTime dateExpiration;
  final StatutOrdonnance statut;
  final double? montantTotal;
  final String? motifRefus;
  final String? qrCodeData;
  final bool remboursableCmu;
  final double? tauxRemboursement;

  OrdonnanceModel({
    required this.id,
    required this.patientId,
    required this.patientNom,
    required this.patientPrenom,
    this.patientTelephone,
    this.patientCmuNumber,
    required this.medecinId,
    required this.medecinNom,
    required this.medecinSpecialite,
    this.pharmacieId,
    required this.medicaments,
    required this.instructionsGenerales,
    required this.dateEmission,
    required this.dateExpiration,
    this.statut = StatutOrdonnance.enAttente,
    this.montantTotal,
    this.motifRefus,
    this.qrCodeData,
    this.remboursableCmu = false,
    this.tauxRemboursement,
  });

  String get patientNomComplet => '$patientPrenom $patientNom';
  bool get estExpiree => DateTime.now().isAfter(dateExpiration);
  int get nombreMedicaments => medicaments.length;

  OrdonnanceModel copyWith({
    String? pharmacieId,
    StatutOrdonnance? statut,
    double? montantTotal,
    String? motifRefus,
  }) {
    return OrdonnanceModel(
      id: id,
      patientId: patientId,
      patientNom: patientNom,
      patientPrenom: patientPrenom,
      patientTelephone: patientTelephone,
      patientCmuNumber: patientCmuNumber,
      medecinId: medecinId,
      medecinNom: medecinNom,
      medecinSpecialite: medecinSpecialite,
      pharmacieId: pharmacieId ?? this.pharmacieId,
      medicaments: medicaments,
      instructionsGenerales: instructionsGenerales,
      dateEmission: dateEmission,
      dateExpiration: dateExpiration,
      statut: statut ?? this.statut,
      montantTotal: montantTotal ?? this.montantTotal,
      motifRefus: motifRefus ?? this.motifRefus,
      qrCodeData: qrCodeData,
      remboursableCmu: remboursableCmu,
      tauxRemboursement: tauxRemboursement,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'patient_id': patientId,
    'patient_nom': patientNom,
    'patient_prenom': patientPrenom,
    'patient_telephone': patientTelephone,
    'patient_cmu_number': patientCmuNumber,
    'medecin_id': medecinId,
    'medecin_nom': medecinNom,
    'medecin_specialite': medecinSpecialite,
    'pharmacie_id': pharmacieId,
    'medicaments': medicaments.map((m) => m.toJson()).toList(),
    'instructions_generales': instructionsGenerales,
    'date_emission': dateEmission.toIso8601String(),
    'date_expiration': dateExpiration.toIso8601String(),
    'statut': statut.name,
    'montant_total': montantTotal,
    'motif_refus': motifRefus,
    'remboursable_cmu': remboursableCmu,
    'taux_remboursement': tauxRemboursement,
  };
}

// ─── Données démo ordonnances ──────────────────────────────────────────────────
class OrdonnanceDemo {
  static List<OrdonnanceModel> get ordonnances => [
    OrdonnanceModel(
      id: 'ord_001',
      patientId: 'usr_kouansan',
      patientNom: 'KOUANSAN',
      patientPrenom: 'Echimane Antoine',
      patientTelephone: '+225 07 12 34 56 78',
      patientCmuNumber: 'CMU-CI007252550',
      medecinId: 'doc_001',
      medecinNom: 'Dr. Kouassi Amedée',
      medecinSpecialite: 'Cardiologue',
      pharmacieId: 'pharma_001',
      medicaments: const [
        MedicamentPrescrit(
          nom: 'Amoxicilline',
          dosage: '500mg',
          posologie: '1 comprimé 3x/jour',
          dureeJours: 7,
          instructions: 'Prendre pendant les repas',
          disponible: true,
          prixUnitaire: 2500,
        ),
        MedicamentPrescrit(
          nom: 'Paracétamol',
          dosage: '1000mg',
          posologie: '1 comprimé si douleur, max 3x/jour',
          dureeJours: 5,
          instructions: 'Ne pas dépasser 3g/jour',
          disponible: true,
          prixUnitaire: 800,
        ),
        MedicamentPrescrit(
          nom: 'Ibuprofène',
          dosage: '400mg',
          posologie: '1 comprimé 2x/jour',
          dureeJours: 5,
          instructions: 'Prendre après les repas',
          disponible: true,
          prixUnitaire: 1200,
        ),
      ],
      instructionsGenerales: 'Éviter l\'exposition au soleil. Boire beaucoup d\'eau. Revenir en consultation si les symptômes persistent après 3 jours.',
      dateEmission: DateTime.now().subtract(const Duration(hours: 2)),
      dateExpiration: DateTime.now().add(const Duration(days: 30)),
      statut: StatutOrdonnance.enAttente,
      remboursableCmu: true,
      tauxRemboursement: 80,
    ),
    OrdonnanceModel(
      id: 'ord_002',
      patientId: 'usr_adjoua',
      patientNom: 'ADJOUA',
      patientPrenom: 'Marie',
      patientTelephone: '+225 05 98 76 54 32',
      patientCmuNumber: 'CMU-CI001234567',
      medecinId: 'doc_002',
      medecinNom: 'Dr. Koné Fatoumata',
      medecinSpecialite: 'Pédiatre',
      pharmacieId: 'pharma_001',
      medicaments: const [
        MedicamentPrescrit(
          nom: 'Doliprane Enfant',
          dosage: '250mg',
          posologie: '1 sachet 3x/jour',
          dureeJours: 5,
          disponible: true,
          prixUnitaire: 1500,
        ),
        MedicamentPrescrit(
          nom: 'Smecta',
          dosage: '3g',
          posologie: '1 sachet après chaque selle liquide',
          dureeJours: 3,
          instructions: 'Diluer dans un verre d\'eau',
          disponible: true,
          prixUnitaire: 3000,
        ),
      ],
      instructionsGenerales: 'Hydrater régulièrement l\'enfant. Surveiller la fièvre.',
      dateEmission: DateTime.now().subtract(const Duration(hours: 5)),
      dateExpiration: DateTime.now().add(const Duration(days: 30)),
      statut: StatutOrdonnance.validee,
      montantTotal: 12500,
      remboursableCmu: true,
      tauxRemboursement: 80,
    ),
    OrdonnanceModel(
      id: 'ord_003',
      patientId: 'usr_konan',
      patientNom: 'KONAN',
      patientPrenom: 'Koffi',
      patientTelephone: '+225 01 23 45 67 89',
      medecinId: 'doc_003',
      medecinNom: 'Dr. Bamba Ibrahim',
      medecinSpecialite: 'Généraliste',
      pharmacieId: 'pharma_001',
      medicaments: const [
        MedicamentPrescrit(
          nom: 'Métformine',
          dosage: '850mg',
          posologie: '1 comprimé 2x/jour',
          dureeJours: 30,
          instructions: 'À prendre au milieu des repas',
          disponible: true,
          prixUnitaire: 4500,
        ),
        MedicamentPrescrit(
          nom: 'Amlodipine',
          dosage: '5mg',
          posologie: '1 comprimé le matin',
          dureeJours: 30,
          disponible: false,
          prixUnitaire: 6000,
        ),
      ],
      instructionsGenerales: 'Contrôle glycémique obligatoire dans 15 jours. Régime pauvre en sucre.',
      dateEmission: DateTime.now().subtract(const Duration(days: 1)),
      dateExpiration: DateTime.now().add(const Duration(days: 29)),
      statut: StatutOrdonnance.payee,
      montantTotal: 28500,
      remboursableCmu: false,
    ),
    OrdonnanceModel(
      id: 'ord_004',
      patientId: 'usr_akissi',
      patientNom: 'AKISSI',
      patientPrenom: 'Bernadette',
      patientTelephone: '+225 07 77 88 99 00',
      patientCmuNumber: 'CMU-CI009876543',
      medecinId: 'doc_001',
      medecinNom: 'Dr. Kouassi Amedée',
      medecinSpecialite: 'Cardiologue',
      pharmacieId: 'pharma_001',
      medicaments: const [
        MedicamentPrescrit(
          nom: 'Lisinopril',
          dosage: '10mg',
          posologie: '1 comprimé/jour',
          dureeJours: 30,
          disponible: true,
          prixUnitaire: 8000,
        ),
        MedicamentPrescrit(
          nom: 'Aspirine cardio',
          dosage: '100mg',
          posologie: '1 comprimé/jour le soir',
          dureeJours: 30,
          disponible: true,
          prixUnitaire: 2000,
        ),
      ],
      instructionsGenerales: 'Surveillance tension artérielle quotidienne. Ne pas arrêter le traitement sans avis médical.',
      dateEmission: DateTime.now().subtract(const Duration(hours: 1)),
      dateExpiration: DateTime.now().add(const Duration(days: 30)),
      statut: StatutOrdonnance.prete,
      montantTotal: 30000,
      remboursableCmu: true,
      tauxRemboursement: 60,
    ),
  ];
}
