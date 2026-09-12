import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle de message pour la messagerie temps réel
class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String senderRole; // 'patient' ou 'doctor'
  final String content;
  final DateTime timestamp;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.content,
    required this.timestamp,
    this.isRead = false,
  });

  /// Créer un ChatMessage depuis un document Firestore
  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? '',
      senderRole: data['senderRole'] as String? ?? '',
      content: data['content'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] as bool? ?? false,
    );
  }

  /// Convertir en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
    };
  }

  /// Créer une copie avec modifications
  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? senderRole,
    String? content,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}

/// Générateur d'ID de conversation unique basé sur patientId et doctorId
class ConversationHelper {
  /// Génère un ID de conversation unique et cohérent
  /// Format: "conv_{patientId}_{doctorId}"
  static String generateConversationId(String patientId, String doctorId) {
    // Trier les IDs pour garantir la cohérence
    final ids = [patientId, doctorId]..sort();
    return 'conv_${ids[0]}_${ids[1]}';
  }

  /// Référence à la collection de conversations Firestore
  static CollectionReference getConversationsCollection() {
    return FirebaseFirestore.instance.collection('conversations');
  }

  /// Référence à la collection de messages d'une conversation
  static CollectionReference getMessagesCollection(String conversationId) {
    return FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId)
        .collection('messages');
  }
}
