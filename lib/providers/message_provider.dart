import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/database_service.dart';

// ─── Modèles internes ─────────────────────────────────────────────────────────

enum ChatMsgType { text, image, info, audio, rdv }

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;   // 'patient', 'pat_xxx' ou 'doc_xxx'
  final String senderName;
  final String senderRole; // 'patient' ou 'doctor'
  final String text;
  final ChatMsgType type;
  final DateTime time;
  bool isReadByPatient;
  bool isReadByDoctor;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.senderRole = 'patient',
    required this.text,
    this.type = ChatMsgType.text,
    required this.time,
    this.isReadByPatient = false,
    this.isReadByDoctor = false,
  });

  /// Est-ce que ce message vient du patient ?
  bool get isFromPatient => senderRole == 'patient' || senderId == 'patient' || senderId.startsWith('pat');
  /// Est-ce que ce message vient du médecin ?
  bool get isFromDoctor => senderRole == 'doctor' || senderId.startsWith('doc');
  
  // Sérialisation JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'conversationId': conversationId,
    'senderId': senderId,
    'senderName': senderName,
    'senderRole': senderRole,
    'text': text,
    'type': type.name,
    'time': time.toIso8601String(),
    'isReadByPatient': isReadByPatient,
    'isReadByDoctor': isReadByDoctor,
  };
  
  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'],
    conversationId: json['conversationId'],
    senderId: json['senderId'] ?? '',
    senderName: json['senderName'] ?? '',
    senderRole: json['senderRole'] ?? (json['senderId'] == 'patient' || (json['senderId'] as String? ?? '').startsWith('pat') ? 'patient' : 'doctor'),
    text: json['text'] ?? '',
    type: ChatMsgType.values.firstWhere((e) => e.name == json['type'], orElse: () => ChatMsgType.text),
    time: DateTime.parse(json['time']),
    isReadByPatient: json['isReadByPatient'] ?? false,
    isReadByDoctor: json['isReadByDoctor'] ?? false,
  );
}

class ChatConversation {
  final String id;           // ex: 'conv_patient_dr1'
  final String patientId;    // toujours 'patient'
  final String patientName;
  final String doctorId;     // ex: 'doctor_kouame'
  final String doctorName;
  final String doctorSpecialty;
  final String? patientCmu;
  final bool isLocked;

  ChatConversation({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    required this.doctorSpecialty,
    this.patientCmu,
    this.isLocked = false,
  });
  
  // Sérialisation JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'patientId': patientId,
    'patientName': patientName,
    'doctorId': doctorId,
    'doctorName': doctorName,
    'doctorSpecialty': doctorSpecialty,
    'patientCmu': patientCmu,
    'isLocked': isLocked,
  };
  
  factory ChatConversation.fromJson(Map<String, dynamic> json) => ChatConversation(
    id: json['id'],
    patientId: json['patientId'],
    patientName: json['patientName'],
    doctorId: json['doctorId'],
    doctorName: json['doctorName'],
    doctorSpecialty: json['doctorSpecialty'],
    patientCmu: json['patientCmu'],
    isLocked: json['isLocked'] ?? false,
  );
}

// ─── MessageProvider ──────────────────────────────────────────────────────────
/// Provider global singleton : partagé entre patient ET médecin.
/// Toute écriture (sendAsPatient / sendAsDoctor) est immédiatement
/// visible à l'autre côté via notifyListeners().

class MessageProvider extends ChangeNotifier {
  // Toutes les conversations disponibles
  final List<ChatConversation> _conversations = [];

  // Messages par conversationId
  final Map<String, List<ChatMessage>> _messages = {};

  // Indicateur "en train d'écrire" par conversationId → senderId
  final Map<String, String?> _typingUser = {};

  MessageProvider() {
    _loadFromStorage();
  }
  
  // ── Persistance localStorage ──────────────────────────────────────────────────
  
  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final convsJson = prefs.getString('chat_conversations');
      if (convsJson != null && convsJson.isNotEmpty) {
        final List<dynamic> convsList = jsonDecode(convsJson);
        _conversations.clear();
        _conversations.addAll(convsList.map((json) => ChatConversation.fromJson(json)));
      }
      
      final msgsJson = prefs.getString('chat_messages');
      if (msgsJson != null && msgsJson.isNotEmpty) {
        final Map<String, dynamic> msgsMap = jsonDecode(msgsJson);
        _messages.clear();
        msgsMap.forEach((convId, msgsList) {
          _messages[convId] = (msgsList as List)
              .map((json) => ChatMessage.fromJson(json))
              .toList();
        });
      }
      
      if (_conversations.isEmpty) {
        await seedDemoConversations();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ Erreur chargement messages depuis storage: $e');
    }
  }

  /// Initialise des conversations de démonstration
  Future<void> seedDemoConversations({bool force = false}) async {
    if (_conversations.length >= 2 && !force) return;

    if (force) {
      _conversations.clear();
      _messages.clear();
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
    final pat3Id = idForEmail('sekou.traore@gmail.com', 'pat_demo_03');
    final doc1Id = idForEmail('docteur@mydoctor.ci', 'doc_demo_01');
    final doc2Id = idForEmail('marc.yao@mydoctor.ci', 'doc_demo_02');

    final c1 = ChatConversation(
      id: 'conv_pat1_doc1',
      patientId: pat1Id,
      patientName: 'Jean Kouassi',
      patientCmu: 'CMU-CI123456789',
      doctorId: doc1Id,
      doctorName: 'Dr. Sarah Touré',
      doctorSpecialty: 'Cardiologie',
    );

    final m1 = [
      ChatMessage(
        id: 'msg_demo_01',
        conversationId: 'conv_pat1_doc1',
        senderId: pat1Id,
        senderName: 'Jean Kouassi',
        senderRole: 'patient',
        text: 'Bonjour Docteur Touré, j\'ai bien pris ma tension ce matin : 12.8 au repos.',
        time: now.subtract(const Duration(days: 2, hours: 3)),
        isReadByPatient: true,
        isReadByDoctor: true,
      ),
      ChatMessage(
        id: 'msg_demo_02',
        conversationId: 'conv_pat1_doc1',
        senderId: doc1Id,
        senderName: 'Dr. Sarah Touré',
        senderRole: 'doctor',
        text: 'Bonjour M. Kouassi, c\'est un excellent chiffre tensionnel. Maintenez le traitement aux mêmes heures.',
        time: now.subtract(const Duration(days: 2, hours: 1)),
        isReadByPatient: true,
        isReadByDoctor: true,
      ),
      ChatMessage(
        id: 'msg_demo_03',
        conversationId: 'conv_pat1_doc1',
        senderId: pat1Id,
        senderName: 'Jean Kouassi',
        senderRole: 'patient',
        text: 'Parfait docteur. Est-ce que je dois faire un bilan sanguin avant notre prochain rendez-vous ?',
        time: now.subtract(const Duration(hours: 18)),
        isReadByPatient: true,
        isReadByDoctor: true,
      ),
      ChatMessage(
        id: 'msg_demo_04',
        conversationId: 'conv_pat1_doc1',
        senderId: doc1Id,
        senderName: 'Dr. Sarah Touré',
        senderRole: 'doctor',
        text: 'Oui, un contrôle de la créatinine et de la kaliémie dans 2 semaines sera idéal.',
        time: now.subtract(const Duration(hours: 4)),
        isReadByPatient: true,
        isReadByDoctor: true,
      ),
    ];

    final c2 = ChatConversation(
      id: 'conv_sekou_yao',
      patientId: pat3Id,
      patientName: 'Sékou Traoré',
      patientCmu: 'CMU-CI456789123',
      doctorId: doc2Id,
      doctorName: 'Dr. Marc Yao',
      doctorSpecialty: 'Pédiatrie',
    );

    final m2 = [
      ChatMessage(
        id: 'msg_demo_05',
        conversationId: 'conv_sekou_yao',
        senderId: pat3Id,
        senderName: 'Sékou Traoré',
        senderRole: 'patient',
        text: 'Docteur Yao, mon fils a une fièvre modérée de 38.3°C depuis ce matin.',
        time: now.subtract(const Duration(hours: 5)),
        isReadByPatient: true,
        isReadByDoctor: true,
      ),
      ChatMessage(
        id: 'msg_demo_06',
        conversationId: 'conv_sekou_yao',
        senderId: doc2Id,
        senderName: 'Dr. Marc Yao',
        senderRole: 'doctor',
        text: 'Bonjour M. Traoré. Donnez-lui du paracétamol adapté à son poids (15mg/kg), proposez-lui à boire fréquemment et surveillez son comportement.',
        time: now.subtract(const Duration(hours: 4)),
        isReadByPatient: true,
        isReadByDoctor: true,
      ),
      ChatMessage(
        id: 'msg_demo_07',
        conversationId: 'conv_sekou_yao',
        senderId: pat3Id,
        senderName: 'Sékou Traoré',
        senderRole: 'patient',
        text: 'Bien reçu Docteur, la température est redescendue à 37.4°C. Merci pour votre réponse rapide !',
        time: now.subtract(const Duration(minutes: 50)),
        isReadByPatient: true,
        isReadByDoctor: true,
      ),
    ];

    _conversations.removeWhere((c) => c.id == c1.id || c.id == c2.id);
    _conversations.addAll([c1, c2]);
    _messages[c1.id] = m1;
    _messages[c2.id] = m2;

    await _saveToStorage();
    notifyListeners();
    debugPrint('🌱 Conversations de démonstration initialisées (${_conversations.length})');
  }
  
  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Sauvegarder les conversations
      final convsJson = jsonEncode(_conversations.map((c) => c.toJson()).toList());
      await prefs.setString('chat_conversations', convsJson);
      
      // Sauvegarder les messages
      final msgsMap = <String, List<Map<String, dynamic>>>{};
      _messages.forEach((convId, msgs) {
        msgsMap[convId] = msgs.map((m) => m.toJson()).toList();
      });
      final msgsJson = jsonEncode(msgsMap);
      await prefs.setString('chat_messages', msgsJson);
    } catch (e) {
      debugPrint('⚠️ Erreur sauvegarde messages vers storage: $e');
    }
  }

  // ── Getters ──────────────────────────────────────────────────────────────────

  List<ChatConversation> get conversations => List.unmodifiable(_conversations);

  List<ChatMessage> messagesOf(String convId) =>
      List.unmodifiable(_messages[convId] ?? []);

  /// Conversations du patient (toutes, sauf verrou)
  List<ChatConversation> get patientConversations =>
      _conversations.where((c) => !c.isLocked).toList();

  /// Conversations du médecin filtré par son doctorId
  List<ChatConversation> conversationsForDoctor(String doctorId) =>
      _conversations.where((c) => c.doctorId == doctorId).toList();

  /// Nombre de messages non lus pour le patient (msgs venant du médecin)
  int unreadCountForPatient(String convId) {
    return (_messages[convId] ?? [])
        .where((m) => m.isFromDoctor && !m.isReadByPatient)
        .length;
  }

  /// Nombre de messages non lus pour le médecin (msgs venant du patient)
  int unreadCountForDoctor(String convId) {
    return (_messages[convId] ?? [])
        .where((m) => m.isFromPatient && !m.isReadByDoctor)
        .length;
  }

  int get totalUnreadForPatient =>
      _conversations.fold(0, (sum, c) => sum + unreadCountForPatient(c.id));

  int totalUnreadForDoctor(String doctorId) =>
      conversationsForDoctor(doctorId)
          .fold(0, (sum, c) => sum + unreadCountForDoctor(c.id));

  ChatMessage? lastMessageOf(String convId) {
    final msgs = _messages[convId];
    if (msgs == null || msgs.isEmpty) return null;
    return msgs.last;
  }

  bool isTyping(String convId) => _typingUser[convId] != null;
  String? whoIsTyping(String convId) => _typingUser[convId];

  // ── Quota messages gratuits (contrôlé par DatabaseService) ───────────────────

  /// Nombre de messages gratuits restants pour un patient (0 à 10)
  int getRemainingFreeMessages(String patientId) {
    return DatabaseService().getPatientMessageUsage(patientId).remaining;
  }

  /// Statistiques détaillées de quota pour un patient
  PatientMessageUsage getUsageForPatient(String patientId) {
    return DatabaseService().getPatientMessageUsage(patientId);
  }

  /// Total des messages envoyés dans tout le système (pour l'admin)
  int get totalMessagesCount =>
      _messages.values.fold(0, (sum, msgs) => sum + msgs.length);

  /// Toutes les conversations sans filtre (pour l'admin)
  List<ChatConversation> get allConversations => List.unmodifiable(_conversations);

  // ── Actions patient ───────────────────────────────────────────────────────────

  /// Envoi d'un message par le patient.
  /// Vérifie et consomme un crédit gratuit côté BDD. Retourne false si la limite est atteinte.
  Future<bool> sendAsPatient(
    String convId,
    String text, {
    String? patientId,
    String? patientName,
    ChatMsgType type = ChatMsgType.text,
  }) async {
    final effectivePatientId = (patientId != null && patientId.isNotEmpty)
        ? patientId
        : _patientIdOf(convId);

    // 1. Contrôle strict de quota côté base de données (Backend Enforcement)
    final allowed = await DatabaseService().consumePatientMessage(effectivePatientId);
    if (!allowed) {
      debugPrint('⛔ Refus envoi message : quota patient ($effectivePatientId) épuisé');
      notifyListeners();
      return false;
    }

    _send(
      convId,
      senderId: effectivePatientId,
      senderName: patientName ?? _patientNameOf(convId),
      senderRole: 'patient',
      text: text,
      type: type,
    );

    // Marquer les messages médecin comme lus quand le patient écrit
    _markDoctorMsgsReadByPatient(convId);
    return true;
  }

  void markReadByPatient(String convId) {
    final msgs = _messages[convId];
    if (msgs == null) return;
    bool changed = false;
    for (final m in msgs) {
      if (m.isFromDoctor && !m.isReadByPatient) {
        m.isReadByPatient = true;
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
      _saveToStorage(); // 💾 Persistance
    }
  }

  // ── Actions médecin ───────────────────────────────────────────────────────────

  void sendAsDoctor(
    String convId,
    String doctorId,
    String doctorName,
    String text, {
    ChatMsgType type = ChatMsgType.text,
  }) {
    _send(
      convId,
      senderId: doctorId,
      senderName: doctorName,
      senderRole: 'doctor',
      text: text,
      type: type,
    );
    _markPatientMsgsReadByDoctor(convId);
  }

  void markReadByDoctor(String convId) {
    final msgs = _messages[convId];
    if (msgs == null) return;
    bool changed = false;
    for (final m in msgs) {
      if (m.isFromPatient && !m.isReadByDoctor) {
        m.isReadByDoctor = true;
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
      _saveToStorage(); // 💾 Persistance
    }
  }

  // ── Typing indicator ──────────────────────────────────────────────────────────

  void setTyping(String convId, String senderId, bool isTyping) {
    if (isTyping) {
      _typingUser[convId] = senderId;
    } else {
      _typingUser.remove(convId);
    }
    notifyListeners();
  }

  /// Envoie un message informatif / système (ex: quota atteint, paiement validé)
  void sendSystemMessage(String convId, String text) {
    _send(
      convId,
      senderId: 'system',
      senderName: 'My Doctor',
      senderRole: 'system',
      text: text,
      type: ChatMsgType.info,
    );
  }

  // ── Utilitaires internes ─────────────────────────────────────────────────────

  void _send(String convId, {
    required String senderId,
    required String senderName,
    required String senderRole,
    required String text,
    required ChatMsgType type,
  }) {
    _messages.putIfAbsent(convId, () => []);
    _messages[convId]!.add(ChatMessage(
      id: '${convId}_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: convId,
      senderId: senderId,
      senderName: senderName,
      senderRole: senderRole,
      text: text,
      type: type,
      time: DateTime.now(),
      isReadByPatient: senderRole == 'patient', // si le patient envoie, il l'a "lu"
      isReadByDoctor: senderRole == 'doctor',   // si le médecin envoie, il l'a "lu"
    ));
    notifyListeners();
    _saveToStorage(); // 💾 Persistance
  }

  void _markDoctorMsgsReadByPatient(String convId) {
    final msgs = _messages[convId];
    if (msgs == null) return;
    for (final m in msgs) {
      if (m.isFromDoctor) m.isReadByPatient = true;
    }
  }

  void _markPatientMsgsReadByDoctor(String convId) {
    final msgs = _messages[convId];
    if (msgs == null) return;
    for (final m in msgs) {
      if (m.isFromPatient) m.isReadByDoctor = true;
    }
  }

  String _patientNameOf(String convId) {
    return _conversations
        .firstWhere((c) => c.id == convId,
            orElse: () => ChatConversation(
                id: convId,
                patientId: 'patient',
                patientName: 'Patient',
                doctorId: 'doctor',
                doctorName: 'Médecin',
                doctorSpecialty: ''))
        .patientName;
  }

  String _patientIdOf(String convId) {
    return _conversations
        .firstWhere((c) => c.id == convId,
            orElse: () => ChatConversation(
                id: convId,
                patientId: 'patient',
                patientName: 'Patient',
                doctorId: 'doctor',
                doctorName: 'Médecin',
                doctorSpecialty: ''))
        .patientId;
  }

  // ── Données de démo ───────────────────────────────────────────────────────────

  void _initDemoData() {
    // ✅ Toutes les données de démo ont été supprimées
    // Les conversations et messages seront créés dynamiquement par les utilisateurs réels
  }
  
  /// Efface toutes les conversations et messages du localStorage
  /// Utile pour réinitialiser complètement le système de chat
  Future<void> clearAllMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('chat_conversations');
      await prefs.remove('chat_messages');
      
      _conversations.clear();
      _messages.clear();
      notifyListeners();
      
      if (kDebugMode) {
        debugPrint('✅ Tous les messages et conversations ont été effacés');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Erreur lors de l\'effacement des messages: $e');
      }
    }
  }

  // ── Helpers pour les vues ─────────────────────────────────────────────────────

  /// Retourne la conversation du patient connecté avec un médecin donné
  ChatConversation? findConvForPatient(String doctorId, {String? patientId}) {
    if (doctorId.isEmpty || patientId == null || patientId.isEmpty) return null;
    try {
      return _conversations.firstWhere(
        (c) => c.patientId == patientId && c.doctorId == doctorId,
      );
    } catch (_) {
      return null;
    }
  }

  /// Retourne les conversations pour un patient donné (ou patient démo)
  List<ChatConversation> conversationsForPatient(String patientId) {
    if (patientId.isEmpty) return const [];
    return _conversations
        .where((c) =>
            !c.isLocked &&
            c.patientId == patientId)
        .toList();
  }

  /// Retourne une conversation existante entre un patient et un médecin
  ChatConversation? findConversation(String patientId, String doctorId) {
    if (patientId.isEmpty || doctorId.isEmpty) return null;
    try {
      return _conversations.firstWhere(
        (c) => c.patientId == patientId && c.doctorId == doctorId,
      );
    } catch (_) {
      return null;
    }
  }

  /// Crée ou récupère une conversation avec des identifiants réels
  ChatConversation getOrCreateConversation({
    required String patientId,
    required String patientName,
    required String doctorId,
    required String doctorName,
    required String doctorSpecialty,
    String? patientCmu,
  }) {
    final existing = findConversation(patientId, doctorId);
    if (existing != null) return existing;

    final conv = ChatConversation(
      id: 'conv_${patientId}_${doctorId}',
      patientId: patientId,
      patientName: patientName,
      doctorId: doctorId,
      doctorName: doctorName,
      doctorSpecialty: doctorSpecialty,
      patientCmu: patientCmu,
    );
    _conversations.add(conv);
    _messages[conv.id] = [];
    notifyListeners();
    _saveToStorage(); // 💾 Persistance
    return conv;
  }

  /// Retourne ou crée une conversation entre le patient connecté et un médecin
  ChatConversation getOrCreateConvForPatient({
    required String doctorId,
    required String doctorName,
    required String doctorSpecialty,
    String patientName = 'Kouansan Echimane Antoine',
    String? patientCmu,
    String patientId = 'patient',
  }) {
    return getOrCreateConversation(
      patientId: patientId,
      patientName: patientName,
      doctorId: doctorId,
      doctorName: doctorName,
      doctorSpecialty: doctorSpecialty,
      patientCmu: patientCmu,
    );
  }
}
