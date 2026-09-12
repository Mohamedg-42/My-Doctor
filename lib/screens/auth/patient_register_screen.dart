// ════════════════════════════════════════════════════════════
//  patient_register_screen.dart
//  MédiLink Care - Inscription Patient Simplifiée
//  Flux en 3 étapes : 1. Numéro -> 2. Code SMS -> 3. Mot de passe
//  Design moderne inspiré Fuel Pay : Gradient turquoise + Wave
// ════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';
import '../../widgets/common/app_logo.dart';

class PatientRegisterScreen extends StatefulWidget {
  const PatientRegisterScreen({super.key});

  @override
  State<PatientRegisterScreen> createState() => _PatientRegisterScreenState();
}

class _PatientRegisterScreenState extends State<PatientRegisterScreen> {
  // Contrôle des étapes : 0 = Téléphone, 1 = OTP/SMS, 2 = Mot de passe
  int _currentStep = 0;
  final PageController _pageController = PageController();

  // Formulaires & contrôleurs
  final _phoneFormKey = GlobalKey<FormState>();
  final _passFormKey = GlobalKey<FormState>();

  final _phoneCtrl = TextEditingController();
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
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _phoneCtrl.dispose();
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

  // ─── ÉTAPE 1 : ENVOI DU CODE OTP ────────────────────────────────────
  Future<void> _handleSendOtp() async {
    if (!_phoneFormKey.currentState!.validate()) return;

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

      // Simulation de latence réseau
      await Future.delayed(const Duration(milliseconds: 600));

      if (!mounted) return;

      _startCountdown();

      setState(() => _isLoading = false);
      _goToStep(1); // Passage à l'étape 2 (Code OTP) avec animation fluide

      // Notification visuelle / bannière informant du code généré
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

    // Accepte le code généré ou code universel de démo "123456"
    if (_enteredOtp == _generatedOtp || _enteredOtp == '123456') {
      _timer?.cancel();
      _goToStep(2); // Passage à l'étape 3 (Mot de passe) avec animation fluide
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

      // Inscription du patient en base
      final user = await db.registerPatient(
        phone: phone,
        password: password,
        firstName: 'Patient',
        lastName: '',
      );

      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Ce numéro est déjà utilisé'),
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
            content: const Text('Compte créé avec succès ! Bienvenue.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pushReplacementNamed(context, '/patient/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.errorMessage ?? 'Erreur lors de la connexion'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
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

  // ─── GESTION RETOUR ARRIÈRE ─────────────────────────────────────────
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
              height: MediaQuery.of(context).size.height * 0.35,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      // Barre supérieure avec bouton retour et logo officiel
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
                            const Spacer(),
                            const AppLogo(
                              height: 52,
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            ),
                            const Spacer(),
                            const SizedBox(width: 48), // Équilibre le bouton retour
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Titre dynamique selon l'étape
                      Text(
                        _currentStep == 0
                            ? 'Créez votre'
                            : _currentStep == 1
                                ? 'Vérification'
                                : 'Sécurisez votre',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 26,
                          fontWeight: FontWeight.w300,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        _currentStep == 0
                            ? 'compte patient'
                            : _currentStep == 1
                                ? 'par SMS'
                                : 'mot de passe',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 26,
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
              top: MediaQuery.of(context).size.height * 0.28,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Indicateur visuel d'étapes (Stepper 1-2-3) ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 28, 28, 12),
                      child: _buildStepIndicator(),
                    ),

                    // ── Pager fluide avec animation de glissement entre étapes ──
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
                            child: _buildStep1Phone(),
                          ),
                          SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
                            child: _buildStep2Otp(),
                          ),
                          SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
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

  // ─── STEPPER VISUEL ─────────────────────────────────────────────────
  Widget _buildStepIndicator() {
    return Row(
      children: [
        _buildStepDot(stepIndex: 0, label: 'Numéro', icon: LucideIcons.smartphone),
        _buildStepLine(isActive: _currentStep >= 1),
        _buildStepDot(stepIndex: 1, label: 'Code SMS', icon: LucideIcons.message_square_code),
        _buildStepLine(isActive: _currentStep >= 2),
        _buildStepDot(stepIndex: 2, label: 'Passe', icon: LucideIcons.lock),
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
            width: 40,
            height: 40,
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
              size: 18,
              color: (isDone || isActive) ? Colors.white : AppColors.textLight,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? AppColors.primary : AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine({required bool isActive}) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        color: isActive ? AppColors.primary : AppColors.backgroundGrey,
      ),
    );
  }

  // ─── WIDGET : ÉTAPE 1 (NUMÉRO DE TÉLÉPHONE) ────────────────────────
  Widget _buildStep1Phone() {
    return Form(
      key: _phoneFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Votre numéro',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Entrez votre numéro de téléphone. Un code de vérification SMS vous sera immédiatement transmis.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),

          // Champ Téléphone
          TextFormField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            autofocus: true,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              letterSpacing: 1.2,
            ),
            decoration: InputDecoration(
              prefixIconConstraints: const BoxConstraints(minWidth: 70, minHeight: 0),
              prefixIcon: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.centerLeft,
                width: 70,
                child: const Text(
                  '+225',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              hintText: '07 00 00 00 00',
              hintStyle: TextStyle(
                color: AppColors.textLight.withValues(alpha: 0.6),
                fontSize: 14,
                letterSpacing: 0.5,
              ),
              filled: true,
              fillColor: AppColors.backgroundGrey,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Veuillez saisir votre numéro de téléphone';
              }
              if (v.trim().length < 8) {
                return 'Numéro invalide (minimum 8 chiffres)';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),

          // Bouton Continuer / Envoyer le code
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSendOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Recevoir le code',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(LucideIcons.arrow_right, color: Colors.white, size: 20),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 24),

          // Lien vers Connexion
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Déjà un compte ? ',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
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

  // ─── WIDGET : ÉTAPE 2 (VÉRIFICATION CODE OTP) ──────────────────────
  Widget _buildStep2Otp() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Code de vérification',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  children: [
                    const TextSpan(text: 'Code envoyé au '),
                    TextSpan(
                      text: '+225 ${_phoneCtrl.text.trim()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                _timer?.cancel();
                _goToStep(0);
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(50, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Modifier',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Champ PIN Code
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
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
          animationType: AnimationType.fade,
          animationDuration: const Duration(milliseconds: 200),
        ),
        const SizedBox(height: 16),

        // Timer & Renvoyer
        Center(
          child: _canResend
              ? TextButton.icon(
                  onPressed: _resendCode,
                  icon: const Icon(LucideIcons.rotate_cw, color: AppColors.primary, size: 18),
                  label: const Text(
                    'Renvoyer le code',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                )
              : Text(
                  'Renvoyer le code dans $_countdown s',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: AppColors.textLight,
                  ),
                ),
        ),
        const SizedBox(height: 24),

        // Bouton Valider le code
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _handleVerifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Confirmer le code',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── WIDGET : ÉTAPE 3 (DÉFINITION DU MOT DE PASSE) ─────────────────
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
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Définissez votre mot de passe pour accéder à votre espace santé en toute sécurité.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // Champ Mot de passe
          TextFormField(
            controller: _passCtrl,
            obscureText: _obscurePass,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Mot de passe (min. 6 caractères)',
              hintStyle: TextStyle(
                color: AppColors.textLight.withValues(alpha: 0.6),
                fontSize: 14,
              ),
              filled: true,
              fillColor: AppColors.backgroundGrey,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePass ? LucideIcons.eye_off : LucideIcons.eye,
                  color: AppColors.textLight,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscurePass = !_obscurePass),
              ),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Veuillez saisir un mot de passe';
              }
              if (v.trim().length < 6) {
                return 'Le mot de passe doit comporter au moins 6 caractères';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Champ Confirmation du mot de passe
          TextFormField(
            controller: _confirmPassCtrl,
            obscureText: _obscureConfirm,
            decoration: InputDecoration(
              hintText: 'Confirmer le mot de passe',
              hintStyle: TextStyle(
                color: AppColors.textLight.withValues(alpha: 0.6),
                fontSize: 14,
              ),
              filled: true,
              fillColor: AppColors.backgroundGrey,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm ? LucideIcons.eye_off : LucideIcons.eye,
                  color: AppColors.textLight,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Veuillez confirmer votre mot de passe';
              }
              if (v.trim() != _passCtrl.text.trim()) {
                return 'Les mots de passe ne correspondent pas';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),

          // Bouton Finaliser Inscription
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleCompleteRegistration,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Créer mon compte',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
