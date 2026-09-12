import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/doctor_model.dart';
import '../../providers/message_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/treating_request_provider.dart';
import '../../widgets/common/avatar_widget.dart';
import 'package:intl/intl.dart';

/// Écran de chat fonctionnel avec MessageProvider
class TreatingDoctorChatScreen extends StatefulWidget {
  final DoctorModel doctor;

  const TreatingDoctorChatScreen({
    super.key,
    required this.doctor,
  });

  @override
  State<TreatingDoctorChatScreen> createState() => _TreatingDoctorChatScreenState();
}

class _TreatingDoctorChatScreenState extends State<TreatingDoctorChatScreen> {
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
    final patientId = auth.currentUser?.id ?? '';
    final hasAccess = context.read<TreatingRequestProvider>().hasAccessTo(patientId, widget.doctor.id);
    if (!hasAccess) {
      if (mounted) setState(() {});
      return;
    }
    
    // Debug: Afficher les informations de création de conversation
    if (kDebugMode) {
      debugPrint('🏥 DEBUG TreatingDoctorChatScreen (PATIENT):');
      debugPrint('   - DoctorId utilisé: ${widget.doctor.id}');
      debugPrint('   - DoctorName: ${widget.doctor.firstName} ${widget.doctor.lastName}');
      debugPrint('   - PatientName: ${auth.userName}');
      debugPrint('   - Avant création - Conversations: ${msgProvider.conversations.length}');
    }
    
    // Créer ou récupérer la conversation
    _conversation = msgProvider.getOrCreateConvForPatient(
      doctorId: widget.doctor.id,
      doctorName: '${widget.doctor.firstName} ${widget.doctor.lastName}',
      doctorSpecialty: widget.doctor.specialty,
      patientName: auth.userName,
      patientCmu: auth.currentUser?.cmuNumber,
      patientId: auth.currentUser?.id ?? 'patient',
    );
    
    if (kDebugMode) {
      debugPrint('✅ Conversation créée/récupérée:');
      debugPrint('   - ID: ${_conversation?.id}');
      debugPrint('   - patientId: ${_conversation?.patientId}');
      debugPrint('   - doctorId: ${_conversation?.doctorId}');
      debugPrint('   - Après création - Conversations: ${msgProvider.conversations.length}');
    }
    
    // Marquer les messages du médecin comme lus
    msgProvider.markReadByPatient(_conversation!.id);
    
    setState(() {});
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_conversation == null) return;
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final auth = context.read<AuthProvider>();
    final patientId = auth.currentUser?.id ?? 'patient';
    final msgProvider = context.read<MessageProvider>();
    final success = await msgProvider.sendAsPatient(
      _conversation!.id,
      text,
      patientId: patientId,
      patientName: auth.userName,
    );

    if (!success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Limite de 10 messages gratuits atteinte.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
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
              imageUrl: widget.doctor.avatarUrl,
              initials: '${widget.doctor.firstName[0]}${widget.doctor.lastName[0]}',
              size: 36,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${widget.doctor.firstName} ${widget.doctor.lastName}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Text(
                    widget.doctor.specialty,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            // Indicateur en ligne
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: widget.doctor.isOnline ? Colors.green : Colors.grey,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ],
        ),
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
                  if (_conversation == null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock_outline, size: 56, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            const Text('Messagerie verrouillée', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
                            const SizedBox(height: 8),
                            Text('La demande du médecin doit être acceptée avant de pouvoir échanger.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey[600], fontFamily: 'Poppins')),
                          ],
                        ),
                      ),
                    );
                  }
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
                            'Envoyez votre premier message au Dr. ${widget.doctor.lastName}',
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
                      final isFromMe = message.isFromPatient;
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
            if (_conversation != null) _buildMessageInput(),
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
              imageUrl: widget.doctor.avatarUrl,
              initials: '${widget.doctor.firstName[0]}${widget.doctor.lastName[0]}',
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
