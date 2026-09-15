// lib/providers/treating_request_provider.dart
//
// Provider centralisé pour les demandes de médecin traitant / de famille.
// Partagé entre le compte patient ET le compte médecin via MultiProvider.
// Toute action (envoi, acceptation, refus) est immédiatement visible
// des deux côtés grâce aux notifyListeners().
//
// Persistance : Hive box 'treating_requests_v1'

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/treating_doctor_request_model.dart';
import 'message_provider.dart';
import '../services/database_service.dart';

// ─── Modèle de notification in-app ──────────────────────────────────────────

enum AppNotifType { requestSent, requestAccepted, requestRejected, newMessage }

class AppNotification {
  final String id;
  final AppNotifType type;
  final String title;
  final String body;
  final String? doctorId;
  final String? patientId;
  final String? requestId;
  final DateTime createdAt;
  bool isRead;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.doctorId,
    this.patientId,
    this.requestId,
    required this.createdAt,
    this.isRead = false,
  });
}

// ─── TreatingRequestProvider ─────────────────────────────────────────────────

class TreatingRequestProvider extends ChangeNotifier {
  static const _boxName = 'treating_requests_v1';

  // Toutes les demandes (tous patients + tous médecins)
  final List<TreatingDoctorRequest> _requests = [];

  // Notifications in-app
  final List<AppNotification> _notifications = [];

  bool _initialized = false;

  // ── Getters ──────────────────────────────────────────────────────────────

  List<TreatingDoctorRequest> get allRequests => List.unmodifiable(_requests);

  /// Demandes envoyées par un patient donné
  List<TreatingDoctorRequest> requestsForPatient(String patientId) =>
      _requests.where((r) => r.patientId == patientId).toList();
  List<TreatingDoctorRequest> getRequestsForPatient(String patientId) =>
      requestsForPatient(patientId);

  /// Demandes reçues par un médecin donné
  List<TreatingDoctorRequest> requestsForDoctor(String doctorId) =>
      _requests.where((r) => r.doctorId == doctorId).toList();
  List<TreatingDoctorRequest> getRequestsForDoctor(String doctorId) =>
      requestsForDoctor(doctorId);

  /// Demandes en attente pour un médecin donné
  List<TreatingDoctorRequest> pendingForDoctor(String doctorId) =>
      _requests
          .where((r) => r.doctorId == doctorId && r.isPending)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  /// Demandes acceptées pour un patient donné
  List<TreatingDoctorRequest> acceptedForPatient(String patientId) =>
      _requests
          .where((r) => r.patientId == patientId && r.isAccepted)
          .toList();

  /// Vérifie si un patient a une demande (pending ou accepted) vers un médecin
  /// → si true, le médecin doit être masqué de la liste du patient
  bool hasPendingOrAccepted(String patientId, String doctorId) {
    return _requests.any((r) =>
        r.patientId == patientId &&
        r.doctorId == doctorId &&
        (r.status == TreatingDoctorStatus.pending ||
            r.status == TreatingDoctorStatus.accepted));
  }

  /// Vérifie si le patient a accès aux canaux de communication avec ce médecin
  bool hasAccessTo(String patientId, String doctorId) {
    return _requests.any((r) =>
        r.patientId == patientId &&
        r.doctorId == doctorId &&
        r.isAccepted);
  }

  /// Demande existante entre ce patient et ce médecin (n'importe quel statut)
  TreatingDoctorRequest? findRequest(String patientId, String doctorId) {
    try {
      return _requests.lastWhere(
          (r) => r.patientId == patientId && r.doctorId == doctorId);
    } catch (_) {
      return null;
    }
  }

  // ── Notifications ────────────────────────────────────────────────────────

  List<AppNotification> get notifications {
    final items = List<AppNotification>.of(_notifications);
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(items);
  }

  List<AppNotification> notificationsForPatient(String patientId) {
    final items = _notifications.where((n) => n.patientId == patientId).toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  List<AppNotification> notificationsForDoctor(String doctorId) {
    final items = _notifications.where((n) => n.doctorId == doctorId).toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  int unreadCountForPatient(String patientId) =>
      _notifications
          .where((n) => n.patientId == patientId && !n.isRead)
          .length;

  int unreadCountForDoctor(String doctorId) =>
      _notifications
          .where((n) => n.doctorId == doctorId && !n.isRead)
          .length;

  void markAllReadForPatient(String patientId) {
    bool changed = false;
    for (final n in _notifications) {
      if (n.patientId == patientId && !n.isRead) {
        n.isRead = true;
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  void markAllReadForDoctor(String doctorId) {
    bool changed = false;
    for (final n in _notifications) {
      if (n.doctorId == doctorId && !n.isRead) {
        n.isRead = true;
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  // ── Initialisation ───────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
    _loadFromHive();
    if (_requests.isEmpty) {
      await seedDemoRequests();
    }
  }

  /// Initialise des demandes de démonstration
  Future<void> seedDemoRequests({bool force = false}) async {
    Box? box;
    try {
      if (!Hive.isBoxOpen(_boxName)) {
        await Hive.openBox(_boxName);
      }
      box = Hive.box(_boxName);
    } catch (e) {
      debugPrint('Note: Hive not available for seedDemoRequests: $e');
    }

    if (_requests.length >= 4 && !force) return;

    if (force) {
      try {
        await box?.clear();
      } catch (_) {}
      _requests.clear();
    }

    final now = DateTime.now();
    final users = DatabaseService().getAllUsers();
    String idForEmail(String email, String fallback) {
      for (final user in users) {
        if (user.email.toLowerCase() == email.toLowerCase()) return user.id;
      }
      return fallback;
    }
    final pat1Id = idForEmail('patient@mydoctor.ci', 'pat_demo_01');
    final pat2Id = idForEmail('marieange.bamba@gmail.com', 'pat_demo_02');
    final pat3Id = idForEmail('sekou.traore@gmail.com', 'pat_demo_03');
    final pat4Id = idForEmail('awa.kone@gmail.com', 'pat_demo_04');
    final doc1Id = idForEmail('docteur@mydoctor.ci', 'doc_demo_01');
    final doc2Id = idForEmail('marc.yao@mydoctor.ci', 'doc_demo_02');
    final doc3Id = idForEmail('aminata.diallo@mydoctor.ci', 'doc_demo_03');
    final demoRequests = [
      TreatingDoctorRequest(
        id: 'tr_demo_01',
        patientId: pat2Id,
        patientName: 'Marie-Ange Bamba',
        doctorId: doc1Id,
        doctorName: 'Dr. Sarah Touré',
        doctorSpecialty: 'Cardiologie',
        message: 'Bonjour Docteur, je souhaite vous désigner comme médecin traitant pour mon suivi cardiologique régulier.',
        status: TreatingDoctorStatus.pending,
        isPaid: true,
        amount: 750,
        paymentMethod: 'orange_money',
        paymentRef: 'OM-CI-984312',
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      TreatingDoctorRequest(
        id: 'tr_demo_02',
        patientId: pat1Id,
        patientName: 'Jean Kouassi',
        doctorId: doc1Id,
        doctorName: 'Dr. Sarah Touré',
        doctorSpecialty: 'Cardiologie',
        message: 'Demande de suivi médical et renouvellement d\'ordonnance.',
        status: TreatingDoctorStatus.accepted,
        isPaid: true,
        amount: 750,
        paymentMethod: 'wave',
        paymentRef: 'WAVE-CI-771204',
        createdAt: now.subtract(const Duration(days: 1)),
        respondedAt: now.subtract(const Duration(hours: 18)),
      ),
      TreatingDoctorRequest(
        id: 'tr_demo_03',
        patientId: pat3Id,
        patientName: 'Bakary Traoré',
        doctorId: doc2Id,
        doctorName: 'Dr. Marc Yao',
        doctorSpecialty: 'Pédiatrie',
        message: 'Suivi régulier pédiatrique pour mes deux enfants.',
        status: TreatingDoctorStatus.accepted,
        isPaid: true,
        amount: 750,
        paymentMethod: 'mtn',
        paymentRef: 'MTN-CI-551829',
        createdAt: now.subtract(const Duration(days: 3)),
        respondedAt: now.subtract(const Duration(days: 2)),
      ),
      TreatingDoctorRequest(
        id: 'tr_demo_04',
        patientId: pat4Id,
        patientName: 'Awa Koné',
        doctorId: doc3Id,
        doctorName: 'Dr. Aminata Diallo',
        doctorSpecialty: 'Gynécologie',
        message: 'Bonjour Dr. Diallo, je sollicite un suivi gynécologique à distance.',
        status: TreatingDoctorStatus.rejected,
        rejectionReason: 'Planning complet pour les téléconsultations ce mois-ci. Merci de contacter le secrétariat pour un rdv physique.',
        isPaid: true,
        amount: 750,
        paymentMethod: 'wave',
        paymentRef: 'WAVE-CI-331092',
        createdAt: now.subtract(const Duration(days: 7)),
        respondedAt: now.subtract(const Duration(days: 6)),
      ),
    ];

    for (final req in demoRequests) {
      if (box != null) {
        try {
          await box.put(req.id, _toMap(req));
        } catch (_) {}
      }
      _requests.add(req);
    }
    notifyListeners();
    debugPrint('🌱 Demandes de médecin traitant de démonstration initialisées (${demoRequests.length})');
  }

  void _loadFromHive() {
    final box = Hive.box(_boxName);
    _requests.clear();
    for (final key in box.keys) {
      final m = box.get(key);
      if (m != null) {
        try {
          _requests.add(_fromMap(Map<String, dynamic>.from(m as Map)));
        } catch (_) {}
      }
    }
    notifyListeners();
  }

  Future<void> _saveToHive(TreatingDoctorRequest req) async {
    final box = Hive.box(_boxName);
    await box.put(req.id, _toMap(req));
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  /// Envoi d'une demande par le patient.
  /// Retourne false si une demande active existe déjà.
  Future<bool> sendRequest({
    required String patientId,
    required String patientName,
    required String patientPhone,
    required String doctorId,
    required String doctorName,
    required String doctorSpecialty,
    String? message,
    String paymentMethod = 'wave',
    String? patientAvatar,
  }) async {
    // Vérifier qu'il n'y a pas déjà une demande active
    if (hasPendingOrAccepted(patientId, doctorId)) return false;

    final req = TreatingDoctorRequest(
      id: 'tr_${patientId}_${doctorId}_${DateTime.now().millisecondsSinceEpoch}',
      patientId: patientId,
      patientName: patientName,
      patientAvatar: patientAvatar,
      doctorId: doctorId,
      doctorName: doctorName,
      doctorSpecialty: doctorSpecialty,
      message: message ?? TreatingDoctorRequest.defaultMessage,
      status: TreatingDoctorStatus.pending,
      isPaid: true,
      amount: 750,
      paymentMethod: paymentMethod,
      createdAt: DateTime.now(),
    );

    _requests.add(req);
    await _saveToHive(req);

    // Notification pour le médecin (in-app + push)
    _addNotification(AppNotification(
      id: 'notif_req_${req.id}',
      type: AppNotifType.requestSent,
      title: 'Nouvelle demande de médecin traitant',
      body: '$patientName souhaite que vous soyez son médecin traitant.',
      doctorId: doctorId,
      patientId: patientId,
      requestId: req.id,
      createdAt: DateTime.now(),
    ));
    
    // Envoyer notification push au médecin (désactivée en mode dégradé)
    // PushNotificationService().notifyNewRequest(
    //   doctorId: doctorId,
    //   patientName: patientName,
    //   message: message ?? TreatingDoctorRequest.defaultMessage,
    // );

    notifyListeners();
    return true;
  }

  /// Réponse du médecin : accepter ou refuser.
  Future<void> respondToRequest({
    required String requestId,
    required bool accept,
    String? rejectionReason,
    MessageProvider? messageProvider,
  }) async {
    final idx = _requests.indexWhere((r) => r.id == requestId);
    if (idx == -1) return;

    final old = _requests[idx];
    final updated = TreatingDoctorRequest(
      id: old.id,
      patientId: old.patientId,
      patientName: old.patientName,
      patientAvatar: old.patientAvatar,
      doctorId: old.doctorId,
      doctorName: old.doctorName,
      doctorSpecialty: old.doctorSpecialty,
      message: old.message,
      status: accept
          ? TreatingDoctorStatus.accepted
          : TreatingDoctorStatus.rejected,
      isPaid: old.isPaid,
      amount: old.amount,
      paymentMethod: old.paymentMethod,
      rejectionReason: rejectionReason,
      createdAt: old.createdAt,
      respondedAt: DateTime.now(),
    );

    _requests[idx] = updated;
    await _saveToHive(updated);

    // Si acceptée, créer immédiatement la conversation
    if (accept && messageProvider != null) {
      messageProvider.getOrCreateConversation(
        patientId: old.patientId,
        patientName: old.patientName,
        doctorId: old.doctorId,
        doctorName: old.doctorName,
        doctorSpecialty: old.doctorSpecialty,
      );
    }

    // Notification pour le patient (in-app + push)
    if (accept) {
      _addNotification(AppNotification(
        id: 'notif_accept_${requestId}_${DateTime.now().millisecondsSinceEpoch}',
        type: AppNotifType.requestAccepted,
        title: '✅ Demande acceptée !',
        body:
            '${old.doctorName} a accepté votre demande. Vous pouvez maintenant le contacter.',
        doctorId: old.doctorId,
        patientId: old.patientId,
        requestId: requestId,
        createdAt: DateTime.now(),
      ));
      
      // Envoyer notification push (désactivée en mode dégradé)
      // PushNotificationService().notifyRequestAccepted(
      //   patientId: old.patientId,
      //   doctorName: old.doctorName,
      //   doctorSpecialty: old.doctorSpecialty,
      // );
    } else {
      _addNotification(AppNotification(
        id: 'notif_reject_${requestId}_${DateTime.now().millisecondsSinceEpoch}',
        type: AppNotifType.requestRejected,
        title: '❌ Demande refusée',
        body: '${old.doctorName} a refusé votre demande.',
        doctorId: old.doctorId,
        patientId: old.patientId,
        requestId: requestId,
        createdAt: DateTime.now(),
      ));
      
      // Envoyer notification push (désactivée en mode dégradé)
      // PushNotificationService().notifyRequestRefused(
      //   patientId: old.patientId,
      //   doctorName: old.doctorName,
      //   reason: rejectionReason,
      // );
    }

    notifyListeners();
  }

  /// Référer une demande vers un autre médecin (remplace le refus chez le médecin)
  Future<void> referRequest({
    required String requestId,
    required String targetDoctorId,
    required String targetDoctorName,
    required String targetDoctorSpecialty,
    String? referralNote,
  }) async {
    final idx = _requests.indexWhere((r) => r.id == requestId);
    if (idx == -1) return;

    final old = _requests[idx];
    final updated = TreatingDoctorRequest(
      id: old.id,
      patientId: old.patientId,
      patientName: old.patientName,
      patientAvatar: old.patientAvatar,
      doctorId: targetDoctorId,
      doctorName: targetDoctorName,
      doctorSpecialty: targetDoctorSpecialty,
      message: old.message,
      status: TreatingDoctorStatus.pending,
      isPaid: old.isPaid,
      amount: old.amount,
      paymentMethod: old.paymentMethod,
      paymentRef: old.paymentRef,
      rejectionReason: null,
      referredFromDoctorId: old.doctorId,
      referredFromDoctorName: old.doctorName,
      referredToDoctorId: targetDoctorId,
      referredToDoctorName: targetDoctorName,
      referralNote: referralNote,
      createdAt: old.createdAt,
      respondedAt: DateTime.now(),
    );

    _requests[idx] = updated;
    await _saveToHive(updated);

    // Notification pour le patient
    _addNotification(AppNotification(
      id: 'notif_refer_${requestId}_${DateTime.now().millisecondsSinceEpoch}',
      type: AppNotifType.requestSent,
      title: '🔄 Demande référée avec soin',
      body:
          '${old.doctorName} a référé votre demande au Dr. $targetDoctorName ($targetDoctorSpecialty) pour une prise en charge adaptée.',
      doctorId: targetDoctorId,
      patientId: old.patientId,
      requestId: requestId,
      createdAt: DateTime.now(),
    ));

    // Notification pour le confrère destinataire
    _addNotification(AppNotification(
      id: 'notif_doc_refer_${requestId}_${DateTime.now().millisecondsSinceEpoch}',
      type: AppNotifType.requestSent,
      title: '📋 Nouveau patient référé par un confrère',
      body:
          '${old.doctorName} vous a référé le patient ${old.patientName}${referralNote != null && referralNote.isNotEmpty ? " • Note : $referralNote" : ""}.',
      doctorId: targetDoctorId,
      patientId: old.patientId,
      requestId: requestId,
      createdAt: DateTime.now(),
    ));

    notifyListeners();
  }

  void _addNotification(AppNotification notif) {
    _notifications.add(notif);
  }

  // ── Sérialisation ────────────────────────────────────────────────────────

  Map<String, dynamic> _toMap(TreatingDoctorRequest r) => {
        'id': r.id,
        'patient_id': r.patientId,
        'patient_name': r.patientName,
        'patient_avatar': r.patientAvatar,
        'doctor_id': r.doctorId,
        'doctor_name': r.doctorName,
        'doctor_specialty': r.doctorSpecialty,
        'message': r.message,
        'status': r.status.name,
        'is_paid': r.isPaid,
        'amount': r.amount,
        'payment_method': r.paymentMethod,
        'payment_ref': r.paymentRef,
        'rejection_reason': r.rejectionReason,
        'referred_from_doctor_id': r.referredFromDoctorId,
        'referred_from_doctor_name': r.referredFromDoctorName,
        'referred_to_doctor_id': r.referredToDoctorId,
        'referred_to_doctor_name': r.referredToDoctorName,
        'referral_note': r.referralNote,
        'created_at': r.createdAt.toIso8601String(),
        'responded_at': r.respondedAt?.toIso8601String(),
      };

  TreatingDoctorRequest _fromMap(Map<String, dynamic> m) =>
      TreatingDoctorRequest(
        id: m['id'] ?? '',
        patientId: m['patient_id'] ?? '',
        patientName: m['patient_name'] ?? '',
        patientAvatar: m['patient_avatar'],
        doctorId: m['doctor_id'] ?? '',
        doctorName: m['doctor_name'] ?? '',
        doctorSpecialty: m['doctor_specialty'] ?? '',
        message: m['message'] ?? TreatingDoctorRequest.defaultMessage,
        status: _parseStatus(m['status']),
        isPaid: m['is_paid'] ?? false,
        amount: (m['amount'] ?? 750).toDouble(),
        paymentMethod: m['payment_method'],
        paymentRef: m['payment_ref'],
        rejectionReason: m['rejection_reason'],
        referredFromDoctorId: m['referred_from_doctor_id'],
        referredFromDoctorName: m['referred_from_doctor_name'],
        referredToDoctorId: m['referred_to_doctor_id'],
        referredToDoctorName: m['referred_to_doctor_name'],
        referralNote: m['referral_note'],
        createdAt:
            DateTime.tryParse(m['created_at'] ?? '') ?? DateTime.now(),
        respondedAt: m['responded_at'] != null
            ? DateTime.tryParse(m['responded_at'])
            : null,
      );

  TreatingDoctorStatus _parseStatus(String? s) {
    switch (s) {
      case 'accepted':
        return TreatingDoctorStatus.accepted;
      case 'rejected':
        return TreatingDoctorStatus.rejected;
      case 'cancelled':
        return TreatingDoctorStatus.cancelled;
      case 'referred':
        return TreatingDoctorStatus.referred;
      default:
        return TreatingDoctorStatus.pending;
    }
  }
}
