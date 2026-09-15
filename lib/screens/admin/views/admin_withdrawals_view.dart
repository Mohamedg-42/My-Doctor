// lib/screens/admin/views/admin_withdrawals_view.dart
//
// Vue de gestion des demandes de retrait et des finances médecins pour l'administrateur.

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../components/admin_empty_state.dart';

class WithdrawalItem {
  final String id;
  final String doctorId;
  final String doctorName;
  final String doctorPhone;
  final double grossAmount;
  final double commissionRate; // ex: 0.10 pour 10%
  final String paymentMethod;  // 'Wave', 'Orange Money', 'Moov Money', 'Virement'
  final String accountNumber;
  final DateTime createdAt;
  String status;               // 'pending', 'approved', 'processed', 'rejected'
  String? adminNote;
  String? rejectionReason;

  WithdrawalItem({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    required this.doctorPhone,
    required this.grossAmount,
    this.commissionRate = 0.10,
    required this.paymentMethod,
    required this.accountNumber,
    required this.createdAt,
    this.status = 'pending',
    this.adminNote,
    this.rejectionReason,
  });

  double get commission => grossAmount * commissionRate;
  double get netAmount => grossAmount - commission;
}

class AdminWithdrawalsView extends StatefulWidget {
  const AdminWithdrawalsView({super.key});

  @override
  State<AdminWithdrawalsView> createState() => _AdminWithdrawalsViewState();
}

class _AdminWithdrawalsViewState extends State<AdminWithdrawalsView> {
  String _selectedFilter = 'Tous'; // 'Tous', 'En attente', 'Approuvés', 'Traités', 'Rejetés'
  bool _isProcessing = false;

  final NumberFormat _currencyFormat = NumberFormat('#,###');

  // Liste des retraits avec données de démo initiales
  final List<WithdrawalItem> _withdrawals = [
    WithdrawalItem(
      id: 'wd_001',
      doctorId: 'doc_demo_01',
      doctorName: 'Dr. Sarah Touré',
      doctorPhone: '0505050505',
      grossAmount: 150000,
      paymentMethod: 'Wave',
      accountNumber: '0505050505',
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      status: 'pending',
    ),
    WithdrawalItem(
      id: 'wd_002',
      doctorId: 'doc_demo_02',
      doctorName: 'Dr. Marc Yao',
      doctorPhone: '0505050506',
      grossAmount: 220000,
      paymentMethod: 'Orange Money',
      accountNumber: '0505050506',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      status: 'approved',
      adminNote: 'Approuvé par Admin Principal le 13/09',
    ),
    WithdrawalItem(
      id: 'wd_003',
      doctorId: 'doc_demo_03',
      doctorName: 'Dr. Aminata Diallo',
      doctorPhone: '0505050507',
      grossAmount: 380000,
      paymentMethod: 'Virement bancaire (SIB)',
      accountNumber: 'CI092 01001 12345678901 45',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      status: 'processed',
      adminNote: 'Virement émis et validé via portail bancaire',
    ),
  ];

  Future<void> _changeWithdrawalStatus(WithdrawalItem item, String newStatus, String actionTitle) async {
    String? reason;
    final reasonCtrl = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(actionTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Montant brut : ${_currencyFormat.format(item.grossAmount)} FCFA\n'
              'Commission (10%) : ${_currencyFormat.format(item.commission)} FCFA\n'
              'Montant net à verser : ${_currencyFormat.format(item.netAmount)} FCFA\n'
              'Bénéficiaire : ${item.doctorName} (${item.paymentMethod})',
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
            if (newStatus == 'rejected') ...[
              const SizedBox(height: 14),
              const Text('Motif du rejet (obligatoire) :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 6),
              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(
                  hintText: 'Ex: Numéro de compte erroné, justificatif manquant...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(10),
                ),
                maxLines: 2,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (newStatus == 'rejected' && reasonCtrl.text.trim().isEmpty) {
                return;
              }
              reason = reasonCtrl.text.trim();
              Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus == 'rejected'
                  ? AppColors.error
                  : (newStatus == 'processed' ? AppColors.success : AppColors.brandBlue),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 400));

    setState(() {
      item.status = newStatus;
      if (reason != null && reason!.isNotEmpty) {
        item.rejectionReason = reason;
      }
      _isProcessing = false;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Demande de retrait ${item.id} mise à jour : $newStatus.'),
        backgroundColor: newStatus == 'processed' ? AppColors.success : AppColors.brandBlue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _withdrawals.where((w) {
      if (_selectedFilter == 'En attente') return w.status == 'pending';
      if (_selectedFilter == 'Approuvés') return w.status == 'approved';
      if (_selectedFilter == 'Traités') return w.status == 'processed';
      if (_selectedFilter == 'Rejetés') return w.status == 'rejected';
      return true;
    }).toList();

    // Calculs financiers récapitulatifs
    final totalPending = _withdrawals
        .where((w) => w.status == 'pending')
        .fold<double>(0, (sum, w) => sum + w.netAmount);
    final totalProcessed = _withdrawals
        .where((w) => w.status == 'processed')
        .fold<double>(0, (sum, w) => sum + w.netAmount);
    final totalCommissions = _withdrawals
        .where((w) => w.status == 'processed')
        .fold<double>(0, (sum, w) => sum + w.commission);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cartes récapitulatives financières
          LayoutBuilder(
            builder: (ctx, constraints) {
              final isNarrow = constraints.maxWidth < 700;
              if (isNarrow) {
                return Column(
                  children: [
                    _FinanceCard(
                      title: 'En attente de paiement',
                      amount: '${_currencyFormat.format(totalPending)} FCFA',
                      icon: LucideIcons.clock,
                      color: const Color(0xFFEA580C),
                    ),
                    const SizedBox(height: 10),
                    _FinanceCard(
                      title: 'Total décaissé aux médecins',
                      amount: '${_currencyFormat.format(totalProcessed)} FCFA',
                      icon: LucideIcons.circle_check,
                      color: AppColors.success,
                    ),
                    const SizedBox(height: 10),
                    _FinanceCard(
                      title: 'Commissions plateforme perçues',
                      amount: '${_currencyFormat.format(totalCommissions)} FCFA',
                      icon: LucideIcons.badge_percent,
                      color: AppColors.brandBlue,
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: _FinanceCard(
                      title: 'En attente de paiement',
                      amount: '${_currencyFormat.format(totalPending)} FCFA',
                      icon: LucideIcons.clock,
                      color: const Color(0xFFEA580C),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _FinanceCard(
                      title: 'Total décaissé aux médecins',
                      amount: '${_currencyFormat.format(totalProcessed)} FCFA',
                      icon: LucideIcons.circle_check,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _FinanceCard(
                      title: 'Commissions plateforme perçues',
                      amount: '${_currencyFormat.format(totalCommissions)} FCFA',
                      icon: LucideIcons.badge_percent,
                      color: AppColors.brandBlue,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // Barre de filtres
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...['Tous', 'En attente', 'Approuvés', 'Traités', 'Rejetés'].map((f) {
                  final isSel = _selectedFilter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f),
                      selected: isSel,
                      onSelected: (_) => setState(() => _selectedFilter = f),
                      selectedColor: AppColors.brandBlue,
                      labelStyle: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                        color: isSel ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Liste des retraits
          Expanded(
            child: filtered.isEmpty
                ? const AdminEmptyState(
                    icon: LucideIcons.wallet,
                    title: 'Aucune demande de retrait',
                    message: 'Aucune transaction ne correspond à ce filtre.',
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final w = filtered[i];

                      Color statusColor = const Color(0xFFEA580C);
                      String statusLabel = 'En attente';
                      if (w.status == 'approved') {
                        statusColor = AppColors.brandBlue;
                        statusLabel = 'Approuvé';
                      } else if (w.status == 'processed') {
                        statusColor = AppColors.success;
                        statusLabel = 'Traité & Payé';
                      } else if (w.status == 'rejected') {
                        statusColor = AppColors.error;
                        statusLabel = 'Rejeté';
                      }

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: w.status == 'pending'
                                ? const Color(0xFFFED7AA)
                                : Colors.grey.shade200,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(LucideIcons.wallet, color: statusColor, size: 20),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        w.doctorName,
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      Text(
                                        '${w.paymentMethod} • Compte : ${w.accountNumber} • Tél : ${w.doctorPhone}',
                                        style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    statusLabel,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 24,
                              runSpacing: 14,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              alignment: WrapAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Montant brut', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                    Text(
                                      '${_currencyFormat.format(w.grossAmount)} F',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Commission 10%', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                    Text(
                                      '- ${_currencyFormat.format(w.commission)} F',
                                      style: const TextStyle(fontSize: 13, color: AppColors.brandCoral, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Net à transférer', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                    Text(
                                      '${_currencyFormat.format(w.netAmount)} FCFA',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.success),
                                    ),
                                  ],
                                ),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    if (w.status == 'pending') ...[
                                      ElevatedButton(
                                        onPressed: _isProcessing
                                            ? null
                                            : () => _changeWithdrawalStatus(w, 'approved', 'Approuver le retrait'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.brandBlue,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                        child: const Text('Approuver'),
                                      ),
                                      const SizedBox(width: 8),
                                      OutlinedButton(
                                        onPressed: _isProcessing
                                            ? null
                                            : () => _changeWithdrawalStatus(w, 'rejected', 'Rejeter la demande'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.error,
                                          side: const BorderSide(color: AppColors.error),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        ),
                                        child: const Text('Rejeter'),
                                      ),
                                    ],
                                    if (w.status == 'approved') ...[
                                      ElevatedButton.icon(
                                        onPressed: _isProcessing
                                            ? null
                                            : () => _changeWithdrawalStatus(w, 'processed', 'Confirmer le virement exécuté'),
                                        icon: const Icon(LucideIcons.check, size: 14),
                                        label: const Text('Marquer comme payé'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.success,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                            if (w.rejectionReason != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Motif de refus : ${w.rejectionReason}',
                                style: const TextStyle(fontSize: 11, color: AppColors.error, fontStyle: FontStyle.italic),
                              ),
                            ],
                            if (w.adminNote != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Note admin : ${w.adminNote}',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                              ),
                            ],
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

class _FinanceCard extends StatelessWidget {
  final String title;
  final String amount;
  final IconData icon;
  final Color color;

  const _FinanceCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
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
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  amount,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
