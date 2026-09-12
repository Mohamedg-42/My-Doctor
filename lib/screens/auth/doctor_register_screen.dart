// ════════════════════════════════════════════════════════════
//  doctor_register_screen.dart
//  MédiLink Care - Inscription Médecin Simplifiée (2 Étapes)
//  Étape 1: Nom & Prénom
//  Étape 2: Téléphone & Mot de passe (+ email optionnel)
//  Complétion du profil et validation admin après connexion
// ════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';
import '../../widgets/common/app_logo.dart';

class DoctorRegisterScreen extends StatefulWidget {
  const DoctorRegisterScreen({super.key});

  @override
  State<DoctorRegisterScreen> createState() => _DoctorRegisterScreenState();
}

class _DoctorRegisterScreenState extends State<DoctorRegisterScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  // Contrôleurs de champs
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _firstNameCtrl.addListener(_capitalizeFirstName);
    _lastNameCtrl.addListener(_capitalizeLastName);
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
      final capitalized = _capitalizeEachWord(text);
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
    _pageController.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage == 0) {
      if (!_validatePage1()) return;
      _pageController.animateToPage(
        1,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _handleRegister();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      Navigator.pop(context);
    }
  }

  bool _validatePage1() {
    if (_firstNameCtrl.text.trim().isEmpty) {
      _showError('Veuillez entrer votre nom');
      return false;
    }
    if (_lastNameCtrl.text.trim().isEmpty) {
      _showError('Veuillez entrer votre prénom');
      return false;
    }
    return true;
  }

  bool _validatePage2() {
    final phone = _phoneCtrl.text.trim();
    if (phone.length != 10) {
      _showError('Le numéro de téléphone doit contenir exactement 10 chiffres');
      return false;
    }

    final email = _emailCtrl.text.trim();
    if (email.isNotEmpty && (!email.contains('@') || !email.contains('.'))) {
      _showError('Veuillez entrer une adresse email valide ou laisser le champ vide');
      return false;
    }

    final pass = _passCtrl.text.trim();
    if (pass.length < 6) {
      _showError('Le mot de passe doit contenir au moins 6 caractères');
      return false;
    }

    if (pass != _confirmPassCtrl.text.trim()) {
      _showError('Les mots de passe ne correspondent pas');
      return false;
    }

    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.circle_alert, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _handleRegister() async {
    if (!_validatePage2()) return;

    setState(() => _isLoading = true);

    try {
      final db = DatabaseService();
      final fullPhone = '+225${_phoneCtrl.text.trim()}';
      final emailText = _emailCtrl.text.trim();

      // Enregistrement avec statut 'pending' par défaut
      final user = await db.registerDoctor(
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        phone: fullPhone,
        password: _passCtrl.text.trim(),
        email: emailText.isNotEmpty ? emailText : null,
        status: 'pending',
      );

      if (user == null) {
        if (!mounted) return;
        _showError('Ce numéro de téléphone est déjà utilisé par un autre compte.');
        setState(() => _isLoading = false);
        return;
      }

      if (!mounted) return;

      // Connexion automatique immédiate
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final loggedIn = await auth.loginDoctor(
        identifier: fullPhone,
        password: _passCtrl.text.trim(),
      );

      if (!mounted) return;

      if (loggedIn) {
        // Redirection directe vers le tableau de bord médecin
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/doctor/home',
          (route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.circle_check, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Bienvenue Dr. ${_lastNameCtrl.text.trim()} ! Complétez votre profil pour validation par l\'administration.',
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF0D9488),
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        Navigator.pushReplacementNamed(context, '/auth/welcome');
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Erreur lors de l\'inscription : $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header avec gradient et logo ──────────────────────────
            _buildHeader(),

            // ── Indicateur de progression (2 étapes) ─────────────────
            _buildProgressIndicator(),

            // ── Formulaire à 2 pages ─────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  _buildPage1(),
                  _buildPage2(),
                ],
              ),
            ),

            // ── Boutons de navigation ────────────────────────────────
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
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
                LucideIcons.arrow_left,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            onPressed: _previousPage,
          ),
          const Spacer(),
          const AppLogo(
            height: 50,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Étape ${_currentPage + 1} sur 2',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              Text(
                _currentPage == 0 ? 'Identité' : 'Sécurité & Accès',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(2, (index) {
              final isActive = index <= _currentPage;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 5,
                  margin: EdgeInsets.only(right: index < 1 ? 10 : 0),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // PAGE 1 : IDENTITÉ (NOM & PRÉNOM)
  // ══════════════════════════════════════════════════════════
  Widget _buildPage1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Création de compte Médecin',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Renseignez votre nom et prénom. Vous compléterez vos informations professionnelles après connexion.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),

          // Champ Nom de famille
          _buildInputField(
            controller: _firstNameCtrl,
            label: 'Nom de famille',
            hint: 'Ex: KOUASSI',
            icon: LucideIcons.user,
            capitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 20),

          // Champ Prénom(s)
          _buildInputField(
            controller: _lastNameCtrl,
            label: 'Prénom(s)',
            hint: 'Ex: Jean-Marc',
            icon: LucideIcons.user_check,
            capitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 28),

          // Note informative
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  LucideIcons.info,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'L\'inscription est rapide en 2 étapes. Votre spécialité, ville et numéro d\'ordre seront renseignés directement depuis votre espace praticien.',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // PAGE 2 : TÉLÉPHONE & MOT DE PASSE
  // ══════════════════════════════════════════════════════════
  Widget _buildPage2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Coordonnées & Sécurité',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Définissez votre numéro de téléphone et votre mot de passe pour sécuriser votre compte praticien.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),

          // Numéro de téléphone (+225)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Numéro de téléphone',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: InputDecoration(
                  hintText: '0102030405',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  prefixIcon: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.phone, color: AppColors.primary, size: 18),
                        const SizedBox(width: 8),
                        const Text(
                          '+225',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 1,
                          height: 18,
                          color: Colors.grey.shade300,
                        ),
                      ],
                    ),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Email (Optionnel)
          _buildInputField(
            controller: _emailCtrl,
            label: 'Adresse email (Facultatif)',
            hint: 'docteur@exemple.com',
            icon: LucideIcons.mail,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),

          // Mot de passe
          _buildPasswordField(
            controller: _passCtrl,
            label: 'Mot de passe',
            hint: 'Minimum 6 caractères',
            obscure: _obscurePass,
            onToggle: () => setState(() => _obscurePass = !_obscurePass),
          ),
          const SizedBox(height: 16),

          // Confirmation
          _buildPasswordField(
            controller: _confirmPassCtrl,
            label: 'Confirmer le mot de passe',
            hint: 'Retapez votre mot de passe',
            obscure: _obscureConfirm,
            onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
          const SizedBox(height: 24),

          // Information validation admin
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  LucideIcons.shield_alert,
                  color: Color(0xFFD97706),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Votre compte sera activé en attente de validation administrative. Une fois votre profil renseigné et validé par l\'admin, vous apparaitrez auprès des patients.',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.amber.shade900,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextCapitalization capitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: capitalization,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
            prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
            prefixIcon: const Icon(LucideIcons.lock, color: AppColors.primary, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                obscure ? LucideIcons.eye_off : LucideIcons.eye,
                color: Colors.grey.shade500,
                size: 20,
              ),
              onPressed: onToggle,
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _previousPage,
                icon: const Icon(LucideIcons.arrow_left, size: 18),
                label: const Text(
                  'Précédent',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentPage == 0 ? 'Continuer' : 'Créer mon compte',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _currentPage == 0 ? LucideIcons.arrow_right : LucideIcons.check,
                          size: 18,
                          color: Colors.white,
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
