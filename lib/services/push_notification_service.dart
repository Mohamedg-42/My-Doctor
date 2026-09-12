import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

/// Service de gestion des notifications push
/// 
/// Fonctionnalités :
/// - Firebase Cloud Messaging (FCM) pour notifications push
/// - Notifications locales pour affichage en premier plan
/// - Gestion des clics sur notifications
/// - Badges et sons personnalisés
class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;
  bool get isInitialized => _isInitialized;

  /// Initialiser le service de notifications
  Future<void> initialize() async {
    if (_isInitialized) {
      if (kDebugMode) {
        debugPrint('✅ Notifications déjà initialisées');
      }
      return;
    }

    try {
      // 1. Demander permissions iOS/Android
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        if (kDebugMode) {
          debugPrint('✅ Permissions notifications accordées');
        }
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        if (kDebugMode) {
          debugPrint('⚠️ Permissions notifications provisoires');
        }
      } else {
        if (kDebugMode) {
          debugPrint('❌ Permissions notifications refusées');
        }
        return;
      }

      // 2. Obtenir le token FCM
      _fcmToken = await _firebaseMessaging.getToken();
      if (kDebugMode) {
        debugPrint('📱 FCM Token: $_fcmToken');
      }

      // 3. Écouter les changements de token
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        if (kDebugMode) {
          debugPrint('🔄 FCM Token mis à jour: $newToken');
        }
        // TODO: Envoyer le nouveau token au serveur
      });

      // 4. Initialiser les notifications locales
      await _initializeLocalNotifications();

      // 5. Configurer les handlers de messages
      _configureMessageHandlers();

      _isInitialized = true;
      if (kDebugMode) {
        debugPrint('✅ Service de notifications initialisé');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Erreur initialisation notifications: $e');
      }
      rethrow;
    }
  }

  /// Initialiser les notifications locales
  Future<void> _initializeLocalNotifications() async {
    // Configuration Android
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuration iOS
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    if (kDebugMode) {
      debugPrint('✅ Notifications locales initialisées');
    }
  }

  /// Configurer les handlers de messages Firebase
  void _configureMessageHandlers() {
    // Messages reçus quand l'app est au premier plan
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        debugPrint('📩 Message reçu (premier plan): ${message.notification?.title}');
      }

      // Afficher notification locale
      if (message.notification != null) {
        _showLocalNotification(
          title: message.notification!.title ?? 'Nouvelle notification',
          body: message.notification!.body ?? '',
          payload: message.data.toString(),
        );
      }
    });

    // Messages reçus quand l'app est en arrière-plan
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        debugPrint('📩 Notification cliquée (arrière-plan): ${message.notification?.title}');
      }
      _handleNotificationClick(message.data);
    });

    // Messages reçus quand l'app est fermée (handler en dehors de la classe)
    // Voir _firebaseMessagingBackgroundHandler en bas du fichier
  }

  /// Afficher une notification locale
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'my_doctor_channel', // Channel ID
      'Notifications My Doctor', // Channel name
      channelDescription: 'Notifications importantes de My Doctor',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond, // ID unique
      title,
      body,
      details,
      payload: payload,
    );

    if (kDebugMode) {
      debugPrint('✅ Notification locale affichée: $title');
    }
  }

  /// Gestion du clic sur notification (notification locale)
  void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) {
      debugPrint('👆 Notification cliquée (locale): ${response.payload}');
    }
    
    // TODO: Navigation vers l'écran approprié
    if (response.payload != null) {
      // Parser le payload et naviguer
      _handleNotificationClick({'action': response.payload});
    }
  }

  /// Gérer le clic sur notification
  void _handleNotificationClick(Map<String, dynamic> data) {
    // TODO: Implémenter la navigation selon le type de notification
    final String? action = data['action'];
    final String? requestId = data['requestId'];
    
    if (kDebugMode) {
      debugPrint('🔔 Action notification: $action, requestId: $requestId');
    }

    // Exemples de navigation :
    // - action = 'request_accepted' → Ouvrir chat avec médecin
    // - action = 'request_refused' → Ouvrir liste médecins
    // - action = 'new_request' → Ouvrir dashboard médecin
    // - action = 'new_message' → Ouvrir chat
  }

  /// Envoyer une notification de demande acceptée (patient)
  Future<void> notifyRequestAccepted({
    required String patientId,
    required String doctorName,
    required String doctorSpecialty,
  }) async {
    await _showLocalNotification(
      title: '✅ Demande acceptée !',
      body: 'Dr. $doctorName ($doctorSpecialty) a accepté votre demande de médecin traitant.',
      payload: 'request_accepted',
    );

    if (kDebugMode) {
      debugPrint('✅ Notification envoyée: Demande acceptée pour patient $patientId');
    }
  }

  /// Envoyer une notification de demande refusée (patient)
  Future<void> notifyRequestRefused({
    required String patientId,
    required String doctorName,
    required String? reason,
  }) async {
    final reasonText = reason != null && reason.isNotEmpty
        ? '\n\nMotif: $reason'
        : '';

    await _showLocalNotification(
      title: '❌ Demande refusée',
      body: 'Dr. $doctorName a refusé votre demande.$reasonText',
      payload: 'request_refused',
    );

    if (kDebugMode) {
      debugPrint('📢 Notification envoyée: Demande refusée pour patient $patientId');
    }
  }

  /// Envoyer une notification de nouvelle demande (médecin)
  Future<void> notifyNewRequest({
    required String doctorId,
    required String patientName,
    required String message,
  }) async {
    await _showLocalNotification(
      title: '🔔 Nouvelle demande !',
      body: '$patientName vous a envoyé une demande de médecin traitant.',
      payload: 'new_request',
    );

    if (kDebugMode) {
      debugPrint('📬 Notification envoyée: Nouvelle demande pour médecin $doctorId');
    }
  }

  /// Envoyer une notification de nouveau message
  Future<void> notifyNewMessage({
    required String userId,
    required String senderName,
    required String messagePreview,
  }) async {
    await _showLocalNotification(
      title: '💬 Nouveau message',
      body: '$senderName: $messagePreview',
      payload: 'new_message',
    );

    if (kDebugMode) {
      debugPrint('💬 Notification envoyée: Nouveau message pour $userId');
    }
  }

  /// S'abonner à un topic (pour notifications groupées)
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    if (kDebugMode) {
      debugPrint('✅ Abonné au topic: $topic');
    }
  }

  /// Se désabonner d'un topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    if (kDebugMode) {
      debugPrint('❌ Désabonné du topic: $topic');
    }
  }

  /// Nettoyer les ressources
  Future<void> dispose() async {
    // Rien à nettoyer pour FCM
    if (kDebugMode) {
      debugPrint('✅ Service de notifications nettoyé');
    }
  }
}

/// Handler pour les messages reçus en arrière-plan
/// DOIT être une fonction top-level (pas dans une classe)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    debugPrint('📩 Message reçu (arrière-plan): ${message.notification?.title}');
  }
  // Traitement du message en arrière-plan
  // Note: Impossible d'afficher UI ici, seulement traiter les données
}
