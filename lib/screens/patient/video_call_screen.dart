// lib/screens/patient/video_call_screen.dart
//
// Écran de téléconsultation vidéo.
// Caméra locale réelle via le package `camera`, avec fallback gracieux.
// Reçoit les préférences micro/caméra depuis PreCallScreen.

import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/video_call_permission_service.dart';

class VideoCallScreen extends StatefulWidget {
  final String doctorName;
  final String doctorSpecialty;
  final String? doctorAvatar;
  final bool isIncoming;
  final bool micEnabled;
  final bool cameraEnabled;

  const VideoCallScreen({
    super.key,
    required this.doctorName,
    required this.doctorSpecialty,
    this.doctorAvatar,
    this.isIncoming = false,
    this.micEnabled = true,
    this.cameraEnabled = true,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen>
    with TickerProviderStateMixin {

  // ─── États appel ────────────────────────────────────────────────────────────
  bool _isConnecting = true;
  bool _isConnected  = false;
  bool _isMicOn      = true;
  bool _isCameraOn   = true;
  bool _isSpeakerOn  = true;
  bool _isFrontCamera = true;
  bool _showControls  = true;
  bool _isChatOpen    = false;

  // ─── Caméra ─────────────────────────────────────────────────────────────────
  CameraController? _cameraCtrl;
  List<CameraDescription> _cameras = [];
  bool _cameraReady   = false;
  bool _cameraError   = false;
  String _cameraErrorMsg = '';
  bool _cameraLoading = false;

  // ─── Timer & durée ──────────────────────────────────────────────────────────
  Duration _callDuration = Duration.zero;
  Timer? _timer;
  Timer? _hideTimer;
  Timer? _connectTimer;

  // ─── Chat in-call ────────────────────────────────────────────────────────────
  final _chatCtrl       = TextEditingController();
  final _chatScrollCtrl = ScrollController();
  final List<Map<String, dynamic>> _chatMessages = [];

  // ─── Animations ─────────────────────────────────────────────────────────────
  late AnimationController _pulseCtrl;
  late AnimationController _connectingCtrl;
  late Animation<double>   _pulseAnim;
  late Animation<double>   _connectingAnim;

  @override
  void initState() {
    super.initState();

    // Initialiser depuis les préférences PreCallScreen
    _isMicOn    = widget.micEnabled;
    _isCameraOn = widget.cameraEnabled;

    // Animations
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat();
    _connectingCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.18).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _connectingAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _connectingCtrl, curve: Curves.easeInOut));

    // Initialiser la caméra si activée
    if (_isCameraOn) _initCamera();

    // Simuler la connexion (3 sec) — remplacer par vraie signalisation WebRTC
    _connectTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _isConnecting = false;
        _isConnected  = true;
      });
      _startCallTimer();
      _scheduleHideControls();
      _addSystemMsg('Connexion établie avec ${widget.doctorName}');
    });
  }

  // ─── Initialisation caméra ──────────────────────────────────────────────────
  Future<void> _initCamera() async {
    if (_cameraLoading) return;
    setState(() { _cameraLoading = true; _cameraError = false; });

    final result = await VideoCallPermissionService.initCamera(
      preferFront: _isFrontCamera,
      resolution: ResolutionPreset.medium,
      enableAudio: _isMicOn,
    );

    if (!mounted) return;

    if (result.success) {
      setState(() {
        _cameraCtrl   = result.controller;
        _cameras      = result.cameras;
        _cameraReady  = true;
        _cameraError  = false;
        _cameraLoading = false;
      });
    } else {
      setState(() {
        _cameraError    = true;
        _cameraErrorMsg = result.errorMessage ?? 'Caméra non disponible.';
        _cameraReady    = false;
        _cameraLoading  = false;
      });
    }
  }

  // ─── Retournement caméra ────────────────────────────────────────────────────
  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    final oldCtrl = _cameraCtrl;
    setState(() { _isFrontCamera = !_isFrontCamera; _cameraReady = false; });
    await oldCtrl?.dispose();
    _cameraCtrl = null;
    await _initCamera();
  }

  // ─── Toggle caméra ──────────────────────────────────────────────────────────
  Future<void> _toggleCamera() async {
    setState(() => _isCameraOn = !_isCameraOn);
    if (_isCameraOn) {
      await _initCamera();
    } else {
      await _cameraCtrl?.dispose();
      setState(() { _cameraCtrl = null; _cameraReady = false; });
    }
    _scheduleHideControls();
  }

  // ─── Timer appel ────────────────────────────────────────────────────────────
  void _startCallTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _callDuration += const Duration(seconds: 1));
    });
  }

  void _scheduleHideControls() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && !_isChatOpen) setState(() => _showControls = false);
    });
  }

  void _onTapScreen() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _scheduleHideControls();
  }

  // ─── Chat ────────────────────────────────────────────────────────────────────
  void _addSystemMsg(String text) {
    setState(() => _chatMessages.add({
      'text': text, 'isMe': false, 'isSystem': true, 'time': DateTime.now()
    }));
  }

  void _sendChatMsg() {
    final text = _chatCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _chatMessages.add({'text': text, 'isMe': true, 'isSystem': false, 'time': DateTime.now()});
      _chatCtrl.clear();
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_chatScrollCtrl.hasClients) {
        _chatScrollCtrl.animateTo(
          _chatScrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _fmtDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '$h:$m:$s' : '$m:$s';
  }

  void _endCall() {
    _timer?.cancel();
    _hideTimer?.cancel();
    _connectTimer?.cancel();
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _hideTimer?.cancel();
    _connectTimer?.cancel();
    _pulseCtrl.dispose();
    _connectingCtrl.dispose();
    _cameraCtrl?.dispose();
    _chatCtrl.dispose();
    _chatScrollCtrl.dispose();
    super.dispose();
  }

  // ─── BUILD PRINCIPAL ────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _onTapScreen,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // Fond : flux distant simulé (future intégration WebRTC)
            _buildRemoteView(),

            // PiP : ma caméra locale (coin bas-droit)
            if (_isConnected) _buildPip(),

            // Overlay connexion en cours
            if (_isConnecting) _buildConnectingOverlay(),

            // Barre top
            if (_showControls) _buildTopBar(),

            // Contrôles bas
            if (_showControls) _buildBottomBar(),

            // Chat
            if (_isChatOpen) _buildChatPanel(),
          ],
        ),
      ),
    );
  }

  // ── Vue distante simulée ────────────────────────────────────────────────────
  Widget _buildRemoteView() {
    if (!_isConnected) {
      return Container(color: const Color(0xFF0D1117));
    }
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0D1117), Color(0xFF1A1A2E)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 30,
                  spreadRadius: 6,
                ),
              ],
            ),
            child: const Icon(Icons.person_rounded,
                size: 52, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            widget.doctorName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.doctorSpecialty,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 13,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 12),
          // Indicateur flux distant simulé
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Flux vidéo distant',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── PiP — ma caméra locale ──────────────────────────────────────────────────
  Widget _buildPip() {
    return Positioned(
      bottom: 130,
      right: 16,
      child: GestureDetector(
        onTap: _cameras.length > 1 ? _switchCamera : null,
        child: Container(
          width: 92,
          height: 134,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 12,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildCameraWidget(isSmall: true),
          ),
        ),
      ),
    );
  }

  // ── Widget caméra (préview + états) ────────────────────────────────────────
  Widget _buildCameraWidget({bool isSmall = false}) {
    // Caméra désactivée
    if (!_isCameraOn) {
      return Container(
        color: const Color(0xFF1A1A2E),
        child: const Center(
          child: Icon(Icons.videocam_off_rounded,
              color: Colors.white38, size: 28),
        ),
      );
    }
    // Chargement
    if (_cameraLoading) {
      return Container(
        color: const Color(0xFF1A1A2E),
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
                color: Colors.white38, strokeWidth: 2),
          ),
        ),
      );
    }
    // Erreur caméra
    if (_cameraError) {
      return Container(
        color: const Color(0xFF1A1A2E),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.videocam_off_rounded,
                  color: Colors.white30,
                  size: isSmall ? 22 : 40),
              if (!isSmall) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    _cameraErrorMsg,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      fontFamily: 'Poppins',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _initCamera,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.5)),
                    ),
                    child: const Text(
                      'Réessayer',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }
    // Caméra non initialisée
    if (!_cameraReady || _cameraCtrl == null ||
        !_cameraCtrl!.value.isInitialized) {
      return Container(
        color: const Color(0xFF1A1A2E),
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
                color: Colors.white38, strokeWidth: 2),
          ),
        ),
      );
    }
    // Preview caméra réelle
    return CameraPreview(_cameraCtrl!);
  }

  // ── Overlay connexion ───────────────────────────────────────────────────────
  Widget _buildConnectingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.88),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _pulseAnim,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.5),
                      blurRadius: 30,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(Icons.videocam_rounded,
                    color: Colors.white, size: 52),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              widget.isIncoming
                  ? 'Appel entrant...'
                  : 'Connexion en cours...',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.doctorName,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 15,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.doctorSpecialty,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 13,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 36),
            FadeTransition(
              opacity: _connectingAnim,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.white54,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Barre supérieure ────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16, right: 16, bottom: 14,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.75),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            // Durée / statut
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Colors.green.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _isConnected ? Colors.green : Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _isConnected
                        ? _fmtDuration(_callDuration)
                        : 'Connexion...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Nom
            Text(
              widget.doctorName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const Spacer(),
            // Bouton chat
            _TopBtn(
              icon: _isChatOpen
                  ? Icons.chat_bubble_rounded
                  : Icons.chat_bubble_outline_rounded,
              badge: _chatMessages
                  .where((m) => !m['isMe'] && !m['isSystem'])
                  .length,
              onTap: () {
                setState(() => _isChatOpen = !_isChatOpen);
                _scheduleHideControls();
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Barre de contrôles bas ──────────────────────────────────────────────────
  Widget _buildBottomBar() {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 24,
          top: 20, left: 16, right: 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.85),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Micro
            _CtrlBtn(
              icon: _isMicOn ? Icons.mic_rounded : Icons.mic_off_rounded,
              label: _isMicOn ? 'Micro' : 'Muet',
              active: _isMicOn,
              onTap: () {
                setState(() => _isMicOn = !_isMicOn);
                _scheduleHideControls();
              },
            ),
            // Caméra
            _CtrlBtn(
              icon: _isCameraOn
                  ? Icons.videocam_rounded
                  : Icons.videocam_off_rounded,
              label: _isCameraOn ? 'Caméra' : 'Cam. off',
              active: _isCameraOn,
              onTap: _toggleCamera,
            ),
            // Raccrocher
            GestureDetector(
              onTap: _endCall,
              child: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.error.withValues(alpha: 0.55),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.call_end_rounded,
                    color: Colors.white, size: 32),
              ),
            ),
            // Haut-parleur
            _CtrlBtn(
              icon: _isSpeakerOn
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded,
              label: _isSpeakerOn ? 'Haut-parl.' : 'HP off',
              active: _isSpeakerOn,
              onTap: () {
                setState(() => _isSpeakerOn = !_isSpeakerOn);
                _scheduleHideControls();
              },
            ),
            // Retourner caméra
            _CtrlBtn(
              icon: Icons.flip_camera_ios_rounded,
              label: _isFrontCamera ? 'Retourner' : 'Avant',
              active: true,
              onTap: () {
                _switchCamera();
                _scheduleHideControls();
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Panneau chat in-call ────────────────────────────────────────────────────
  Widget _buildChatPanel() {
    return Positioned(
      bottom: 0,
      right: 0,
      top: MediaQuery.of(context).padding.top + 56,
      width: MediaQuery.of(context).size.width * 0.76,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E).withValues(alpha: 0.96),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            bottomLeft: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(-4, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            // En-tête
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded,
                      color: Colors.white70, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'Messages',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _isChatOpen = false),
                    child: const Icon(Icons.close_rounded,
                        color: Colors.white60),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white10, height: 1),

            // Liste messages
            Expanded(
              child: _chatMessages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'Envoyez un message\nà ${widget.doctorName}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 13,
                            fontFamily: 'Poppins',
                            height: 1.6,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _chatScrollCtrl,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      itemCount: _chatMessages.length,
                      itemBuilder: (_, i) {
                        final msg = _chatMessages[i];
                        if (msg['isSystem'] == true) {
                          return Center(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                msg['text'],
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 10,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          );
                        }
                        final isMe = msg['isMe'] as bool;
                        return Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 3),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? AppColors.primary
                                  : Colors.white
                                      .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              msg['text'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Champ saisie
            Padding(
              padding: EdgeInsets.only(
                left: 10,
                right: 10,
                bottom: MediaQuery.of(context).padding.bottom + 10,
                top: 8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: TextField(
                        controller: _chatCtrl,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontFamily: 'Poppins',
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Message...',
                          hintStyle: TextStyle(
                              color: Colors.white38, fontSize: 13),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                        ),
                        onSubmitted: (_) => _sendChatMsg(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendChatMsg,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bouton de contrôle ───────────────────────────────────────────────────────
class _CtrlBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _CtrlBtn({
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
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: active
                  ? Colors.white.withValues(alpha: 0.15)
                  : AppColors.error.withValues(alpha: 0.3),
              shape: BoxShape.circle,
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
              color: (active ? Colors.white : AppColors.error)
                  .withValues(alpha: 0.85),
              fontSize: 10,
              fontFamily: 'Poppins',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── Bouton top (chat) ────────────────────────────────────────────────────────
class _TopBtn extends StatelessWidget {
  final IconData icon;
  final int badge;
  final VoidCallback onTap;

  const _TopBtn({required this.icon, required this.onTap, this.badge = 0});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          if (badge > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$badge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
