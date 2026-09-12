// lib/screens/shared/pre_call_screen.dart
//
// Écran de pré-appel affiché avant d'entrer dans une téléconsultation.
// Vérifie et demande les permissions caméra/micro, affiche un aperçu
// de la caméra locale, et permet de configurer audio/vidéo avant de rejoindre.

import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/video_call_permission_service.dart';
import '../patient/video_call_screen.dart';

class PreCallScreen extends StatefulWidget {
  final String doctorName;
  final String doctorSpecialty;
  final String? doctorAvatarBase64;
  final bool isIncoming; // true = médecin reçoit l'appel du patient

  const PreCallScreen({
    super.key,
    required this.doctorName,
    required this.doctorSpecialty,
    this.doctorAvatarBase64,
    this.isIncoming = false,
  });

  @override
  State<PreCallScreen> createState() => _PreCallScreenState();
}

class _PreCallScreenState extends State<PreCallScreen>
    with SingleTickerProviderStateMixin {

  // ─── États ──────────────────────────────────────────────────────────────────
  _CheckState _checkState = _CheckState.checking;
  PermissionResult? _permResult;
  CameraController? _previewCtrl;
  List<CameraDescription> _cameras = [];

  bool _micEnabled = true;
  bool _cameraEnabled = true;
  bool _isFront = true;
  bool _isJoining = false;

  // Animation entrée
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));

    _startPermissionCheck();
  }

  // ─── Vérification des permissions ──────────────────────────────────────────
  Future<void> _startPermissionCheck() async {
    setState(() => _checkState = _CheckState.checking);

    // 1. Vérifier le statut actuel
    final status = await VideoCallPermissionService.checkPermissions();

    if (status.allGranted) {
      // Déjà accordées → initialiser caméra directement
      _permResult = status;
      await _initPreviewCamera();
    } else {
      // Demander les permissions
      final requested = await VideoCallPermissionService.requestPermissions();
      _permResult = requested;

      if (requested.allGranted) {
        await _initPreviewCamera();
      } else {
        if (mounted) {
          setState(() => _checkState = _CheckState.denied);
        }
      }
    }
  }

  // ─── Initialisation de la caméra de prévisualisation ───────────────────────
  Future<void> _initPreviewCamera() async {
    if (!_cameraEnabled) {
      if (mounted) {
        setState(() => _checkState = _CheckState.ready);
        _animCtrl.forward();
      }
      return;
    }

    final result = await VideoCallPermissionService.initCamera(
      preferFront: _isFront,
      resolution: ResolutionPreset.medium,
      enableAudio: _micEnabled,
    );

    if (!mounted) return;

    if (result.success) {
      setState(() {
        _previewCtrl = result.controller;
        _cameras = result.cameras;
        _checkState = _CheckState.ready;
      });
      _animCtrl.forward();
    } else {
      setState(() {
        _checkState = _CheckState.cameraError;
        _permResult = PermissionResult(
          cameraGranted: _permResult?.cameraGranted ?? false,
          micGranted: _permResult?.micGranted ?? false,
          errorMessage: result.errorMessage,
        );
      });
      _animCtrl.forward();
    }
  }

  // ─── Retournement caméra ────────────────────────────────────────────────────
  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    await _previewCtrl?.dispose();
    setState(() {
      _isFront = !_isFront;
      _previewCtrl = null;
    });
    await _initPreviewCamera();
  }

  // ─── Toggle caméra preview ──────────────────────────────────────────────────
  Future<void> _toggleCamera() async {
    setState(() => _cameraEnabled = !_cameraEnabled);
    if (_cameraEnabled) {
      await _initPreviewCamera();
    } else {
      await _previewCtrl?.dispose();
      setState(() => _previewCtrl = null);
    }
  }

  // ─── Rejoindre l'appel ──────────────────────────────────────────────────────
  Future<void> _joinCall() async {
    setState(() => _isJoining = true);

    // Libérer la caméra de prévisualisation — VideoCallScreen va l'ouvrir lui-même
    await _previewCtrl?.dispose();
    _previewCtrl = null;

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a1, a2) => VideoCallScreen(
          doctorName: widget.doctorName,
          doctorSpecialty: widget.doctorSpecialty,
          doctorAvatar: widget.doctorAvatarBase64,
          isIncoming: widget.isIncoming,
          micEnabled: _micEnabled,
          cameraEnabled: _cameraEnabled,
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _previewCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    switch (_checkState) {
      case _CheckState.checking:
        return _buildCheckingView();
      case _CheckState.denied:
        return _buildDeniedView();
      case _CheckState.cameraError:
        return _buildCameraErrorView();
      case _CheckState.ready:
        return _buildReadyView();
    }
  }

  // ── Vue "Vérification en cours" ─────────────────────────────────────────────
  Widget _buildCheckingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(Icons.videocam_rounded,
                color: Colors.white, size: 38),
          ),
          const SizedBox(height: 24),
          const Text(
            'Vérification des accès...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Caméra et microphone',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 13,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 32),
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              color: Colors.white54,
              strokeWidth: 2.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Vue "Permissions refusées" ──────────────────────────────────────────────
  Widget _buildDeniedView() {
    final isPermanent = _permResult?.isPermanentlyDenied ?? false;
    const isWeb = kIsWeb;
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.error.withValues(alpha: 0.15),
              border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.4), width: 2),
            ),
            child: const Icon(Icons.videocam_off_rounded,
                color: AppColors.error, size: 38),
          ),
          const SizedBox(height: 24),
          const Text(
            'Accès refusé',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _permResult?.errorMessage ??
                'La téléconsultation nécessite l\'accès à la caméra et au microphone.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
              fontFamily: 'Poppins',
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),

          // Instructions selon la plateforme
          if (isWeb) ...[
            _buildWebPermissionGuide(),
          ] else ...[
            _buildMobilePermissionGuide(isPermanent),
          ],

          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Annuler',
                      style:
                          TextStyle(fontFamily: 'Poppins', fontSize: 14)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _startPermissionCheck,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Réessayer',
                      style:
                          TextStyle(fontFamily: 'Poppins', fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWebPermissionGuide() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: const Column(
        children: [
          _StepRow(
            icon: Icons.lock_outline_rounded,
            text: 'Cliquez sur l\'icône 🔒 dans la barre d\'adresse',
          ),
          SizedBox(height: 10),
          _StepRow(
            icon: Icons.settings_outlined,
            text: 'Sélectionnez "Paramètres du site"',
          ),
          SizedBox(height: 10),
          _StepRow(
            icon: Icons.videocam_rounded,
            text: 'Autorisez "Caméra" et "Microphone"',
          ),
          SizedBox(height: 10),
          _StepRow(
            icon: Icons.refresh_rounded,
            text: 'Cliquez sur "Réessayer" ci-dessous',
          ),
        ],
      ),
    );
  }

  Widget _buildMobilePermissionGuide(bool isPermanent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          if (isPermanent) ...[
            const _StepRow(
              icon: Icons.phone_android_rounded,
              text: 'Ouvrez les Paramètres de votre téléphone',
            ),
            const SizedBox(height: 10),
            const _StepRow(
              icon: Icons.apps_rounded,
              text: 'Applications → MédiLink Care',
            ),
            const SizedBox(height: 10),
            const _StepRow(
              icon: Icons.security_rounded,
              text: 'Autorisations → Activer Caméra et Micro',
            ),
          ] else ...[
            const _StepRow(
              icon: Icons.touch_app_rounded,
              text: 'Appuyez sur "Réessayer"',
            ),
            const SizedBox(height: 10),
            const _StepRow(
              icon: Icons.check_circle_outline_rounded,
              text: 'Acceptez les permissions caméra et microphone',
            ),
          ],
        ],
      ),
    );
  }

  // ── Vue "Erreur caméra" (permissions OK mais caméra inaccessible) ───────────
  Widget _buildCameraErrorView() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.orange.withValues(alpha: 0.15),
                  border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.4), width: 2),
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    color: Colors.orange, size: 38),
              ),
              const SizedBox(height: 24),
              const Text(
                'Caméra inaccessible',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _permResult?.errorMessage ??
                    'Impossible d\'accéder à la caméra.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                  fontFamily: 'Poppins',
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 28),
              // Continuer en audio seulement
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.mic_rounded,
                        color: Colors.white70, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Vous pouvez continuer en mode audio uniquement. La téléconsultation restera fonctionnelle.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontFamily: 'Poppins',
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.3)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Annuler',
                          style: TextStyle(
                              fontFamily: 'Poppins', fontSize: 14)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() => _cameraEnabled = false);
                        _joinCall();
                      },
                      icon: const Icon(Icons.mic_rounded, size: 18),
                      label: const Text('Audio seul',
                          style: TextStyle(
                              fontFamily: 'Poppins', fontSize: 14)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Vue "Prêt" — Prévisualisation + contrôles ───────────────────────────────
  Widget _buildReadyView() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Column(
          children: [
            // En-tête
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_back_ios_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Prêt à rejoindre ?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 36), // équilibre
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Nom du correspondant
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Text(
                    widget.isIncoming ? 'Consultation avec' : 'Appel vers',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.doctorName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    widget.doctorSpecialty,
                    style: TextStyle(
                      color: AppColors.primary.withValues(alpha: 0.85),
                      fontSize: 13,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Prévisualisation caméra
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: double.infinity,
                    color: const Color(0xFF1A1F2E),
                    child: _buildCameraPreview(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Contrôles pré-appel
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Micro
                  _PreCallBtn(
                    icon: _micEnabled
                        ? Icons.mic_rounded
                        : Icons.mic_off_rounded,
                    label: _micEnabled ? 'Micro' : 'Muet',
                    active: _micEnabled,
                    onTap: () => setState(() => _micEnabled = !_micEnabled),
                  ),
                  const SizedBox(width: 20),
                  // Caméra
                  _PreCallBtn(
                    icon: _cameraEnabled
                        ? Icons.videocam_rounded
                        : Icons.videocam_off_rounded,
                    label: _cameraEnabled ? 'Caméra' : 'Cam. off',
                    active: _cameraEnabled,
                    onTap: _toggleCamera,
                  ),
                  // Retourner caméra (si plusieurs caméras)
                  if (_cameras.length > 1) ...[
                    const SizedBox(width: 20),
                    _PreCallBtn(
                      icon: Icons.flip_camera_ios_rounded,
                      label: _isFront ? 'Avant' : 'Arrière',
                      active: true,
                      onTap: _switchCamera,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Bouton rejoindre
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isJoining ? null : _joinCall,
                  icon: _isJoining
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.videocam_rounded, size: 20),
                  label: Text(
                    _isJoining
                        ? 'Connexion...'
                        : widget.isIncoming
                            ? 'Rejoindre la consultation'
                            : 'Démarrer l\'appel',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF27AE60),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (!_cameraEnabled) {
      return _buildNoCamera(icon: Icons.videocam_off_rounded,
          label: 'Caméra désactivée');
    }
    if (_previewCtrl == null || !(_previewCtrl!.value.isInitialized)) {
      return const Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            color: Colors.white38,
            strokeWidth: 2,
          ),
        ),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(_previewCtrl!),
        // Badge micro off
        if (!_micEnabled)
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.mic_off_rounded, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text('Micro coupé',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontFamily: 'Poppins')),
                ],
              ),
            ),
          ),
        // Badge qualité
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.signal_cellular_alt_rounded,
                    color: Colors.greenAccent, size: 14),
                SizedBox(width: 4),
                Text('HD',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoCamera({required IconData icon, required String label}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white24, size: 52),
        const SizedBox(height: 12),
        Text(label,
            style: const TextStyle(
                color: Colors.white38,
                fontFamily: 'Poppins',
                fontSize: 13)),
      ],
    );
  }
}

// ─── Bouton contrôle pré-appel ────────────────────────────────────────────────
class _PreCallBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _PreCallBtn({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active
                  ? Colors.white.withValues(alpha: 0.15)
                  : AppColors.error.withValues(alpha: 0.25),
              border: Border.all(
                color: active
                    ? Colors.white.withValues(alpha: 0.3)
                    : AppColors.error.withValues(alpha: 0.6),
                width: 1.5,
              ),
            ),
            child: Icon(
              icon,
              color: active ? Colors.white : AppColors.error,
              size: 24,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: active
                  ? Colors.white.withValues(alpha: 0.7)
                  : AppColors.error,
              fontSize: 11,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Widget étape guide permissions ──────────────────────────────────────────
class _StepRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _StepRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontFamily: 'Poppins',
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── États internes ───────────────────────────────────────────────────────────
enum _CheckState { checking, denied, cameraError, ready }
