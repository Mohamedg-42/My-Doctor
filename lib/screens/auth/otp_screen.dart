// ════════════════════════════════════════════════════════════
//  otp_screen.dart
//  Hello Doc - Vérification OTP 2FA
//  Design moderne inspiré Fuel Pay : Gradient turquoise + Wave
// ════════════════════════════════════════════════════════════

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_logo.dart';

class OtpScreen extends StatefulWidget {
  final String identifier;
  final String role;

  const OtpScreen({
    super.key,
    required this.identifier,
    required this.role,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  String _otp = '';
  int _countdown = 60;
  Timer? _timer;
  bool _canResend = false;
  bool _isVerifying = false;
  final _pinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _countdown = 60;
    _canResend = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          _canResend = true;
          t.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Veuillez entrer le code à 6 chiffres'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isVerifying = true);

    final auth = context.read<AuthProvider>();
    final ok = await auth.verify2FA(
      otp: _otp,
      role: widget.role,
      identifier: widget.identifier,
    );

    if (!mounted) return;
    setState(() => _isVerifying = false);

    if (ok) {
      if (widget.role == 'doctor') {
        Navigator.pushNamedAndRemoveUntil(
            context, '/doctor/home', (route) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(
            context, '/patient/home', (route) => false);
      }
    } else if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage!),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _resendCode() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Code renvoyé avec succès'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Header gradient turquoise avec wave ─────────────────
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
                              child: const Icon(Icons.arrow_back_ios_rounded,
                                  color: AppColors.primary, size: 18),
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Spacer(),
                          const AppLogo(
                            height: 48,
                            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          ),
                          const Spacer(),
                          const SizedBox(width: 48), // Équilibre le bouton retour
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Icône de sécurité
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.shield_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Titre
                    const Text(
                      'Vérification',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 32,
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

          // ── Carte blanche avec formulaire (effet wave) ──────────
          Positioned(
            top: MediaQuery.of(context).size.height * 0.3,
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(32, 40, 32, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Message d'information
                    const Text(
                      'Code de vérification',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Entrez le code à 6 chiffres envoyé à ${widget.identifier}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Champ PIN code
                    PinCodeTextField(
                      appContext: context,
                      controller: _pinController,
                      length: 6,
                      onChanged: (v) => setState(() => _otp = v),
                      onCompleted: (v) {
                        _otp = v;
                        _verify();
                      },
                      pinTheme: PinTheme(
                        shape: PinCodeFieldShape.box,
                        borderRadius: BorderRadius.circular(14),
                        fieldHeight: 56,
                        fieldWidth: 45,
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
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                      animationType: AnimationType.fade,
                      animationDuration: const Duration(milliseconds: 200),
                    ),
                    const SizedBox(height: 24),

                    // Bouton renvoyer / timer
                    Center(
                      child: _canResend
                          ? TextButton.icon(
                              onPressed: _resendCode,
                              icon: const Icon(Icons.refresh_rounded, size: 20),
                              label: const Text(
                                'Renvoyer le code',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.backgroundGrey,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.timer_outlined,
                                    size: 18,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Renvoyer dans $_countdown s',
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                    const SizedBox(height: 32),

                    // Bouton vérifier
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isVerifying ? null : _verify,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: _isVerifying
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Vérifier',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Message de sécurité
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            color: AppColors.success,
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'La vérification en deux étapes protège votre compte et vos données de santé.',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: AppColors.success,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
