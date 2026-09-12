import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/message_provider.dart';

// ─── Screen principal ─────────────────────────────────────────────────────────

class SharedChatScreen extends StatefulWidget {
  final String conversationId;
  final String otherPersonName;
  final String otherPersonRole;       // 'Médecin' ou 'Patient'
  final String? otherPersonAvatar;
  final String? otherPersonSpecialty;
  final bool isDoctor;                // true = vue médecin, false = vue patient
  final String? cmuNumber;            // bannière CMU si patient
  final VoidCallback? onVideoCall;
  // Pour la vue médecin : son propre ID et nom (pour signer les messages)
  final String? doctorId;
  final String? doctorName;

  const SharedChatScreen({
    super.key,
    required this.conversationId,
    required this.otherPersonName,
    required this.otherPersonRole,
    this.otherPersonAvatar,
    this.otherPersonSpecialty,
    this.isDoctor = false,
    this.cmuNumber,
    this.onVideoCall,
    this.doctorId,
    this.doctorName,
  });

  @override
  State<SharedChatScreen> createState() => _SharedChatScreenState();
}

class _SharedChatScreenState extends State<SharedChatScreen>
    with TickerProviderStateMixin {

  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();
  final _picker = ImagePicker();

  bool _showEmoji = false;
  bool _showAttach = false;
  bool _isTyping = false;
  Timer? _typingTimer;
  Timer? _typingStopTimer;

  late AnimationController _sendBtnCtrl;
  late Animation<double> _sendBtnAnim;

  // ID de l'expéditeur selon le rôle
  String get _mySenderId => widget.isDoctor
      ? (widget.doctorId ?? 'doctor_kouame')
      : 'patient';

  String get _myName {
    if (widget.isDoctor) {
      return widget.doctorName ?? 'Dr. Kouamé Jean-Pierre';
    }
    // Nom dynamique depuis le user connecté
    final auth = context.read<AuthProvider>();
    return auth.currentUser?.fullName ?? 'Patient';
  }

  @override
  void initState() {
    super.initState();
    _sendBtnCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _sendBtnAnim = CurvedAnimation(parent: _sendBtnCtrl, curve: Curves.elasticOut);

    _msgCtrl.addListener(_onTextChanged);
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) setState(() { _showEmoji = false; });
    });

    // Marquer comme lu à l'ouverture
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mp = context.read<MessageProvider>();
      if (widget.isDoctor) {
        mp.markReadByDoctor(widget.conversationId);
      } else {
        mp.markReadByPatient(widget.conversationId);
      }
      _scrollToBottom(animated: false);
    });
  }

  void _onTextChanged() {
    final hasText = _msgCtrl.text.trim().isNotEmpty;
    if (hasText) {
      _sendBtnCtrl.forward();
    } else {
      _sendBtnCtrl.reverse();
    }

    final mp = context.read<MessageProvider>();

    if (!_isTyping && hasText) {
      setState(() => _isTyping = true);
      mp.setTyping(widget.conversationId, _mySenderId, true);
    }

    _typingTimer?.cancel();
    if (hasText) {
      _typingTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _isTyping = false);
          mp.setTyping(widget.conversationId, _mySenderId, false);
        }
      });
    } else {
      if (_isTyping) {
        setState(() => _isTyping = false);
        mp.setTyping(widget.conversationId, _mySenderId, false);
      }
    }
  }

  Future<void> _sendMessage({String? text, ChatMsgType type = ChatMsgType.text}) async {
    final content = text ?? _msgCtrl.text.trim();
    if (content.isEmpty && type == ChatMsgType.text) return;

    final mp = context.read<MessageProvider>();

    if (widget.isDoctor) {
      mp.sendAsDoctor(
        widget.conversationId,
        _mySenderId,
        _myName,
        content,
        type: type,
      );
    } else {
      final auth = context.read<AuthProvider>();
      final patientId = auth.currentUser?.id ?? 'patient';
      final success = await mp.sendAsPatient(
        widget.conversationId,
        content,
        patientId: patientId,
        patientName: _myName,
        type: type,
      );

      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.lock_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Limite de 10 messages gratuits atteinte.',
                      style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
        return;
      }
    }

    // Stopper l'indicateur typing
    mp.setTyping(widget.conversationId, _mySenderId, false);
    setState(() {
      _msgCtrl.clear();
      _showEmoji = false;
      _showAttach = false;
      _isTyping = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients && _scrollCtrl.position.hasContentDimensions) {
        if (animated) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent + 100,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
        }
      }
    });
  }

  Future<void> _pickImage({bool fromCamera = false}) async {
    final XFile? img = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery);
    if (img != null && mounted) {
      _sendMessage(text: '📷 Photo envoyée', type: ChatMsgType.image);
    }
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) return "Aujourd'hui";
    final yesterday = now.subtract(const Duration(days: 1));
    if (dt.day == yesterday.day && dt.month == yesterday.month) return 'Hier';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  void dispose() {
    // On stoppe l'indicateur typing proprement
    context.read<MessageProvider>().setTyping(widget.conversationId, _mySenderId, false);
    _msgCtrl.removeListener(_onTextChanged);
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    _typingTimer?.cancel();
    _typingStopTimer?.cancel();
    _sendBtnCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: _buildAppBar(),
      body: Consumer<MessageProvider>(
        builder: (_, mp, __) {
          final auth = context.watch<AuthProvider>();
          final patientId = auth.currentUser?.id ?? 'patient';
          final remaining = !widget.isDoctor ? mp.getRemainingFreeMessages(patientId) : 10;
          final messages = mp.messagesOf(widget.conversationId);
          final otherTyping = mp.isTyping(widget.conversationId) &&
              mp.whoIsTyping(widget.conversationId) != _mySenderId;

          // Auto-scroll quand nouveau message arrive
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom(animated: true));

          return Column(
            children: [
              // Bannière CMU (patient seulement)
              if (!widget.isDoctor && widget.cmuNumber != null) _buildCmuBanner(),

              // Bannière Quota 10 messages (patient seulement)
              if (!widget.isDoctor) _buildQuotaBanner(remaining),

              // Liste messages
              Expanded(child: _buildMessageList(messages)),

              // Indicateur "en train d'écrire"
              if (otherTyping) _buildTypingIndicator(),

              // Zone de saisie (bloquée si 10 messages consommés pour le patient)
              _buildInputArea(isBlocked: !widget.isDoctor && remaining <= 0),
            ],
          );
        },
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
        color: AppColors.textPrimary,
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: Consumer<MessageProvider>(
        builder: (_, mp, __) {
          final otherTyping = mp.isTyping(widget.conversationId) &&
              mp.whoIsTyping(widget.conversationId) != _mySenderId;
          return GestureDetector(
            onTap: _showProfilDialog,
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primaryUltraLight,
                      child: Text(
                        widget.otherPersonName.isNotEmpty ? widget.otherPersonName[0].toUpperCase() : '?',
                        style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16),
                      ),
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        width: 11, height: 11,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.otherPersonName,
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        otherTyping ? 'En train d\'écrire...' : (widget.otherPersonSpecialty ?? widget.otherPersonRole),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: otherTyping ? AppColors.primary : AppColors.textSecondary,
                          fontWeight: otherTyping ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.call_rounded, color: AppColors.primary),
          onPressed: () => _showCallDialog(isVideo: false),
        ),
        IconButton(
          icon: const Icon(Icons.videocam_rounded, color: AppColors.primary),
          onPressed: () => _showCallDialog(isVideo: true),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: AppColors.textPrimary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          onSelected: (val) {
            if (val == 'rdv') _showRdvDialog();
            if (val == 'profil') _showProfilDialog();
            if (val == 'clear') {
              // On vide les messages de la conversation
              context.read<MessageProvider>().messagesOf(widget.conversationId);
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'rdv', child: Row(children: [Icon(Icons.calendar_today_outlined, size: 18), SizedBox(width: 8), Text('Prendre RDV')])),
            const PopupMenuItem(value: 'profil', child: Row(children: [Icon(Icons.person_outline_rounded, size: 18), SizedBox(width: 8), Text('Voir le profil')])),
          ],
        ),
      ],
    );
  }

  // ── Bannière CMU ──────────────────────────────────────────────────────────────
  Widget _buildCmuBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.primaryUltraLight,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
            child: const Text('CMU', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'CMU-CI: ${widget.cmuNumber} · Couverture active',
              style: const TextStyle(fontSize: 11, fontFamily: 'Poppins', color: AppColors.primary, fontWeight: FontWeight.w500),
            ),
          ),
          const Icon(Icons.verified_rounded, color: AppColors.primary, size: 16),
        ],
      ),
    );
  }

  // ── Bannière Quota 10 messages gratuits ───────────────────────────────────────
  Widget _buildQuotaBanner(int remaining) {
    Color badgeColor;
    Color textColor;
    String statusText;

    if (remaining > 3) {
      badgeColor = AppColors.success.withValues(alpha: 0.12);
      textColor = AppColors.success;
      statusText = 'Il vous reste $remaining messages gratuits.';
    } else if (remaining > 0) {
      badgeColor = AppColors.warning.withValues(alpha: 0.15);
      textColor = AppColors.warning;
      statusText = 'Attention : il ne vous reste que $remaining message${remaining > 1 ? 's' : ''} gratuit${remaining > 1 ? 's' : ''}.';
    } else {
      badgeColor = AppColors.error.withValues(alpha: 0.12);
      textColor = AppColors.error;
      statusText = 'Limite atteinte : 0 message gratuit restant.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: badgeColor,
      child: Row(
        children: [
          Icon(
            remaining > 0 ? Icons.chat_bubble_outline_rounded : Icons.lock_outline_rounded,
            size: 16,
            color: textColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: textColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$remaining / 10',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Liste messages ────────────────────────────────────────────────────────────
  Widget _buildMessageList(List<ChatMessage> messages) {
    return GestureDetector(
      onTap: () {
        _focusNode.unfocus();
        setState(() { _showEmoji = false; _showAttach = false; });
      },
      child: messages.isEmpty
          ? _buildEmptyConv()
          : ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              itemCount: messages.length,
              itemBuilder: (_, i) {
                final msg = messages[i];
                final showDate = i == 0 ||
                    _formatDate(messages[i - 1].time) != _formatDate(msg.time);
                return Column(
                  children: [
                    if (showDate) _DateSeparator(label: _formatDate(msg.time)),
                    _buildMessageBubble(msg),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildEmptyConv() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(color: AppColors.primaryUltraLight, shape: BoxShape.circle),
            child: const Icon(Icons.chat_bubble_outline_rounded, size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          const Text(
            'Commencez la conversation',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Écrivez votre premier message\nà ${widget.otherPersonName}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    // Message info
    if (msg.type == ChatMsgType.info) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryUltraLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(msg.text,
                      style: const TextStyle(fontSize: 11, fontFamily: 'Poppins', color: AppColors.primary, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Message normal : isMe = "c'est moi qui ai envoyé"
    final isMe = msg.senderId == _mySenderId;

    // Statut de lecture
    final isReadByOther = widget.isDoctor
        ? msg.isReadByPatient   // médecin envoie → lu par patient ?
        : msg.isReadByDoctor;   // patient envoie → lu par médecin ?

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primaryUltraLight,
              child: Text(
                widget.otherPersonName.isNotEmpty ? widget.otherPersonName[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.68),
                  decoration: BoxDecoration(
                    gradient: isMe ? AppColors.primaryGradient : null,
                    color: isMe ? null : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.07),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    msg.text,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: isMe ? Colors.white : AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(msg.time),
                      style: const TextStyle(fontSize: 10, color: AppColors.textLight, fontFamily: 'Poppins'),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        isReadByOther ? Icons.done_all_rounded : Icons.done_rounded,
                        size: 12,
                        color: isReadByOther ? AppColors.primary : AppColors.textLight,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }

  // ── Indicateur "en train d'écrire" ────────────────────────────────────────────
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primaryUltraLight,
            child: Text(
              widget.otherPersonName.isNotEmpty ? widget.otherPersonName[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
            ),
            child: _TypingDots(),
          ),
        ],
      ),
    );
  }

  // ── Zone de saisie ────────────────────────────────────────────────────────────
  Widget _buildInputArea({bool isBlocked = false}) {
    if (isBlocked) {
      return _buildBlockedInputArea();
    }
    return Column(
      children: [
        // Panel Emoji
        if (_showEmoji)
          SizedBox(
            height: 280,
            child: EmojiPicker(
              onEmojiSelected: (_, emoji) {
                _msgCtrl.text += emoji.emoji;
                _msgCtrl.selection = TextSelection.fromPosition(
                    TextPosition(offset: _msgCtrl.text.length));
              },
              config: const Config(
                emojiViewConfig: EmojiViewConfig(columns: 7, emojiSizeMax: 28),
              ),
            ),
          ),

        // Panel pièces jointes
        if (_showAttach) _buildAttachPanel(),

        // Barre de saisie
        Container(
          padding: EdgeInsets.only(
            left: 8, right: 8, top: 8,
            bottom: MediaQuery.of(context).padding.bottom + 8,
          ),
          color: Colors.white,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Bouton emoji
              IconButton(
                icon: Icon(
                  _showEmoji ? Icons.keyboard_rounded : Icons.emoji_emotions_outlined,
                  color: AppColors.primary,
                ),
                onPressed: () {
                  _focusNode.unfocus();
                  setState(() { _showEmoji = !_showEmoji; _showAttach = false; });
                },
              ),
              // Champ texte
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.backgroundGrey),
                  ),
                  child: TextField(
                    controller: _msgCtrl,
                    focusNode: _focusNode,
                    maxLines: null,
                    textInputAction: TextInputAction.newline,
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Votre message...',
                      hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textLight),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.attach_file_rounded, color: AppColors.textSecondary, size: 20),
                        onPressed: () {
                          _focusNode.unfocus();
                          setState(() { _showAttach = !_showAttach; _showEmoji = false; });
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Bouton envoyer
              ScaleTransition(
                scale: _sendBtnAnim,
                child: GestureDetector(
                  onTap: _sendMessage,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: _msgCtrl.text.trim().isNotEmpty ? AppColors.primaryGradient : null,
                      color: _msgCtrl.text.trim().isEmpty ? AppColors.backgroundGrey : null,
                      shape: BoxShape.circle,
                      boxShadow: _msgCtrl.text.trim().isNotEmpty
                          ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 12, spreadRadius: 1)]
                          : null,
                    ),
                    child: Icon(
                      Icons.send_rounded,
                      color: _msgCtrl.text.trim().isNotEmpty ? Colors.white : AppColors.textLight,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Zone de saisie bloquée (quand limite de 10 messages atteinte) ────────────
  Widget _buildBlockedInputArea() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: EdgeInsets.only(
        left: 12, right: 12, top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_rounded, color: AppColors.error, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Limite de 10 messages atteinte',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.error,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Vous avez consommé vos 10 messages gratuits. Le médecin peut toujours vous répondre.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Panel pièces jointes ──────────────────────────────────────────────────────
  Widget _buildAttachPanel() {
    final items = [
      _AttachItem(icon: Icons.image_rounded, label: 'Photo', color: Colors.purple,
          onTap: () => _pickImage()),
      _AttachItem(icon: Icons.camera_alt_rounded, label: 'Caméra', color: Colors.orange,
          onTap: () => _pickImage(fromCamera: true)),
      _AttachItem(icon: Icons.description_rounded, label: 'Document', color: Colors.blue,
          onTap: () { setState(() => _showAttach = false); _sendMessage(text: '📄 Document partagé'); }),
      _AttachItem(
        icon: Icons.medication_rounded,
        label: widget.isDoctor ? 'Ordonnance' : 'CMU',
        color: AppColors.primary,
        onTap: () {
          setState(() => _showAttach = false);
          _sendMessage(text: widget.isDoctor ? '📋 Ordonnance envoyée' : '🏥 Carte CMU partagée');
        },
      ),
      _AttachItem(icon: Icons.calendar_today_rounded, label: 'RDV', color: Colors.green,
          onTap: () { setState(() => _showAttach = false); _showRdvDialog(); }),
      _AttachItem(icon: Icons.location_on_rounded, label: 'Position', color: Colors.red,
          onTap: () { setState(() => _showAttach = false); _sendMessage(text: '📍 Localisation partagée'); }),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      color: Colors.white,
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 8,
        childAspectRatio: 0.9,
        children: items.map((item) => GestureDetector(
          onTap: item.onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, color: item.color, size: 26),
              ),
              const SizedBox(height: 6),
              Text(item.label,
                  style: const TextStyle(fontSize: 10, fontFamily: 'Poppins', color: AppColors.textSecondary),
                  textAlign: TextAlign.center),
            ],
          ),
        )).toList(),
      ),
    );
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────────
  void _showCallDialog({required bool isVideo}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(isVideo ? Icons.videocam_rounded : Icons.call_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(isVideo ? 'Appel vidéo' : 'Appel audio',
                style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          'Démarrer un appel ${isVideo ? 'vidéo' : 'audio'} avec ${widget.otherPersonName} ?',
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              if (isVideo && widget.onVideoCall != null) widget.onVideoCall!();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: Icon(isVideo ? Icons.videocam_rounded : Icons.call_rounded, size: 16),
            label: Text(isVideo ? 'Appel vidéo' : 'Appeler',
                style: const TextStyle(fontFamily: 'Poppins', color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showRdvDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.primaryUltraLight, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.calendar_today_rounded, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                const Text('Proposer un rendez-vous',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 20),
            ...['Demain à 09h00', 'Demain à 14h00', 'Jeudi à 10h30', 'Vendredi à 16h00'].map((slot) =>
              ListTile(
                leading: const Icon(Icons.schedule_rounded, color: AppColors.primary),
                title: Text(slot, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w500)),
                trailing: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _sendMessage(text: '📅 RDV proposé : $slot', type: ChatMsgType.rdv);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Proposer', style: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontSize: 12)),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showProfilDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.primaryUltraLight,
              child: Text(
                widget.otherPersonName.isNotEmpty ? widget.otherPersonName[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 12),
            Text(widget.otherPersonName,
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(widget.otherPersonSpecialty ?? widget.otherPersonRole,
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textSecondary)),
            if (widget.cmuNumber != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.primaryUltraLight, borderRadius: BorderRadius.circular(10)),
                child: Text(widget.cmuNumber!, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─── Widgets auxiliaires ──────────────────────────────────────────────────────

class _DateSeparator extends StatelessWidget {
  final String label;
  const _DateSeparator({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final delay = i / 3;
          final value = ((_anim.value - delay).clamp(0.0, 1.0));
          final opacity = (value < 0.5 ? value * 2 : (1 - value) * 2).clamp(0.3, 1.0);
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: opacity),
              shape: BoxShape.circle,
            ),
          );
        }),
      ),
    );
  }
}

class _AttachItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _AttachItem({required this.icon, required this.label, required this.color, required this.onTap});
}
