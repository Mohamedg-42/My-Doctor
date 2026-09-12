import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pharmacie_provider.dart';
import '../../data/models/ordonnance_model.dart';
import '../../data/models/pharmacie_model.dart';
import '../widgets/statut_badge_widget.dart';
import 'paiement_patient_screen.dart';

class DetailOrdonnanceScreen extends StatefulWidget {
  final String ordonnanceId;
  const DetailOrdonnanceScreen({super.key, required this.ordonnanceId});

  @override
  State<DetailOrdonnanceScreen> createState() => _DetailOrdonnanceScreenState();
}

class _DetailOrdonnanceScreenState extends State<DetailOrdonnanceScreen> {
  final _montantCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _montantCtrl.dispose();
    super.dispose();
  }

  // ── Valider l'ordonnance ────────────────────────────────────────────────────
  Future<void> _valider(BuildContext ctx, OrdonnanceModel ord) async {
    if (!_formKey.currentState!.validate()) return;
    final montant = double.tryParse(_montantCtrl.text.replaceAll(' ', ''));
    if (montant == null) return;

    final provider = ctx.read<PharmacieProvider>();
    final ok = await provider.validerOrdonnance(ord.id, montant);
    if (ok && ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: const Row(children: [
          Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Text('Ordonnance validée — Notification envoyée au patient'),
        ]),
        backgroundColor: PharmacieColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  // ── Refuser l'ordonnance ────────────────────────────────────────────────────
  void _refuser(BuildContext ctx, OrdonnanceModel ord) {
    final motifs = [
      'Médicaments en rupture de stock',
      'Ordonnance illisible ou incomplète',
      'Ordonnance expirée',
      'Posologie incorrecte / dangereuse',
      'Contre-indication détectée',
      'Autre motif',
    ];
    String? motifSelectionne;

    showDialog(
      context: ctx,
      builder: (_) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(children: [
            Icon(Icons.cancel_outlined, color: Color(0xFFE74C3C), size: 22),
            SizedBox(width: 8),
            Text('Refuser l\'ordonnance',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 16,
                    fontWeight: FontWeight.w700, color: Color(0xFF1A2340))),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Sélectionnez le motif de refus :',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 12,
                      color: Color(0xFF7A8BA0))),
              const SizedBox(height: 12),
              ...motifs.map((m) => GestureDetector(
                onTap: () => setDialogState(() => motifSelectionne = m),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: motifSelectionne == m
                        ? const Color(0xFFFFEBEE)
                        : const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: motifSelectionne == m
                          ? const Color(0xFFE74C3C)
                          : Colors.grey.shade200,
                      width: motifSelectionne == m ? 1.5 : 1,
                    ),
                  ),
                  child: Row(children: [
                    Icon(
                      motifSelectionne == m
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 16,
                      color: motifSelectionne == m
                          ? const Color(0xFFE74C3C)
                          : Colors.grey.shade400,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(m,
                          style: TextStyle(
                            fontFamily: 'Poppins', fontSize: 12,
                            fontWeight: motifSelectionne == m
                                ? FontWeight.w700 : FontWeight.normal,
                            color: motifSelectionne == m
                                ? const Color(0xFFE74C3C)
                                : const Color(0xFF1A2340),
                          )),
                    ),
                  ]),
                ),
              )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Annuler',
                  style: TextStyle(fontFamily: 'Poppins', color: Color(0xFF7A8BA0))),
            ),
            ElevatedButton(
              onPressed: motifSelectionne == null
                  ? null
                  : () async {
                      Navigator.pop(dialogCtx);
                      final provider = ctx.read<PharmacieProvider>();
                      await provider.refuserOrdonnance(ord.id, motifSelectionne!);
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                          content: Text('Ordonnance refusée : $motifSelectionne'),
                          backgroundColor: const Color(0xFFE74C3C),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ));
                        Navigator.pop(ctx);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE74C3C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Confirmer le refus',
                  style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PharmacieProvider>();
    final ord = provider.getOrdonnanceById(widget.ordonnanceId);

    if (ord == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ordonnance')),
        body: const Center(child: Text('Ordonnance introuvable')),
      );
    }

    // Pré-remplir le montant si calculé
    if (_montantCtrl.text.isEmpty && ord.montantTotal != null) {
      _montantCtrl.text = ord.montantTotal!.toInt().toString();
    } else if (_montantCtrl.text.isEmpty && ord.medicaments.isNotEmpty) {
      final total = ord.medicaments
          .where((m) => m.prixUnitaire != null)
          .fold(0.0, (sum, m) => sum + (m.prixUnitaire! * m.dureeJours));
      if (total > 0) _montantCtrl.text = total.toInt().toString();
    }

    final peutValider = ord.statut == StatutOrdonnance.enAttente;
    final peutPayer = ord.statut == StatutOrdonnance.validee && ord.montantTotal != null;
    final peutMarquerPrete = ord.statut == StatutOrdonnance.payee;
    final peutLivrer = ord.statut == StatutOrdonnance.prete;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F1),
      body: SafeArea(
        child: Column(
          children: [
            // ── AppBar ───────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              decoration: const BoxDecoration(
                gradient: PharmacieColors.gradient,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Détail Ordonnance',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 16,
                            fontWeight: FontWeight.w700, color: Colors.white)),
                    Text('#${ord.id}',
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 10,
                            color: Colors.white70)),
                  ],
                )),
                StatutBadgeWidget(statut: ord.statut),
              ]),
            ),

            // ── Contenu ──────────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(children: [
                    // Patient
                    _Section(
                      title: 'Patient',
                      icon: Icons.person_rounded,
                      child: Column(children: [
                        _Row('Nom complet', ord.patientNomComplet,
                            icon: Icons.badge_rounded),
                        if (ord.patientTelephone != null)
                          _Row('Téléphone', ord.patientTelephone!,
                              icon: Icons.phone_rounded),
                        if (ord.patientCmuNumber != null)
                          _Row('N° CMU-CI', ord.patientCmuNumber!,
                              icon: Icons.verified_rounded,
                              valueColor: const Color(0xFF185FA5)),
                        _Row('CMU Remboursable',
                            ord.remboursableCmu
                                ? 'Oui (${ord.tauxRemboursement?.toInt() ?? 0}%)'
                                : 'Non',
                            icon: Icons.health_and_safety_rounded,
                            valueColor: ord.remboursableCmu
                                ? PharmacieColors.primary
                                : const Color(0xFF7A8BA0)),
                      ]),
                    ),
                    const SizedBox(height: 12),

                    // Médecin
                    _Section(
                      title: 'Médecin prescripteur',
                      icon: Icons.local_hospital_rounded,
                      child: Column(children: [
                        _Row('Médecin', ord.medecinNom, icon: Icons.person_outline_rounded),
                        _Row('Spécialité', ord.medecinSpecialite,
                            icon: Icons.medical_services_outlined),
                        _Row('Date prescription',
                            _formatDate(ord.dateEmission), icon: Icons.calendar_today_rounded),
                        _Row('Date expiration',
                            _formatDate(ord.dateExpiration), icon: Icons.event_rounded,
                            valueColor: ord.estExpiree
                                ? const Color(0xFFE74C3C) : null),
                      ]),
                    ),
                    const SizedBox(height: 12),

                    // Médicaments
                    _Section(
                      title: '${ord.nombreMedicaments} Médicament${ord.nombreMedicaments > 1 ? 's' : ''} prescrits',
                      icon: Icons.medication_rounded,
                      child: Column(
                        children: ord.medicaments.asMap().entries.map((e) =>
                          _MedicamentCard(medicament: e.value, numero: e.key + 1)
                        ).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Instructions
                    if (ord.instructionsGenerales.isNotEmpty)
                      _Section(
                        title: 'Instructions générales',
                        icon: Icons.info_outline_rounded,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F8F1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(ord.instructionsGenerales,
                              style: const TextStyle(fontFamily: 'Poppins',
                                  fontSize: 12, color: Color(0xFF1A2340), height: 1.6)),
                        ),
                      ),
                    if (ord.instructionsGenerales.isNotEmpty) const SizedBox(height: 12),

                    // Montant & validation
                    if (peutValider)
                      _Section(
                        title: 'Validation & Tarification',
                        icon: Icons.calculate_rounded,
                        child: Column(children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF8E7),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: const Color(0xFFF39C12).withValues(alpha: 0.4)),
                            ),
                            child: const Row(children: [
                              Icon(Icons.info_rounded, color: Color(0xFFF39C12), size: 16),
                              SizedBox(width: 8),
                              Expanded(child: Text(
                                'Calculez le montant total des médicaments et validez pour notifier le patient.',
                                style: TextStyle(fontFamily: 'Poppins', fontSize: 11,
                                    color: Color(0xFFF39C12), height: 1.4),
                              )),
                            ]),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _montantCtrl,
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Saisir le montant';
                              final m = double.tryParse(v.replaceAll(' ', ''));
                              if (m == null || m <= 0) return 'Montant invalide';
                              return null;
                            },
                            style: const TextStyle(fontFamily: 'Poppins',
                                fontSize: 22, fontWeight: FontWeight.w800,
                                color: PharmacieColors.primary),
                            decoration: InputDecoration(
                              labelText: 'Montant total (FCFA)',
                              labelStyle: const TextStyle(fontFamily: 'Poppins',
                                  fontSize: 12, color: Color(0xFF7A8BA0)),
                              suffixText: 'FCFA',
                              suffixStyle: const TextStyle(fontFamily: 'Poppins',
                                  fontSize: 14, fontWeight: FontWeight.w600,
                                  color: Color(0xFF7A8BA0)),
                              prefixIcon: const Icon(Icons.payments_rounded,
                                  color: PharmacieColors.primary, size: 22),
                              filled: true,
                              fillColor: PharmacieColors.primaryUltraLight,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                    color: PharmacieColors.primary, width: 1.5),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                    color: PharmacieColors.primary.withValues(alpha: 0.4)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                    color: PharmacieColors.primary, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                            ),
                          ),
                          if (ord.remboursableCmu && ord.tauxRemboursement != null) ...[
                            const SizedBox(height: 8),
                            _CmuCalculator(
                              montantCtrl: _montantCtrl,
                              taux: ord.tauxRemboursement!,
                            ),
                          ],
                        ]),
                      ),

                    // Montant affiché si validé
                    if (!peutValider && ord.montantTotal != null) ...[
                      _Section(
                        title: 'Montant validé',
                        icon: Icons.payments_rounded,
                        child: Row(children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                            Text('${ord.montantTotal!.toInt()} FCFA',
                                style: const TextStyle(fontFamily: 'Poppins', fontSize: 28,
                                    fontWeight: FontWeight.w900, color: PharmacieColors.primary)),
                            if (ord.remboursableCmu && ord.tauxRemboursement != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'CMU rembourse ${ord.tauxRemboursement!.toInt()}% = ${(ord.montantTotal! * ord.tauxRemboursement! / 100).toInt()} FCFA',
                                style: const TextStyle(fontFamily: 'Poppins', fontSize: 11,
                                    color: Color(0xFF185FA5)),
                              ),
                              Text(
                                'Patient paie : ${(ord.montantTotal! * (1 - ord.tauxRemboursement! / 100)).toInt()} FCFA',
                                style: const TextStyle(fontFamily: 'Poppins', fontSize: 11,
                                    fontWeight: FontWeight.w700, color: PharmacieColors.primary),
                              ),
                            ],
                          ])),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: PharmacieColors.primaryUltraLight,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.check_circle_rounded,
                                color: PharmacieColors.primary, size: 32),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 12),
                    ],

                    const SizedBox(height: 80), // Espace pour les boutons
                  ]),
                ),
              ),
            ),

            // ── Boutons d'action ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16, offset: const Offset(0, -4),
                )],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Bouton principal
                  if (peutValider) ...[
                    Row(children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _refuser(context, ord),
                          icon: const Icon(Icons.cancel_outlined,
                              color: Color(0xFFE74C3C), size: 18),
                          label: const Text('Refuser',
                              style: TextStyle(fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFE74C3C))),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE74C3C)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: provider.isLoading
                              ? null : () => _valider(context, ord),
                          icon: provider.isLoading
                              ? const SizedBox(width: 18, height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.check_circle_rounded, size: 18),
                          label: const Text('Valider la commande',
                              style: TextStyle(fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w700, fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PharmacieColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    // Chat
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Chat avec le patient en cours...'),
                              behavior: SnackBarBehavior.floating)),
                        icon: const Icon(Icons.chat_rounded, size: 16),
                        label: const Text('Contacter le patient',
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: PharmacieColors.primary,
                          side: BorderSide(color: PharmacieColors.primary.withValues(alpha: 0.4)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],

                  if (peutPayer)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => PaiementPatientScreen(ordonnanceId: ord.id),
                        )),
                        icon: const Icon(Icons.payment_rounded, size: 18),
                        label: Text('Payer ${ord.montantTotal!.toInt()} FCFA via Mobile Money',
                            style: const TextStyle(fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700, fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B96F3),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                      ),
                    ),

                  if (peutMarquerPrete)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await provider.marquerPrete(ord.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: const Row(children: [
                                Icon(Icons.medication_rounded, color: Colors.white, size: 16),
                                SizedBox(width: 8),
                                Text('Commande marquée prête — Patient notifié'),
                              ]),
                              backgroundColor: PharmacieColors.primary,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ));
                          }
                        },
                        icon: const Icon(Icons.medication_rounded, size: 18),
                        label: const Text('Marquer comme prête à récupérer',
                            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PharmacieColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                      ),
                    ),

                  if (peutLivrer)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await provider.marquerLivree(ord.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text('✅ Médicaments remis au patient'),
                              backgroundColor: Color(0xFF607D8B),
                              behavior: SnackBarBehavior.floating,
                            ));
                            Navigator.pop(context);
                          }
                        },
                        icon: const Icon(Icons.done_all_rounded, size: 18),
                        label: const Text('Confirmer la remise des médicaments',
                            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF607D8B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                      ),
                    ),

                  if (ord.statut == StatutOrdonnance.refusee && ord.motifRefus != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE74C3C).withValues(alpha: 0.3)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.cancel_outlined, color: Color(0xFFE74C3C), size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Motif de refus : ${ord.motifRefus}',
                            style: const TextStyle(fontFamily: 'Poppins', fontSize: 12,
                                color: Color(0xFFE74C3C)))),
                      ]),
                    ),
                  ],

                  if (ord.statut == StatutOrdonnance.livree) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F8F1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.done_all_rounded, color: Color(0xFF607D8B), size: 18),
                        SizedBox(width: 8),
                        Text('Médicaments remis au patient',
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 12,
                                color: Color(0xFF607D8B), fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

// ─── Calculateur CMU ──────────────────────────────────────────────────────────
class _CmuCalculator extends StatefulWidget {
  final TextEditingController montantCtrl;
  final double taux;
  const _CmuCalculator({required this.montantCtrl, required this.taux});
  @override
  State<_CmuCalculator> createState() => _CmuCalculatorState();
}
class _CmuCalculatorState extends State<_CmuCalculator> {
  @override
  void initState() {
    super.initState();
    widget.montantCtrl.addListener(() => setState(() {}));
  }
  @override
  Widget build(BuildContext context) {
    final montant = double.tryParse(widget.montantCtrl.text.replaceAll(' ', '')) ?? 0;
    final rembourse = montant * widget.taux / 100;
    final aCharge = montant - rembourse;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF185FA5).withValues(alpha: 0.3)),
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('CMU rembourse', style: TextStyle(fontFamily: 'Poppins',
              fontSize: 11, color: Color(0xFF185FA5))),
          Text('${widget.taux.toInt()}% = ${rembourse.toInt()} FCFA',
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 11,
                  fontWeight: FontWeight.w700, color: Color(0xFF185FA5))),
        ]),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Patient à charge', style: TextStyle(fontFamily: 'Poppins',
              fontSize: 11, color: PharmacieColors.primary)),
          Text('${aCharge.toInt()} FCFA',
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 13,
                  fontWeight: FontWeight.w800, color: PharmacieColors.primary)),
        ]),
      ]),
    );
  }
}

// ─── Carte médicament ─────────────────────────────────────────────────────────
class _MedicamentCard extends StatelessWidget {
  final MedicamentPrescrit medicament;
  final int numero;
  const _MedicamentCard({required this.medicament, required this.numero});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: medicament.disponible
            ? const Color(0xFFF1F8F1)
            : const Color(0xFFFFF3F3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: medicament.disponible
              ? PharmacieColors.primary.withValues(alpha: 0.2)
              : const Color(0xFFE74C3C).withValues(alpha: 0.3),
        ),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: medicament.disponible ? PharmacieColors.primary : const Color(0xFFE74C3C),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(child: Text('$numero',
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 13,
                  fontWeight: FontWeight.w800, color: Colors.white))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(medicament.nom,
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 13,
                    fontWeight: FontWeight.w700, color: Color(0xFF1A2340)))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF185FA5).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(medicament.dosage,
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 10,
                      fontWeight: FontWeight.w700, color: Color(0xFF185FA5))),
            ),
          ]),
          const SizedBox(height: 4),
          Text('💊 ${medicament.posologie}',
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 11,
                  color: Color(0xFF1A2340))),
          Text('⏱ ${medicament.dureeJours} jours',
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 10,
                  color: Color(0xFF7A8BA0))),
          if (medicament.instructions != null) ...[
            const SizedBox(height: 4),
            Text('ℹ️ ${medicament.instructions}',
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 10,
                    color: Color(0xFF7A8BA0), fontStyle: FontStyle.italic)),
          ],
          if (medicament.prixUnitaire != null) ...[
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(medicament.disponible ? '✅ En stock' : '❌ Rupture de stock',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: medicament.disponible
                          ? PharmacieColors.primary
                          : const Color(0xFFE74C3C))),
              Text('${(medicament.prixUnitaire! * medicament.dureeJours).toInt()} FCFA',
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 12,
                      fontWeight: FontWeight.w800, color: PharmacieColors.primary)),
            ]),
          ],
        ])),
      ]),
    );
  }
}

// ─── Widgets réutilisables ────────────────────────────────────────────────────
class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _Section({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: PharmacieColors.primaryUltraLight,
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: PharmacieColors.primary, size: 16)),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13,
              fontWeight: FontWeight.w700, color: Color(0xFF1A2340))),
        ]),
        const SizedBox(height: 12),
        const Divider(height: 1, color: Color(0xFFF1F8F1)),
        const SizedBox(height: 12),
        child,
      ]),
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color? valueColor;
  const _Row(this.label, this.value, {required this.icon, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
                color: const Color(0xFFF1F8F1),
                borderRadius: BorderRadius.circular(7)),
            child: Icon(icon, color: PharmacieColors.primary, size: 13)),
        const SizedBox(width: 10),
        Expanded(child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11,
                color: Color(0xFF7A8BA0))),
            Flexible(child: Text(value,
                style: TextStyle(fontFamily: 'Poppins', fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: valueColor ?? const Color(0xFF1A2340)),
                textAlign: TextAlign.end)),
          ],
        )),
      ]),
    );
  }
}
