import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';

class DoctorPaymentScreen extends StatefulWidget {
  const DoctorPaymentScreen({super.key});

  @override
  State<DoctorPaymentScreen> createState() => _DoctorPaymentScreenState();
}

class _DoctorPaymentScreenState extends State<DoctorPaymentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  PaymentMethod? _selectedMethod;
  final _amountCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _ribCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final bool _isWithdrawing = false;

  // Données mock des gains
  final double _totalEarnings = 685000;
  final double _pendingEarnings = 450000;
  final double _withdrawnEarnings = 235000;
  final double _platformFee = 0.05; // 5%

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _amountCtrl.dispose();
    _phoneCtrl.dispose();
    _ribCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  double get _netAmount {
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    return amount * (1 - _platformFee);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Mes Revenus & Paiements'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_rounded),
            onPressed: () => _showPaySlip(context),
            tooltip: 'Bulletin de paie',
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Solde et stats ───────────────────────────────────────────
          _buildEarningsHeader(),
          const SizedBox(height: 4),
          // ─── Onglets ──────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabCtrl,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12),
              tabs: const [
                Tab(text: 'Retrait'),
                Tab(text: 'Historique'),
                Tab(text: 'Stats'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildWithdrawTab(),
                _buildHistoryTab(),
                _buildStatsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Header Gains ─────────────────────────────────────────────────────────
  Widget _buildEarningsHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Solde disponible', style: TextStyle(fontFamily: 'Poppins', color: Colors.white70, fontSize: 13)),
                    Text(
                      '${_pendingEarnings.toStringAsFixed(0)} F CFA',
                      style: const TextStyle(fontFamily: 'Poppins', color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _showPaySlip(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.download_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text('Bulletin', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _EarningChip(label: 'Total gagné', value: '${_totalEarnings.toStringAsFixed(0)} F', color: Colors.white),
              const SizedBox(width: 10),
              _EarningChip(label: 'Retiré', value: '${_withdrawnEarnings.toStringAsFixed(0)} F', color: Colors.white70),
              const SizedBox(width: 10),
              _EarningChip(label: 'Commission', value: '${(_platformFee * 100).toStringAsFixed(0)}%', color: Colors.orangeAccent),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Onglet Retrait ───────────────────────────────────────────────────────
  Widget _buildWithdrawTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Montant à retirer
          Text('Montant à retirer', style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.backgroundGrey),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _amountCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                    decoration: const InputDecoration(
                      hintText: '0',
                      hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 22, color: AppColors.textLight),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const Text('F CFA', style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: AppColors.textSecondary)),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    _amountCtrl.text = _pendingEarnings.toStringAsFixed(0);
                    setState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: AppColors.primaryUltraLight, borderRadius: BorderRadius.circular(8)),
                    child: const Text('Max', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
          if (_amountCtrl.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.success, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Vous recevrez : ${_netAmount.toStringAsFixed(0)} F CFA (après ${(_platformFee * 100).toStringAsFixed(0)}% commission Allo Docteur)',
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.success),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Méthode de retrait
          Text('Mode de virement', style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _buildMethodSelector(),
          const SizedBox(height: 20),

          // Informations bénéficiaire
          if (_selectedMethod != null) ...[
            Text('Informations bénéficiaire', style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _buildBeneficiaryForm(),
            const SizedBox(height: 24),
          ],

          // Bouton retrait
          Consumer<AppProvider>(
            builder: (_, app, __) => SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (app.isProcessingPayment || _selectedMethod == null || _amountCtrl.text.isEmpty) ? null : () => _requestWithdrawal(context, app),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.textLight,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: app.isProcessingPayment
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                          SizedBox(width: 12),
                          Text('Traitement...', style: TextStyle(fontFamily: 'Poppins', color: Colors.white)),
                        ],
                      )
                    : Text(
                        _amountCtrl.text.isEmpty
                            ? 'Demander un retrait'
                            : 'Retirer ${_amountCtrl.text} F CFA',
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodSelector() {
    final methods = [
      const _WithdrawMethodInfo(method: PaymentMethod.wave, name: 'Wave', color: Color(0xFF0099FF), icon: Icons.waves_rounded),
      const _WithdrawMethodInfo(method: PaymentMethod.orangeMoney, name: 'Orange Money', color: Color(0xFFFF6600), icon: Icons.circle_rounded),
      const _WithdrawMethodInfo(method: PaymentMethod.mtnMoney, name: 'MTN Money', color: Color(0xFFFFCC00), icon: Icons.signal_cellular_alt_rounded),
      const _WithdrawMethodInfo(method: PaymentMethod.moovMoney, name: 'Moov Money', color: Color(0xFF00AA44), icon: Icons.trending_up_rounded),
      const _WithdrawMethodInfo(method: PaymentMethod.djamo, name: 'Djamo', color: Color(0xFF6C3FC5), icon: Icons.account_balance_wallet_rounded),
      const _WithdrawMethodInfo(method: PaymentMethod.visa, name: 'Virement bancaire', color: Color(0xFF1A1F71), icon: Icons.account_balance_rounded),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.3,
      ),
      itemCount: methods.length,
      itemBuilder: (_, i) {
        final m = methods[i];
        final isSelected = _selectedMethod == m.method;
        return GestureDetector(
          onTap: () => setState(() => _selectedMethod = m.method),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected ? m.color.withValues(alpha: 0.15) : AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isSelected ? m.color : AppColors.backgroundGrey, width: isSelected ? 2 : 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(m.icon, color: m.color, size: 20),
                const SizedBox(height: 5),
                Text(m.name, style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w600, color: isSelected ? m.color : AppColors.textPrimary), textAlign: TextAlign.center),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBeneficiaryForm() {
    final isCard = _selectedMethod == PaymentMethod.visa;
    return Column(
      children: [
        // Nom bénéficiaire
        _FormField(
          label: 'Nom complet',
          hint: 'Dr. Kouassi Amedée',
          controller: _nameCtrl,
        ),
        const SizedBox(height: 12),
        if (!isCard) ...[
          _FormField(
            label: 'Numéro de téléphone',
            hint: '07 XX XX XX XX',
            controller: _phoneCtrl,
            prefix: '+225',
            inputType: TextInputType.phone,
          ),
        ] else ...[
          _FormField(
            label: 'IBAN / Numéro de compte',
            hint: 'CI00 1234 5678 9012 3456 789',
            controller: _ribCtrl,
          ),
        ],
      ],
    );
  }

  // ─── Onglet Historique ────────────────────────────────────────────────────
  Widget _buildHistoryTab() {
    final mockPayments = [
      _PaymentHistory(date: DateTime.now().subtract(const Duration(days: 2)), amount: 125000, method: 'Wave', status: 'Effectué', reference: 'WV2025040912345'),
      _PaymentHistory(date: DateTime.now().subtract(const Duration(days: 15)), amount: 85000, method: 'Orange Money', status: 'Effectué', reference: 'OM2025032554321'),
      _PaymentHistory(date: DateTime.now().subtract(const Duration(days: 32)), amount: 60000, method: 'MTN Money', status: 'Effectué', reference: 'MTN2025022899876'),
      _PaymentHistory(date: DateTime.now().subtract(const Duration(days: 3)), amount: 45000, method: 'Wave', status: 'En cours', reference: 'WV2025040811111'),
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: mockPayments.length,
      itemBuilder: (_, i) => _PaymentHistoryTile(payment: mockPayments[i]),
    );
  }

  // ─── Onglet Stats ─────────────────────────────────────────────────────────
  Widget _buildStatsTab() {
    final months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun'];
    final values = [85000.0, 120000.0, 95000.0, 145000.0, 110000.0, 130000.0];
    final maxVal = values.reduce((a, b) => a > b ? a : b);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Carte stats rapides
          const Row(
            children: [
              Expanded(child: _StatCard(title: 'Ce mois', value: '130 000 F', icon: Icons.trending_up_rounded, color: AppColors.success)),
              SizedBox(width: 10),
              Expanded(child: _StatCard(title: 'Consultations', value: '42', icon: Icons.people_rounded, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Expanded(child: _StatCard(title: 'Moy/consult.', value: '18 500 F', icon: Icons.bar_chart_rounded, color: AppColors.accentBlue)),
              SizedBox(width: 10),
              Expanded(child: _StatCard(title: 'Note moyenne', value: '4.8 ★', icon: Icons.star_rounded, color: Color(0xFFFFB800))),
            ],
          ),
          const SizedBox(height: 20),

          // Graphique barres
          Text('Revenus mensuels', style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.backgroundCard, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                SizedBox(
                  height: 140,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(months.length, (i) {
                      final height = (values[i] / maxVal) * 120;
                      final isCurrent = i == months.length - 1;
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isCurrent)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(6)),
                              child: Text(
                                '${(values[i] / 1000).toStringAsFixed(0)}k',
                                style: const TextStyle(fontFamily: 'Poppins', fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700),
                              ),
                            ),
                          const SizedBox(height: 4),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 600),
                            width: 32,
                            height: height,
                            decoration: BoxDecoration(
                              color: isCurrent ? AppColors.primary : AppColors.primaryUltraLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(months[i], style: AppTextStyles.caption.copyWith(color: isCurrent ? AppColors.primary : AppColors.textLight)),
                        ],
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Répartition modes paiement
          Text('Modes de paiement reçus', style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...[
            ('Wave', 0.42, const Color(0xFF0099FF)),
            ('Orange Money', 0.28, const Color(0xFFFF6600)),
            ('MTN Money', 0.18, const Color(0xFFFFCC00)),
            ('Djamo / Visa', 0.12, const Color(0xFF6C3FC5)),
          ].map((item) => _PaymentMethodBar(label: item.$1, percent: item.$2, color: item.$3)),
        ],
      ),
    );
  }

  Future<void> _requestWithdrawal(BuildContext context, AppProvider app) async {
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    if (amount <= 0 || amount > _pendingEarnings) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(amount > _pendingEarnings ? 'Solde insuffisant' : 'Montant invalide'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final status = await app.requestDoctorWithdrawal(
      doctorId: auth.currentUser?.id ?? 'doc_001',
      amount: amount,
      method: _selectedMethod!,
      accountNumber: _phoneCtrl.text.isNotEmpty ? _phoneCtrl.text : _ribCtrl.text,
      accountName: _nameCtrl.text.isNotEmpty ? _nameCtrl.text : auth.userName,
    );

    if (!mounted) return;

    if (status == PaymentStatus.success) {
      _showWithdrawSuccessDialog(amount);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Échec du retrait. Veuillez réessayer.'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
      );
    }
  }

  void _showWithdrawSuccessDialog(double amount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 20),
            const Text('Retrait initié !', style: TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              '${amount.toStringAsFixed(0)} F CFA en cours de transfert\nDélai : 24-48h ouvrées',
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Poppins', color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => _showPaySlip(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.primaryUltraLight, borderRadius: BorderRadius.circular(12)),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 18),
                    SizedBox(width: 8),
                    Text('Voir le bulletin récapitulatif', style: TextStyle(fontFamily: 'Poppins', color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _amountCtrl.clear();
                  _phoneCtrl.clear();
                  setState(() => _selectedMethod = null);
                },
                child: const Text('Terminé', style: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaySlip(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final now = DateTime.now();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            controller: controller,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.backgroundGrey, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),

                // En-tête bulletin
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.local_hospital_rounded, color: Colors.white, size: 28),
                          SizedBox(width: 10),
                          Text('Allo Docteur', style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: Colors.white24),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('BULLETIN DE PAIE', style: TextStyle(fontFamily: 'Poppins', color: Colors.white70, fontSize: 11, letterSpacing: 1.5)),
                              Text(auth.userName, style: const TextStyle(fontFamily: 'Poppins', color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${_getMonthName(now.month)} ${now.year}', style: const TextStyle(fontFamily: 'Poppins', color: Colors.white70, fontSize: 11)),
                              Text('Réf: ML${now.millisecondsSinceEpoch.toString().substring(7)}', style: const TextStyle(fontFamily: 'Poppins', color: Colors.white60, fontSize: 10)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Détails
                const _PaySlipSection(title: 'Activité du mois'),
                const _PaySlipRow(label: 'Consultations réalisées', value: '42'),
                const _PaySlipRow(label: 'Téléconsultations', value: '15'),
                const _PaySlipRow(label: 'Note moyenne', value: '4.8 / 5.0'),
                const SizedBox(height: 16),

                const _PaySlipSection(title: 'Revenus bruts'),
                const _PaySlipRow(label: 'Consultations présentiel', value: '520 000 F CFA'),
                const _PaySlipRow(label: 'Téléconsultations', value: '165 000 F CFA'),
                const _PaySlipRow(label: 'Total brut', value: '685 000 F CFA', isBold: true),
                const SizedBox(height: 16),

                const _PaySlipSection(title: 'Déductions'),
                const _PaySlipRow(label: 'Commission Allo Docteur (5%)', value: '-34 250 F CFA', isDeduction: true),
                const _PaySlipRow(label: 'Frais de transfert', value: '-500 F CFA', isDeduction: true),
                const SizedBox(height: 16),

                // Total net
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('NET À PAYER', style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      Text('650 250 F CFA', style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.success)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Historique retraits
                const _PaySlipSection(title: 'Retraits du mois'),
                const _PaySlipRow(label: 'Wave - 04/04/2025', value: '125 000 F'),
                const _PaySlipRow(label: 'Orange Money - 20/03', value: '85 000 F'),
                const _PaySlipRow(label: 'Total retiré', value: '210 000 F CFA', isBold: true),
                const SizedBox(height: 20),

                // Note bas de page
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.backgroundLight, borderRadius: BorderRadius.circular(12)),
                  child: const Text(
                    'Ce bulletin est généré automatiquement par Allo Docteur. Pour toute réclamation, contactez support@medilink.ci',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Bulletin envoyé par email'),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.email_rounded, size: 18),
                    label: const Text('Envoyer par email', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'];
    return months[month - 1];
  }
}

// ─── Widgets utilitaires ──────────────────────────────────────────────────────

class _EarningChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _EarningChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: Colors.white.withValues(alpha: 0.7))),
          ],
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final String? prefix;
  final TextInputType inputType;
  const _FormField({required this.label, required this.hint, required this.controller, this.prefix, this.inputType = TextInputType.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(color: AppColors.backgroundCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.backgroundGrey)),
          child: Row(
            children: [
              if (prefix != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: const BoxDecoration(color: AppColors.primaryUltraLight, borderRadius: BorderRadius.horizontal(left: Radius.circular(11))),
                  child: Text(prefix!, style: const TextStyle(fontFamily: 'Poppins', color: AppColors.primary, fontWeight: FontWeight.w700)),
                ),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: inputType,
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(fontFamily: 'Poppins', color: AppColors.textLight),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WithdrawMethodInfo {
  final PaymentMethod method;
  final String name;
  final Color color;
  final IconData icon;
  const _WithdrawMethodInfo({required this.method, required this.name, required this.color, required this.icon});
}

class _PaymentHistory {
  final DateTime date;
  final double amount;
  final String method;
  final String status;
  final String reference;
  const _PaymentHistory({required this.date, required this.amount, required this.method, required this.status, required this.reference});
}

class _PaymentHistoryTile extends StatelessWidget {
  final _PaymentHistory payment;
  const _PaymentHistoryTile({required this.payment});

  @override
  Widget build(BuildContext context) {
    final isSuccess = payment.status == 'Effectué';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSuccess ? AppColors.success.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.account_balance_wallet_rounded, color: isSuccess ? AppColors.success : AppColors.warning, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(payment.method, style: AppTextStyles.subtitle2.copyWith(fontWeight: FontWeight.w700)),
                Text('Réf: ${payment.reference}', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                Text('${payment.date.day}/${payment.date.month}/${payment.date.year}', style: AppTextStyles.caption.copyWith(color: AppColors.textLight)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${payment.amount.toStringAsFixed(0)} F', style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isSuccess ? AppColors.success.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(payment.status, style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: isSuccess ? AppColors.success : AppColors.warning, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontFamily: 'Poppins', fontSize: 17, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _PaymentMethodBar extends StatelessWidget {
  final String label;
  final double percent;
  final Color color;
  const _PaymentMethodBar({required this.label, required this.percent, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: percent,
                backgroundColor: color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 10,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('${(percent * 100).toStringAsFixed(0)}%', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _PaySlipSection extends StatelessWidget {
  final String title;
  const _PaySlipSection({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(width: 4, height: 16, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(title, style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _PaySlipRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final bool isDeduction;
  const _PaySlipRow({required this.label, required this.value, this.isBold = false, this.isDeduction = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textSecondary, fontWeight: isBold ? FontWeight.w700 : FontWeight.normal))),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: isDeduction ? AppColors.error : (isBold ? AppColors.textPrimary : AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
