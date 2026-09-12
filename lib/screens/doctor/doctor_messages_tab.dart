import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/message_provider.dart';
import '../patient/notifications_screen.dart';
import '../patient/video_call_screen.dart';
import '../shared/shared_chat_screen.dart';

// ─── ID du médecin connecté (démo) ───────────────────────────────────────────
// En production, ce serait extrait de AuthProvider (auth.doctorProfile.id)
const _kDoctorId = 'doctor_kouame';
const _kDoctorName = 'Dr. Kouamé Jean-Pierre';

// ─── DoctorMessagesTab ────────────────────────────────────────────────────────

class DoctorMessagesTab extends StatefulWidget {
  const DoctorMessagesTab({super.key});

  @override
  State<DoctorMessagesTab> createState() => _DoctorMessagesTabState();
}

class _DoctorMessagesTabState extends State<DoctorMessagesTab>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  String _effectiveDoctorId(BuildContext context) {
    final auth = context.read<AuthProvider>();
    return auth.doctorProfile?.id ?? auth.currentUser?.id ?? _kDoctorId;
  }

  String _effectiveDoctorName(BuildContext context) {
    final auth = context.read<AuthProvider>();
    return auth.doctorProfile?.fullName ?? auth.currentUser?.fullName ?? _kDoctorName;
  }

  void _openPatientChat(BuildContext context, ChatConversation conv) {
    final docId = _effectiveDoctorId(context);
    final docName = _effectiveDoctorName(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SharedChatScreen(
          conversationId: conv.id,
          otherPersonName: conv.patientName,
          otherPersonRole: 'Patient',
          otherPersonSpecialty: null,
          isDoctor: true,
          cmuNumber: conv.patientCmu,
          doctorId: docId,
          doctorName: docName,
          onVideoCall: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VideoCallScreen(
                  doctorName: conv.patientName,
                  doctorSpecialty: 'Patient - ${conv.patientCmu ?? ''}',
                  isIncoming: false,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final docId = auth.doctorProfile?.id ?? auth.currentUser?.id ?? _kDoctorId;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: _buildAppBar(context, docId),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Consumer<MessageProvider>(
          builder: (_, mp, __) {
            final convs = mp.conversationsForDoctor(docId);
            final filtered = _searchQuery.isEmpty
                ? convs
                : convs.where((c) =>
                    c.patientName.toLowerCase().contains(_searchQuery) ||
                    (c.patientCmu ?? '').toLowerCase().contains(_searchQuery)).toList();
            final totalUnread = mp.totalUnreadForDoctor(docId);

            return Column(
              children: [
                _buildSearchBar(),
                if (totalUnread > 0) _buildUnreadBanner(totalUnread),
                Expanded(
                  child: filtered.isEmpty
                      ? _buildEmpty()
                      : _buildList(context, mp, filtered),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, String docId) {
    return AppBar(
      backgroundColor: AppColors.backgroundCard,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Consumer<MessageProvider>(
        builder: (_, mp, __) {
          final total = mp.conversationsForDoctor(docId).length;
          return Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Messagerie',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  Text(
                    '$total patient${total > 1 ? 's' : ''}',
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          );
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
        ),
        IconButton(
          icon: const Icon(Icons.filter_list_rounded, color: AppColors.primary),
          onPressed: () => _showFilterSheet(context),
          tooltip: 'Filtrer',
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: AppColors.backgroundCard,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.backgroundGrey),
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Rechercher un patient, CMU...',
            hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textLight),
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textLight, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? GestureDetector(
                    onTap: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); },
                    child: const Icon(Icons.close_rounded, color: AppColors.textLight, size: 18),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildUnreadBanner(int totalUnread) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withValues(alpha: 0.08), AppColors.primary.withValues(alpha: 0.04)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: Text(
              '$totalUnread',
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$totalUnread message${totalUnread > 1 ? 's' : ''} non lu${totalUnread > 1 ? 's' : ''} de vos patients',
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, MessageProvider mp, List<ChatConversation> convs) {
    // Trier par dernier message (plus récent en premier)
    final sorted = [...convs];
    sorted.sort((a, b) {
      final la = mp.lastMessageOf(a.id);
      final lb = mp.lastMessageOf(b.id);
      if (la == null && lb == null) return 0;
      if (la == null) return 1;
      if (lb == null) return -1;
      return lb.time.compareTo(la.time);
    });

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final conv = sorted[i];
        final lastMsg = mp.lastMessageOf(conv.id);
        final unread = mp.unreadCountForDoctor(conv.id);
        return _ConvCard(
          conv: conv,
          lastMsg: lastMsg,
          unreadCount: unread,
          onTap: () => _openPatientChat(context, conv),
          onVideoCall: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VideoCallScreen(
                doctorName: conv.patientName,
                doctorSpecialty: 'Patient',
                isIncoming: false,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: const BoxDecoration(color: AppColors.primaryUltraLight, shape: BoxShape.circle),
            child: const Icon(Icons.chat_bubble_outline_rounded, size: 52, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          const Text('Aucune conversation',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Aucun résultat pour "$_searchQuery"'
                : 'Vos conversations avec vos\npatients apparaîtront ici',
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.backgroundGrey, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('Filtrer les messages', style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: ['Tous', 'Non lus', 'En ligne'].map((label) =>
                ActionChip(
                  label: Text(label, style: const TextStyle(fontFamily: 'Poppins')),
                  onPressed: () => Navigator.pop(context),
                  backgroundColor: AppColors.primaryUltraLight,
                ),
              ).toList(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Appliquer', style: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Carte de conversation ────────────────────────────────────────────────────

class _ConvCard extends StatelessWidget {
  final ChatConversation conv;
  final ChatMessage? lastMsg;
  final int unreadCount;
  final VoidCallback onTap;
  final VoidCallback onVideoCall;

  const _ConvCard({
    required this.conv,
    required this.lastMsg,
    required this.unreadCount,
    required this.onTap,
    required this.onVideoCall,
  });

  @override
  Widget build(BuildContext context) {
    final hasUnread = unreadCount > 0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(18),
          border: hasUnread
              ? Border.all(color: AppColors.primary.withValues(alpha: 0.35), width: 1.5)
              : Border.all(color: Colors.transparent),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: hasUnread ? 0.08 : 0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                _PatientAvatar(name: conv.patientName),
                Positioned(
                  right: 2, bottom: 2,
                  child: Container(
                    width: 12, height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.backgroundCard, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),

            // Contenu
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom + heure
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          conv.patientName,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (lastMsg != null)
                        Text(
                          _timeAgo(lastMsg!.time),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            color: hasUnread ? AppColors.primary : AppColors.textLight,
                            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),

                  // Badge CMU
                  if (conv.patientCmu != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF185FA5).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        conv.patientCmu!,
                        style: const TextStyle(
                          fontFamily: 'Poppins', fontSize: 9,
                          fontWeight: FontWeight.w600, color: Color(0xFF185FA5),
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),

                  // Dernier message
                  if (lastMsg != null)
                    Row(
                      children: [
                        // Icône "envoyé par moi" (médecin)
                        if (lastMsg!.isFromDoctor && lastMsg!.senderId == _kDoctorId) ...[
                          Icon(
                            lastMsg!.isReadByPatient ? Icons.done_all_rounded : Icons.done_rounded,
                            size: 13,
                            color: lastMsg!.isReadByPatient ? AppColors.primary : AppColors.textLight,
                          ),
                          const SizedBox(width: 3),
                        ],
                        Expanded(
                          child: Text(
                            lastMsg!.text,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: hasUnread ? AppColors.textPrimary : AppColors.textSecondary,
                              fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      'Démarrer la conversation',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.primary.withValues(alpha: 0.7), fontStyle: FontStyle.italic),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Badge + bouton appel
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  )
                else
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textLight, size: 20),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: onVideoCall,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.videocam_rounded, color: AppColors.success, size: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'maintenant';
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}j';
    return '${dt.day}/${dt.month}';
  }
}

// ─── Avatar patient ───────────────────────────────────────────────────────────

class _PatientAvatar extends StatelessWidget {
  final String name;
  const _PatientAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final parts = name.split(' ').where((w) => w.isNotEmpty).toList();
    final initials = parts.take(2).map((w) => w[0].toUpperCase()).join();
    final palette = [
      [const Color(0xFF2563A8), const Color(0xFF1A4A80)],
      [const Color(0xFF059669), const Color(0xFF047857)],
      [const Color(0xFFD97706), const Color(0xFFB45309)],
      [const Color(0xFF7C3AED), const Color(0xFF6D28D9)],
      [const Color(0xFFDC2626), const Color(0xFFB91C1C)],
      [const Color(0xFF0891B2), const Color(0xFF0E7490)],
    ];
    final pair = palette[name.length % palette.length];
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: pair, begin: Alignment.topLeft, end: Alignment.bottomRight),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(initials, style: const TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }
}
