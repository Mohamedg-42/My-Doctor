// lib/services/video_call_permission_service.dart
//
// Service centralisé de gestion des permissions caméra + microphone.
// Compatible Android, iOS et Web (via camera_web + permission_handler_html).

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';

/// Résultat d'une demande de permissions
class PermissionResult {
  final bool cameraGranted;
  final bool micGranted;
  final String? errorMessage;
  final bool isPermanentlyDenied;

  const PermissionResult({
    required this.cameraGranted,
    required this.micGranted,
    this.errorMessage,
    this.isPermanentlyDenied = false,
  });

  bool get allGranted => cameraGranted && micGranted;

  @override
  String toString() =>
      'PermissionResult(cam=$cameraGranted, mic=$micGranted, err=$errorMessage)';
}

/// Résultat de l'initialisation caméra
class CameraInitResult {
  final bool success;
  final CameraController? controller;
  final List<CameraDescription> cameras;
  final String? errorMessage;

  const CameraInitResult({
    required this.success,
    this.controller,
    this.cameras = const [],
    this.errorMessage,
  });
}

class VideoCallPermissionService {
  // ─── Vérification statut permissions ───────────────────────────────────────
  static Future<PermissionResult> checkPermissions() async {
    if (kIsWeb) {
      // Sur Web, les permissions sont gérées par le navigateur au moment
      // d'appeler getUserMedia — on retourne granted par défaut
      return const PermissionResult(cameraGranted: true, micGranted: true);
    }

    final camStatus = await Permission.camera.status;
    final micStatus = await Permission.microphone.status;

    return PermissionResult(
      cameraGranted: camStatus.isGranted,
      micGranted: micStatus.isGranted,
      isPermanentlyDenied:
          camStatus.isPermanentlyDenied || micStatus.isPermanentlyDenied,
    );
  }

  // ─── Demande de permissions ─────────────────────────────────────────────────
  static Future<PermissionResult> requestPermissions() async {
    if (kIsWeb) {
      // Sur Web : tenter d'ouvrir la caméra force le navigateur à demander
      try {
        final cameras = await availableCameras();
        if (cameras.isEmpty) {
          return const PermissionResult(
            cameraGranted: false,
            micGranted: false,
            errorMessage: 'Aucune caméra détectée sur cet appareil.',
          );
        }
        // Test rapide d'initialisation pour déclencher la demande navigateur
        final testCtrl = CameraController(
          cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.front,
            orElse: () => cameras.first,
          ),
          ResolutionPreset.low,
          enableAudio: true,
        );
        await testCtrl.initialize();
        await testCtrl.dispose();
        return const PermissionResult(cameraGranted: true, micGranted: true);
      } catch (e) {
        final msg = e.toString();
        if (msg.contains('NotAllowedError') || msg.contains('Permission')) {
          return const PermissionResult(
            cameraGranted: false,
            micGranted: false,
            errorMessage:
                'Accès caméra/micro refusé par le navigateur. Cliquez sur l\'icône 🔒 dans la barre d\'adresse pour autoriser.',
            isPermanentlyDenied: true,
          );
        }
        if (msg.contains('NotFoundError') || msg.contains('DevicesNotFound')) {
          return const PermissionResult(
            cameraGranted: false,
            micGranted: false,
            errorMessage:
                'Aucune caméra ou microphone détecté sur cet appareil.',
          );
        }
        return PermissionResult(
          cameraGranted: false,
          micGranted: false,
          errorMessage: 'Erreur d\'accès caméra : $msg',
        );
      }
    }

    // Android / iOS — demande via permission_handler
    final results = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    final camStatus = results[Permission.camera]!;
    final micStatus = results[Permission.microphone]!;

    final isPermanentlyDenied =
        camStatus.isPermanentlyDenied || micStatus.isPermanentlyDenied;

    String? errorMsg;
    if (!camStatus.isGranted && !micStatus.isGranted) {
      errorMsg = isPermanentlyDenied
          ? 'Caméra et microphone sont bloqués. Activez-les dans les paramètres de l\'application.'
          : 'Autorisation caméra et microphone refusées.';
    } else if (!camStatus.isGranted) {
      errorMsg = isPermanentlyDenied
          ? 'Caméra bloquée. Activez-la dans les paramètres.'
          : 'Autorisation caméra refusée.';
    } else if (!micStatus.isGranted) {
      errorMsg = isPermanentlyDenied
          ? 'Microphone bloqué. Activez-le dans les paramètres.'
          : 'Autorisation microphone refusée.';
    }

    return PermissionResult(
      cameraGranted: camStatus.isGranted,
      micGranted: micStatus.isGranted,
      errorMessage: errorMsg,
      isPermanentlyDenied: isPermanentlyDenied,
    );
  }

  // ─── Initialisation de la caméra ───────────────────────────────────────────
  static Future<CameraInitResult> initCamera({
    bool preferFront = true,
    ResolutionPreset resolution = ResolutionPreset.medium,
    bool enableAudio = true,
  }) async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        return const CameraInitResult(
          success: false,
          cameras: [],
          errorMessage: 'Aucune caméra disponible sur cet appareil.',
        );
      }

      // Choisir la caméra
      CameraDescription selected;
      if (preferFront) {
        selected = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
          orElse: () => cameras.first,
        );
      } else {
        selected = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first,
        );
      }

      final controller = CameraController(
        selected,
        resolution,
        enableAudio: enableAudio,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();

      return CameraInitResult(
        success: true,
        controller: controller,
        cameras: cameras,
      );
    } on CameraException catch (e) {
      String msg;
      switch (e.code) {
        case 'CameraAccessDenied':
          msg = 'Accès caméra refusé. Autorisez l\'accès dans les paramètres.';
          break;
        case 'AudioAccessDenied':
          msg = 'Accès microphone refusé. Autorisez l\'accès dans les paramètres.';
          break;
        case 'cameraPermission':
          msg = 'Permission caméra manquante.';
          break;
        default:
          msg = 'Erreur caméra (${e.code}): ${e.description}';
      }
      return CameraInitResult(
        success: false,
        cameras: [],
        errorMessage: msg,
      );
    } catch (e) {
      return CameraInitResult(
        success: false,
        cameras: [],
        errorMessage: 'Erreur inattendue: $e',
      );
    }
  }

  // ─── Ouvrir les paramètres système ─────────────────────────────────────────
  static Future<void> openAppSettings() async {
    if (!kIsWeb) {
      await openAppSettings();
    }
  }
}
