import 'package:flutter/material.dart';

// ─── Opérateur Mobile Money ───────────────────────────────────────────────────
enum OperateurMobileMoney {
  orangeMoney,
  wave,
  moovMoney,
  mtnMoney,
}

extension OperateurExt on OperateurMobileMoney {
  String get nom {
    switch (this) {
      case OperateurMobileMoney.orangeMoney: return 'Orange Money';
      case OperateurMobileMoney.wave:        return 'Wave';
      case OperateurMobileMoney.moovMoney:   return 'Moov Money';
      case OperateurMobileMoney.mtnMoney:    return 'MTN Money';
    }
  }

  Color get couleur {
    switch (this) {
      case OperateurMobileMoney.orangeMoney: return const Color(0xFFFF7900);
      case OperateurMobileMoney.wave:        return const Color(0xFF1B96F3);
      case OperateurMobileMoney.moovMoney:   return const Color(0xFF8B2FC9);
      case OperateurMobileMoney.mtnMoney:    return const Color(0xFFFFCC00);
    }
  }

  Color get couleurTexte {
    switch (this) {
      case OperateurMobileMoney.mtnMoney: return Colors.black87;
      default:                            return Colors.white;
    }
  }

  IconData get icone {
    switch (this) {
      case OperateurMobileMoney.orangeMoney: return Icons.phone_android_rounded;
      case OperateurMobileMoney.wave:        return Icons.waves_rounded;
      case OperateurMobileMoney.moovMoney:   return Icons.mobile_friendly_rounded;
      case OperateurMobileMoney.mtnMoney:    return Icons.signal_cellular_alt_rounded;
    }
  }

  String get prefixe {
    switch (this) {
      case OperateurMobileMoney.orangeMoney: return '07, 08, 09';
      case OperateurMobileMoney.wave:        return '01, 05, 07';
      case OperateurMobileMoney.moovMoney:   return '01, 02';
      case OperateurMobileMoney.mtnMoney:    return '05, 06';
    }
  }
}

// ─── Statut Paiement ──────────────────────────────────────────────────────────
enum StatutPaiement { initie, enCours, confirme, echoue }

extension StatutPaiementExt on StatutPaiement {
  String get label {
    switch (this) {
      case StatutPaiement.initie:   return 'Initié';
      case StatutPaiement.enCours:  return 'En cours';
      case StatutPaiement.confirme: return 'Confirmé';
      case StatutPaiement.echoue:   return 'Échoué';
    }
  }

  Color get couleur {
    switch (this) {
      case StatutPaiement.initie:   return const Color(0xFFF39C12);
      case StatutPaiement.enCours:  return const Color(0xFF2196F3);
      case StatutPaiement.confirme: return const Color(0xFF2E7D32);
      case StatutPaiement.echoue:   return const Color(0xFFE74C3C);
    }
  }
}

// ─── Modèle Paiement Mobile ───────────────────────────────────────────────────
class PaiementMobileModel {
  final String id;
  final String ordonnanceId;
  final String patientId;
  final String pharmacieId;
  final double montantFCFA;
  final OperateurMobileMoney operateur;
  final String numeroTelephone;
  final StatutPaiement statut;
  final DateTime createdAt;
  final String? reference;
  final String? messageErreur;
  final double? montantCmuRembourse;

  PaiementMobileModel({
    required this.id,
    required this.ordonnanceId,
    required this.patientId,
    required this.pharmacieId,
    required this.montantFCFA,
    required this.operateur,
    required this.numeroTelephone,
    this.statut = StatutPaiement.initie,
    required this.createdAt,
    this.reference,
    this.messageErreur,
    this.montantCmuRembourse,
  });

  double get montantNetPatient =>
      montantFCFA - (montantCmuRembourse ?? 0);

  PaiementMobileModel copyWith({
    StatutPaiement? statut,
    String? reference,
    String? messageErreur,
    double? montantCmuRembourse,
  }) {
    return PaiementMobileModel(
      id: id,
      ordonnanceId: ordonnanceId,
      patientId: patientId,
      pharmacieId: pharmacieId,
      montantFCFA: montantFCFA,
      operateur: operateur,
      numeroTelephone: numeroTelephone,
      statut: statut ?? this.statut,
      createdAt: createdAt,
      reference: reference ?? this.reference,
      messageErreur: messageErreur ?? this.messageErreur,
      montantCmuRembourse: montantCmuRembourse ?? this.montantCmuRembourse,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'ordonnance_id': ordonnanceId,
    'patient_id': patientId,
    'pharmacie_id': pharmacieId,
    'montant_fcfa': montantFCFA,
    'operateur': operateur.name,
    'numero_telephone': numeroTelephone,
    'statut': statut.name,
    'created_at': createdAt.toIso8601String(),
    'reference': reference,
    'montant_cmu_rembourse': montantCmuRembourse,
  };
}
