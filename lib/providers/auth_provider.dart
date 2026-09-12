// lib/providers/auth_provider.dart
//
// Gestion de l'authentification avec persistance via DatabaseService (Hive).
// Supporte : inscription patient/médecin, connexion, 2FA, déconnexion.

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/doctor_model.dart';
import '../core/constants/app_constants.dart';
import '../services/database_service.dart';

import '../core/routing/route_persistence_service.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }
enum TwoFAState { none, pending, verified }
// ─── AuthProvider ─────────────────────────────────────────────────────────────

class AuthProvider extends ChangeNotifier {
  AuthState _state = AuthState.initial;
  TwoFAState _twoFAState = TwoFAState.none;
  UserModel? _currentUser;
  DoctorModel? _doctorProfile;
  String? _errorMessage;
  bool _isLoading = false;

  // Stocke l'utilisateur en attente de 2FA
  DbUser? _pendingDbUser;
  String _pendingRole = '';

  // BDD
  final _db = DatabaseService();

  // Getters
  AuthState get state => _state;
  TwoFAState get twoFAState => _twoFAState;
  UserModel? get currentUser => _currentUser;
  DoctorModel? get doctorProfile => _doctorProfile;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  String get pendingRole => _pendingRole;
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get isPatient => _currentUser?.role == UserRole.patient;
  bool get isDoctor => _currentUser?.role == UserRole.doctor;
  bool get isAdmin => _currentUser?.role == UserRole.admin;
  String get userInitials => _currentUser?.initials ?? 'U';
  String get userName => _currentUser?.fullName ?? 'Utilisateur';


  // Mock doctors (pour compatibilité écrans existants)
  List<DoctorModel> _mockDoctors = [];
  List<DoctorModel> get mockDoctors => _mockDoctors;

  bool _initialized = false;

  AuthProvider() {
    // Si pas encore initialisé via initSession() avant runApp, initialiser en tâche de fond
    if (!_initialized) {
      _init();
    }
  }

  Future<void> initSession() async {
    _initialized = true;
    await _db.initialize();
    _loadDoctors();
    
    _db.doctorsStream.listen((doctors) {
      _mockDoctors = doctors.map((u) => dbUserToDoctorModel(u)).whereType<DoctorModel>().toList();
      notifyListeners();
    });
    
    await _checkAuthStatus(silent: true);
  }

  Future<void> _init() async {
    await initSession();
  }

  // ─── Conversions DbUser → UserModel/DoctorModel ───────────────────────────

  UserModel _dbUserToUserModel(DbUser u) => dbUserToUserModel(u);
  DoctorModel? _dbUserToDoctorModel(DbUser u) => dbUserToDoctorModel(u);

  UserModel dbUserToUserModel(DbUser u) => UserModel(
    id: u.id,
    firstName: u.firstName,
    lastName: u.lastName,
    email: u.email,
    phone: u.phone,
    role: u.role == 'doctor'
        ? UserRole.doctor
        : (u.role == 'admin' ? UserRole.admin : UserRole.patient),
    status: u.status == 'active' ? AccountStatus.active : AccountStatus.pending,
    avatarUrl: u.avatarUrl,
    avatarBase64: u.avatarBase64,
    is2FAEnabled: true,
    isEmailVerified: u.email.isNotEmpty,
    isPhoneVerified: true,
    createdAt: u.createdAt,
    lastLoginAt: u.lastLoginAt,
    cmuNumber: u.cmuNumber,
    birthDate: u.birthDate != null ? DateTime.tryParse(u.birthDate!) : null,
    gender: u.gender,
    profession: u.profession,
    commune: u.commune,
    city: u.city,
  );

  DoctorModel? dbUserToDoctorModel(DbUser u) {
    if (u.role != 'doctor') return null;
    // Cherche si ce médecin est dans les mock doctors (pour les données étendues)
    try {
      return _mockDoctors.firstWhere((d) => d.email == u.email);
    } catch (_) {
      // Médecin inscrit via la BDD (pas dans les mocks)
      return DoctorModel(
        id: u.id,
        userId: u.id,
        firstName: u.firstName,
        lastName: u.lastName,
        email: u.email,
        phone: u.phone,
        specialty: u.specialty ?? 'Généraliste',
        orderNumber: u.orderNumber ?? '00000',
        bio: u.bio ?? '',
        avatarBase64: u.avatarBase64,  // ← photo locale transmise
        latitude: 5.3484,
        longitude: -4.0107,
        address: 'Abidjan, Côte d\'Ivoire',
        city: 'Abidjan',
        rating: 0.0,
        reviewCount: 0,
        patientCount: 0,
        experienceYears: 0,
        successRate: 0.0,
        consultationPrice: 15000,
        isAvailable: true,
        isVerified: false,
        isOnline: true,
        availableDays: ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi'],
        availableSlots: {},
        createdAt: u.createdAt,
      );
    }
  }

  // ─── Chargement des médecins depuis la BDD ───────────────────────────────────

  void _loadDoctors() {
    final dbDoctors = _db.getAllDoctors();
    _mockDoctors = dbDoctors.map((u) => dbUserToDoctorModel(u)).whereType<DoctorModel>().toList();
    notifyListeners(); // ← notifie les écrans patients qui écoutent
  }

  /// Recharge la liste des médecins depuis la BDD et notifie les listeners.
  /// À appeler après toute inscription médecin ou au retour sur l'écran patient.
  void refreshDoctors() {
    _loadDoctors();
  }

  // ─── Vérification de session ──────────────────────────────────────────────────

  Future<void> _checkAuthStatus({bool silent = false}) async {
    if (!silent) {
      _state = AuthState.loading;
      notifyListeners();
    }

    try {
      // 1. Tenter la restauration directe depuis la base Hive (instantanée)
      final session = await _db.loadSession();
      if (session != null) {
        final userId = session['userId'];
        if (userId != null && userId.isNotEmpty) {
          final dbUser = _db.getUserById(userId);
          if (dbUser != null) {
            _currentUser = dbUserToUserModel(dbUser);
            if (dbUser.role == 'doctor') {
              _doctorProfile = dbUserToDoctorModel(dbUser);
            }
            _twoFAState = TwoFAState.verified;
            _state = AuthState.authenticated;
            debugPrint('✅ AuthProvider session restaurée via Hive: ${_currentUser?.email} (${_currentUser?.role})');
            if (!silent) notifyListeners();
            return;
          }
        }
      }

      // 2. Fallback SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.keyAuthToken);
      final userId = prefs.getString(AppConstants.keyUserId);

      if (token != null && userId != null) {
        final dbUser = _db.getUserById(userId);
        if (dbUser != null) {
          _currentUser = dbUserToUserModel(dbUser);
          if (dbUser.role == 'doctor') {
            _doctorProfile = dbUserToDoctorModel(dbUser);
          }
          _twoFAState = TwoFAState.verified;
          _state = AuthState.authenticated;
          debugPrint('✅ AuthProvider session restaurée via SharedPreferences: ${_currentUser?.email}');
          if (!silent) notifyListeners();
          return;
        }
      }
    } catch (e) {
      debugPrint('Auth check error: $e');
    }

    _state = AuthState.unauthenticated;
    if (!silent) notifyListeners();
  }

  // ─── INSCRIPTION PATIENT ──────────────────────────────────────────────────────

  /// Inscription d'un nouveau patient avec persistance en base.
  Future<RegisterResult> registerPatient({
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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final dbUser = await _db.registerPatient(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        password: password,
        email: email,
        gender: gender,
        birthDate: birthDate,
        profession: profession,
        commune: commune,
        city: city,
        avatarBase64: avatarBase64,
        attachments: attachments,
      );

      if (dbUser == null) {
        _errorMessage = 'Ce numéro de téléphone est déjà associé à un compte.';
        _isLoading = false;
        notifyListeners();
        return RegisterResult.duplicate;
      }

      // Mettre l'utilisateur en attente de 2FA
      _pendingDbUser = dbUser;
      _pendingRole = AppConstants.rolePatient;
      _twoFAState = TwoFAState.pending;
      _isLoading = false;
      notifyListeners();
      return RegisterResult.success;
    } catch (e) {
      _errorMessage = 'Erreur lors de l\'inscription. Veuillez réessayer.';
      _isLoading = false;
      notifyListeners();
      return RegisterResult.error;
    }
  }

  // ─── INSCRIPTION MÉDECIN ──────────────────────────────────────────────────────

  /// Inscription d'un nouveau médecin avec persistance en base (statut pending).
  Future<RegisterResult> registerDoctor({
    required String firstName,
    required String lastName,
    required String phone,
    required String password,
    String? email,
    String? orderNumber,
    String? specialty,
    String? avatarBase64,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (orderNumber != null && orderNumber.isNotEmpty) {
      final orderRegex = RegExp(r'^\d{5}$');
      if (!orderRegex.hasMatch(orderNumber)) {
        _errorMessage = 'Le numéro d\'ordre doit contenir exactement 5 chiffres.';
        _isLoading = false;
        notifyListeners();
        return RegisterResult.validationError;
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final manualApproval = prefs.getBool(AppConstants.keyAdminManualDoctorApproval) ?? true;
      final dbUser = await _db.registerDoctor(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        password: password,
        orderNumber: orderNumber,
        specialty: specialty,
        avatarBase64: avatarBase64,
        status: manualApproval ? 'pending' : 'active',
      );

      if (dbUser == null) {
        _errorMessage = 'Cet email ou numéro de téléphone est déjà associé à un compte.';
        _isLoading = false;
        notifyListeners();
        return RegisterResult.duplicate;
      }

      _pendingDbUser = dbUser;
      _pendingRole = AppConstants.roleDoctor;
      _twoFAState = TwoFAState.pending;
      _isLoading = false;
      _loadDoctors();
      notifyListeners();
      return RegisterResult.success;
    } catch (e) {
      _errorMessage = 'Erreur lors de l\'inscription. Veuillez réessayer.';
      _isLoading = false;
      notifyListeners();
      return RegisterResult.error;
    }
  }

  // ─── CONNEXION PATIENT ────────────────────────────────────────────────────────

  Future<bool> loginPatient({
    required String identifier,
    required String password,
    String? birthDate, // format JJ/MM/AAAA — optionnel si non renseigné au profil
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final dbUser = await _db.login(identifier: identifier, password: password);

      if (dbUser == null) {
        // Message d'erreur distinguant CMU vs téléphone
        final id = identifier.toUpperCase();
        if (id.startsWith('CMU')) {
          _errorMessage = 'Numéro CMU-CI ou mot de passe incorrect.';
        } else {
          _errorMessage = 'Numéro de téléphone ou mot de passe incorrect.';
        }
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (dbUser.role == 'admin') {
        // L'administrateur se connecte via l'interface patient
        _currentUser = _dbUserToUserModel(dbUser);
        _state = AuthState.authenticated;
        _twoFAState = TwoFAState.verified;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.keyUserId, dbUser.id);
        await prefs.setString(AppConstants.keyUserRole, AppConstants.roleAdmin);

        _pendingDbUser = null;
        _pendingRole = '';
        _isLoading = false;
        notifyListeners();
        return true;
      }

      if (dbUser.role != 'patient') {
        _errorMessage = 'Ce compte est un compte médecin. Utilisez la connexion médecin.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // ── Vérification date de naissance ─────────────────────────────────────
      // On vérifie uniquement si le profil a une date ET que l'utilisateur en a saisi une.
      // Si le profil n'a pas de date enregistrée, on passe (inscription ancienne).
      if (dbUser.birthDate != null && dbUser.birthDate!.isNotEmpty &&
          birthDate != null && birthDate.isNotEmpty) {
        // Normaliser : enlever les espaces, comparer en ignorant la casse
        final storedNorm  = dbUser.birthDate!.trim().replaceAll(' ', '');
        final enteredNorm = birthDate.trim().replaceAll(' ', '');
        if (storedNorm != enteredNorm) {
          _errorMessage = 'Date de naissance incorrecte. Vérifiez la date saisie.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      // Connexion directe sans OTP - finalisation immédiate
      _currentUser = _dbUserToUserModel(dbUser);
      _state = AuthState.authenticated;
      _twoFAState = TwoFAState.verified;
      
      // Sauvegarde de la session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyUserId, dbUser.id);
      await prefs.setString(AppConstants.keyUserRole, AppConstants.rolePatient);
      await RoutePersistenceService.saveTab('patient', 0);
      
      _pendingDbUser = null;
      _pendingRole = '';
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur inattendue. Réessayez dans quelques instants.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── CONNEXION MÉDECIN ────────────────────────────────────────────────────────

  Future<bool> loginDoctor({
    required String identifier,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final dbUser = await _db.login(identifier: identifier, password: password);

      if (dbUser == null) {
        _errorMessage = 'Identifiant ou mot de passe incorrect.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (dbUser.role == 'admin') {
        // L'administrateur se connecte via l'interface médecin
        _currentUser = _dbUserToUserModel(dbUser);
        _state = AuthState.authenticated;
        _twoFAState = TwoFAState.verified;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.keyUserId, dbUser.id);
        await prefs.setString(AppConstants.keyUserRole, AppConstants.roleAdmin);

        _pendingDbUser = null;
        _pendingRole = '';
        _isLoading = false;
        notifyListeners();
        return true;
      }

      if (dbUser.role != 'doctor') {
        _errorMessage = 'Ce compte est un compte patient. Utilisez la connexion médecin.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (dbUser.status != 'active') {
        _errorMessage = dbUser.status == 'pending'
            ? 'Votre compte médecin est en attente de validation par l’administration.'
            : 'Votre compte médecin est suspendu. Contactez l’administration.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Connexion directe sans OTP - finalisation immédiate
      _currentUser = _dbUserToUserModel(dbUser);
      _doctorProfile = _dbUserToDoctorModel(dbUser);
      _state = AuthState.authenticated;
      _twoFAState = TwoFAState.verified;
      
      // Sauvegarde de la session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyUserId, dbUser.id);
      await prefs.setString(AppConstants.keyUserRole, AppConstants.roleDoctor);
      await RoutePersistenceService.saveTab('doctor', 0);
      
      _pendingDbUser = null;
      _pendingRole = '';
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur de connexion.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── CONNEXION ADMINISTRATEUR ──────────────────────────────────────────────────

  Future<bool> loginAdmin({
    required String identifier,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final dbUser = await _db.login(identifier: identifier, password: password);

      if (dbUser == null) {
        _errorMessage = 'Identifiant ou mot de passe incorrect.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (dbUser.role != 'admin') {
        _errorMessage = 'Ce compte n\'a pas accès à l\'administration.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _currentUser = _dbUserToUserModel(dbUser);
      _state = AuthState.authenticated;
      _twoFAState = TwoFAState.verified;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyAuthToken, 'admin_token_${dbUser.id}');
      await prefs.setString(AppConstants.keyUserId, dbUser.id);
      await prefs.setString(AppConstants.keyUserRole, AppConstants.roleAdmin);
      await _db.saveSession(dbUser.id, 'admin');

      _pendingDbUser = null;
      _pendingRole = '';
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur de connexion administrateur.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── CONNEXION MÉDECIN AVEC NUMÉRO D'ORDRE ────────────────────────────────────

  Future<bool> loginDoctorWithOrderNumber({
    required String firstName,
    required String lastName,
    required String orderNumber,
    required String phone,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Connexion avec le numéro de téléphone comme identifiant
      final dbUser = await _db.login(identifier: phone, password: password);

      if (dbUser == null) {
        _errorMessage = 'Identifiants incorrects.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (dbUser.role != 'doctor') {
        _errorMessage = 'Ce compte n\'est pas un compte médecin.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Vérifier le numéro d'ordre
      if (dbUser.orderNumber != orderNumber) {
        _errorMessage = 'Numéro d\'ordre incorrect.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Vérifier nom et prénom (insensible à la casse, tolérant aux espaces et à l'ordre prénom/nom)
      final fnMatch = (dbUser.firstName.toLowerCase().trim() == firstName.toLowerCase().trim() &&
                       dbUser.lastName.toLowerCase().trim() == lastName.toLowerCase().trim());
      final invMatch = (dbUser.firstName.toLowerCase().trim() == lastName.toLowerCase().trim() &&
                        dbUser.lastName.toLowerCase().trim() == firstName.toLowerCase().trim());
      if (!fnMatch && !invMatch) {
        _errorMessage = 'Nom ou prénom incorrect.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _pendingDbUser = dbUser;
      _pendingRole = AppConstants.roleDoctor;
      _twoFAState = TwoFAState.pending;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur de connexion: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── VÉRIFICATION 2FA ─────────────────────────────────────────────────────────

  Future<bool> verify2FA({
    required String otp,
    required String role,
    String? identifier,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800));

    // Accepte n'importe quel code à 6 chiffres
    if (otp.length != 6) {
      _errorMessage = 'Code OTP incorrect. Veuillez entrer le code reçu par SMS.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      if (_pendingDbUser != null) {
        // Connexion/inscription via BDD
        _currentUser = _dbUserToUserModel(_pendingDbUser!);
        if (_pendingDbUser!.role == 'doctor') {
          _doctorProfile = _dbUserToDoctorModel(_pendingDbUser!);
        }
      } else {
        // Fallback: identifier fourni (ancien flow)
        final id = identifier ?? '';
        if (role == AppConstants.roleDoctor) {
          final dbUser = await _db.login(identifier: id, password: '');
          if (dbUser != null) {
            _currentUser = _dbUserToUserModel(dbUser);
            _doctorProfile = _dbUserToDoctorModel(dbUser);
          } else {
            _currentUser = UserModel(
              id: 'usr_dr_fallback',
              firstName: 'Médecin',
              lastName: '',
              email: id,
              phone: '',
              role: UserRole.doctor,
              status: AccountStatus.active,
              is2FAEnabled: true,
              isEmailVerified: true,
              isPhoneVerified: true,
              createdAt: DateTime.now(),
            );
            _doctorProfile = null;
          }
        } else {
          // Patient fallback
          _currentUser = UserModel(
              id: 'usr_pat_${id.hashCode.abs()}',
              firstName: 'Patient',
              lastName: '',
              email: id,
              phone: id,
              role: UserRole.patient,
              status: AccountStatus.active,
              is2FAEnabled: true,
              isEmailVerified: false,
              isPhoneVerified: true,
              createdAt: DateTime.now(),
            );
        }
      }

      _twoFAState = TwoFAState.verified;
      _state = AuthState.authenticated;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyAuthToken, 'token_${DateTime.now().millisecondsSinceEpoch}');
      await prefs.setString(AppConstants.keyUserRole, role);

      if (_currentUser != null) {
        await _db.saveSession(_currentUser!.id, role);
      }

      _pendingDbUser = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la vérification.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── MISE À JOUR ──────────────────────────────────────────────────────────────

  Future<void> updateAvatar(String avatarUrl) async {
    if (_currentUser != null) {
      await _db.updateUserAvatar(_currentUser!.id, avatarUrl);
      _currentUser = _currentUser!.copyWith(avatarUrl: avatarUrl);
      notifyListeners();
    }
  }

  /// Met à jour la photo de profil en base64 (photo locale prise lors de l'inscription ou du profil)
  Future<void> updateAvatarBase64(String base64) async {
    if (_currentUser == null) return;
    await _db.updateUserAvatarBase64(_currentUser!.id, base64);
    // Recharger l'utilisateur depuis la BDD pour avoir la photo à jour
    final updated = _db.getUserById(_currentUser!.id);
    if (updated != null) {
      _currentUser = dbUserToUserModel(updated);
    }
    notifyListeners();
  }

  /// Retourne le base64 de la photo de l'utilisateur courant (prioritaire sur avatarUrl)
  String? get currentUserAvatarBase64 {
    if (_currentUser == null) return null;
    return _db.getUserAvatarBase64(_currentUser!.id);
  }

  // ─── DÉCONNEXION ──────────────────────────────────────────────────────────────

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.keyAuthToken);
      await prefs.remove(AppConstants.keyRefreshToken);
      await prefs.remove(AppConstants.keyUserRole);
      await prefs.remove(AppConstants.keyUserId);
      await prefs.remove(AppConstants.keyUserData);
      await _db.clearSession();
      await RoutePersistenceService.clearOnLogout();

      _currentUser = null;
      _doctorProfile = null;
      _state = AuthState.unauthenticated;
      _twoFAState = TwoFAState.none;
      _pendingDbUser = null;
      _pendingRole = '';
    } catch (e) {
      debugPrint('Logout error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Met à jour la photo de profil de l'utilisateur connecté
  Future<bool> updateProfilePhoto(String base64Image) async {
    if (_currentUser == null) return false;
    
    try {
      // Mise à jour dans la base de données
      await _db.updateUserAvatarBase64(_currentUser!.id, base64Image);
      
      // Mise à jour du modèle local
      _currentUser = _currentUser!.copyWith(avatarBase64: base64Image);
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour de la photo: $e');
      return false;
    }
  }

  /// Rafraîchit les données de l'utilisateur actuel depuis la base de données
  Future<void> refreshCurrentUser() async {
    if (_currentUser == null) return;
    
    try {
      final dbUser = _db.getUserById(_currentUser!.id);
      if (dbUser != null) {
        _currentUser = dbUserToUserModel(dbUser);
        if (dbUser.role == 'doctor') {
          _doctorProfile = dbUserToDoctorModel(dbUser);
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erreur lors du rafraîchissement du profil: $e');
    }
  }
}

// ─── Enum résultat d'inscription ──────────────────────────────────────────────

enum RegisterResult {
  success,
  duplicate,
  validationError,
  error,
}
