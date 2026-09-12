import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

/// Service pour gérer les appels audio/vidéo via Agora WebRTC
/// 
/// Configuration requise :
/// - App ID Agora (obtenu depuis console.agora.io)
/// - Permissions : CAMERA, MICROPHONE (Android/iOS)
class AgoraService {
  static final AgoraService _instance = AgoraService._internal();
  factory AgoraService() => _instance;
  AgoraService._internal();

  RtcEngine? _engine;
  bool _isInitialized = false;

  /// App ID Agora - REMPLACER avec votre vraie clé en production
  /// Obtenez gratuitement sur : https://console.agora.io/
  static const String appId = 'YOUR_AGORA_APP_ID_HERE';
  
  /// Pour le développement, on utilise un token null (mode test)
  /// En production, générer des tokens côté serveur pour sécurité
  static const String? token = null;

  bool get isInitialized => _isInitialized;
  RtcEngine? get engine => _engine;

  /// Initialiser le moteur Agora RTC
  Future<void> initialize() async {
    if (_isInitialized) {
      if (kDebugMode) {
        debugPrint('✅ Agora déjà initialisé');
      }
      return;
    }

    try {
      // Créer le moteur Agora
      _engine = createAgoraRtcEngine();
      
      await _engine!.initialize(const RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      // Configuration pour appels 1-1
      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      await _engine!.enableAudio();
      
      _isInitialized = true;
      
      if (kDebugMode) {
        debugPrint('✅ Agora initialisé avec succès');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Erreur initialisation Agora: $e');
      }
      rethrow;
    }
  }

  /// Rejoindre un canal audio
  Future<void> joinAudioChannel({
    required String channelName,
    required int uid,
  }) async {
    if (!_isInitialized || _engine == null) {
      throw Exception('Agora non initialisé - appelez initialize() d\'abord');
    }

    try {
      // Demander permission microphone
      final micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) {
        throw Exception('Permission microphone refusée');
      }

      // Désactiver la vidéo pour appel audio uniquement
      await _engine!.disableVideo();
      
      // Rejoindre le canal
      await _engine!.joinChannel(
        token: token ?? '',
        channelId: channelName,
        uid: uid,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileCommunication,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          autoSubscribeAudio: true,
          autoSubscribeVideo: false,
        ),
      );

      if (kDebugMode) {
        debugPrint('✅ Rejoint canal audio: $channelName avec UID: $uid');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Erreur rejoindre canal audio: $e');
      }
      rethrow;
    }
  }

  /// Rejoindre un canal vidéo
  Future<void> joinVideoChannel({
    required String channelName,
    required int uid,
  }) async {
    if (!_isInitialized || _engine == null) {
      throw Exception('Agora non initialisé - appelez initialize() d\'abord');
    }

    try {
      // Demander permissions caméra et microphone
      final cameraStatus = await Permission.camera.request();
      final micStatus = await Permission.microphone.request();
      
      if (!cameraStatus.isGranted || !micStatus.isGranted) {
        throw Exception('Permissions caméra/microphone refusées');
      }

      // Activer la vidéo
      await _engine!.enableVideo();
      await _engine!.startPreview();
      
      // Rejoindre le canal
      await _engine!.joinChannel(
        token: token ?? '',
        channelId: channelName,
        uid: uid,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileCommunication,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
        ),
      );

      if (kDebugMode) {
        debugPrint('✅ Rejoint canal vidéo: $channelName avec UID: $uid');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Erreur rejoindre canal vidéo: $e');
      }
      rethrow;
    }
  }

  /// Quitter le canal actuel
  Future<void> leaveChannel() async {
    if (_engine == null) return;

    try {
      await _engine!.leaveChannel();
      await _engine!.stopPreview();
      
      if (kDebugMode) {
        debugPrint('✅ Canal quitté');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Erreur quitter canal: $e');
      }
    }
  }

  /// Activer/désactiver le microphone
  Future<void> toggleMicrophone(bool muted) async {
    if (_engine == null) return;
    
    try {
      await _engine!.muteLocalAudioStream(muted);
      
      if (kDebugMode) {
        debugPrint('🎤 Microphone ${muted ? "coupé" : "activé"}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Erreur toggle micro: $e');
      }
    }
  }

  /// Activer/désactiver la caméra
  Future<void> toggleCamera(bool muted) async {
    if (_engine == null) return;
    
    try {
      await _engine!.muteLocalVideoStream(muted);
      
      if (kDebugMode) {
        debugPrint('📹 Caméra ${muted ? "désactivée" : "activée"}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Erreur toggle caméra: $e');
      }
    }
  }

  /// Changer de caméra (avant/arrière)
  Future<void> switchCamera() async {
    if (_engine == null) return;
    
    try {
      await _engine!.switchCamera();
      
      if (kDebugMode) {
        debugPrint('🔄 Caméra changée');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Erreur switch caméra: $e');
      }
    }
  }

  /// Activer/désactiver haut-parleur
  Future<void> toggleSpeaker(bool enabled) async {
    if (_engine == null) return;
    
    try {
      await _engine!.setEnableSpeakerphone(enabled);
      
      if (kDebugMode) {
        debugPrint('🔊 Haut-parleur ${enabled ? "activé" : "désactivé"}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Erreur toggle haut-parleur: $e');
      }
    }
  }

  /// Nettoyer et libérer les ressources
  Future<void> dispose() async {
    if (_engine == null) return;

    try {
      await leaveChannel();
      await _engine!.release();
      _engine = null;
      _isInitialized = false;
      
      if (kDebugMode) {
        debugPrint('✅ Agora nettoyé');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Erreur dispose Agora: $e');
      }
    }
  }

  /// Générer un nom de canal unique basé sur patient + docteur
  static String generateChannelName(String patientId, String doctorId) {
    // Trier pour cohérence
    final ids = [patientId, doctorId]..sort();
    return 'call_${ids[0]}_${ids[1]}';
  }

  /// Générer un UID unique pour l'utilisateur
  static int generateUid(String userId) {
    // Convertir l'ID utilisateur en entier stable
    return userId.hashCode.abs() % 999999;
  }
}
