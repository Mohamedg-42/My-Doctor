import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/pharmacie_provider.dart';
import '../../data/models/ordonnance_model.dart';
import '../../data/models/paiement_mobile_model.dart';
import '../../data/models/pharmacie_model.dart';
import '../widgets/mobile_money_selector_widget.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/bictorys_service.dart';

class PaiementPatientScreen extends StatefulWidget {
  final String ordonnanceId;
  const PaiementPatientScreen({super.key, required this.ordonnanceId});

  @override
  State<PaiementPatientScreen> createState() => _PaiementPatientScreenState();
}

class _PaiementPatientScreenState extends State<PaiementPatientScreen>
    with TickerProviderStateMixin {
  OperateurMobileMoney? _operateurSelectionne;
  final _phoneController = TextEditingController();
  late AnimationController _pulseController;
  late AnimationController _successController;
  late Animation<double> _pulseAnim;
  late Animation<double> _successAnim;

  _EtatPaiement _etat = _EtatPaiement.formulaire;
  OrdonnanceModel? _ordonnance;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _successAnim = CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _chargerOrdonnance());
  }

  void _chargerOrdonnance() {
    final provider = context.read<PharmacieProvider>();
    final ord = provider.ordonnances
        .where((o) => o.id == widget.ordonnanceId)
        .firstOrNull;
    setState(() => _ordonnance = ord ?? OrdonnanceDemo.ordonnances.first);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _successController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  double get _montant => _ordonnance?.montantTotal ?? 0;

  String _formatMontant(double m) =>
      '${m.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]} ')} FCFA';

  Future<void> _initierPaiement() async {
    if (_operateurSelectionne == null) {
      _showSnack('Veuillez sélectionner un opérateur Mobile Money', isError: true);
      return;
    }
    if (_phoneController.text.trim().length < 10) {
      _showSnack('Numéro de téléphone invalide (min. 10 chiffres)', isError: true);
      return;
    }
    setState(() => _etat = _EtatPaiement.enCours);
    _pulseController.repeat(reverse: true);

    // Initialisation via la passerelle Bictorys
    String bictorysPaymentType = 'orange_money';
    switch (_operateurSelectionne!) {
      case OperateurMobileMoney.wave:
        bictorysPaymentType = 'wave_money';
        break;
      case OperateurMobileMoney.orangeMoney:
        bictorysPaymentType = 'orange_money';
        break;
      case OperateurMobileMoney.mtnMoney:
        bictorysPaymentType = 'mtn_money';
        break;
      case OperateurMobileMoney.moovMoney:
        bictorysPaymentType = 'moov';
        break;
    }

    final internalRef = 'PHARM-${widget.ordonnanceId}-${DateTime.now().millisecondsSinceEpoch}';

    final result = await BictorysService.instance.initiatePayment(
      amount: _montant,
      paymentReference: internalRef,
      paymentType: bictorysPaymentType,
      customerName: _ordonnance?.patientNom ?? 'Patient Pharmacie',
      customerPhone: _phoneController.text.trim(),
    );

    _pulseController.stop();
    setState(() => _etat = _EtatPaiement.succes);
    _successController.forward();

    if (mounted) {
      final paiement = PaiementMobileModel(
        id: result.displayReference,
        ordonnanceId: widget.ordonnanceId,
        patientId: _ordonnance?.patientId ?? '',
        pharmacieId: _ordonnance?.pharmacieId ?? '',
        montantFCFA: _montant,
        operateur: _operateurSelectionne!,
        numeroTelephone: _phoneController.text.trim(),
        statut: StatutPaiement.confirme,
        createdAt: DateTime.now(),
      );
      context.read<PharmacieProvider>().initierPaiement(paiement);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : PharmacieColors.primary,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Paiement Mobile Money',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: PharmacieColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _etat == _EtatPaiement.formulaire
            ? _buildFormulaire()
            : _etat == _EtatPaiement.enCours
                ? _buildEnCours()
                : _etat == _EtatPaiement.succes
                    ? _buildSucces()
                    : _buildEchec(),
      ),
    );
  }

  Widget _buildFormulaire() {
    return SingleChildScrollView(
      key: const ValueKey('formulaire'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Récapitulatif ordonnance
          _RecapOrdonnanceCard(ordonnance: _ordonnance),
          const SizedBox(height: 20),

          // Montant à payer
          _MontantCard(montant: _montant, formatFn: _formatMontant),
          const SizedBox(height: 20),

          // Sélecteur opérateur
          const Text(
            'Choisir l\'opérateur',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF1A2340),
            ),
          ),
          const SizedBox(height: 12),
          MobileMoneySelectorWidget(
            selected: _operateurSelectionne,
            onSelected: (op) => setState(() => _operateurSelectionne = op),
          ),
          const SizedBox(height: 20),

          // Numéro de téléphone
          const Text(
            'Numéro de téléphone',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF1A2340),
            ),
          ),
          const SizedBox(height: 8),
          _PhoneField(controller: _phoneController),
          const SizedBox(height: 12),

          // Info sécurité opérateur
          if (_operateurSelectionne != null)
            _SecuriteInfo(operateur: _operateurSelectionne!),
          const SizedBox(height: 24),

          // Bouton payer
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _initierPaiement,
              style: ElevatedButton.styleFrom(
                backgroundColor: PharmacieColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 4,
              ),
              icon: const Icon(Icons.payment_rounded),
              label: Text(
                'Payer ${_formatMontant(_montant)}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '🔒 Paiement sécurisé via Kkiapay',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildEnCours() {
    return Center(
      key: const ValueKey('enCours'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _pulseAnim,
            child: Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: PharmacieColors.primaryUltraLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mobile_friendly_rounded,
                size: 60,
                color: PharmacieColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Traitement en cours...',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A2340),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Veuillez confirmer le paiement\nsur votre téléphone',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.grey[600]),
          ),
          const SizedBox(height: 40),
          const CircularProgressIndicator(
            color: PharmacieColors.primary,
            strokeWidth: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildSucces() {
    return Center(
      key: const ValueKey('succes'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _successAnim,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 80,
                  color: Colors.green,
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Paiement confirmé !',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A2340),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Votre ordonnance est en cours\nde préparation à la pharmacie.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              _formatMontant(_montant),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.popUntil(
                  context,
                  ModalRoute.withName('/patient/home'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PharmacieColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.home_rounded),
                label: const Text('Retour à l\'accueil',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEchec() {
    return Center(
      key: const ValueKey('echec'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.red[50],
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cancel_rounded, size: 80, color: Colors.red),
          ),
          const SizedBox(height: 24),
          const Text(
            'Paiement échoué',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A2340),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Le paiement n\'a pas pu être traité.\nVeuillez réessayer.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => setState(() => _etat = _EtatPaiement.formulaire),
            style: ElevatedButton.styleFrom(
              backgroundColor: PharmacieColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

enum _EtatPaiement { formulaire, enCours, succes }

// ── Widgets composants ────────────────────────────────────────────────────────

class _RecapOrdonnanceCard extends StatelessWidget {
  final OrdonnanceModel? ordonnance;
  const _RecapOrdonnanceCard({required this.ordonnance});

  @override
  Widget build(BuildContext context) {
    if (ordonnance == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: PharmacieColors.primaryUltraLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.description_outlined,
                    color: PharmacieColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ordonnance médicale',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(
                      ordonnance!.medecinNom,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Text(
            'Patient : ${ordonnance!.patientNomComplet}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          ...ordonnance!.medicaments.map((m) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    const Icon(Icons.medication_rounded,
                        size: 16, color: PharmacieColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('${m.nom} – ${m.posologie}',
                          style: const TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _MontantCard extends StatelessWidget {
  final double montant;
  final String Function(double) formatFn;
  const _MontantCard({required this.montant, required this.formatFn});

  @override
  Widget build(BuildContext context) {
    final remb = montant * 0.8;
    final net = montant * 0.2;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: PharmacieColors.gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: PharmacieColors.primary.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          const Text('Montant total',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            formatFn(montant),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(color: Colors.white24, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MontantItem(
                  label: 'CMU (80%)',
                  valeur: formatFn(remb),
                  couleur: Colors.greenAccent),
              _MontantItem(
                  label: 'Votre part',
                  valeur: formatFn(net),
                  couleur: Colors.white),
            ],
          ),
        ],
      ),
    );
  }
}

class _MontantItem extends StatelessWidget {
  final String label, valeur;
  final Color couleur;
  const _MontantItem(
      {required this.label, required this.valeur, required this.couleur});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        const SizedBox(height: 2),
        Text(valeur,
            style: TextStyle(
                color: couleur, fontSize: 15, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _PhoneField extends StatelessWidget {
  final TextEditingController controller;
  const _PhoneField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.phone,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        hintText: '+225 07 00 00 00 00',
        prefixIcon: const Icon(Icons.phone_android_rounded,
            color: PharmacieColors.primary),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: PharmacieColors.primary, width: 2),
        ),
      ),
    );
  }
}

class _SecuriteInfo extends StatelessWidget {
  final OperateurMobileMoney operateur;
  const _SecuriteInfo({required this.operateur});

  @override
  Widget build(BuildContext context) {
    const infos = {
      OperateurMobileMoney.orangeMoney:
          'Un code de confirmation vous sera envoyé par SMS Orange Money.',
      OperateurMobileMoney.wave:
          'Ouvrez l\'app Wave et validez la demande de paiement.',
      OperateurMobileMoney.moovMoney:
          'Composez *155# sur votre téléphone Moov pour confirmer.',
      OperateurMobileMoney.mtnMoney:
          'Composez *133# sur votre téléphone MTN pour confirmer.',
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Colors.blue, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              infos[operateur] ?? '',
              style: TextStyle(color: Colors.blue[800], fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
