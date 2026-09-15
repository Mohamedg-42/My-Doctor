// lib/screens/admin/views/admin_conversations_view.dart
//
// Vue de supervision des conversations et audit des quotas de messagerie pour l'administrateur.

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/message_provider.dart';
import '../../../services/database_service.dart';
import '../components/admin_empty_state.dart';

class AdminConversationsView extends StatefulWidget {
  const AdminConversationsView({super.key});

  @override
  State<AdminConversationsView> createState() => _AdminConversationsViewState();
}

class _AdminConversationsViewState extends State<AdminConversationsView> {
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _resetQuota(String patientId, String patientName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Recharger le quota patient'),
        content: Text('Voulez-vous réinitialiser le quota de $patientName à 10 messages gratuits ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandBlue, foregroundColor: Colors.white),
            child: const Text('Recharger (10 msgs)'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    await DatabaseService().resetPatientMessageUsage(patientId, 10);
    setState(() {});

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Quota de messages rechargé pour $patientName.'), backgroundColor: AppColors.success),
    );
  }

  void _showConversationAudit(ChatConversation conv, List<ChatMessage> messages, PatientMessageUsage usage) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(LucideIcons.messages_square, color: AppColors.brandBlue),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Audit Conversation : ${conv.patientName} & ${conv.doctorName}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _DetailRow('Identifiant', conv.id),
                _DetailRow('Patient', '${conv.patientName} (${conv.patientId})'),
                _DetailRow('Médecin', '${conv.doctorName} (${conv.doctorSpecialty})'),
                _DetailRow('Total messages', '${messages.length}'),
                _DetailRow('Quota patient consommé', '${usage.freeMessagesUsed} / ${usage.freeMessagesLimit}'),
                _DetailRow('Quota patient restant', '${usage.remaining}'),
                _DetailRow('Statut conversation', conv.isLocked ? 'Verrouillée' : 'Active'),
                const SizedBox(height: 16),
                const Text('Derniers messages échangés (Métadonnées & Aperçu) :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 8),
                if (messages.isEmpty)
                  const Text('Aucun message échangé', style: TextStyle(color: Colors.grey, fontSize: 12))
                else
                  ...messages.reversed.take(5).map((m) => Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.isFromDoctor ? '👨‍⚕️ Dr : ' : '👤 Patient : ',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                            Expanded(
                              child: Text(m.text, style: const TextStyle(fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _dateFormat.format(m.time),
                              style: const TextStyle(fontSize: 9, color: Colors.grey),
                            ),
                          ],
                        ),
                      )),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();
    final messageProvider = context.watch<MessageProvider>();
    final conversations = messageProvider.conversations;

    final filtered = conversations.where((c) {
      final q = _searchQuery.toLowerCase();
      return q.isEmpty ||
          c.patientName.toLowerCase().contains(q) ||
          c.doctorName.toLowerCase().contains(q) ||
          c.doctorSpecialty.toLowerCase().contains(q);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Rechercher une conversation par patient ou praticien...',
                hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey.shade400),
                prefixIcon: const Icon(LucideIcons.search, size: 18, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: filtered.isEmpty
                ? const AdminEmptyState(
                    icon: LucideIcons.message_square_off,
                    title: 'Aucune conversation trouvée',
                    message: 'Aucune conversation active ne correspond à vos filtres.',
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final conv = filtered[i];
                      final messages = messageProvider.messagesOf(conv.id);
                      final lastMsg = messageProvider.lastMessageOf(conv.id);
                      final usage = db.getPatientMessageUsage(conv.patientId);

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.brandBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(LucideIcons.message_circle, color: AppColors.brandBlue, size: 22),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          '${conv.patientName} & ${conv.doctorName}',
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF0F172A),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: (usage.isLimitReached ? AppColors.error : AppColors.success)
                                              .withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          usage.isLimitReached ? 'Quota atteint' : 'Quota actif (${usage.remaining} restants)',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: usage.isLimitReached ? AppColors.error : AppColors.success,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${messages.length} message(s) échangé(s) • Dr. ${conv.doctorName} (${conv.doctorSpecialty})',
                                    style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                  if (lastMsg != null) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      'Dernier message : "${lastMsg.text}" (${_dateFormat.format(lastMsg.time)})',
                                      style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.grey.shade500),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(LucideIcons.rotate_ccw, size: 18, color: AppColors.brandBlue),
                                  tooltip: 'Réinitialiser quota (10 msgs)',
                                  onPressed: () => _resetQuota(conv.patientId, conv.patientName),
                                ),
                                IconButton(
                                  icon: const Icon(LucideIcons.eye, size: 18, color: Color(0xFF475569)),
                                  tooltip: 'Audit conversation',
                                  onPressed: () => _showConversationAudit(conv, messages, usage),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        ],
      ),
    );
  }
}
