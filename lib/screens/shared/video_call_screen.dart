import 'dart:async';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../../core/theme/app_theme.dart';
import '../../services/agora_service.dart';

/// Écran d'appel vidéo entre patient et médecin
class VideoCallScreen extends StatefulWidget {
  final String channelName;
  final String callerName;
  final String callerRole; // 'patient' ou 'doctor'
  final String? callerAvatar;
  final String receiverName;
  final String receiverRole;
  final String? receiverAvatar;
  final int uid;

  const VideoCallScreen({
    super.key,
    required this.channelName,
    required this.callerName,
    required this.callerRole,
    this.callerAvatar,
    required this.receiverName,
    required this.receiverRole,
    this.receiverAvatar,
    required this.uid,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final AgoraService _agoraService = AgoraService();
  
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isConnected = false;
  bool _isLoading = true;
  String _callStatus = 'Connexion en cours...';
  Timer? _callTimer;
  int _callDuration = 0;
  int? _remoteUid;

  @override
  void initState() {
    super.initState();
    _initializeCall();
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _agoraService.leaveChannel();
    super.dispose();
  }

  /// Initialiser l'appel vidéo
  Future<void> _initializeCall() async {
    try {
      // Initialiser Agora si pas déjà fait
      await _agoraService.initialize();

      // Configurer les événements
      _agoraService.engine?.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            if (mounted) {
              setState(() {
                _isConnected = true;
                _isLoading = false;
                _callStatus = 'Appel en cours';
              });
              _startCallTimer();
            }
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            if (mounted) {
              setState(() {
                _remoteUid = remoteUid;
                _callStatus = 'Connecté';
              });
            }
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            if (mounted) {
              setState(() {
                _remoteUid = null;
                _callStatus = 'En attente...';
              });
            }
          },
          onLeaveChannel: (RtcConnection connection, RtcStats stats) {
            if (mounted) {
              Navigator.pop(context);
            }
          },
          onError: (ErrorCodeType err, String msg) {
            debugPrint('❌ Erreur Agora: $err - $msg');
            if (mounted) {
              setState(() {
                _callStatus = 'Erreur de connexion';
                _isLoading = false;
              });
            }
          },
        ),
      );

      // Rejoindre le canal vidéo
      await _agoraService.joinVideoChannel(
        channelName: widget.channelName,
        uid: widget.uid,
      );
    } catch (e) {
      debugPrint('❌ Erreur initialisation appel: $e');
      if (mounted) {
        setState(() {
          _callStatus = 'Échec de connexion';
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Démarrer le timer d'appel
  void _startCallTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _callDuration++;
        });
      }
    });
  }

  /// Formater la durée d'appel
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// Basculer le micro
  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    _agoraService.toggleMicrophone(_isMuted);
  }

  /// Basculer la caméra
  void _toggleCamera() {
    setState(() {
      _isCameraOff = !_isCameraOff;
    });
    _agoraService.toggleCamera(_isCameraOff);
  }

  /// Changer de caméra (avant/arrière)
  void _switchCamera() {
    _agoraService.switchCamera();
  }

  /// Terminer l'appel
  void _endCall() {
    _callTimer?.cancel();
    _agoraService.leaveChannel();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Vidéo distante (plein écran)
          if (_remoteUid != null && !_isLoading)
            SizedBox.expand(
              child: AgoraVideoView(
                controller: VideoViewController.remote(
                  rtcEngine: _agoraService.engine!,
                  canvas: VideoCanvas(uid: _remoteUid),
                  connection: RtcConnection(channelId: widget.channelName),
                ),
              ),
            ),

          // État de chargement ou attente
          if (_isLoading || _remoteUid == null)
            Container(
              color: Colors.black,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isLoading)
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    const SizedBox(height: 24),
                    Text(
                      _callStatus,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (!_isLoading && _remoteUid == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          'En attente de ${widget.receiverName}...',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // Vidéo locale (petit encadré)
          if (!_isLoading && !_isCameraOff)
            Positioned(
              top: 50,
              right: 20,
              child: Container(
                width: 120,
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: AgoraVideoView(
                    controller: VideoViewController(
                      rtcEngine: _agoraService.engine!,
                      canvas: const VideoCanvas(uid: 0),
                    ),
                  ),
                ),
              ),
            ),

          // Header overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Nom et durée
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.receiverName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_isConnected && _callDuration > 0)
                          Text(
                            _formatDuration(_callDuration),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),

                    // Indicateur de connexion
                    if (_remoteUid != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.greenAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'En ligne',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
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

          // Contrôles en bas
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 30),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Microphone
                    _VideoControlButton(
                      icon: _isMuted ? Icons.mic_off : Icons.mic,
                      label: _isMuted ? 'Muet' : 'Micro',
                      isActive: !_isMuted,
                      onTap: _toggleMute,
                    ),

                    // Caméra
                    _VideoControlButton(
                      icon: _isCameraOff ? Icons.videocam_off : Icons.videocam,
                      label: 'Caméra',
                      isActive: !_isCameraOff,
                      onTap: _toggleCamera,
                    ),

                    // Changer caméra
                    _VideoControlButton(
                      icon: Icons.flip_camera_ios,
                      label: 'Changer',
                      isActive: true,
                      onTap: _switchCamera,
                    ),

                    // Raccrocher
                    _VideoControlButton(
                      icon: Icons.call_end,
                      label: 'Terminer',
                      isActive: false,
                      backgroundColor: Colors.red,
                      onTap: _endCall,
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

/// Widget de bouton de contrôle vidéo
class _VideoControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color? backgroundColor;
  final VoidCallback onTap;

  const _VideoControlButton({
    required this.icon,
    required this.label,
    required this.isActive,
    this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ??
        (isActive
            ? Colors.white.withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.15));

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
