import 'package:flutter/foundation.dart';
import '../models/review_model.dart';

// ─── Modèle Notification ──────────────────────────────────────────────────────
enum NotifType { appointment, message, payment, review, system, videoCall }

class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotifType type;
  final DateTime createdAt;
  bool isRead;
  final String? routeOnTap;
  final Map<String, dynamic>? data;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.routeOnTap,
    this.data,
  });
}

// ─── Modèle Paiement ─────────────────────────────────────────────────────────
enum PaymentMethod { wave, orangeMoney, mtnMoney, moovMoney, djamo, visa, mastercard }
enum PaymentStatus { pending, processing, success, failed, refunded }
enum PaymentType { appointment, treatingRequest, subscription, withdrawal }

class PaymentModel {
  final String id;
  final double amount;
  final String currency;
  final PaymentMethod method;
  final PaymentStatus status;
  final PaymentType type;
  final String description;
  final String? reference;
  final DateTime createdAt;
  final String? doctorId;
  final String? appointmentId;

  PaymentModel({
    required this.id,
    required this.amount,
    this.currency = 'XOF',
    required this.method,
    this.status = PaymentStatus.pending,
    required this.type,
    required this.description,
    this.reference,
    required this.createdAt,
    this.doctorId,
    this.appointmentId,
  });

  String get methodLabel {
    switch (method) {
      case PaymentMethod.wave: return 'Wave';
      case PaymentMethod.orangeMoney: return 'Orange Money';
      case PaymentMethod.mtnMoney: return 'MTN Money';
      case PaymentMethod.moovMoney: return 'Moov Money';
      case PaymentMethod.djamo: return 'Djamo';
      case PaymentMethod.visa: return 'Carte Visa';
      case PaymentMethod.mastercard: return 'Mastercard';
    }
  }

  String get statusLabel {
    switch (status) {
      case PaymentStatus.pending: return 'En attente';
      case PaymentStatus.processing: return 'En cours';
      case PaymentStatus.success: return 'Réussi';
      case PaymentStatus.failed: return 'Échoué';
      case PaymentStatus.refunded: return 'Remboursé';
    }
  }

  String get formattedAmount => '${amount.toStringAsFixed(0)} F CFA';
}

// ─── Modèle Message Chat ──────────────────────────────────────────────────────
class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final bool isFromDoctor;
  final String content;
  final MessageType type;
  final DateTime sentAt;
  bool isRead;
  final String? fileUrl;
  final String? fileName;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.isFromDoctor,
    required this.content,
    this.type = MessageType.text,
    required this.sentAt,
    this.isRead = false,
    this.fileUrl,
    this.fileName,
  });
}

enum MessageType { text, image, file, audio, prescription }

// ─── AppProvider ──────────────────────────────────────────────────────────────
class AppProvider extends ChangeNotifier {
  // Notifications
  List<AppNotification> _notifications = [];
  // Paiements
  List<PaymentModel> _payments = [];
  // Chat messages par conversationId
  Map<String, List<ChatMessage>> _chatMessages = {};
  // Évaluations
  List<ReviewModel> _reviews = [];

  bool _isProcessingPayment = false;
  PaymentStatus? _lastPaymentStatus;

  // Dark mode & Accessibility
  bool _isDarkMode = false;
  double _textScaleFactor = 1.0;

  // Getters
  List<AppNotification> get notifications => _notifications;
  List<AppNotification> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();
  int get unreadCount => unreadNotifications.length;
  List<PaymentModel> get payments => _payments;
  bool get isProcessingPayment => _isProcessingPayment;
  PaymentStatus? get lastPaymentStatus => _lastPaymentStatus;
  List<ReviewModel> get reviews => _reviews;
  bool get isDarkMode => _isDarkMode;
  double get textScaleFactor => _textScaleFactor;

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setTextScaleFactor(double value) {
    _textScaleFactor = value.clamp(0.8, 1.6);
    notifyListeners();
  }

  AppProvider() {
    _loadMockData();
  }

  void _loadMockData() {
    // ✅ Toutes les données de démo ont été supprimées
    // Notifications, paiements, messages et avis vides par défaut
    _notifications = [];
    _payments = [];
    _chatMessages = {};
    _reviews = [];
  }

  // ─── Notifications ───────────────────────────────────────────────────────────

  void addNotification(AppNotification notif) {
    _notifications.insert(0, notif);
    notifyListeners();
  }

  void markNotificationRead(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notifications[idx].isRead = true;
      notifyListeners();
    }
  }

  void markAllNotificationsRead() {
    for (final n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  // Méthode pour charger des notifications de démo pour les médecins
  void loadDoctorDemoNotifications() {
    // ✅ Notifications de démo supprimées - liste vide par défaut
    _notifications = [];
    notifyListeners();
  }

  // ─── Chat ────────────────────────────────────────────────────────────────────

  List<ChatMessage> getMessages(String conversationId) {
    return _chatMessages[conversationId] ?? [];
  }

  // Nom du docteur par conversation (pour les réponses auto)
  final Map<String, String> _convDoctorNames = {};

  void setConversationDoctorName(String conversationId, String doctorName) {
    _convDoctorNames[conversationId] = doctorName;
  }

  void sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required bool isFromDoctor,
    required String content,
    String? doctorName,
    MessageType type = MessageType.text,
  }) {
    final msg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      isFromDoctor: isFromDoctor,
      content: content,
      type: type,
      sentAt: DateTime.now(),
      isRead: false,
    );

    if (_chatMessages[conversationId] == null) {
      _chatMessages[conversationId] = [];
    }
    _chatMessages[conversationId]!.add(msg);

    // Simule une réponse automatique du médecin après 2s (démo)
    if (!isFromDoctor) {
      final drName = doctorName ?? _convDoctorNames[conversationId] ?? 'Dr. Médecin';
      final contentLower = content.toLowerCase();

      // Choisir une réponse contextuelle selon le message du patient
      String replyContent;
      final now = DateTime.now();
      if (contentLower.contains('douleur') || contentLower.contains('mal') || contentLower.contains('souffr')) {
        final replies = [
          'Je comprends votre douleur. Pouvez-vous me préciser l\'intensité sur 10 et la localisation exacte ?',
          'Cette douleur est-elle continue ou intermittente ? Y a-t-il des facteurs qui l\'aggravent ou la soulagent ?',
          'Je vous conseille de prendre du repos. Si la douleur s\'intensifie, venez me consulter d\'urgence.',
        ];
        replyContent = replies[now.second % replies.length];
      } else if (contentLower.contains('fièvre') || contentLower.contains('temperature') || contentLower.contains('chaud')) {
        final replies = [
          'Prenez votre température et communiquez-moi la valeur. Si elle dépasse 39°C, consultez rapidement.',
          'En cas de fièvre, restez hydraté(e) et prenez du paracétamol selon la notice. Informez-moi si cela persiste.',
          'Avez-vous d\'autres symptômes comme des frissons, des maux de tête ou une fatigue intense ?',
        ];
        replyContent = replies[now.second % replies.length];
      } else if (contentLower.contains('rdv') || contentLower.contains('rendez-vous') || contentLower.contains('consultation')) {
        final replies = [
          'Je vais vérifier mes disponibilités. Êtes-vous disponible en semaine ou préférez-vous le week-end ?',
          'Bien reçu. Je vous propose un créneau cette semaine. Quelle est votre disponibilité ?',
          'Pour une consultation urgente, je peux vous recevoir demain matin. Cela vous convient-il ?',
        ];
        replyContent = replies[now.second % replies.length];
      } else if (contentLower.contains('ordonnance') || contentLower.contains('médicament') || contentLower.contains('traitement')) {
        final replies = [
          'Je ne peux pas renouveler une ordonnance sans consultation. Prenez rendez-vous pour un suivi.',
          'Continuez votre traitement actuel. Je vous ferai une nouvelle ordonnance lors de notre prochaine consultation.',
          'Avant tout renouvellement, je dois évaluer votre état de santé. Prenez rendez-vous.',
        ];
        replyContent = replies[now.second % replies.length];
      } else if (contentLower.contains('bonjour') || contentLower.contains('bonsoir') || contentLower.contains('salut')) {
        final replies = [
          'Bonjour ! Comment puis-je vous aider aujourd\'hui ?',
          'Bonjour ! Je suis disponible. Quels sont vos symptômes ou préoccupations ?',
          'Bonjour ! J\'espère que vous allez bien. En quoi puis-je vous aider ?',
        ];
        replyContent = replies[now.second % replies.length];
      } else if (contentLower.contains('résultat') || contentLower.contains('analyse') || contentLower.contains('examen')) {
        final replies = [
          'Avez-vous les résultats en main ? Vous pouvez me les transmettre en photo pour que je les analyse.',
          'Je vais examiner vos résultats. Pouvez-vous me les envoyer par la messagerie ou les apporter lors de notre prochain RDV ?',
          'Envoyez-moi vos résultats en photo, je vous donnerai mon interprétation rapidement.',
        ];
        replyContent = replies[now.second % replies.length];
      } else {
        final replies = [
          'Merci pour votre message. Je prends note et vous réponds dès que possible.',
          'Bien reçu. Pouvez-vous me donner plus de précisions sur votre situation ?',
          'Je comprends. Restez serein(e), nous allons gérer cela ensemble.',
          'D\'accord, nous en discuterons lors de notre prochain échange.',
          'Merci de m\'avoir contacté. Je reviens vers vous dans les meilleurs délais.',
        ];
        replyContent = replies[now.second % replies.length];
      }

      Future.delayed(const Duration(seconds: 2), () {
        if (_chatMessages[conversationId] == null) return;
        final reply = ChatMessage(
          id: 'msg_auto_${DateTime.now().millisecondsSinceEpoch}',
          conversationId: conversationId,
          senderId: 'doc_auto',
          senderName: drName,
          isFromDoctor: true,
          content: replyContent,
          sentAt: DateTime.now(),
          isRead: false,
        );
        _chatMessages[conversationId]!.add(reply);
        // Ajoute une notification
        final preview = replyContent.length > 50 ? '${replyContent.substring(0, 50)}...' : replyContent;
        addNotification(AppNotification(
          id: 'notif_chat_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Nouveau message de $drName',
          body: preview,
          type: NotifType.message,
          createdAt: DateTime.now(),
        ));
        notifyListeners();
      });
    }

    notifyListeners();
  }

  void markMessagesRead(String conversationId) {
    final msgs = _chatMessages[conversationId];
    if (msgs != null) {
      for (final m in msgs) {
        m.isRead = true;
      }
      notifyListeners();
    }
  }

  // ─── Paiements ───────────────────────────────────────────────────────────────

  Future<PaymentStatus> processPayment({
    required double amount,
    required PaymentMethod method,
    required PaymentType type,
    required String description,
    String? phoneNumber,
    String? cardNumber,
    String? appointmentId,
    String? doctorId,
    String? customReference,
  }) async {
    _isProcessingPayment = true;
    _lastPaymentStatus = PaymentStatus.processing;
    notifyListeners();

    // Simulation réseau (2-3s)
    await Future.delayed(const Duration(seconds: 1));

    // 98% de succès en démo
    final success = DateTime.now().millisecond % 50 != 0;
    final status = success ? PaymentStatus.success : PaymentStatus.failed;

    if (success) {
      final payment = PaymentModel(
        id: 'pay_${DateTime.now().millisecondsSinceEpoch}',
        amount: amount,
        method: method,
        status: status,
        type: type,
        description: description,
        reference: customReference ?? '${method.name.toUpperCase()}${DateTime.now().millisecondsSinceEpoch}',
        createdAt: DateTime.now(),
        appointmentId: appointmentId,
        doctorId: doctorId,
      );
      _payments.insert(0, payment);

      addNotification(AppNotification(
        id: 'notif_pay_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Paiement confirmé',
        body: '${amount.toStringAsFixed(0)} F CFA via ${payment.methodLabel} — $description',
        type: NotifType.payment,
        createdAt: DateTime.now(),
      ));
    }

    _isProcessingPayment = false;
    _lastPaymentStatus = status;
    notifyListeners();
    return status;
  }

  // ─── Paiement Médecin (retrait/virement) ─────────────────────────────────────

  double getDoctorEarnings(String doctorId) {
    // Simule les revenus du médecin
    return 450000; // 450 000 FCFA
  }

  Future<PaymentStatus> requestDoctorWithdrawal({
    required String doctorId,
    required double amount,
    required PaymentMethod method,
    required String accountNumber,
    required String accountName,
  }) async {
    _isProcessingPayment = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 3));

    final payment = PaymentModel(
      id: 'pay_wd_${DateTime.now().millisecondsSinceEpoch}',
      amount: amount,
      method: method,
      status: PaymentStatus.success,
      type: PaymentType.withdrawal,
      description: 'Retrait médecin - ${method.name}',
      reference: 'WD${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
      doctorId: doctorId,
    );

    _payments.insert(0, payment);
    _isProcessingPayment = false;
    notifyListeners();
    return PaymentStatus.success;
  }

  // ─── Évaluations ─────────────────────────────────────────────────────────────

  List<ReviewModel> getReviewsForDoctor(String doctorId) =>
      _reviews.where((r) => r.doctorId == doctorId).toList();

  bool hasReviewedDoctor(String patientId, String doctorId) =>
      _reviews.any((r) => r.patientId == patientId && r.doctorId == doctorId);

  Future<void> submitReview({
    required String patientId,
    required String patientName,
    required String doctorId,
    required String doctorName,
    required double rating,
    required String comment,
    bool isAnonymous = false,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    final review = ReviewModel(
      id: 'rev_${DateTime.now().millisecondsSinceEpoch}',
      patientId: patientId,
      patientName: isAnonymous ? 'Patient anonyme' : patientName,
      doctorId: doctorId,
      doctorName: doctorName,
      rating: rating,
      comment: comment,
      isAnonymous: isAnonymous,
      isVerified: true,
      createdAt: DateTime.now(),
    );

    _reviews.add(review);
    addNotification(AppNotification(
      id: 'notif_rev_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Évaluation envoyée',
      body: 'Merci pour votre avis sur $doctorName ($rating/5 étoiles)',
      type: NotifType.review,
      createdAt: DateTime.now(),
    ));
    notifyListeners();
  }
}
