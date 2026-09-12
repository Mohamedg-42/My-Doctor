// lib/services/database_service.dart
//
// Service de base de données locale utilisant Hive.
// Gère la persistance des comptes patients, médecins et pharmacies.

import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/appointment_model.dart';
import 'supabase_service.dart';

// ─── Constantes des boxes Hive ────────────────────────────────────────────────
class _Boxes {
  static const String users        = 'users_v1';
  static const String doctors      = 'doctors_v1';
  static const String sessions     = 'sessions_v1';
  static const String messageUsage = 'message_usage_v1';
  static const String appointments = 'appointments_v1';
}

// ─── Modèles de stockage ──────────────────────────────────────────────────────

/// Représentation complète d'un utilisateur stocké en base
class DbUser {
  final String id;
  final String role; // 'patient' | 'doctor' | 'admin'
  final String email;
  final String phone;
  final String passwordHash;
  final String firstName;
  final String lastName;
  final String? avatarUrl;      // URL réseau (comptes démo)
  final String? avatarBase64;   // Photo locale en base64 (comptes réels)
  final String status;          // 'pending' | 'active' | 'suspended'
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  // Patient-only
  final String? cmuNumber;
  final String? birthDate;
  final String? gender;
  final String? profession;
  final String? commune;
  final String? city;
  // Patient-only — pièces jointes
  // Chaque élément : {'name': 'CNI.pdf', 'base64': '...', 'mimeType': 'application/pdf'}
  final List<Map<String, String>>? attachments;
  // Doctor-only
  final String? specialty;
  final String? orderNumber;
  final String? bio;

  DbUser({
    required this.id,
    required this.role,
    required this.email,
    required this.phone,
    required this.passwordHash,
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
    this.avatarBase64,
    required this.status,
    required this.createdAt,
    this.lastLoginAt,
    this.cmuNumber,
    this.birthDate,
    this.gender,
    this.profession,
    this.commune,
    this.city,
    this.attachments,
    this.specialty,
    this.orderNumber,
    this.bio,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'role': role,
    'email': email,
    'phone': phone,
    'passwordHash': passwordHash,
    'firstName': firstName,
    'lastName': lastName,
    'avatarUrl': avatarUrl,
    'avatarBase64': avatarBase64,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
    'lastLoginAt': lastLoginAt?.toIso8601String(),
    'cmuNumber': cmuNumber,
    'birthDate': birthDate,
    'gender': gender,
    'profession': profession,
    'commune': commune,
    'city': city,
    'attachments': attachments,
    'specialty': specialty,
    'orderNumber': orderNumber,
    'bio': bio,
  };

  factory DbUser.fromMap(Map<dynamic, dynamic> m) => DbUser(
    id: m['id'] ?? '',
    role: m['role'] ?? 'patient',
    email: m['email'] ?? '',
    phone: m['phone'] ?? '',
    passwordHash: m['passwordHash'] ?? '',
    firstName: m['firstName'] ?? '',
    lastName: m['lastName'] ?? '',
    avatarUrl: m['avatarUrl'],
    avatarBase64: m['avatarBase64'],
    status: m['status'] ?? 'active',
    createdAt: DateTime.tryParse(m['createdAt'] ?? '') ?? DateTime.now(),
    lastLoginAt: m['lastLoginAt'] != null
        ? DateTime.tryParse(m['lastLoginAt'])
        : null,
    cmuNumber: m['cmuNumber'],
    birthDate: m['birthDate'],
    gender: m['gender'],
    profession: m['profession'],
    commune: m['commune'],
    city: m['city'],
    attachments: (m['attachments'] as List?)?.map((e) {
      final entry = e as Map;
      return <String, String>{
        'name': (entry['name'] ?? '') as String,
        'base64': (entry['base64'] ?? '') as String,
        'mimeType': (entry['mimeType'] ?? '') as String,
      };
    }).toList(),
    specialty: m['specialty'],
    orderNumber: m['orderNumber'],
    bio: m['bio'],
  );

  DbUser copyWith({
    String? status,
    String? avatarUrl,
    String? avatarBase64,
    DateTime? lastLoginAt,
    String? bio,
    List<Map<String, String>>? attachments,
    String? firstName,
    String? lastName,
    String? phone,
    String? birthDate,
    String? gender,
    String? city,
    String? commune,
    String? profession,
    String? cmuNumber,
    String? specialty,
    String? orderNumber,
  }) => DbUser(
    id: id,
    role: role,
    email: email,
    phone: phone ?? this.phone,
    passwordHash: passwordHash,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    avatarBase64: avatarBase64 ?? this.avatarBase64,
    status: status ?? this.status,
    createdAt: createdAt,
    lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    cmuNumber: cmuNumber ?? this.cmuNumber,
    birthDate: birthDate ?? this.birthDate,
    gender: gender ?? this.gender,
    profession: profession ?? this.profession,
    commune: commune ?? this.commune,
    city: city ?? this.city,
    attachments: attachments ?? this.attachments,
    specialty: specialty ?? this.specialty,
    orderNumber: orderNumber ?? this.orderNumber,
    bio: bio ?? this.bio,
  );
}

/// Modèle pour le suivi sécurisé des messages gratuits par patient
class PatientMessageUsage {
  final String patientId;
  final int freeMessagesLimit;
  final int freeMessagesUsed;
  final DateTime? firstMessageAt;
  final DateTime updatedAt;

  PatientMessageUsage({
    required this.patientId,
    this.freeMessagesLimit = 10,
    this.freeMessagesUsed = 0,
    this.firstMessageAt,
    required this.updatedAt,
  });

  int get remaining => (freeMessagesLimit - freeMessagesUsed).clamp(0, freeMessagesLimit);
  bool get canSend => remaining > 0;
  bool get isBlocked => remaining <= 0;

  PatientMessageUsage copyWith({
    String? patientId,
    int? freeMessagesLimit,
    int? freeMessagesUsed,
    DateTime? firstMessageAt,
    DateTime? updatedAt,
  }) => PatientMessageUsage(
    patientId: patientId ?? this.patientId,
    freeMessagesLimit: freeMessagesLimit ?? this.freeMessagesLimit,
    freeMessagesUsed: freeMessagesUsed ?? this.freeMessagesUsed,
    firstMessageAt: firstMessageAt ?? this.firstMessageAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toMap() => {
    'patientId': patientId,
    'freeMessagesLimit': freeMessagesLimit,
    'freeMessagesUsed': freeMessagesUsed,
    'firstMessageAt': firstMessageAt?.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory PatientMessageUsage.fromMap(Map<dynamic, dynamic> m) => PatientMessageUsage(
    patientId: m['patientId'] ?? '',
    freeMessagesLimit: m['freeMessagesLimit'] ?? 10,
    freeMessagesUsed: m['freeMessagesUsed'] ?? 0,
    firstMessageAt: m['firstMessageAt'] != null ? DateTime.tryParse(m['firstMessageAt']) : null,
    updatedAt: DateTime.tryParse(m['updatedAt'] ?? '') ?? DateTime.now(),
  );
}

// ─── DatabaseService ──────────────────────────────────────────────────────────

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  bool _initialized = false;
  
  // StreamController pour diffuser les changements de la liste des médecins
  final _doctorsStreamController = StreamController<List<DbUser>>.broadcast();
  Stream<List<DbUser>> get doctorsStream => _doctorsStreamController.stream;

  // StreamController pour diffuser les changements de rendez-vous
  final _appointmentsStreamController = StreamController<List<AppointmentModel>>.broadcast();
  Stream<List<AppointmentModel>> get appointmentsStream => _appointmentsStreamController.stream;

  // ─── Initialisation ──────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;

    await Hive.initFlutter('medilink_db');

    await Hive.openBox(_Boxes.users);
    await Hive.openBox(_Boxes.doctors);
    await Hive.openBox(_Boxes.sessions);
    await Hive.openBox(_Boxes.messageUsage);
    await Hive.openBox(_Boxes.appointments);

    // Initialiser les comptes de démonstration Patient et Médecin
    await _seedDefaultAccounts();
    await _seedDefaultAppointments();

    // Écouter les changements de la box users pour actualiser la liste des médecins
    _usersBox.watch().listen((event) {
      _broadcastDoctors();
    });

    // Écouter les changements des rendez-vous
    _appointmentsBox.watch().listen((event) {
      _broadcastAppointments();
    });

    _initialized = true;
    debugPrint('✅ DatabaseService initialisé avec Stream de médecins et rendez-vous');
    
    // Diffuser la liste initiale
    _broadcastDoctors();
    _broadcastAppointments();
  }
  
  /// Diffuse la liste actuelle des médecins via le Stream
  void _broadcastDoctors() {
    final doctors = getAllDoctors();
    _doctorsStreamController.add(doctors);
    debugPrint('📡 Diffusion de ${doctors.length} médecin(s) via Stream');
  }

  /// Diffuse la liste actuelle des rendez-vous via le Stream
  void _broadcastAppointments() {
    final appts = getAllAppointments();
    _appointmentsStreamController.add(appts);
    debugPrint('📡 Diffusion de ${appts.length} rendez-vous via Stream');
  }

  Box get _usersBox        => Hive.box(_Boxes.users);
  Box get _sessionsBox     => Hive.box(_Boxes.sessions);
  Box get _usageBox        => Hive.box(_Boxes.messageUsage);
  Box get _appointmentsBox => Hive.box(_Boxes.appointments);

  // ─── Utilitaires ─────────────────────────────────────────────────────────────

  /// Hash SHA-256 du mot de passe
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  /// Génère un numéro CMU unique
  String _generateCmu() {
    const uuid = Uuid();
    final shortId = uuid.v4().replaceAll('-', '').substring(0, 9);
    return 'CMU-CI$shortId'.toUpperCase();
  }

  /// Génère un ID unique
  String _generateId([String prefix = 'usr']) {
    const uuid = Uuid();
    return '${prefix}_${uuid.v4().substring(0, 8)}';
  }

  // ─── INSCRIPTION PATIENT ──────────────────────────────────────────────────────

  /// Vérifie si un numéro de téléphone existe déjà dans la base
  bool isPhoneRegistered(String phone) {
    return _findUserByPhone(phone) != null;
  }

  /// Inscrit un nouveau patient. Retourne le DbUser créé ou null si email/téléphone déjà utilisé.
  Future<DbUser?> registerPatient({
    String? firstName,
    String? lastName,
    required String phone,
    required String password,
    String? email,
    String? gender,
    String? birthDate,
    String? profession,
    String? commune,
    String? city,
    String? avatarBase64,
    List<Map<String, String>>? attachments,
  }) async {
    // Vérifier l'unicité du téléphone
    final existing = _findUserByPhone(phone);
    if (existing != null) return null; // Compte déjà existant

    // Vérifier email si fourni
    if (email != null && email.isNotEmpty) {
      final byEmail = _findUserByEmail(email);
      if (byEmail != null) return null;
    }

    final id  = _generateId('pat');
    final cmu = _generateCmu();

    final cleanFirstName = (firstName != null && firstName.trim().isNotEmpty)
        ? firstName.trim()
        : 'Patient';
    final cleanLastName = (lastName != null && lastName.trim().isNotEmpty)
        ? lastName.trim()
        : '';

    final user = DbUser(
      id: id,
      role: 'patient',
      email: email ?? '',
      phone: phone.trim(),
      passwordHash: _hashPassword(password),
      firstName: cleanFirstName,
      lastName: cleanLastName,
      avatarBase64: (avatarBase64 != null && avatarBase64.isNotEmpty) ? avatarBase64 : null,
      attachments: (attachments != null && attachments.isNotEmpty) ? attachments : null,
      status: 'active',
      createdAt: DateTime.now(),
      cmuNumber: cmu,
      gender: gender,
      birthDate: birthDate,
      profession: profession,
      commune: commune,
      city: city,
    );

    await _usersBox.put(id, user.toMap());
    debugPrint('✅ Patient enregistré: $id ($cmu)');
    return user;
  }

  // ─── INSCRIPTION MÉDECIN ──────────────────────────────────────────────────────

  /// Inscrit un nouveau médecin. Retourne le DbUser créé ou null si déjà existant.
  Future<DbUser?> registerDoctor({
    required String firstName,
    required String lastName,
    required String phone,
    required String password,
    String? email,
    String? orderNumber,
    String? specialty,
    String? bio,
    String? avatarBase64,
    String? birthDate,
    String status = 'pending',
  }) async {
    // Vérifier l'unicité de l'email si renseigné
    if (email != null && email.trim().isNotEmpty) {
      final byEmail = _findUserByEmail(email.trim());
      if (byEmail != null) return null;
    }

    // Vérifier le téléphone
    final byPhone = _findUserByPhone(phone);
    if (byPhone != null) return null;

    final id = _generateId('doc');

    final user = DbUser(
      id: id,
      role: 'doctor',
      email: email != null ? email.trim().toLowerCase() : '',
      phone: phone.trim(),
      passwordHash: _hashPassword(password),
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      avatarBase64: (avatarBase64 != null && avatarBase64.isNotEmpty) ? avatarBase64 : null,
      status: status, // 'pending' jusqu'à validation par l'administration
      createdAt: DateTime.now(),
      birthDate: birthDate,
      specialty: specialty ?? '',
      orderNumber: orderNumber ?? '',
      bio: bio ?? (specialty != null && specialty.isNotEmpty ? 'Médecin spécialiste en $specialty.' : ''),
    );

    await _usersBox.put(id, user.toMap());
    _doctorsStreamController.add(getAllDoctors());
    debugPrint('✅ Médecin enregistré: $id ($phone, statut: $status)');
    return user;
  }

  // ─── CONNEXION ────────────────────────────────────────────────────────────────

  /// Authentifie un utilisateur. Accepte email, téléphone ou numéro CMU.
  /// Retourne le DbUser ou null si identifiants incorrects.
  Future<DbUser?> login({
    required String identifier,
    required String password,
  }) async {
    final id = identifier.trim();
    final hash = _hashPassword(password);

    DbUser? user;

    // Essai par email
    user = _findUserByEmail(id.toLowerCase());
    // Essai par téléphone
    user ??= _findUserByPhone(id);
    // Essai par CMU
    user ??= _findUserByCmu(id.toUpperCase());

    if (user == null || user.passwordHash != hash) return null;
    if (user.status == 'suspended') return null;

    // Mettre à jour la date de dernière connexion
    final updated = user.copyWith(lastLoginAt: DateTime.now());
    await _usersBox.put(user.id, updated.toMap());

    debugPrint('✅ Connexion réussie: ${user.id} (${user.role})');
    return updated;
  }

  // ─── RECHERCHE ────────────────────────────────────────────────────────────────

  DbUser? _findUserByEmail(String email) {
    for (final key in _usersBox.keys) {
      final m = _usersBox.get(key);
      if (m != null) {
        final u = DbUser.fromMap(m as Map);
        if (u.email.toLowerCase() == email.toLowerCase()) return u;
      }
    }
    return null;
  }

  DbUser? _findUserByPhone(String phone) {
    final normalized = phone.replaceAll(' ', '').replaceAll('-', '').replaceAll('+225', '');
    for (final key in _usersBox.keys) {
      final m = _usersBox.get(key);
      if (m != null) {
        final u = DbUser.fromMap(m as Map);
        final uPhone = u.phone.replaceAll(' ', '').replaceAll('-', '').replaceAll('+225', '');
        if (uPhone == normalized) return u;
      }
    }
    return null;
  }

  /// Initialise l'ensemble des comptes de démonstration (médecins, patients, admin)
  Future<void> seedDemoData({bool force = false}) async {
    if (!Hive.isBoxOpen(_Boxes.users)) return;
    final shouldForce = force || totalUsers < 6;
    // 1. Compte Patient Principal (Jean Kouassi)
    var patient1 = _findUserByPhone('0707070707') ?? _findUserByEmail('patient@mydoctor.ci');
    final pat1Id = patient1?.id ?? 'pat_demo_01';
    if (patient1 == null || shouldForce) {
      patient1 = DbUser(
        id: pat1Id,
        role: 'patient',
        email: 'patient@mydoctor.ci',
        phone: '0707070707',
        passwordHash: _hashPassword('Password123!'),
        firstName: 'Jean',
        lastName: 'Kouassi',
        status: 'active',
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
        cmuNumber: 'CMU-CI123456789',
        gender: 'M',
        birthDate: '15/05/1990',
        profession: 'Ingénieur Informatique',
        commune: 'Cocody',
        city: 'Abidjan',
      );
      await _usersBox.put(pat1Id, patient1.toMap());
      debugPrint('🌱 Compte patient démo 1 initialisé : 0707070707 / Password123!');
    }
    if (_usageBox.get(pat1Id) == null || force) {
      await _usageBox.put(pat1Id, PatientMessageUsage(
        patientId: pat1Id,
        freeMessagesLimit: 10,
        freeMessagesUsed: 4,
        firstMessageAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 12)),
      ).toMap());
    }

    // 2. Patient 2 (Marie-Ange Bamba)
    var patient2 = _findUserByPhone('0707070708') ?? _findUserByEmail('marieange.bamba@gmail.com');
    final pat2Id = patient2?.id ?? 'pat_demo_02';
    if (patient2 == null || force) {
      patient2 = DbUser(
        id: pat2Id,
        role: 'patient',
        email: 'marieange.bamba@gmail.com',
        phone: '0707070708',
        passwordHash: _hashPassword('Password123!'),
        firstName: 'Marie-Ange',
        lastName: 'Bamba',
        status: 'active',
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        cmuNumber: 'CMU-CI987654321',
        gender: 'F',
        birthDate: '22/08/1995',
        profession: 'Comptable',
        commune: 'Cocody',
        city: 'Abidjan',
      );
      await _usersBox.put(pat2Id, patient2.toMap());
      debugPrint('🌱 Compte patient démo 2 initialisé : 0707070708');
    }
    if (_usageBox.get(pat2Id) == null || force) {
      await _usageBox.put(pat2Id, PatientMessageUsage(
        patientId: pat2Id,
        freeMessagesLimit: 10,
        freeMessagesUsed: 8,
        firstMessageAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ).toMap());
    }

    // 3. Patient 3 (Sékou Traoré - Quota épuisé / bloqué pour test)
    var patient3 = _findUserByPhone('0707070709') ?? _findUserByEmail('sekou.traore@gmail.com');
    final pat3Id = patient3?.id ?? 'pat_demo_03';
    if (patient3 == null || force) {
      patient3 = DbUser(
        id: pat3Id,
        role: 'patient',
        email: 'sekou.traore@gmail.com',
        phone: '0707070709',
        passwordHash: _hashPassword('Password123!'),
        firstName: 'Sékou',
        lastName: 'Traoré',
        status: 'active',
        createdAt: DateTime.now().subtract(const Duration(days: 35)),
        cmuNumber: 'CMU-CI456789123',
        gender: 'M',
        birthDate: '10/11/1984',
        profession: 'Commerçant',
        commune: 'Yopougon',
        city: 'Abidjan',
      );
      await _usersBox.put(pat3Id, patient3.toMap());
      debugPrint('🌱 Compte patient démo 3 initialisé : 0707070709');
    }
    if (_usageBox.get(pat3Id) == null || force) {
      await _usageBox.put(pat3Id, PatientMessageUsage(
        patientId: pat3Id,
        freeMessagesLimit: 10,
        freeMessagesUsed: 10, // Quota épuisé
        firstMessageAt: DateTime.now().subtract(const Duration(days: 15)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
      ).toMap());
    }

    // 4. Patient 4 (Awa Koné)
    var patient4 = _findUserByPhone('0707070710') ?? _findUserByEmail('awa.kone@gmail.com');
    final pat4Id = patient4?.id ?? 'pat_demo_04';
    if (patient4 == null || force) {
      patient4 = DbUser(
        id: pat4Id,
        role: 'patient',
        email: 'awa.kone@gmail.com',
        phone: '0707070710',
        passwordHash: _hashPassword('Password123!'),
        firstName: 'Awa',
        lastName: 'Koné',
        status: 'active',
        createdAt: DateTime.now().subtract(const Duration(days: 12)),
        cmuNumber: 'CMU-CI789123456',
        gender: 'F',
        birthDate: '03/04/1998',
        profession: 'Professeure',
        commune: 'Marcory',
        city: 'Abidjan',
      );
      await _usersBox.put(pat4Id, patient4.toMap());
      debugPrint('🌱 Compte patient démo 4 initialisé : 0707070710');
    }
    if (_usageBox.get(pat4Id) == null || force) {
      await _usageBox.put(pat4Id, PatientMessageUsage(
        patientId: pat4Id,
        freeMessagesLimit: 10,
        freeMessagesUsed: 2,
        firstMessageAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ).toMap());
    }

    // ── MÉDECINS ─────────────────────────────────────────────────────────────

    // 1. Dr. Sarah Touré (Actif)
    var doc1 = _findUserByPhone('0505050505') ?? _findUserByEmail('docteur@mydoctor.ci');
    final doc1Id = doc1?.id ?? 'doc_demo_01';
    if (doc1 == null || force) {
      doc1 = DbUser(
        id: doc1Id,
        role: 'doctor',
        email: 'docteur@mydoctor.ci',
        phone: '0505050505',
        passwordHash: _hashPassword('Password123!'),
        firstName: 'Sarah',
        lastName: 'Touré',
        orderNumber: '12345',
        specialty: 'Cardiologie',
        bio: 'Dr. Sarah Touré, cardiologue spécialisée en prévention cardiovasculaire et télémédecine.',
        status: 'active',
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
        city: 'Abidjan',
        commune: 'Cocody',
      );
      await _usersBox.put(doc1Id, doc1.toMap());
      debugPrint('🌱 Médecin 1 initialisé : Dr. Sarah Touré');
    }

    // 2. Dr. Marc Yao (Actif)
    var doc2 = _findUserByPhone('0505050506') ?? _findUserByEmail('marc.yao@mydoctor.ci');
    final doc2Id = doc2?.id ?? 'doc_demo_02';
    if (doc2 == null || force) {
      doc2 = DbUser(
        id: doc2Id,
        role: 'doctor',
        email: 'marc.yao@mydoctor.ci',
        phone: '0505050506',
        passwordHash: _hashPassword('Password123!'),
        firstName: 'Marc',
        lastName: 'Yao',
        orderNumber: '14289',
        specialty: 'Pédiatrie',
        bio: 'Pédiatre urgentiste et spécialiste du nourrisson au CHU de Treichville.',
        status: 'active',
        createdAt: DateTime.now().subtract(const Duration(days: 40)),
        city: 'Abidjan',
        commune: 'Treichville',
      );
      await _usersBox.put(doc2Id, doc2.toMap());
      debugPrint('🌱 Médecin 2 initialisé : Dr. Marc Yao');
    }

    // 3. Dr. Aminata Diallo (Actif)
    var doc3 = _findUserByPhone('0505050507') ?? _findUserByEmail('aminata.diallo@mydoctor.ci');
    final doc3Id = doc3?.id ?? 'doc_demo_03';
    if (doc3 == null || force) {
      doc3 = DbUser(
        id: doc3Id,
        role: 'doctor',
        email: 'aminata.diallo@mydoctor.ci',
        phone: '0505050507',
        passwordHash: _hashPassword('Password123!'),
        firstName: 'Aminata',
        lastName: 'Diallo',
        orderNumber: '15672',
        specialty: 'Gynécologie',
        bio: 'Gynécologue obstétricienne, suivi de grossesse, fertilité et santé reproductive.',
        status: 'active',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        city: 'Abidjan',
        commune: 'Plateau',
      );
      await _usersBox.put(doc3Id, doc3.toMap());
      debugPrint('🌱 Médecin 3 initialisé : Dr. Aminata Diallo');
    }

    // 4. Dr. Koffi Brou (En attente de validation admin)
    var doc4 = _findUserByPhone('0505050508') ?? _findUserByEmail('koffi.brou@mydoctor.ci');
    final doc4Id = doc4?.id ?? 'doc_demo_04';
    if (doc4 == null || force) {
      doc4 = DbUser(
        id: doc4Id,
        role: 'doctor',
        email: 'koffi.brou@mydoctor.ci',
        phone: '0505050508',
        passwordHash: _hashPassword('Password123!'),
        firstName: 'Koffi',
        lastName: 'Brou',
        orderNumber: '18901',
        specialty: 'Médecine Générale',
        bio: 'Médecin généraliste à Bouaké, consultations de premier recours et dépistage.',
        status: 'pending', // En attente de validation
        createdAt: DateTime.now().subtract(const Duration(hours: 14)),
        city: 'Bouaké',
      );
      await _usersBox.put(doc4Id, doc4.toMap());
      debugPrint('🌱 Médecin 4 en attente initialisé : Dr. Koffi Brou');
    }

    // 5. Dr. Estelle N'Guessan (En attente de validation admin)
    var doc5 = _findUserByPhone('0505050509') ?? _findUserByEmail('estelle.nguessan@mydoctor.ci');
    final doc5Id = doc5?.id ?? 'doc_demo_05';
    if (doc5 == null || force) {
      doc5 = DbUser(
        id: doc5Id,
        role: 'doctor',
        email: 'estelle.nguessan@mydoctor.ci',
        phone: '0505050509',
        passwordHash: _hashPassword('Password123!'),
        firstName: 'Estelle',
        lastName: 'N\'Guessan',
        orderNumber: '19445',
        specialty: 'Dermatologie',
        bio: 'Dermatologue vénérologue, pathologies cutanées et dermoscopie.',
        status: 'pending', // En attente de validation
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        city: 'Abidjan',
        commune: 'Marcory',
      );
      await _usersBox.put(doc5Id, doc5.toMap());
      debugPrint('🌱 Médecin 5 en attente initialisé : Dr. Estelle N\'Guessan');
    }

    // 6. Dr. Ibrahim Sanogo (Suspendu pour test de réactivation)
    var doc6 = _findUserByPhone('0505050510') ?? _findUserByEmail('ibrahim.sanogo@mydoctor.ci');
    final doc6Id = doc6?.id ?? 'doc_demo_06';
    if (doc6 == null || force) {
      doc6 = DbUser(
        id: doc6Id,
        role: 'doctor',
        email: 'ibrahim.sanogo@mydoctor.ci',
        phone: '0505050510',
        passwordHash: _hashPassword('Password123!'),
        firstName: 'Ibrahim',
        lastName: 'Sanogo',
        orderNumber: '11023',
        specialty: 'Neurologie',
        bio: 'Neurologue consultant, prise en charge des céphalées et AVC.',
        status: 'suspended', // Suspendu
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
        city: 'Abidjan',
        commune: 'Yopougon',
      );
      await _usersBox.put(doc6Id, doc6.toMap());
      debugPrint('🌱 Médecin 6 suspendu initialisé : Dr. Ibrahim Sanogo');
    }

    // ── ADMINISTRATEUR ───────────────────────────────────────────────────────
    final existingAdmin = _findUserByPhone('0101010101') ?? _findUserByEmail('admin@mydoctor.ci');
    final adminId = existingAdmin?.id ?? 'adm_demo_01';
    if (existingAdmin == null || force) {
      final admin = DbUser(
        id: adminId,
        role: 'admin',
        email: 'admin@mydoctor.ci',
        phone: '0101010101',
        passwordHash: _hashPassword('Password123!'),
        firstName: 'Admin',
        lastName: 'Principal',
        status: 'active',
        createdAt: DateTime.now().subtract(const Duration(days: 100)),
      );
      await _usersBox.put(adminId, admin.toMap());
      debugPrint('🌱 Compte administrateur démo initialisé : 0101010101 / Password123!');
    }

    _broadcastDoctors();
  }

  /// Initialise les comptes prédéfinis pour le patient et le médecin
  Future<void> _seedDefaultAccounts() async {
    await seedDemoData();
  }

  DbUser? _findUserByCmu(String cmu) {
    for (final key in _usersBox.keys) {
      final m = _usersBox.get(key);
      if (m != null) {
        final u = DbUser.fromMap(m as Map);
        if (u.cmuNumber?.toUpperCase() == cmu) return u;
      }
    }
    return null;
  }

  DbUser? getUserById(String id) {
    if (!Hive.isBoxOpen(_Boxes.users)) return null;
    final m = _usersBox.get(id);
    if (m == null) return null;
    return DbUser.fromMap(m as Map);
  }

  /// Retourne les médecins enregistrés (filtrés sur les actifs pour les clients/patients)
  List<DbUser> getAllDoctors({bool onlyActive = true}) {
    if (!Hive.isBoxOpen(_Boxes.users)) return [];
    final list = <DbUser>[];
    for (final key in _usersBox.keys) {
      final m = _usersBox.get(key);
      if (m != null) {
        final u = DbUser.fromMap(m as Map);
        if (u.role == 'doctor') {
          if (!onlyActive || u.status == 'active') {
            list.add(u);
          }
        }
      }
    }
    return list;
  }

  /// Retourne tous les patients
  List<DbUser> getAllPatients() {
    if (!Hive.isBoxOpen(_Boxes.users)) return [];
    final list = <DbUser>[];
    for (final key in _usersBox.keys) {
      final m = _usersBox.get(key);
      if (m != null) {
        final u = DbUser.fromMap(m as Map);
        if (u.role == 'patient') list.add(u);
      }
    }
    return list;
  }

  /// Retourne tous les utilisateurs (patients, médecins, admins)
  List<DbUser> getAllUsers() {
    if (!Hive.isBoxOpen(_Boxes.users)) return [];
    final list = <DbUser>[];
    for (final key in _usersBox.keys) {
      final m = _usersBox.get(key);
      if (m != null) {
        list.add(DbUser.fromMap(m as Map));
      }
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Compte total d'utilisateurs
  int get totalUsers => Hive.isBoxOpen(_Boxes.users) ? _usersBox.length : 0;
  int get totalDoctors => getAllDoctors(onlyActive: false).length;
  int get totalActiveDoctors => getAllDoctors(onlyActive: true).length;
  int get totalPendingDoctors => getAllDoctors(onlyActive: false).where((d) => d.status == 'pending').length;
  int get totalPatients => getAllPatients().length;

  // ─── GESTION DU QUOTA DES 10 MESSAGES GRATUITS ─────────────────────────────────

  /// Récupère le statut du quota pour un patient
  PatientMessageUsage getPatientMessageUsage(String patientId) {
    if (!Hive.isBoxOpen(_Boxes.messageUsage)) {
      return PatientMessageUsage(
        patientId: patientId,
        freeMessagesLimit: 10,
        freeMessagesUsed: 0,
        updatedAt: DateTime.now(),
      );
    }
    final m = _usageBox.get(patientId);
    if (m != null) {
      try {
        return PatientMessageUsage.fromMap(Map<dynamic, dynamic>.from(m as Map));
      } catch (e) {
        debugPrint('⚠️ Erreur lecture message_usage pour $patientId: $e');
      }
    }
    return PatientMessageUsage(
      patientId: patientId,
      freeMessagesLimit: 10,
      freeMessagesUsed: 0,
      updatedAt: DateTime.now(),
    );
  }

  /// Vérifie côté serveur si le patient peut envoyer un message (restant > 0)
  bool checkCanPatientSendMessage(String patientId) {
    return getPatientMessageUsage(patientId).canSend;
  }

  /// Consomme un message gratuit pour le patient si la limite n'est pas atteinte.
  /// Retourne true si le message a pu être consommé, false si la limite est atteinte.
  Future<bool> consumePatientMessage(String patientId) async {
    final current = getPatientMessageUsage(patientId);
    if (!current.canSend) {
      debugPrint('⛔ Limite de ${current.freeMessagesLimit} messages atteinte pour le patient $patientId');
      return false;
    }

    final updated = PatientMessageUsage(
      patientId: patientId,
      freeMessagesLimit: current.freeMessagesLimit,
      freeMessagesUsed: current.freeMessagesUsed + 1,
      firstMessageAt: current.firstMessageAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _usageBox.put(patientId, updated.toMap());
    debugPrint('📨 Message consommé pour $patientId : ${updated.freeMessagesUsed}/${updated.freeMessagesLimit} (restants: ${updated.remaining})');
    return true;
  }

  /// Réinitialise le quota d'un patient (pour l'administration ou recharge)
  Future<void> resetPatientMessageUsage(String patientId, [int limit = 10]) async {
    final reset = PatientMessageUsage(
      patientId: patientId,
      freeMessagesLimit: limit,
      freeMessagesUsed: 0,
      updatedAt: DateTime.now(),
    );
    await _usageBox.put(patientId, reset.toMap());
    debugPrint('🔄 Quota réinitialisé pour $patientId : 0/$limit');
  }

  /// Réinitialise les quotas de tous les patients
  Future<void> resetAllPatientsMessageUsage([int limit = 10]) async {
    for (final key in _usageBox.keys) {
      await resetPatientMessageUsage(key.toString(), limit);
    }
    debugPrint('🔄 Quotas réinitialisés pour tous les patients : 0/$limit');
  }

  // ─── MISE À JOUR ──────────────────────────────────────────────────────────────

  Future<void> updateUserAvatar(String userId, String avatarUrl) async {
    final m = _usersBox.get(userId);
    if (m == null) return;
    final u = DbUser.fromMap(m as Map);
    await _usersBox.put(userId, u.copyWith(avatarUrl: avatarUrl).toMap());
  }

  /// Stocke la photo de profil en base64 (pour les comptes locaux)
  Future<void> updateUserAvatarBase64(String userId, String base64) async {
    final m = _usersBox.get(userId);
    if (m == null) return;
    final u = DbUser.fromMap(m as Map);
    await _usersBox.put(userId, u.copyWith(avatarBase64: base64).toMap());
  }

  /// Récupère le base64 de l'avatar d'un utilisateur
  String? getUserAvatarBase64(String userId) {
    final m = _usersBox.get(userId);
    if (m == null) return null;
    return DbUser.fromMap(m as Map).avatarBase64;
  }

  /// Met à jour le profil complet d'un utilisateur (patient ou médecin)
  Future<void> updateUserProfile({
    required String userId,
    String? firstName,
    String? lastName,
    String? phone,
    String? address,
    String? city,
    String? commune,
    String? profession,
    String? cmuNumber,
    String? birthDate,
    String? gender,
    String? avatarBase64,
    String? specialty,
    String? orderNumber,
    String? bio,
  }) async {
    final m = _usersBox.get(userId);
    if (m == null) return;
    final u = DbUser.fromMap(m as Map);
    
    await _usersBox.put(
      userId,
      u.copyWith(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        city: city ?? address,
        commune: commune,
        profession: profession,
        cmuNumber: cmuNumber,
        birthDate: birthDate,
        gender: gender,
        avatarBase64: avatarBase64,
        specialty: specialty,
        orderNumber: orderNumber,
        bio: bio,
      ).toMap(),
    );
    _doctorsStreamController.add(getAllDoctors());
  }

  Future<void> updateUserStatus(String userId, String status) async {
    final m = _usersBox.get(userId);
    if (m == null) return;
    final u = DbUser.fromMap(m as Map);
    await _usersBox.put(userId, u.copyWith(status: status).toMap());
    _doctorsStreamController.add(getAllDoctors());
  }

  // ─── GESTION DES RENDEZ-VOUS ───────────────────────────────────────────────

  int get totalAppointments => _appointmentsBox.length;

  List<AppointmentModel> getAllAppointments() {
    if (!Hive.isBoxOpen(_Boxes.appointments)) return [];
    final list = <AppointmentModel>[];
    for (final val in _appointmentsBox.values) {
      if (val is Map) {
        try {
          list.add(AppointmentModel.fromJson(Map<String, dynamic>.from(val)));
        } catch (e) {
          debugPrint('Erreur parsing AppointmentModel: $e');
        }
      }
    }
    list.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return list;
  }

  List<AppointmentModel> getAppointmentsForPatient(String patientId) {
    return getAllAppointments().where((a) => a.patientId == patientId).toList();
  }

  List<AppointmentModel> getAppointmentsForDoctor(String doctorId) {
    return getAllAppointments().where((a) => a.doctorId == doctorId).toList();
  }

  Future<void> saveAppointment(AppointmentModel appointment) async {
    if (!Hive.isBoxOpen(_Boxes.appointments)) {
      await Hive.openBox(_Boxes.appointments);
    }
    final json = appointment.toJson();
    await _appointmentsBox.put(appointment.id, json);
    _broadcastAppointments();

    // Synchronisation PostgreSQL distante en arrière-plan
    try {
      unawaited(SupabaseService().saveAppointment(json));
    } catch (_) {}
  }

  Future<void> updateAppointmentStatus(String appointmentId, AppointmentStatus status) async {
    if (!Hive.isBoxOpen(_Boxes.appointments)) return;
    final val = _appointmentsBox.get(appointmentId);
    if (val is Map) {
      try {
        final current = AppointmentModel.fromJson(Map<String, dynamic>.from(val));
        final updated = current.copyWith(status: status);
        await _appointmentsBox.put(appointmentId, updated.toJson());
        _broadcastAppointments();

        // Sync PostgreSQL
        try {
          unawaited(SupabaseService().updateAppointmentStatus(appointmentId, status.name));
        } catch (_) {}
      } catch (e) {
        debugPrint('Erreur updateAppointmentStatus: $e');
      }
    }
  }

  Future<void> deleteAppointment(String appointmentId) async {
    if (!Hive.isBoxOpen(_Boxes.appointments)) return;
    await _appointmentsBox.delete(appointmentId);
    _broadcastAppointments();
  }

  Future<void> seedDemoAppointments({bool force = false}) async {
    if (!Hive.isBoxOpen(_Boxes.appointments)) return;
    if (_appointmentsBox.isNotEmpty && !force) return;

    final users = getAllUsers();
    String idForEmail(String email, String fallback) {
      for (final u in users) {
        if (u.email.toLowerCase() == email.toLowerCase()) return u.id;
      }
      return fallback;
    }

    final pat1Id = idForEmail('patient@mydoctor.ci', 'pat_demo_01');
    final pat2Id = idForEmail('marieange.bamba@gmail.com', 'pat_demo_02');
    final pat3Id = idForEmail('sekou.traore@gmail.com', 'pat_demo_03');
    final doc1Id = idForEmail('docteur@mydoctor.ci', 'doc_demo_01');
    final doc2Id = idForEmail('marc.yao@mydoctor.ci', 'doc_demo_02');

    final now = DateTime.now();

    final demoAppointments = [
      AppointmentModel(
        id: 'apt_demo_01',
        patientId: pat1Id,
        patientName: 'Jean Kouassi',
        doctorId: doc1Id,
        doctorName: 'Dr. Sarah Touré',
        doctorSpecialty: 'Cardiologie',
        scheduledAt: DateTime(now.year, now.month, now.day + 1, 10, 0),
        durationMinutes: 30,
        status: AppointmentStatus.confirmed,
        type: AppointmentType.inPerson,
        reason: 'Suivi cardiologique et contrôle tensionnel',
        consultationPrice: 15000.0,
        isPaid: true,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      AppointmentModel(
        id: 'apt_demo_02',
        patientId: pat2Id,
        patientName: 'Marie-Ange Bamba',
        doctorId: doc1Id,
        doctorName: 'Dr. Sarah Touré',
        doctorSpecialty: 'Cardiologie',
        scheduledAt: DateTime(now.year, now.month, now.day + 2, 14, 30),
        durationMinutes: 30,
        status: AppointmentStatus.pending,
        type: AppointmentType.teleconsultation,
        reason: 'Avis cardiologique sur ECG',
        consultationPrice: 15000.0,
        isPaid: true,
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
      AppointmentModel(
        id: 'apt_demo_03',
        patientId: pat1Id,
        patientName: 'Jean Kouassi',
        doctorId: doc1Id,
        doctorName: 'Dr. Sarah Touré',
        doctorSpecialty: 'Cardiologie',
        scheduledAt: DateTime(now.year, now.month, now.day - 7, 11, 0),
        durationMinutes: 30,
        status: AppointmentStatus.completed,
        type: AppointmentType.inPerson,
        reason: 'Consultation initiale et électrocardiogramme',
        consultationPrice: 15000.0,
        isPaid: true,
        createdAt: now.subtract(const Duration(days: 10)),
      ),
      AppointmentModel(
        id: 'apt_demo_04',
        patientId: pat3Id,
        patientName: 'Bakary Traoré',
        doctorId: doc2Id,
        doctorName: 'Dr. Marc Yao',
        doctorSpecialty: 'Pédiatrie',
        scheduledAt: DateTime(now.year, now.month, now.day + 1, 15, 0),
        durationMinutes: 30,
        status: AppointmentStatus.confirmed,
        type: AppointmentType.inPerson,
        reason: 'Vaccination et bilan de croissance',
        consultationPrice: 12000.0,
        isPaid: true,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ];

    for (final appt in demoAppointments) {
      await _appointmentsBox.put(appt.id, appt.toJson());
    }
    _broadcastAppointments();
    debugPrint('🌱 ${demoAppointments.length} rendez-vous de démonstration initialisés !');
  }

  Future<void> _seedDefaultAppointments() async {
    await seedDemoAppointments();
  }

  // ─── SESSION ──────────────────────────────────────────────────────────────────

  Future<void> saveSession(String userId, String role) async {
    await _sessionsBox.put('current', {
      'userId': userId,
      'role': role,
      'savedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<Map<String, String>?> loadSession() async {
    final m = _sessionsBox.get('current');
    if (m == null) return null;
    return {
      'userId': (m['userId'] ?? '') as String,
      'role': (m['role'] ?? '') as String,
    };
  }

  Future<void> clearSession() async {
    await _sessionsBox.delete('current');
  }

  // ─── DEBUG ────────────────────────────────────────────────────────────────────

  void printStats() {
    debugPrint('📊 BDD Stats: $totalUsers users ($totalPatients patients, $totalDoctors médecins)');
  }
  
  // ─── CLEANUP ──────────────────────────────────────────────────────────────────
  
  /// Ferme les StreamControllers (à appeler lors de la fermeture de l'app)
  void dispose() {
    _doctorsStreamController.close();
    _appointmentsStreamController.close();
  }
}
