// lib/models/patient_subscription_model.dart
//
// Modèle des abonnements santé patient et gestion de la famille
// Conforme aux spécifications exactes de l'application My Doctor.

import 'package:flutter/material.dart';

enum PatientPlanType {
  gratuit,
  essentiel,
  confort,
  famille,
}

enum SubscriptionBillingCycle {
  mensuel,
  annuel,
}

/// Modèle d'un membre de la famille rattaché à l'abonnement Famille (max 6)
class FamilyMember {
  final String id;
  final String fullName;
  final String relationship;
  final String? cmuNumber;
  final DateTime? birthDate;

  FamilyMember({
    required this.id,
    required this.fullName,
    required this.relationship,
    this.cmuNumber,
    this.birthDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'relationship': relationship,
      'cmuNumber': cmuNumber,
      'birthDate': birthDate?.toIso8601String(),
    };
  }

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      relationship: json['relationship'] as String? ?? 'Autre proche',
      cmuNumber: json['cmuNumber'] as String?,
      birthDate: json['birthDate'] != null
          ? DateTime.tryParse(json['birthDate'] as String)
          : null,
    );
  }
}

/// Modèle d'une formule d'abonnement santé patient
class PatientSubscriptionPlan {
  final String id;
  final PatientPlanType type;
  final String name;
  final String tagline;
  final int monthlyPrice;
  final int yearlyPrice;
  final String? badge;
  final Color accentColor;
  final IconData icon;
  final int maxFamilyMembers;
  final int teleconsultationsIncluded;
  final List<String> features;
  final List<String> highlightedPerks;

  const PatientSubscriptionPlan({
    required this.id,
    required this.type,
    required this.name,
    required this.tagline,
    required this.monthlyPrice,
    required this.yearlyPrice,
    this.badge,
    required this.accentColor,
    required this.icon,
    required this.maxFamilyMembers,
    required this.teleconsultationsIncluded,
    required this.features,
    required this.highlightedPerks,
  });

  bool get isFree => monthlyPrice == 0;

  int priceFor(SubscriptionBillingCycle cycle) {
    return cycle == SubscriptionBillingCycle.annuel
        ? yearlyPrice
        : monthlyPrice;
  }

  String priceFormatted(SubscriptionBillingCycle cycle) {
    final price = priceFor(cycle);
    final formattedPrice = _formatAmountWithSpaces(price);
    if (cycle == SubscriptionBillingCycle.annuel) {
      return '$formattedPrice FCFA/an';
    }
    return '$formattedPrice FCFA/mois';
  }

  static String _formatAmountWithSpaces(int amount) {
    final s = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(s[i]);
    }
    return buffer.toString();
  }

  static List<PatientSubscriptionPlan> get defaultPlans => [
        // 1. Plan Gratuit
        const PatientSubscriptionPlan(
          id: 'gratuit',
          type: PatientPlanType.gratuit,
          name: 'Plan Gratuit',
          tagline: "L'accès essentiel à la santé en ligne",
          monthlyPrice: 0,
          yearlyPrice: 0,
          badge: 'Découverte',
          accentColor: Color(0xFF64748B), // gris ardoise
          icon: Icons.shield_outlined,
          maxFamilyMembers: 1,
          teleconsultationsIncluded: 0,
          features: [
            'Carte CMU digitale sécurisée',
            'Prise de rendez-vous en cabinet & clinique',
            'Téléconsultation avec paiement à l’acte',
            '1 profil patient personnel',
            'Rappels SMS de rendez-vous',
            'Recherche géolocalisée de pharmacies de garde',
          ],
          highlightedPerks: [
            'Carte CMU incluse à vie',
            'Sans engagement, 100% gratuit',
          ],
        ),

        // 2. Plan Essentiel
        const PatientSubscriptionPlan(
          id: 'essentiel',
          type: PatientPlanType.essentiel,
          name: 'Plan Essentiel',
          tagline: 'Pour un suivi médical régulier et connecté',
          monthlyPrice: 1500,
          yearlyPrice: 15000,
          badge: 'Économique',
          accentColor: Color(0xFF185FA5), // bleu
          icon: Icons.medical_services_rounded,
          maxFamilyMembers: 1,
          teleconsultationsIncluded: 1,
          features: [
            'Tout ce qui est inclus dans le Plan Gratuit',
            '1 téléconsultation offerte par mois, valeur 5 000 FCFA',
            'Messagerie directe sécurisée avec les médecins',
            'Dossier médical cloud et prescriptions électroniques',
            'Rappels automatiques de prises d’ordonnances',
            'Support client dédié 7j/7',
          ],
          highlightedPerks: [
            '1 téléconsultation gratuite par mois',
            'Messagerie directe avec le médecin traitant',
          ],
        ),

        // 3. Plan Confort
        const PatientSubscriptionPlan(
          id: 'confort',
          type: PatientPlanType.confort,
          name: 'Plan Confort',
          tagline: 'La formule individuelle complète & prioritaire',
          monthlyPrice: 3500,
          yearlyPrice: 35000,
          badge: 'Le Plus Choisi',
          accentColor: Color(0xFF0D9488), // vert turquoise
          icon: Icons.favorite_rounded,
          maxFamilyMembers: 1,
          teleconsultationsIncluded: 3,
          features: [
            'Tout ce qui est inclus dans le Plan Essentiel',
            '3 téléconsultations complètes incluses chaque mois',
            'Ligne prioritaire Urgences & SAMU 24h/24',
            'Suivi intelligent des constantes, notamment tension et glycémie',
            'Historique et archivage illimité des examens de laboratoire',
            'Remises exclusives jusqu’à -15% en pharmacies partenaires',
            'Télé-expertise auprès de spécialistes',
          ],
          highlightedPerks: [
            '3 téléconsultations incluses par mois',
            'Accès prioritaire 24h/24 et réductions pharmacie',
          ],
        ),

        // 4. Plan Famille
        const PatientSubscriptionPlan(
          id: 'famille',
          type: PatientPlanType.famille,
          name: 'Plan Famille',
          tagline:
              'Sérénité totale pour toute votre famille jusqu’à 6 personnes',
          monthlyPrice: 6500,
          yearlyPrice: 65000,
          badge: 'Pack Famille (Jusqu’à 6)',
          accentColor: Color(0xFFEA580C), // orange doré
          icon: Icons.people_rounded,
          maxFamilyMembers: 6,
          teleconsultationsIncluded: 6,
          features: [
            'Couverture complète pour 6 membres : conjoint, enfants, parents',
            '6 téléconsultations partagées par mois pour la famille',
            'Carnet de santé et vaccination pédiatrique pour les enfants',
            'Cartes CMU centralisées pour tous les membres du foyer',
            'Assistance médicale SOS Famille prioritaire 24/7',
            'Consultations pédiatriques et gynécologiques prioritaires',
            'Partage simplifié des bilans de santé aux proches',
            'Économie de deux mois complets en paiement annuel',
          ],
          highlightedPerks: [
            'Jusqu’à 6 personnes couvertes',
            '6 téléconsultations par mois et suivi pédiatrique',
          ],
        ),
      ];
}

/// Modèle d'état d'abonnement actif d'un patient
class PatientSubscription {
  final String patientId;
  final String planId;
  final SubscriptionBillingCycle cycle;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final String paymentMethod;
  final List<FamilyMember> familyMembers;

  PatientSubscription({
    required this.patientId,
    required this.planId,
    required this.cycle,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    required this.paymentMethod,
    this.familyMembers = const [],
  });

  bool get isExpired => DateTime.now().isAfter(endDate);
  bool get isFree => planId == 'gratuit';

  PatientSubscription copyWith({
    String? patientId,
    String? planId,
    SubscriptionBillingCycle? cycle,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    String? paymentMethod,
    List<FamilyMember>? familyMembers,
  }) {
    return PatientSubscription(
      patientId: patientId ?? this.patientId,
      planId: planId ?? this.planId,
      cycle: cycle ?? this.cycle,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      familyMembers: familyMembers ?? this.familyMembers,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patientId': patientId,
      'planId': planId,
      'cycle': cycle == SubscriptionBillingCycle.annuel ? 'annuel' : 'mensuel',
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isActive': isActive,
      'paymentMethod': paymentMethod,
      'familyMembers': familyMembers.map((m) => m.toJson()).toList(),
    };
  }

  factory PatientSubscription.fromJson(Map<String, dynamic> json) {
    final rawMembers = json['familyMembers'] as List<dynamic>? ?? [];
    return PatientSubscription(
      patientId: json['patientId'] as String? ?? '',
      planId: json['planId'] as String? ?? 'gratuit',
      cycle: json['cycle'] == 'annuel'
          ? SubscriptionBillingCycle.annuel
          : SubscriptionBillingCycle.mensuel,
      startDate: json['startDate'] != null
          ? (DateTime.tryParse(json['startDate'] as String) ?? DateTime.now())
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? (DateTime.tryParse(json['endDate'] as String) ??
              DateTime.now().add(const Duration(days: 365 * 99)))
          : DateTime.now().add(const Duration(days: 365 * 99)),
      isActive: json['isActive'] as bool? ?? true,
      paymentMethod: json['paymentMethod'] as String? ?? 'Gratuit',
      familyMembers: rawMembers
          .map((m) => FamilyMember.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}
