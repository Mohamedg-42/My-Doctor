import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/bictorys_service.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentScreen extends StatefulWidget {
  final double amount;
  final String description;
  final String? doctorId;
  final String? appointmentId;
  final PaymentType paymentType;
  final VoidCallback? onSuccess;

  const PaymentScreen({
    super.key,
    required this.amount,
    required this.description,
    this.doctorId,
    this.appointmentId,
    this.paymentType = PaymentType.appointment,
    this.onSuccess,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with SingleTickerProviderStateMixin {
  PaymentMethod? _selectedMethod;
  final _phoneCtrl = TextEditingController();
  final _cardCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  final _cardNameCtrl = TextEditingController();
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _cardCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    _cardNameCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  BictorysPaymentResult? _lastBictorysResult;

  Future<void> _pay() async {
    if (_selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un mode de paiement'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final isCard = _selectedMethod == PaymentMethod.visa ||
        _selectedMethod == PaymentMethod.mastercard;

    if (!isCard && _phoneCtrl.text.trim().length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer un numéro de téléphone valide'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (isCard && _cardCtrl.text.trim().length < 16) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Numéro de carte invalide'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Récupération des informations du patient
    final user = context.read<AuthProvider>().currentUser;
    final customerName = user?.fullName ?? 'Patient My-Doctor';
    final customerEmail = user?.email ?? 'patient@mydoctor.ci';
    final customerPhone = !isCard ? _phoneCtrl.text.trim() : (user?.phone ?? '0700000000');

    final bictorysMethod = BictorysService.instance.mapMethodToBictorys(_selectedMethod!);
    final internalRef = 'MD-${DateTime.now().millisecondsSinceEpoch}';

    // Appel passerelle Bictorys
    final bictorysResult = await BictorysService.instance.initiatePayment(
      amount: widget.amount,
      paymentReference: internalRef,
      paymentType: bictorysMethod,
      customerName: customerName,
      customerPhone: customerPhone,
      customerEmail: customerEmail,
    );

    _lastBictorysResult = bictorysResult;

    final status = await context.read<AppProvider>().processPayment(
          amount: widget.amount,
          method: _selectedMethod!,
          type: widget.paymentType,
          description: widget.description,
          phoneNumber: !isCard ? customerPhone : null,
          cardNumber: isCard ? _cardCtrl.text.trim() : null,
          appointmentId: widget.appointmentId,
          doctorId: widget.doctorId,
          customReference: bictorysResult.displayReference,
        );

    if (!mounted) return;

    if (status == PaymentStatus.success) {
      _showSuccessDialog(bictorysResult);
    } else {
      _showFailDialog(bictorysResult.message);
    }
  }

  void _showSuccessDialog([BictorysPaymentResult? bictorys]) {
    final ref = bictorys?.displayReference ??
        '${_selectedMethod!.name.toUpperCase()}${DateTime.now().millisecondsSinceEpoch}';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 40),
            ),
            const SizedBox(height: 20),
            const Text(
              'Paiement réussi !',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.amount.toStringAsFixed(0)} F CFA\n${widget.description}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            // Badge Bictorys
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF6C3CE1).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shield_outlined, color: Color(0xFF6C3CE1), size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Passerelle Bictorys (Sandbox)',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6C3CE1),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Réf : $ref',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (bictorys?.transactionId != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'ID Transaction : ${bictorys!.transactionId}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (bictorys?.paymentLink != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(bictorys!.paymentLink!);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 14),
                label: const Text(
                  'Voir le reçu Bictorys',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF6C3CE1),
                  side: const BorderSide(color: Color(0xFF6C3CE1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  Navigator.pop(_);
                  Navigator.pop(context);
                  widget.onSuccess?.call();
                },
                child: const Text('Terminé',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }

  void _showFailDialog([String? customError]) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  color: AppColors.error, size: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              'Paiement non complété',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              customError ?? 'Solde insuffisant ou erreur de connexion Bictorys. Veuillez réessayer.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Poppins', color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(_),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Annuler',
                        style: TextStyle(fontFamily: 'Poppins')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(_);
                      _pay();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Réessayer',
                        style: TextStyle(
                            fontFamily: 'Poppins', color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Paiement sécurisé'),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF6C3CE1).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF6C3CE1).withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_rounded, color: Color(0xFF6C3CE1), size: 14),
                SizedBox(width: 4),
                Text('Bictorys',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Color(0xFF6C3CE1),
                      fontWeight: FontWeight.w700,
                    )),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Résumé paiement
            _PaymentSummaryCard(
              amount: widget.amount,
              description: widget.description,
            ),
            const SizedBox(height: 24),

            // Onglets Mobile / Carte
            Container(
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
                labelStyle: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
                tabs: const [
                  Tab(icon: Icon(Icons.phone_android_rounded, size: 18), text: 'Mobile Money'),
                  Tab(icon: Icon(Icons.credit_card_rounded, size: 18), text: 'Carte bancaire'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              height: 420,
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _MobileMoneyTab(
                    selectedMethod: _selectedMethod,
                    phoneCtrl: _phoneCtrl,
                    onMethodSelected: (m) => setState(() {
                      _selectedMethod = m;
                      _tabCtrl.animateTo(0);
                    }),
                  ),
                  _CardPaymentTab(
                    selectedMethod: _selectedMethod,
                    cardCtrl: _cardCtrl,
                    expiryCtrl: _expiryCtrl,
                    cvvCtrl: _cvvCtrl,
                    cardNameCtrl: _cardNameCtrl,
                    onMethodSelected: (m) => setState(() => _selectedMethod = m),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Bouton payer
            Consumer<AppProvider>(
              builder: (_, app, __) => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: app.isProcessingPayment ? null : _pay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.textLight,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                  child: app.isProcessingPayment
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text('Traitement en cours...',
                                style: TextStyle(
                                    fontFamily: 'Poppins', color: Colors.white)),
                          ],
                        )
                      : Text(
                          'Payer ${widget.amount.toStringAsFixed(0)} F CFA',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Note sécurité Bictorys
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF6C3CE1).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF6C3CE1).withValues(alpha: 0.15)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_rounded,
                      color: Color(0xFF6C3CE1), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Paiements sécurisés par Bictorys via TLS 1.3 & 3D Secure. Support Wave, Orange Money, MTN MoMo, Moov et Cartes bancaires.',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: Color(0xFF6C3CE1),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Résumé du paiement ───────────────────────────────────────────────────────

class _PaymentSummaryCard extends StatelessWidget {
  final double amount;
  final String description;

  const _PaymentSummaryCard({required this.amount, required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.receipt_long_rounded,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Montant à payer',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '${amount.toStringAsFixed(0)} F CFA',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white70,
                    fontSize: 12,
                  ),
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

// ─── Tab Mobile Money ─────────────────────────────────────────────────────────

class _MobileMoneyTab extends StatelessWidget {
  final PaymentMethod? selectedMethod;
  final TextEditingController phoneCtrl;
  final void Function(PaymentMethod) onMethodSelected;

  const _MobileMoneyTab({
    required this.selectedMethod,
    required this.phoneCtrl,
    required this.onMethodSelected,
  });

  static const _mobileMethods = [
    _MobileMethodInfo(
      method: PaymentMethod.wave,
      name: 'Wave',
      color: Color(0xFF0099FF),
      prefix: '+225 07',
      icon: Icons.waves_rounded,
    ),
    _MobileMethodInfo(
      method: PaymentMethod.orangeMoney,
      name: 'Orange Money',
      color: Color(0xFFFF6600),
      prefix: '+225 07',
      icon: Icons.circle_rounded,
    ),
    _MobileMethodInfo(
      method: PaymentMethod.mtnMoney,
      name: 'MTN Money',
      color: Color(0xFFFFCC00),
      prefix: '+225 05',
      icon: Icons.signal_cellular_alt_rounded,
    ),
    _MobileMethodInfo(
      method: PaymentMethod.moovMoney,
      name: 'Moov Money',
      color: Color(0xFF00AA44),
      prefix: '+225 01',
      icon: Icons.trending_up_rounded,
    ),
    _MobileMethodInfo(
      method: PaymentMethod.djamo,
      name: 'Djamo',
      color: Color(0xFF6C3FC5),
      prefix: '+225 07',
      icon: Icons.account_balance_wallet_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Choisir le réseau',
              style: AppTextStyles.subtitle2
                  .copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          // Grille des méthodes
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.4,
            ),
            itemCount: _mobileMethods.length,
            itemBuilder: (_, i) {
              final m = _mobileMethods[i];
              final isSelected = selectedMethod == m.method;
              return GestureDetector(
                onTap: () => onMethodSelected(m.method),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? m.color.withValues(alpha: 0.15)
                        : AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? m.color
                          : AppColors.backgroundGrey,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: m.color.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(m.icon, color: m.color, size: 22),
                      const SizedBox(height: 4),
                      Text(
                        m.name,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? m.color : AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          if (selectedMethod != null &&
              selectedMethod != PaymentMethod.visa &&
              selectedMethod != PaymentMethod.mastercard) ...[
            const SizedBox(height: 20),
            Text('Numéro de téléphone',
                style: AppTextStyles.subtitle2
                    .copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.backgroundGrey),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryUltraLight,
                      borderRadius: BorderRadius.horizontal(
                          left: Radius.circular(13)),
                    ),
                    child: const Text('+225',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                  ),
                  Expanded(
                    child: TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      style: const TextStyle(
                          fontFamily: 'Poppins', fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: '07 12 34 56 78',
                        hintStyle: TextStyle(
                            fontFamily: 'Poppins',
                            color: AppColors.textLight),
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vous recevrez une demande de confirmation sur votre téléphone.',
              style:
                  AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

class _MobileMethodInfo {
  final PaymentMethod method;
  final String name;
  final Color color;
  final String prefix;
  final IconData icon;

  const _MobileMethodInfo({
    required this.method,
    required this.name,
    required this.color,
    required this.prefix,
    required this.icon,
  });
}

// ─── Tab Carte bancaire ───────────────────────────────────────────────────────

class _CardPaymentTab extends StatelessWidget {
  final PaymentMethod? selectedMethod;
  final TextEditingController cardCtrl;
  final TextEditingController expiryCtrl;
  final TextEditingController cvvCtrl;
  final TextEditingController cardNameCtrl;
  final void Function(PaymentMethod) onMethodSelected;

  const _CardPaymentTab({
    required this.selectedMethod,
    required this.cardCtrl,
    required this.expiryCtrl,
    required this.cvvCtrl,
    required this.cardNameCtrl,
    required this.onMethodSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _CardTypeBtn(
                label: 'Visa',
                icon: Icons.credit_card_rounded,
                color: const Color(0xFF1A1F71),
                isSelected: selectedMethod == PaymentMethod.visa,
                onTap: () => onMethodSelected(PaymentMethod.visa),
              ),
              const SizedBox(width: 10),
              _CardTypeBtn(
                label: 'Mastercard',
                icon: Icons.credit_card_rounded,
                color: const Color(0xFFEB001B),
                isSelected: selectedMethod == PaymentMethod.mastercard,
                onTap: () => onMethodSelected(PaymentMethod.mastercard),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildCardPreview(),
          const SizedBox(height: 20),
          _CardField(
            label: 'Nom sur la carte',
            hint: 'ADJOUA MARIE',
            controller: cardNameCtrl,
            inputType: TextInputType.name,
            formatter: FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z ]')),
          ),
          const SizedBox(height: 12),
          _CardField(
            label: 'Numéro de carte',
            hint: '1234 5678 9012 3456',
            controller: cardCtrl,
            inputType: TextInputType.number,
            formatter: FilteringTextInputFormatter.digitsOnly,
            maxLength: 19,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _CardField(
                  label: 'Expiration',
                  hint: 'MM/AA',
                  controller: expiryCtrl,
                  inputType: TextInputType.number,
                  formatter: FilteringTextInputFormatter.digitsOnly,
                  maxLength: 5,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CardField(
                  label: 'CVV',
                  hint: '123',
                  controller: cvvCtrl,
                  inputType: TextInputType.number,
                  formatter: FilteringTextInputFormatter.digitsOnly,
                  maxLength: 3,
                  obscure: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardPreview() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 175),
      height: 175,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: selectedMethod == PaymentMethod.mastercard
              ? [const Color(0xFFEB001B), const Color(0xFFF79E1B)]
              : [const Color(0xFF1A1F71), const Color(0xFF4A56B5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Allo Docteur Pay',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white70,
                      fontSize: 12)),
              Icon(Icons.credit_card_rounded,
                  color: Colors.white60, size: 28),
            ],
          ),
          const Spacer(),
          Text(
            cardCtrl.text.isEmpty
                ? '•••• •••• •••• ••••'
                : cardCtrl.text,
            style: const TextStyle(
              fontFamily: 'Poppins',
              color: Colors.white,
              fontSize: 16,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                cardNameCtrl.text.isEmpty ? 'NOM PRÉNOM' : cardNameCtrl.text.toUpperCase(),
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
              Text(
                expiryCtrl.text.isEmpty ? 'MM/AA' : expiryCtrl.text,
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white70,
                    fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardTypeBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _CardTypeBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.1) : AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : AppColors.backgroundGrey,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isSelected ? color : AppColors.textPrimary,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType inputType;
  final TextInputFormatter formatter;
  final int? maxLength;
  final bool obscure;

  const _CardField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.inputType,
    required this.formatter,
    this.maxLength,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: inputType,
          obscureText: obscure,
          inputFormatters: [
            formatter,
            if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
          ],
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
                fontFamily: 'Poppins', color: AppColors.textLight, fontSize: 13),
            filled: true,
            fillColor: AppColors.backgroundCard,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.backgroundGrey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.backgroundGrey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}
