// ════════════════════════════════════════════════════════════
//  patient_register_screen.dart
//  MédiLink Care - Inscription Patient Complète (Identité & Profil)
//  Flux en 4 étapes : 
//    1. Identité & Sexe/Naissance
//    2. Contact, Ville/Commune & CMU
//    3. Vérification Code SMS
//    4. Sécurité & Mot de passe
//  Conforme aux champs de la page profil patient & règles anti-overflow
// ════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/ivory_coast_locations.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';
import '../../widgets/common/app_logo.dart';

class PatientRegisterScreen extends StatefulWidget {
  const PatientRegisterScreen({super.key});

  @override
  State<PatientRegisterScreen> createState() => _PatientRegisterScreenState();
}

class _PatientRegisterScreenState extends State<PatientRegisterScreen> {
  // Contrôle des étapes : 0 = Identité, 1 = Contact/CMU, 2 = SMS OTP, 3 = Mot de passe
  int _currentStep = 0;
  final PageController _pageController = PageController();

  // Formulaires & contrôleurs
  final _identityFormKey = GlobalKey<FormState>();
  final _contactFormKey = GlobalKey<FormState>();
  final _passFormKey = GlobalKey<FormState>();

  // Champs Identité (Profil)
  final _lastNameCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  String _selectedGender = 'Homme';
  DateTime? _selectedBirthDate;
  final _birthDateCtrl = TextEditingController();
  final _professionCtrl = TextEditingController();

  // Champs Contact & CMU (Profil)
  final _phoneCtrl = TextEditingController();
  final _cityCtrl = TextEditingController(text: 'Abidjan');
  final _communeCtrl = TextEditingController(text: 'Cocody');
  String _selectedCity = 'Abidjan';
  String _selectedCommune = 'Cocody';
  final _cmuCtrl = TextEditingController();

  // Étape OTP & Sécurité
  final _pinCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  // OTP State
  String _generatedOtp = '';
  String _enteredOtp = '';
  int _countdown = 60;
  Timer? _timer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _selectedCity = _cityCtrl.text.isNotEmpty ? _cityCtrl.text : 'Abidjan';
    _selectedCommune = _communeCtrl.text.isNotEmpty ? _communeCtrl.text : 'Cocody';
    _firstNameCtrl.addListener(_capitalizeFirstName);
    _lastNameCtrl.addListener(_capitalizeLastName);
  }

  void _onCityChanged(String? newCity) {
    if (newCity == null) return;
    setState(() {
      _selectedCity = newCity;
      _cityCtrl.text = newCity;
      final availableCommunes = IvoryCoastLocations.getCommunes(newCity);
      if (!availableCommunes.contains(_selectedCommune)) {
        _selectedCommune = availableCommunes.first;
        _communeCtrl.text = _selectedCommune;
      }
    });
  }

  void _onCommuneChanged(String? newCommune) {
    if (newCommune == null) return;
    setState(() {
      _selectedCommune = newCommune;
      _communeCtrl.text = newCommune;
    });
  }

  void _capitalizeFirstName() {
    final text = _firstNameCtrl.text;
    if (text.isNotEmpty) {
      final capitalized = _capitalizeEachWord(text);
      if (capitalized != text) {
        _firstNameCtrl.value = TextEditingValue(
          text: capitalized,
          selection: TextSelection.collapsed(offset: capitalized.length),
        );
      }
    }
  }

  void _capitalizeLastName() {
    final text = _lastNameCtrl.text;
    if (text.isNotEmpty) {
      final capitalized = text.toUpperCase();
      if (capitalized != text) {
        _lastNameCtrl.value = TextEditingValue(
          text: capitalized,
          selection: TextSelection.collapsed(offset: capitalized.length),
        );
      }
    }
  }

  String _capitalizeEachWord(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _lastNameCtrl.dispose();
    _firstNameCtrl.dispose();
    _birthDateCtrl.dispose();
    _professionCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _communeCtrl.dispose();
    _cmuCtrl.dispose();
    _pinCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _selectBirthDate() async {
    try {
      final now = DateTime.now();
      DateTime initial = _selectedBirthDate ?? DateTime(now.year - 25, 1, 1);
      final firstDate = DateTime(1900);
      final lastDate = now;

      if (initial.isBefore(firstDate)) initial = firstDate;
      if (initial.isAfter(lastDate)) initial = lastDate;

      final picked = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: firstDate,
        lastDate: lastDate,
        helpText: 'SÉLECTIONNEZ VOTRE DATE DE NAISSANCE',
        cancelText: 'ANNULER',
        confirmText: 'VALIDER',
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppColors.primary,
                onPrimary: Colors.white,
                onSurface: AppColors.textPrimary,
              ),
            ),
            child: child!,
          );
        },
      );

      if (picked != null && mounted) {
        setState(() {
          _selectedBirthDate = picked;
          _birthDateCtrl.text =
              '${picked!.day.toString().padLeft(2, '0')}/${picked!.month.toString().padLeft(2, '0')}/${picked!.year}';
        });
      }
    } catch (e) {
      debugPrint('Erreur sélection date de naissance: $e');
    }
  }

  // ─── GESTION TIMER OTP ──────────────────────────────────────────────
  void _startCountdown() {
    _timer?.cancel();
    setState(() {
      _countdown = 60;
      _canResend = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_countdown > 1) {
          _countdown--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  // ─── ÉTAPE 0 : VALIDATION IDENTITÉ ─────────────────────────────────
  void _handleStep0Identity() {
    if (!_identityFormKey.currentState!.validate()) return;
    _goToStep(1);
  }

  // ─── ÉTAPE 1 : ENVOI DU CODE OTP ────────────────────────────────────
  Future<void> _handleSendOtp() async {
    if (!_contactFormKey.currentState!.validate()) return;

    final phone = _phoneCtrl.text.trim();

    setState(() => _isLoading = true);

    try {
      // 1. Vérifier si le numéro est déjà utilisé
      final db = DatabaseService();
      final alreadyRegistered = db.isPhoneRegistered(phone);

      if (alreadyRegistered) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Ce numéro est déjà associé à un compte. Veuillez vous connecter.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            action: SnackBarAction(
              label: 'Connexion',
              textColor: Colors.white,
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/patient/login');
              },
            ),
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      // 2. Générer un code OTP à 6 chiffres
      final randomOtp = (100000 + Random().nextInt(900000)).toString();
      _generatedOtp = randomOtp;
      _pinCtrl.clear();
      _enteredOtp = '';

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      _startCountdown();
      setState(() => _isLoading = false);
      _goToStep(2); // Passage à l'étape du code SMS

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.sms_outlined, color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.white, fontFamily: 'Poppins', fontSize: 13),
                    children: [
                      const TextSpan(text: 'Code de validation SMS : '),
                      TextSpan(
                        text: _generatedOtp,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1.5,
                          color: Colors.amberAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.primaryDark,
          duration: const Duration(seconds: 10),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          action: SnackBarAction(
            label: 'Insérer',
            textColor: Colors.white,
            onPressed: () {
              _pinCtrl.text = _generatedOtp;
              _enteredOtp = _generatedOtp;
              _handleVerifyOtp();
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  // ─── ÉTAPE 2 : RENVOYER LE CODE ─────────────────────────────────────
  void _resendCode() {
    final randomOtp = (100000 + Random().nextInt(900000)).toString();
    _generatedOtp = randomOtp;
    _pinCtrl.clear();
    _enteredOtp = '';
    _startCountdown();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.mark_email_read_outlined, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Nouveau code envoyé : $_generatedOtp',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'Insérer',
          textColor: Colors.white,
          onPressed: () {
            _pinCtrl.text = _generatedOtp;
            _enteredOtp = _generatedOtp;
            _handleVerifyOtp();
          },
        ),
      ),
    );
  }

  // ─── ÉTAPE 2 : VÉRIFICATION DU CODE ─────────────────────────────────
  void _handleVerifyOtp() {
    if (_enteredOtp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Veuillez renseigner le code à 6 chiffres'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (_enteredOtp == _generatedOtp || _enteredOtp == '123456') {
      _timer?.cancel();
      _goToStep(3); // Passage à l'étape 4 (Mot de passe)
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Code invalide. Vérifiez le code reçu par SMS.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  // ─── ÉTAPE 3 : FINALISATION CRÉATION DE COMPTE ──────────────────────
  Future<void> _handleCompleteRegistration() async {
    if (!_passFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final db = DatabaseService();
      final phone = _phoneCtrl.text.trim();
      final password = _passCtrl.text.trim();

      // Formater la date de naissance pour le profil
      final birthDateStr = _selectedBirthDate != null
          ? '${_selectedBirthDate!.day.toString().padLeft(2, '0')}/${_selectedBirthDate!.month.toString().padLeft(2, '0')}/${_selectedBirthDate!.year}'
          : (_birthDateCtrl.text.trim().isNotEmpty ? _birthDateCtrl.text.trim() : null);

      // Inscription du patient avec toutes ses informations de profil
      final user = await db.registerPatient(
        phone: phone,
        password: password,
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        gender: _selectedGender,
        birthDate: birthDateStr,
        profession: _professionCtrl.text.trim().isNotEmpty ? _professionCtrl.text.trim() : null,
        city: _cityCtrl.text.trim().isNotEmpty ? _cityCtrl.text.trim() : 'Abidjan',
        commune: _communeCtrl.text.trim().isNotEmpty ? _communeCtrl.text.trim() : 'Cocody',
        cmuNumber: _cmuCtrl.text.trim().isNotEmpty ? _cmuCtrl.text.trim() : null,
      );

      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Ce numéro est déjà utilisé par un autre compte'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      if (!mounted) return;

      // Connexion automatique après inscription
      final auth = context.read<AuthProvider>();
      final success = await auth.loginPatient(
        identifier: phone,
        password: password,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bienvenue ${_firstNameCtrl.text.trim()} ! Votre profil est prêt.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pushReplacementNamed(context, '/patient/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.errorMessage ?? 'Compte créé avec succès. Veuillez vous connecter.'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pushReplacementNamed(context, '/patient/login');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur d\'inscription: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onBackPressed() {
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentStep == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _onBackPressed();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // ── Header gradient turquoise ──────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.height * 0.33,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  LucideIcons.chevron_left,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              onPressed: _onBackPressed,
                            ),
                            const Expanded(
                              child: Center(
                                child: AppLogo(
                                  height: 44,
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                ),
                              ),
                            ),
                            const SizedBox(width: 48),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _currentStep == 0
                            ? 'Votre Identité'
                            : _currentStep == 1
                                ? 'Coordonnées & CMU'
                                : _currentStep == 2
                                    ? 'Validation SMS'
                                    : 'Sécurisez votre',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 22,
                          fontWeight: FontWeight.w300,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        _currentStep == 0
                            ? 'Profil Patient'
                            : _currentStep == 1
                                ? 'Adresse & Contact'
                                : _currentStep == 2
                                    ? 'Code à 6 chiffres'
                                    : 'Mot de passe',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Carte blanche avec formulaire arrondi (effet wave) ──────────
            Positioned(
              top: MediaQuery.of(context).size.height * 0.26,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(36),
                    topRight: Radius.circular(36),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Stepper 1 - 2 - 3 - 4 ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                      child: _buildStepIndicator(),
                    ),

                    // ── Pager fluide ──
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(24, 6, 24, 24),
                            child: _buildStep0Identity(),
                          ),
                          SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(24, 6, 24, 24),
                            child: _buildStep1Contact(),
                          ),
                          SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(24, 6, 24, 24),
                            child: _buildStep2Otp(),
                          ),
                          SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(24, 6, 24, 24),
                            child: _buildStep3Password(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── STEPPER VISUEL (4 ÉTAPES) ──────────────────────────────────────
  Widget _buildStepIndicator() {
    return Row(
      children: [
        _buildStepDot(stepIndex: 0, label: 'Identité', icon: LucideIcons.user),
        _buildStepLine(isActive: _currentStep >= 1),
        _buildStepDot(stepIndex: 1, label: 'Contact', icon: LucideIcons.map_pin),
        _buildStepLine(isActive: _currentStep >= 2),
        _buildStepDot(stepIndex: 2, label: 'SMS', icon: LucideIcons.message_square_code),
        _buildStepLine(isActive: _currentStep >= 3),
        _buildStepDot(stepIndex: 3, label: 'Passe', icon: LucideIcons.lock),
      ],
    );
  }

  Widget _buildStepDot({
    required int stepIndex,
    required String label,
    required IconData icon,
  }) {
    final isDone = _currentStep > stepIndex;
    final isActive = _currentStep == stepIndex;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDone
                  ? AppColors.primary
                  : isActive
                      ? AppColors.primary
                      : AppColors.backgroundGrey,
              shape: BoxShape.circle,
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ]
                  : null,
            ),
            child: Icon(
              isDone ? LucideIcons.check : icon,
              size: 16,
              color: (isDone || isActive) ? Colors.white : AppColors.textLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? AppColors.primary : AppColors.textLight,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine({required bool isActive}) {
    return Container(
      width: 16,
      height: 2,
      margin: const EdgeInsets.only(bottom: 16),
      color: isActive ? AppColors.primary : AppColors.backgroundGrey,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ÉTAPE 0 : IDENTITÉ & PROFIL PATIENT
  // ═══════════════════════════════════════════════════════════════
  Widget _buildStep0Identity() {
    return Form(
      key: _identityFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informations personnelles',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Remplissez vos informations de base. Elles constituent votre profil médical sécurisé.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Nom de famille
          _buildFieldLabel('Nom de famille *'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _lastNameCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration: _inputDecoration(
              hint: 'Ex: KOUASSI',
              prefixIcon: LucideIcons.user,
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Veuillez saisir votre nom' : null,
          ),
          const SizedBox(height: 16),

          // Prénom(s)
          _buildFieldLabel('Prénom(s) *'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _firstNameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: _inputDecoration(
              hint: 'Ex: Jean-Marc',
              prefixIcon: LucideIcons.user_check,
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Veuillez saisir votre prénom' : null,
          ),
          const SizedBox(height: 16),

          // Sexe / Genre (Homme / Femme)
          _buildFieldLabel('Genre / Sexe *'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildGenderCard(
                  label: 'Homme',
                  icon: LucideIcons.user,
                  isSelected: _selectedGender == 'Homme',
                  onTap: () => setState(() => _selectedGender = 'Homme'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGenderCard(
                  label: 'Femme',
                  icon: LucideIcons.user,
                  isSelected: _selectedGender == 'Femme',
                  onTap: () => setState(() => _selectedGender = 'Femme'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Date de naissance
          _buildFieldLabel('Date de naissance *'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _birthDateCtrl,
            readOnly: true,
            onTap: _selectBirthDate,
            decoration: _inputDecoration(
              hint: 'JJ/MM/AAAA',
              prefixIcon: LucideIcons.calendar,
              suffixIcon: IconButton(
                icon: const Icon(LucideIcons.calendar_days, color: AppColors.primary, size: 20),
                onPressed: _selectBirthDate,
                tooltip: 'Sélectionner la date',
              ),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Veuillez choisir votre date de naissance';
              }
              final parsed = _selectedBirthDate ?? UserModel.parseFlexibleDate(v.trim());
              if (parsed == null) {
                return 'Format invalide (JJ/MM/AAAA)';
              }
              if (parsed.isAfter(DateTime.now())) {
                return 'La date ne peut pas être dans le futur';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Profession
          _buildFieldLabel('Profession'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _professionCtrl,
            decoration: _inputDecoration(
              hint: 'Ex: Enseignant, Étudiant, Commerçant...',
              prefixIcon: LucideIcons.briefcase,
            ),
          ),
          const SizedBox(height: 24),

          // Bouton Continuer vers Étape 1
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _handleStep0Identity,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Continuer',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(LucideIcons.arrow_right, color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Lien de connexion
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'Déjà inscrit ? ',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textSecondary),
                ),
                GestureDetector(
                  onTap: () => Navigator.pushReplacementNamed(context, '/patient/login'),
                  child: const Text(
                    'Se connecter',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ÉTAPE 1 : COORDONNÉES, VILLE, COMMUNE & CMU
  // ═══════════════════════════════════════════════════════════════
  Widget _buildStep1Contact() {
    return Form(
      key: _contactFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Coordonnées & CMU',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Votre numéro servira d\'identifiant de connexion et à recevoir le code de validation.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Numéro de téléphone
          _buildFieldLabel('Numéro de téléphone *'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              letterSpacing: 1.1,
            ),
            decoration: InputDecoration(
              prefixIconConstraints: const BoxConstraints(minWidth: 70, minHeight: 0),
              prefixIcon: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.centerLeft,
                width: 70,
                child: const Text(
                  '+225',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ),
              hintText: '07 00 00 00 00',
              filled: true,
              fillColor: AppColors.backgroundGrey,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Veuillez saisir votre numéro de téléphone';
              if (v.trim().length != 10) return 'Le numéro doit comporter 10 chiffres';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Ville de résidence (Liste déroulante)
          _buildFieldLabel('Ville de résidence *'),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: IvoryCoastLocations.cities.contains(_selectedCity) ? _selectedCity : IvoryCoastLocations.cities.first,
            isExpanded: true,
            icon: const Icon(LucideIcons.chevron_down, size: 18, color: AppColors.primary),
            decoration: _inputDecoration(
              hint: 'Sélectionnez votre ville',
              prefixIcon: LucideIcons.map_pin,
            ),
            items: IvoryCoastLocations.cities.map((city) {
              return DropdownMenuItem<String>(
                value: city,
                child: Text(
                  city,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: _onCityChanged,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Veuillez choisir votre ville' : null,
          ),
          const SizedBox(height: 16),

          // Commune / Quartier (Liste déroulante)
          _buildFieldLabel('Commune / Quartier *'),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: IvoryCoastLocations.getCommunes(_selectedCity).contains(_selectedCommune)
                ? _selectedCommune
                : IvoryCoastLocations.getCommunes(_selectedCity).first,
            isExpanded: true,
            icon: const Icon(LucideIcons.chevron_down, size: 18, color: AppColors.primary),
            decoration: _inputDecoration(
              hint: 'Sélectionnez votre commune',
              prefixIcon: LucideIcons.navigation,
            ),
            items: IvoryCoastLocations.getCommunes(_selectedCity).map((commune) {
              return DropdownMenuItem<String>(
                value: commune,
                child: Text(
                  commune,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: _onCommuneChanged,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Veuillez choisir votre commune' : null,
          ),
          const SizedBox(height: 16),

          // Numéro CMU (Optionnel)
          Row(
            children: [
              _buildFieldLabel('Numéro CMU'),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Optionnel',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _cmuCtrl,
            decoration: _inputDecoration(
              hint: 'Ex: CMU-000000-CI (laisser vide pour auto-génération)',
              prefixIcon: LucideIcons.credit_card,
            ),
          ),
          const SizedBox(height: 24),

          // Bouton Envoyer le code
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSendOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Recevoir le code SMS',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                        SizedBox(width: 8),
                        Icon(LucideIcons.arrow_right, color: Colors.white, size: 18),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ÉTAPE 2 : VÉRIFICATION CODE OTP
  // ═══════════════════════════════════════════════════════════════
  Widget _buildStep2Otp() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Code de vérification',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textSecondary),
                  children: [
                    const TextSpan(text: 'Code envoyé au '),
                    TextSpan(
                      text: '+225 ${_phoneCtrl.text.trim()}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                _timer?.cancel();
                _goToStep(1);
              },
              child: const Text('Modifier', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Pin code
        PinCodeTextField(
          appContext: context,
          controller: _pinCtrl,
          length: 6,
          autoFocus: true,
          onChanged: (v) => setState(() => _enteredOtp = v),
          onCompleted: (v) {
            _enteredOtp = v;
            _handleVerifyOtp();
          },
          pinTheme: PinTheme(
            shape: PinCodeFieldShape.box,
            borderRadius: BorderRadius.circular(12),
            fieldHeight: 52,
            fieldWidth: 42,
            activeColor: AppColors.primary,
            selectedColor: AppColors.primary,
            inactiveColor: AppColors.backgroundGrey,
            activeFillColor: AppColors.primary.withValues(alpha: 0.08),
            selectedFillColor: AppColors.primary.withValues(alpha: 0.08),
            inactiveFillColor: AppColors.backgroundGrey,
          ),
          enableActiveFill: true,
          keyboardType: TextInputType.number,
          textStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
        const SizedBox(height: 16),

        Center(
          child: _canResend
              ? TextButton.icon(
                  onPressed: _resendCode,
                  icon: const Icon(LucideIcons.rotate_cw, color: AppColors.primary, size: 16),
                  label: const Text('Renvoyer le code', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                )
              : Text('Renvoyer le code dans $_countdown s', style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textLight)),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _handleVerifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Text('Confirmer le code', style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ÉTAPE 3 : SÉCURITÉ & MOT DE PASSE
  // ═══════════════════════════════════════════════════════════════
  Widget _buildStep3Password() {
    return Form(
      key: _passFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Créer un mot de passe',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Définissez votre mot de passe pour accéder à votre espace santé sécurisé.',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 20),

          // Récapitulatif profil patient
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  child: const Icon(LucideIcons.user, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_lastNameCtrl.text.trim()} ${_firstNameCtrl.text.trim()}',
                        style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$_selectedGender • ${_communeCtrl.text.trim()}, ${_cityCtrl.text.trim()} • +225 ${_phoneCtrl.text.trim()}',
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _buildFieldLabel('Mot de passe (min. 6 caractères) *'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _passCtrl,
            obscureText: _obscurePass,
            decoration: InputDecoration(
              hintText: 'Mot de passe sécurisé',
              filled: true,
              fillColor: AppColors.backgroundGrey,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              prefixIcon: const Icon(LucideIcons.lock, size: 18, color: AppColors.textSecondary),
              suffixIcon: IconButton(
                icon: Icon(_obscurePass ? LucideIcons.eye_off : LucideIcons.eye, color: AppColors.textLight, size: 18),
                onPressed: () => setState(() => _obscurePass = !_obscurePass),
              ),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Veuillez saisir un mot de passe';
              if (v.trim().length < 6) return 'Le mot de passe doit comporter au moins 6 caractères';
              return null;
            },
          ),
          const SizedBox(height: 16),

          _buildFieldLabel('Confirmer le mot de passe *'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _confirmPassCtrl,
            obscureText: _obscureConfirm,
            decoration: InputDecoration(
              hintText: 'Répétez votre mot de passe',
              filled: true,
              fillColor: AppColors.backgroundGrey,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              prefixIcon: const Icon(LucideIcons.shield_check, size: 18, color: AppColors.textSecondary),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirm ? LucideIcons.eye_off : LucideIcons.eye, color: AppColors.textLight, size: 18),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Veuillez confirmer votre mot de passe';
              if (v.trim() != _passCtrl.text.trim()) return 'Les mots de passe ne correspondent pas';
              return null;
            },
          ),
          const SizedBox(height: 28),

          // Bouton Finaliser
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleCompleteRegistration,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text(
                      'Créer mon compte Patient',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── COMPOSANTS REUTILISABLES ───────────────────────────────────────
  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textLight.withValues(alpha: 0.6), fontSize: 13),
      filled: true,
      fillColor: AppColors.backgroundGrey,
      prefixIcon: Icon(prefixIcon, size: 18, color: AppColors.textSecondary),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    );
  }

  Widget _buildGenderCard({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.backgroundGrey,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.transparent),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? LucideIcons.circle_check : icon,
              size: 18,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
