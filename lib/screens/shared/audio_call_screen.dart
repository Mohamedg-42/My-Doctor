import 'dart:async';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../../core/theme/app_theme.dart';
import '../../services/agora_service.dart';
import '../../widgets/common/avatar_widget.dart';

/// Écran d'appel audio entre patient et médecin
class AudioCallScreen extends StatefulWidget {
  final String channelName;
  final String callerName;
  final String callerRole; // 'patient' ou 'doctor'
  final String? callerAvatar;
  final String receiverName;
  final String receiverRole;
  final String? receiverAvatar;
  final int uid;

  const AudioCallScreen({
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
  State<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen> {
  final AgoraService _agoraService = AgoraService();
  
  bool _isMuted = false;
  bool _isSpeakerOn = true;
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

  /// Initialiser l'appel audio
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

      // Rejoindre le canal audio
      await _agoraService.joinAudioChannel(
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

  /// Basculer le haut-parleur
  void _toggleSpeaker() {
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
    });
    _agoraService.toggleSpeaker(_isSpeakerOn);
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
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: _endCall,
                    ),
                    const Spacer(),
                    Text(
                      _callStatus,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48), // Balance avec le bouton retour
                  ],
                ),
              ),

              const Spacer(),

              // Avatar et informations
              Column(
                children: [
                  // Avatar du destinataire
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 4,
                      ),
                    ),
                    child: AvatarWidget(
                      imageUrl: widget.receiverAvatar,
                      initials: widget.receiverName.isNotEmpty
                          ? widget.receiverName.substring(0, 1).toUpperCase()
                          : 'U',
                      size: 120,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Nom du destinataire
                  Text(
                    widget.receiverName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Rôle du destinataire
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.receiverRole == 'doctor' ? 'Médecin' : 'Patient',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Durée d'appel
                  if (_isConnected && _callDuration > 0)
                    Text(
                      _formatDuration(_callDuration),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                  // Indicateur de connexion
                  if (_isLoading)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Column(
                        children: [
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Connexion...',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Indicateur utilisateur distant
                  if (_remoteUid != null && !_isLoading)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.greenAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'En ligne',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const Spacer(),

              // Contrôles
              Padding(
                padding: const EdgeInsets.all(40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Microphone
                    _CallControlButton(
                      icon: _isMuted ? Icons.mic_off : Icons.mic,
                      label: _isMuted ? 'Muet' : 'Micro',
                      isActive: !_isMuted,
                      onTap: _toggleMute,
                    ),

                    // Haut-parleur
                    _CallControlButton(
                      icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                      label: 'Haut-parleur',
                      isActive: _isSpeakerOn,
                      onTap: _toggleSpeaker,
                    ),

                    // Raccrocher
                    _CallControlButton(
                      icon: Icons.call_end,
                      label: 'Terminer',
                      isActive: false,
                      backgroundColor: Colors.red,
                      onTap: _endCall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget de bouton de contrôle d'appel
class _CallControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color? backgroundColor;
  final VoidCallback onTap;

  const _CallControlButton({
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
