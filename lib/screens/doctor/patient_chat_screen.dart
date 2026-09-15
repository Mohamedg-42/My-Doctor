import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../providers/message_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/treating_request_provider.dart';
import '../../widgets/common/avatar_widget.dart';
import 'package:intl/intl.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../patient/medical_record_screen.dart';

/// Écran de chat fonctionnel côté médecin avec MessageProvider
class PatientChatScreen extends StatefulWidget {
  final UserModel patient;

  const PatientChatScreen({
    super.key,
    required this.patient,
  });

  @override
  State<PatientChatScreen> createState() => _PatientChatScreenState();
}

class _PatientChatScreenState extends State<PatientChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  ChatConversation? _conversation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initConversation();
    });
  }

  void _initConversation() {
    final msgProvider = context.read<MessageProvider>();
    final auth = context.read<AuthProvider>();
    
    // ✅ CORRECTION : Utiliser doctorProfile.id au lieu de currentUser.id
    // Car le patient crée la conversation avec doctor.id (ID du profil médecin)
    final doctorId = auth.doctorProfile?.id ?? '';
    final hasAccess = context.read<TreatingRequestProvider>().hasAccessTo(widget.patient.id, doctorId);
    if (!hasAccess) {
      if (mounted) setState(() {});
      return;
    }
    
    // Debug: Afficher toutes les conversations disponibles
    if (kDebugMode) {
      debugPrint('🔍 DEBUG PatientChatScreen:');
      debugPrint('   - DoctorProfile ID: $doctorId');
      debugPrint('   - CurrentUser ID: ${auth.currentUser?.id}');
      debugPrint('   - Patient recherché: ${widget.patient.id} - ${widget.patient.fullName}');
      debugPrint('   - Nombre total de conversations: ${msgProvider.conversations.length}');
      for (var conv in msgProvider.conversations) {
        debugPrint('   📧 Conversation: ${conv.id}');
        debugPrint('      - patientId: ${conv.patientId}');
        debugPrint('      - doctorId: ${conv.doctorId}');
        debugPrint('      - patientName: ${conv.patientName}');
        debugPrint('      - doctorName: ${conv.doctorName}');
      }
    }
    
    _conversation = msgProvider.findConversation(widget.patient.id, doctorId) ??
        msgProvider.getOrCreateConversation(
          patientId: widget.patient.id,
          patientName: widget.patient.fullName,
          doctorId: doctorId,
          doctorName: auth.doctorProfile?.fullName ?? auth.currentUser?.fullName ?? 'Médecin',
          doctorSpecialty: auth.doctorProfile?.specialty ?? 'Généraliste',
        );
    
    if (_conversation != null) {
      if (kDebugMode) {
        debugPrint('✅ Conversation trouvée ou créée: ${_conversation!.id}');
        debugPrint('   - Messages: ${msgProvider.messagesOf(_conversation!.id).length}');
      }
      // Marquer les messages du patient comme lus
      msgProvider.markReadByDoctor(_conversation!.id);
      setState(() {});
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_conversation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'envoyer un message. Conversation introuvable.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final msgProvider = context.read<MessageProvider>();
    final auth = context.read<AuthProvider>();
    
    // ✅ CORRECTION : Utiliser doctorProfile.id pour être cohérent avec la conversation
    msgProvider.sendAsDoctor(
      _conversation!.id,
      auth.doctorProfile?.id ?? '',
      'Dr. ${auth.doctorProfile?.lastName ?? auth.currentUser?.lastName ?? ''}',
      text,
    );
    
    _messageController.clear();
    
    // Scroll vers le bas
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_conversation == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            '${widget.patient.firstName} ${widget.patient.lastName}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Aucune conversation trouvée',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Le patient doit d\'abord vous envoyer un message',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            AvatarWidget(
              imageUrl: widget.patient.avatarUrl ?? '',
              initials: '${widget.patient.firstName[0]}${widget.patient.lastName[0]}',
              size: 36,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${widget.patient.firstName} ${widget.patient.lastName}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Text(
                    widget.patient.cmuNumber ?? 'Patient',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.clipboard_list, color: AppColors.primary),
            tooltip: 'Dossier Médical',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MedicalRecordScreen(
                    patientName: '${widget.patient.firstName} ${widget.patient.lastName}',
                    patientId: widget.patient.id,
                    patientAvatar: widget.patient.avatarUrl,
                    isDoctorView: true,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              AppColors.primary.withValues(alpha: 0.03),
            ],
          ),
        ),
        child: Column(
          children: [
            // Liste des messages
            Expanded(
              child: Consumer<MessageProvider>(
                builder: (context, msgProvider, _) {
                  final messages = msgProvider.messagesOf(_conversation!.id);
                  
                  if (messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun message',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Envoyez votre premier message à ${widget.patient.firstName}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                              fontFamily: 'Poppins',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isFromMe = message.isFromDoctor;
                      final showDate = index == 0 || 
                          !_isSameDay(message.time, messages[index - 1].time);
                      
                      return Column(
                        children: [
                          if (showDate) _buildDateSeparator(message.time),
                          _buildMessageBubble(message, isFromMe),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            
            // Barre de saisie
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);
    
    String dateText;
    if (messageDate == today) {
      dateText = 'Aujourd\'hui';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      dateText = 'Hier';
    } else {
      dateText = DateFormat('dd MMMM yyyy', 'fr_FR').format(date);
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[300])),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              dateText,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey[300])),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isFromMe) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isFromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isFromMe) ...[
            AvatarWidget(
              imageUrl: widget.patient.avatarUrl ?? '',
              initials: '${widget.patient.firstName[0]}${widget.patient.lastName[0]}',
              size: 32,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isFromMe ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isFromMe ? 16 : 4),
                  bottomRight: Radius.circular(isFromMe ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 15,
                      color: isFromMe ? Colors.white : Colors.black87,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(message.time),
                    style: TextStyle(
                      fontSize: 11,
                      color: isFromMe 
                          ? Colors.white.withValues(alpha: 0.7)
                          : Colors.grey[600],
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundGrey,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Écrivez votre message...',
                    hintStyle: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _sendMessage,
                icon: const Icon(Icons.send_rounded, color: Colors.white),
                padding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
