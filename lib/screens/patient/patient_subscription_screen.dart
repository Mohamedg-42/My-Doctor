// lib/screens/patient/patient_subscription_screen.dart
//
// Écran Abonnements Santé Patient : du Plan Gratuit au Pack Famille.
// Conforme aux spécifications de l'application de référence My Doctor.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/patient_subscription_model.dart';
import '../../providers/patient_subscription_provider.dart';

class PatientSubscriptionScreen extends StatefulWidget {
  const PatientSubscriptionScreen({super.key});

  @override
  State<PatientSubscriptionScreen> createState() =>
      _PatientSubscriptionScreenState();
}

class _PatientSubscriptionScreenState extends State<PatientSubscriptionScreen> {
  @override
  Widget build(BuildContext context) {
    final subProvider = context.watch<PatientSubscriptionProvider>();
    final currentPlan = subProvider.currentPlan;
    final currentSub = subProvider.currentSubscription;
    final selectedCycle = subProvider.selectedCycle;
    final isFamilyPlanActive = currentPlan.type == PatientPlanType.famille;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Abonnements Santé',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Du Plan Gratuit au Pack Famille',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      body: subProvider.isLoading && currentSub == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Bannière du plan actuel
                  _ActivePlanBanner(
                    plan: currentPlan,
                    subscription: currentSub,
                  ),
                  const SizedBox(height: 24),

                  // 2. Section membres de la famille (uniquement si Plan Famille actif)
                  if (isFamilyPlanActive) ...[
                    _FamilyMembersSection(
                      members: subProvider.familyMembers,
                      canAdd: subProvider.canAddFamilyMember,
                      onAddMember: () => _showAddFamilyMemberDialog(context),
                      onRemoveMember: (id, name) =>
                          _confirmRemoveFamilyMember(context, id, name),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 3. Sélecteur de facturation Mensuel / Annuel
                  _BillingCycleSelector(
                    selectedCycle: selectedCycle,
                    onCycleChanged: (cycle) => subProvider.selectCycle(cycle),
                  ),
                  const SizedBox(height: 20),

                  // 4. Cartes des 4 plans
                  ...subProvider.plans.map((plan) {
                    final isCurrent = plan.id == currentPlan.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: _PlanCard(
                        plan: plan,
                        cycle: selectedCycle,
                        isCurrentPlan: isCurrent,
                        onSelect: () =>
                            _handlePlanSelection(context, plan, isCurrent),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),

                  // 5. Tableau comparatif des fonctionnalités
                  const _ComparisonTableSection(),
                  const SizedBox(height: 28),

                  // 6. Section FAQ
                  const _FaqSection(),

                  // 7. Espace inférieur
                  const SizedBox(height: 36),
                ],
              ),
            ),
    );
  }

  // ─── Gestion de la sélection d'un plan ────────────────────────────────────

  void _handlePlanSelection(
    BuildContext context,
    PatientSubscriptionPlan plan,
    bool isCurrent,
  ) {
    if (isCurrent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vous êtes déjà sur le ${plan.name}.'),
          backgroundColor: AppColors.brandBlue,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (plan.isFree) {
      // Demander confirmation pour retour au Plan Gratuit
      _showDowngradeDialog(context);
    } else {
      // Ouvrir le checkout modal pour plan payant
      _showCheckoutModal(context, plan);
    }
  }

  // ─── Dialogue de confirmation retour au Plan Gratuit ───────────────────────

  void _showDowngradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.info_outline_rounded,
                color: AppColors.warning, size: 24),
            SizedBox(width: 10),
            Text(
              'Passer au Plan Gratuit',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: const Text(
          'En revenant au Plan Gratuit, vos téléconsultations incluses et avantages famille prendront fin à la date d’échéance.',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Annuler',
                style: TextStyle(
                    fontFamily: 'Poppins', color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final provider = context.read<PatientSubscriptionProvider>();
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(dialogCtx);
              final ok = await provider.downgradeToFree();
              if (mounted && ok) {
                messenger.showSnackBar(
                  const SnackBar(
                    content:
                        Text('Votre abonnement est désormais le Plan Gratuit.'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandBlue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Confirmer',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ─── Modal de checkout pour plan payant ───────────────────────────────────

  void _showCheckoutModal(BuildContext context, PatientSubscriptionPlan plan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CheckoutBottomSheet(plan: plan),
    );
  }

  // ─── Dialogue d'ajout d'un membre famille ─────────────────────────────────

  void _showAddFamilyMemberDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final cmuCtrl = TextEditingController();
    String selectedRelation = 'Conjoint(e)';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.person_add_alt_1_rounded, color: Color(0xFFEA580C)),
              SizedBox(width: 10),
              Text(
                'Ajouter un membre',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nom & Prénoms *',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      hintText: 'Ex: KOUASSI Marie-Josée',
                      hintStyle: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: AppColors.textLight),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Le nom et les prénoms sont requis.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Lien de parenté',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedRelation,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded,
                            color: AppColors.textSecondary),
                        items: const [
                          DropdownMenuItem(
                              value: 'Conjoint(e)', child: Text('Conjoint(e)')),
                          DropdownMenuItem(
                              value: 'Enfant', child: Text('Enfant')),
                          DropdownMenuItem(
                              value: 'Parent (Père/Mère)',
                              child: Text('Parent (Père/Mère)')),
                          DropdownMenuItem(
                              value: 'Autre proche',
                              child: Text('Autre proche')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedRelation = val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Numéro CMU (optionnel)',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: cmuCtrl,
                    decoration: InputDecoration(
                      hintText: 'Ex: CMU-CI123456789',
                      hintStyle: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: AppColors.textLight),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Annuler',
                  style: TextStyle(
                      fontFamily: 'Poppins', color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  final newMember = FamilyMember(
                    id: 'fam_${DateTime.now().millisecondsSinceEpoch}',
                    fullName: nameCtrl.text.trim(),
                    relationship: selectedRelation,
                    cmuNumber: cmuCtrl.text.trim().isNotEmpty
                        ? cmuCtrl.text.trim()
                        : null,
                  );
                  final provider = context.read<PatientSubscriptionProvider>();
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(dialogCtx);
                  final ok = await provider.addFamilyMember(newMember);
                  if (mounted && ok) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                            '${newMember.fullName} a été ajouté à votre formule famille.'),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEA580C),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Ajouter',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRemoveFamilyMember(
      BuildContext context, String memberId, String memberName) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Retirer ce membre',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w700)),
        content: Text(
            'Êtes-vous sûr de vouloir retirer $memberName du Pack Famille ?',
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Annuler',
                style: TextStyle(
                    fontFamily: 'Poppins', color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await context
                  .read<PatientSubscriptionProvider>()
                  .removeFamilyMember(memberId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Retirer',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ─── 1. Bannière du Plan Actuel ─────────────────────────────────────────────

class _ActivePlanBanner extends StatelessWidget {
  final PatientSubscriptionPlan plan;
  final PatientSubscription? subscription;

  const _ActivePlanBanner({required this.plan, this.subscription});

  @override
  Widget build(BuildContext context) {
    final isFree = plan.isFree;
    final cycle = subscription?.cycle ?? SubscriptionBillingCycle.mensuel;
    final endDate = subscription?.endDate;

    String dateText = 'Actif à vie';
    if (!isFree && endDate != null) {
      final day = endDate.day.toString().padLeft(2, '0');
      final month = endDate.month.toString().padLeft(2, '0');
      final year = endDate.year;
      dateText = 'Jusqu’au $day/$month/$year';
    }

    String teleconsultText = 'Téléconsultations : à l’acte';
    if (!isFree) {
      teleconsultText =
          '${plan.teleconsultationsIncluded} téléconsult. incluses/mois';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            plan.accentColor,
            plan.accentColor.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: plan.accentColor.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white38),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: Colors.white, size: 14),
                    SizedBox(width: 5),
                    Text(
                      'PLAN ACTIF',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isFree)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    cycle == SubscriptionBillingCycle.annuel
                        ? 'Annuel'
                        : 'Mensuel',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: plan.accentColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(plan.icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      plan.tagline,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.white24),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.video_call_rounded,
                      color: Colors.white70, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    teleconsultText,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.access_time_rounded,
                      color: Colors.white70, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    dateText,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── 2. Section Membres Famille (Si Plan Famille actif) ──────────────────────

class _FamilyMembersSection extends StatelessWidget {
  final List<FamilyMember> members;
  final bool canAdd;
  final VoidCallback onAddMember;
  final void Function(String id, String name) onRemoveMember;

  const _FamilyMembersSection({
    required this.members,
    required this.canAdd,
    required this.onAddMember,
    required this.onRemoveMember,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: const Color(0xFFEA580C).withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEA580C).withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Membres de la Famille',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${members.length} / 6 membres enregistrés',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: Color(0xFFEA580C),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (canAdd)
                ElevatedButton.icon(
                  onPressed: onAddMember,
                  icon: const Icon(Icons.add_rounded,
                      size: 16, color: Colors.white),
                  label: const Text(
                    'Ajouter',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEA580C),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (members.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFEDD5)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: Color(0xFFEA580C), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Ajoutez jusqu’à 6 membres (enfants, conjoint, parents) pour leur faire bénéficier de votre couverture santé.',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: Color(0xFF9A3412),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ...members.map(
              (m) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEA580C).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.person_rounded,
                          color: Color(0xFFEA580C), size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.fullName,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            m.cmuNumber != null && m.cmuNumber!.isNotEmpty
                                ? '${m.relationship} · CMU: ${m.cmuNumber}'
                                : m.relationship,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: AppColors.error, size: 20),
                      onPressed: () => onRemoveMember(m.id, m.fullName),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── 3. Sélecteur de facturation ────────────────────────────────────────────

class _BillingCycleSelector extends StatelessWidget {
  final SubscriptionBillingCycle selectedCycle;
  final ValueChanged<SubscriptionBillingCycle> onCycleChanged;

  const _BillingCycleSelector({
    required this.selectedCycle,
    required this.onCycleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _CycleOption(
              title: 'Mensuel',
              isSelected: selectedCycle == SubscriptionBillingCycle.mensuel,
              onTap: () => onCycleChanged(SubscriptionBillingCycle.mensuel),
            ),
          ),
          Expanded(
            child: _CycleOption(
              title: 'Annuel',
              badge: '-2 mois',
              isSelected: selectedCycle == SubscriptionBillingCycle.annuel,
              onTap: () => onCycleChanged(SubscriptionBillingCycle.annuel),
            ),
          ),
        ],
      ),
    );
  }
}

class _CycleOption extends StatelessWidget {
  final String title;
  final String? badge;
  final bool isSelected;
  final VoidCallback onTap;

  const _CycleOption({
    required this.title,
    this.badge,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color:
                    isSelected ? AppColors.brandBlue : AppColors.textSecondary,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── 4. Cartes des Plans ───────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final PatientSubscriptionPlan plan;
  final SubscriptionBillingCycle cycle;
  final bool isCurrentPlan;
  final VoidCallback onSelect;

  const _PlanCard({
    required this.plan,
    required this.cycle,
    required this.isCurrentPlan,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final priceStr = plan.priceFormatted(cycle);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isCurrentPlan
              ? plan.accentColor
              : plan.accentColor.withValues(alpha: 0.2),
          width: isCurrentPlan ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: plan.accentColor.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de la carte
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: plan.accentColor.withValues(alpha: 0.04),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: plan.accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(plan.icon, color: plan.accentColor, size: 24),
                    ),
                    if (plan.badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: plan.accentColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          plan.badge!,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  plan.name,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  plan.tagline,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  priceStr,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: plan.accentColor,
                  ),
                ),
              ],
            ),
          ),

          // Avantages mis en avant
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...plan.highlightedPerks.map(
                  (perk) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(Icons.stars_rounded,
                            color: plan.accentColor, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            perk,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: plan.accentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                const SizedBox(height: 12),

                // Liste complète des fonctionnalités
                ...plan.features.map(
                  (feat) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline_rounded,
                            color: Color(0xFF10B981), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feat,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: AppColors.textPrimary,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Bouton d'action
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onSelect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCurrentPlan
                          ? const Color(0xFFE2E8F0)
                          : plan.accentColor,
                      foregroundColor: isCurrentPlan
                          ? AppColors.textSecondary
                          : Colors.white,
                      elevation: isCurrentPlan ? 0 : 2,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      isCurrentPlan ? 'Plan Actif' : 'Choisir cette formule',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isCurrentPlan
                            ? AppColors.textSecondary
                            : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 5. Tableau Comparatif des Fonctionnalités ─────────────────────────────

class _ComparisonTableSection extends StatelessWidget {
  const _ComparisonTableSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.compare_rounded, color: AppColors.brandBlue, size: 20),
              SizedBox(width: 8),
              Text(
                'Comparatif des Formules',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
              columnSpacing: 16,
              horizontalMargin: 12,
              columns: const [
                DataColumn(
                    label: Text('Fonctionnalité',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            fontSize: 11))),
                DataColumn(
                    label: Text('Gratuit',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            fontSize: 11))),
                DataColumn(
                    label: Text('Essentiel',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: Color(0xFF185FA5)))),
                DataColumn(
                    label: Text('Confort',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: Color(0xFF0D9488)))),
                DataColumn(
                    label: Text('Famille',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: Color(0xFFEA580C)))),
              ],
              rows: const [
                DataRow(cells: [
                  DataCell(Text('Prix mensuel',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 11))),
                  DataCell(Text('0 F',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 11))),
                  DataCell(Text('1 500 F',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w600))),
                  DataCell(Text('3 500 F',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w600))),
                  DataCell(Text('6 500 F',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w600))),
                ]),
                DataRow(cells: [
                  DataCell(Text('Téléconsultations incluses',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 11))),
                  DataCell(Text('À l’acte',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 11))),
                  DataCell(Text('1 / mois',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 11))),
                  DataCell(Text('3 / mois',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 11))),
                  DataCell(Text('6 / mois',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 11))),
                ]),
                DataRow(cells: [
                  DataCell(Text('Personnes couvertes',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 11))),
                  DataCell(Text('1 pers.',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 11))),
                  DataCell(Text('1 pers.',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 11))),
                  DataCell(Text('1 pers.',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 11))),
                  DataCell(Text('Jusqu’à 6',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFEA580C)))),
                ]),
                DataRow(cells: [
                  DataCell(Text('Carte CMU digitale',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 11))),
                  DataCell(
                      Icon(Icons.check, color: Color(0xFF10B981), size: 16)),
                  DataCell(
                      Icon(Icons.check, color: Color(0xFF10B981), size: 16)),
                  DataCell(
                      Icon(Icons.check, color: Color(0xFF10B981), size: 16)),
                  DataCell(
                      Icon(Icons.check, color: Color(0xFF10B981), size: 16)),
                ]),
                DataRow(cells: [
                  DataCell(Text('Prise de RDV cabinet',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 11))),
                  DataCell(
                      Icon(Icons.check, color: Color(0xFF10B981), size: 16)),
                  DataCell(
                      Icon(Icons.check, color: Color(0xFF10B981), size: 16)),
                  DataCell(
                      Icon(Icons.check, color: Color(0xFF10B981), size: 16)),
                  DataCell(
                      Icon(Icons.check, color: Color(0xFF10B981), size: 16)),
                ]),
                DataRow(cells: [
                  DataCell(Text('Messagerie directe médecin',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 11))),
                  DataCell(
                      Icon(Icons.close, color: Color(0xFF94A3B8), size: 16)),
                  DataCell(
                      Icon(Icons.check, color: Color(0xFF10B981), size: 16)),
                  DataCell(
                      Icon(Icons.check, color: Color(0xFF10B981), size: 16)),
                  DataCell(
                      Icon(Icons.check, color: Color(0xFF10B981), size: 16)),
                ]),
                DataRow(cells: [
                  DataCell(Text('Dossier médical cloud',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 11))),
                  DataCell(
                      Icon(Icons.close, color: Color(0xFF94A3B8), size: 16)),
                  DataCell(
                      Icon(Icons.check, color: Color(0xFF10B981), size: 16)),
                  DataCell(
                      Icon(Icons.check, color: Color(0xFF10B981), size: 16)),
                  DataCell(
                      Icon(Icons.check, color: Color(0xFF10B981), size: 16)),
                ]),
                DataRow(cells: [
                  DataCell(Text('Ligne Urgences 24/24',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 11))),
                  DataCell(
                      Icon(Icons.close, color: Color(0xFF94A3B8), size: 16)),
                  DataCell(
                      Icon(Icons.close, color: Color(0xFF94A3B8), size: 16)),
                  DataCell(
                      Icon(Icons.check, color: Color(0xFF10B981), size: 16)),
                  DataCell(
                      Icon(Icons.check, color: Color(0xFF10B981), size: 16)),
                ]),
                DataRow(cells: [
                  DataCell(Text('Suivi constantes & alertes',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 11))),
                  DataCell(
                      Icon(Icons.close, color: Color(0xFF94A3B8), size: 16)),
                  DataCell(
                      Icon(Icons.close, color: Color(0xFF94A3B8), size: 16)),
                  DataCell(
                      Icon(Icons.check, color: Color(0xFF10B981), size: 16)),
                  DataCell(
                      Icon(Icons.check, color: Color(0xFF10B981), size: 16)),
                ]),
                DataRow(cells: [
                  DataCell(Text('SOS Famille 24/7 & Carnet pédiatrique',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 11))),
                  DataCell(
                      Icon(Icons.close, color: Color(0xFF94A3B8), size: 16)),
                  DataCell(
                      Icon(Icons.close, color: Color(0xFF94A3B8), size: 16)),
                  DataCell(
                      Icon(Icons.close, color: Color(0xFF94A3B8), size: 16)),
                  DataCell(
                      Icon(Icons.check, color: Color(0xFF10B981), size: 16)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 6. Section FAQ avec Material Wrapper ───────────────────────────────────

class _FaqSection extends StatelessWidget {
  const _FaqSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.help_outline_rounded,
                color: AppColors.brandBlue, size: 20),
            SizedBox(width: 8),
            Text(
              'Questions Fréquentes (FAQ)',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildFaqTile(
          question: 'Quelle est la différence entre Mensuel et Annuel ?',
          answer:
              'Le paiement annuel vous fait bénéficier d’une remise équivalente à deux mois complets offerts (ex: 15 000 FCFA/an au lieu de 18 000 FCFA). Vous conservez vos avantages toute l’année sans interruption.',
        ),
        _buildFaqTile(
          question: 'Comment fonctionnent les téléconsultations incluses ?',
          answer:
              'Chaque mois, vos téléconsultations incluses sont créditées sur votre compte. Vous pouvez les utiliser pour consulter un médecin généraliste ou spécialiste conventionné sans frais supplémentaires à l’acte.',
        ),
        _buildFaqTile(
          question: 'Comment fonctionne le Pack Famille ?',
          answer:
              'Le Pack Famille permet de rattacher jusqu’à 6 membres (conjoint, enfants, parents). Les téléconsultations sont partagées entre les membres du foyer et chacun dispose d’un carnet de santé digital.',
        ),
        _buildFaqTile(
          question: 'Puis-je arrêter ou changer d’abonnement à tout moment ?',
          answer:
              'Oui, absolument. Vous pouvez changer de formule ou repasser au Plan Gratuit sans frais ni pénalité. Vos avantages en cours restent valables jusqu’à la date d’échéance de votre cycle payé.',
        ),
        _buildFaqTile(
          question:
              'Est-ce que je conserve ma carte CMU en changeant de plan ?',
          answer:
              'Oui, la carte CMU digitale est incluse à vie dans tous les plans, y compris le Plan Gratuit. Vos droits CMU et vos taux de couverture restent inchangés.',
        ),
        _buildFaqTile(
          question: 'Quels sont les moyens de paiement acceptés ?',
          answer:
              'Nous acceptons tous les moyens de paiement locaux : Orange Money, MTN MoMo, Moov Money, Wave, ainsi que les cartes bancaires Visa et Mastercard.',
        ),
      ],
    );
  }

  Widget _buildFaqTile({required String question, required String answer}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          title: Text(
            question,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          children: [
            Text(
              answer,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 7. Bottom Sheet Checkout Paiement ──────────────────────────────────────

class _CheckoutBottomSheet extends StatefulWidget {
  final PatientSubscriptionPlan plan;

  const _CheckoutBottomSheet({required this.plan});

  @override
  State<_CheckoutBottomSheet> createState() => _CheckoutBottomSheetState();
}

class _CheckoutBottomSheetState extends State<_CheckoutBottomSheet> {
  String _selectedMethod = 'Orange Money';
  bool _isProcessing = false;

  static const List<Map<String, dynamic>> _paymentMethods = [
    {
      'name': 'Orange Money',
      'icon': Icons.phone_android_rounded,
      'color': Color(0xFFFF7900)
    },
    {
      'name': 'MTN MoMo',
      'icon': Icons.account_balance_wallet_rounded,
      'color': Color(0xFFFFCC00)
    },
    {
      'name': 'Moov Money',
      'icon': Icons.send_to_mobile_rounded,
      'color': Color(0xFF006699)
    },
    {'name': 'Wave', 'icon': Icons.waves_rounded, 'color': Color(0xFF1EA6D6)},
    {
      'name': 'Carte bancaire',
      'icon': Icons.credit_card_rounded,
      'color': Color(0xFF185FA5)
    },
  ];

  @override
  Widget build(BuildContext context) {
    final subProvider = context.watch<PatientSubscriptionProvider>();
    final cycle = subProvider.selectedCycle;
    final totalAmount = widget.plan.priceFormatted(cycle);
    final periodText =
        cycle == SubscriptionBillingCycle.annuel ? 'par an' : 'par mois';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: widget.plan.accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.plan.icon,
                        color: widget.plan.accentColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Souscrire au ${widget.plan.name}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Facturation ${cycle == SubscriptionBillingCycle.annuel ? 'Annuelle' : 'Mensuelle'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
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
              const SizedBox(height: 18),

              // Récapitulatif du montant
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Montant total à régler',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                color: AppColors.textSecondary),
                          ),
                          Text(
                            '$totalAmount ($periodText)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: widget.plan.accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Sans engagement',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Moyen de paiement
              const Text(
                'Moyen de paiement',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              ..._paymentMethods.map((m) {
                final isSelected = _selectedMethod == m['name'];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (m['color'] as Color).withValues(alpha: 0.06)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? (m['color'] as Color)
                          : const Color(0xFFE2E8F0),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: ListTile(
                    dense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    leading: Icon(m['icon'] as IconData,
                        color: m['color'] as Color, size: 22),
                    title: Text(
                      m['name'] as String,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_circle_rounded,
                            color: m['color'] as Color, size: 20)
                        : const Icon(Icons.radio_button_unchecked_rounded,
                            color: Color(0xFFCBD5E1), size: 20),
                    onTap: _isProcessing
                        ? null
                        : () => setState(
                            () => _selectedMethod = m['name'] as String),
                  ),
                );
              }),
              const SizedBox(height: 12),

              // Note simulation mode développement
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_rounded,
                        color: Color(0xFF64748B), size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Passerelle sécurisée. En mode développement, la transaction est validée en simulation.',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Boutons de confirmation et annulation
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isProcessing ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      child: const Text(
                        'Annuler',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed:
                          _isProcessing ? null : () => _confirmPayment(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.plan.accentColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'Confirmer l’abonnement',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
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

  Future<void> _confirmPayment(BuildContext sheetContext) async {
    setState(() => _isProcessing = true);
    final subProvider = sheetContext.read<PatientSubscriptionProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(sheetContext);

    // Simulation de traitement sécurisé
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;

    final success = await subProvider.subscribeToPlan(
      planId: widget.plan.id,
      cycle: subProvider.selectedCycle,
      paymentMethod: _selectedMethod,
    );

    if (mounted) {
      setState(() => _isProcessing = false);
      nav.pop();

      if (success) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Félicitations ! Vous êtes désormais abonné au ${widget.plan.name}.',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
