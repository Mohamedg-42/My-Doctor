import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/message_provider.dart';

class AdminConversationsView extends StatefulWidget {
  const AdminConversationsView({super.key});

  @override
  State<AdminConversationsView> createState() => _AdminConversationsViewState();
}

class _AdminConversationsViewState extends State<AdminConversationsView> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final msgProvider = context.watch<MessageProvider>();
    final allConvs = msgProvider.allConversations;

    final filtered = allConvs.where((c) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchPatient = c.patientName.toLowerCase().contains(q);
        final matchDoctor = c.doctorName.toLowerCase().contains(q);
        final matchSpec = c.doctorSpecialty.toLowerCase().contains(q);
        return matchPatient || matchDoctor || matchSpec;
      }
      return true;
    }).toList();

    return Column(
      children: [
        // ── Avertissement Confidentialité Médicale ────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: AppColors.selectedBg,
          child: const Row(
            children: [
              Icon(LucideIcons.shield_alert, color: AppColors.brandBlue, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Déontologie & Secret Médical : Seules les métadonnées (participants, volumes, horodatages) sont affichées.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: AppColors.brandNavy,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Recherche ───────────────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v.trim()),
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Rechercher par patient ou médecin...',
                hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textMuted),
                prefixIcon: const Icon(LucideIcons.search, size: 18, color: AppColors.textMuted),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(LucideIcons.x, size: 16),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 11),
              ),
            ),
          ),
        ),

        // ── Compteur ───────────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.surfaceSubtle,
          child: Text(
            '${filtered.length} conversation(s) active(s) • ${msgProvider.totalMessagesCount} message(s) au total',
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
        ),

        // ── Liste des conversations ────────────────────────────────────
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.messages_square, size: 48, color: AppColors.textMuted.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      const Text(
                        'Aucune conversation enregistrée',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final conv = filtered[i];
                    final msgs = msgProvider.messagesOf(conv.id);
                    final lastMsg = msgProvider.lastMessageOf(conv.id);

                    return _ConversationAdminCard(
                      conv: conv,
                      messagesCount: msgs.length,
                      lastMessage: lastMsg,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ConversationAdminCard extends StatelessWidget {
  final ChatConversation conv;
  final int messagesCount;
  final ChatMessage? lastMessage;

  const _ConversationAdminCard({
    required this.conv,
    required this.messagesCount,
    required this.lastMessage,
  });

  @override
  Widget build(BuildContext context) {
    final lastTimeStr = lastMessage != null
        ? DateFormat('dd/MM HH:mm').format(lastMessage!.time)
        : 'Aucun message';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ID : ${conv.id}',
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, color: AppColors.textMuted),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.brandBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.message_circle, size: 12, color: AppColors.brandBlue),
                    const SizedBox(width: 4),
                    Text(
                      '$messagesCount message(s)',
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.brandBlue),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Binôme Patient ↔ Médecin
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.brandBlue.withValues(alpha: 0.12),
                      child: const Icon(LucideIcons.user, size: 16, color: AppColors.brandBlue),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Patient', style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: AppColors.textMuted)),
                          Text(
                            conv.patientName,
                            style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(LucideIcons.arrow_left_right, size: 16, color: AppColors.textMuted),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Médecin', style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: AppColors.textMuted)),
                          Text(
                            conv.doctorName,
                            style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.brandTurquoise),
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.brandTurquoise.withValues(alpha: 0.12),
                      child: const Icon(LucideIcons.stethoscope, size: 16, color: AppColors.brandTurquoise),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.borderSubtle),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.clock, size: 12, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text('Dernière activité : $lastTimeStr', style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, color: AppColors.textMuted)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: conv.isLocked ? AppColors.error.withValues(alpha: 0.1) : AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  conv.isLocked ? 'Verrouillée' : 'Active',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: conv.isLocked ? AppColors.error : AppColors.success,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
