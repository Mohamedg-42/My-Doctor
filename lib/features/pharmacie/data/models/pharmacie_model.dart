import 'package:flutter/material.dart';

// ─── Couleur identitaire Pharmacie ────────────────────────────────────────────
class PharmacieColors {
  static const Color primary = Color(0xFF2E7D32);       // Vert pharmacie
  static const Color primaryLight = Color(0xFF4CAF50);
  static const Color primaryDark = Color(0xFF1B5E20);
  static const Color primaryUltraLight = Color(0xFFE8F5E9);
  static const Color accent = Color(0xFF00BFA5);
  static const LinearGradient gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
  );
}

// ─── Modèle Pharmacie ─────────────────────────────────────────────────────────
class PharmacieModel {
  final String id;
  final String nomPharmacie;
  final String nomTitulaire;
  final String prenomTitulaire;
  final String numeroOrdreOPCI;
  final String numeroLicenceExploitation;
  final String commune;
  final String ville;
  final String adresseComplete;
  final String telephone;
  final String email;
  final String motDePasse;
  final Map<String, String> horaires;
  final bool estDeGarde;
  final String? photoFacadeUrl;
  final String? documentJustificatifUrl;
  final bool estVerifiee;
  final bool accepteOrdonnances;
  final DateTime createdAt;
  final double? latitude;
  final double? longitude;

  PharmacieModel({
    required this.id,
    required this.nomPharmacie,
    required this.nomTitulaire,
    required this.prenomTitulaire,
    required this.numeroOrdreOPCI,
    required this.numeroLicenceExploitation,
    required this.commune,
    this.ville = 'Abidjan',
    required this.adresseComplete,
    required this.telephone,
    required this.email,
    this.motDePasse = '',
    this.horaires = const {},
    this.estDeGarde = false,
    this.photoFacadeUrl,
    this.documentJustificatifUrl,
    this.estVerifiee = false,
    this.accepteOrdonnances = true,
    required this.createdAt,
    this.latitude,
    this.longitude,
  });

  String get nomCompletTitulaire => '$prenomTitulaire $nomTitulaire';
  String get initialesTitulaire {
    final p = prenomTitulaire.isNotEmpty ? prenomTitulaire[0].toUpperCase() : '';
    final n = nomTitulaire.isNotEmpty ? nomTitulaire[0].toUpperCase() : '';
    return '$p$n';
  }

  PharmacieModel copyWith({
    String? nomPharmacie,
    String? nomTitulaire,
    String? prenomTitulaire,
    String? telephone,
    String? email,
    Map<String, String>? horaires,
    bool? estDeGarde,
    bool? accepteOrdonnances,
    bool? estVerifiee,
    String? photoFacadeUrl,
    String? commune,
  }) {
    return PharmacieModel(
      id: id,
      nomPharmacie: nomPharmacie ?? this.nomPharmacie,
      nomTitulaire: nomTitulaire ?? this.nomTitulaire,
      prenomTitulaire: prenomTitulaire ?? this.prenomTitulaire,
      numeroOrdreOPCI: numeroOrdreOPCI,
      numeroLicenceExploitation: numeroLicenceExploitation,
      commune: commune ?? this.commune,
      ville: ville,
      adresseComplete: adresseComplete,
      telephone: telephone ?? this.telephone,
      email: email ?? this.email,
      motDePasse: motDePasse,
      horaires: horaires ?? this.horaires,
      estDeGarde: estDeGarde ?? this.estDeGarde,
      photoFacadeUrl: photoFacadeUrl ?? this.photoFacadeUrl,
      documentJustificatifUrl: documentJustificatifUrl,
      estVerifiee: estVerifiee ?? this.estVerifiee,
      accepteOrdonnances: accepteOrdonnances ?? this.accepteOrdonnances,
      createdAt: createdAt,
      latitude: latitude,
      longitude: longitude,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nom_pharmacie': nomPharmacie,
    'nom_titulaire': nomTitulaire,
    'prenom_titulaire': prenomTitulaire,
    'numero_ordre_opci': numeroOrdreOPCI,
    'numero_licence': numeroLicenceExploitation,
    'commune': commune,
    'ville': ville,
    'adresse': adresseComplete,
    'telephone': telephone,
    'email': email,
    'horaires': horaires,
    'est_de_garde': estDeGarde,
    'photo_facade_url': photoFacadeUrl,
    'document_url': documentJustificatifUrl,
    'est_verifiee': estVerifiee,
    'accepte_ordonnances': accepteOrdonnances,
    'created_at': createdAt.toIso8601String(),
    'latitude': latitude,
    'longitude': longitude,
  };
}

// ─── Données démo ──────────────────────────────────────────────────────────────
class PharmacieDemo {
  static final PharmacieModel pharma1 = PharmacieModel(
    id: 'pharma_001',
    nomPharmacie: 'Pharmacie Centrale de Cocody',
    nomTitulaire: 'KOUAMÉ',
    prenomTitulaire: 'Adjoua',
    numeroOrdreOPCI: '12345',
    numeroLicenceExploitation: 'LIC-2023-0456',
    commune: 'Cocody',
    ville: 'Abidjan',
    adresseComplete: 'Rue des Jardins, face à la mairie, Cocody',
    telephone: '+225 07 10 20 30 40',
    email: 'pharmacie.centrale.cocody@gmail.com',
    motDePasse: 'pharma2025',
    horaires: {
      'Lundi': '08h00 - 21h00',
      'Mardi': '08h00 - 21h00',
      'Mercredi': '08h00 - 21h00',
      'Jeudi': '08h00 - 21h00',
      'Vendredi': '08h00 - 21h00',
      'Samedi': '09h00 - 20h00',
      'Dimanche': 'Fermé',
    },
    estDeGarde: true,
    estVerifiee: true,
    accepteOrdonnances: true,
    createdAt: DateTime(2024, 1, 15),
    latitude: 5.3600,
    longitude: -3.9900,
  );

  static final PharmacieModel pharma2 = PharmacieModel(
    id: 'pharma_002',
    nomPharmacie: 'Pharmacie du Plateau',
    nomTitulaire: 'BAMBA',
    prenomTitulaire: 'Ibrahim',
    numeroOrdreOPCI: '67890',
    numeroLicenceExploitation: 'LIC-2022-0112',
    commune: 'Plateau',
    ville: 'Abidjan',
    adresseComplete: 'Avenue Chardy, Immeuble CCIA, Plateau',
    telephone: '+225 05 30 40 50 60',
    email: 'pharmacie.plateau@medilink.ci',
    motDePasse: 'pharma2025',
    horaires: {
      'Lundi': '07h30 - 22h00',
      'Mardi': '07h30 - 22h00',
      'Mercredi': '07h30 - 22h00',
      'Jeudi': '07h30 - 22h00',
      'Vendredi': '07h30 - 22h00',
      'Samedi': '08h00 - 20h00',
      'Dimanche': '10h00 - 18h00',
    },
    estDeGarde: false,
    estVerifiee: true,
    accepteOrdonnances: true,
    createdAt: DateTime(2023, 6, 10),
    latitude: 5.3210,
    longitude: -4.0170,
  );

  static List<PharmacieModel> get all => [pharma1, pharma2];
}
