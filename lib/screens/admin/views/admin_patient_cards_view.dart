// lib/screens/admin/views/admin_patient_cards_view.dart
//
// Vue de gestion et d'audit des cartes patient et affiliations CMU-CI.

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/database_service.dart';
import '../components/admin_empty_state.dart';

class AdminPatientCardsView extends StatefulWidget {
  const AdminPatientCardsView({super.key});

  @override
  State<AdminPatientCardsView> createState() => _AdminPatientCardsViewState();
}

class _AdminPatientCardsViewState extends State<AdminPatientCardsView> {
  String _searchQuery = '';
  String _selectedFilter = 'Toutes'; // 'Toutes', 'Valides CMU', 'Sans CMU'
  final TextEditingController _searchCtrl = TextEditingController();

  // Statuts de cartes gérés localement en admin
  final Map<String, String> _cardStatuses = {};

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _getCardStatus(DbUser p) {
    if (_cardStatuses.containsKey(p.id)) return _cardStatuses[p.id]!;
    if (p.cmuNumber != null && p.cmuNumber!.isNotEmpty) return 'Valide';
    return 'Incomplète';
  }

  void _showCardModal(DbUser p) {
    final status = _getCardStatus(p);
    final isValide = status == 'Valide';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        title: const Row(
          children: [
            Icon(LucideIcons.id_card, color: Color(0xFF185FA5), size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Détail Carte Patient & CMU',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge carte
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF185FA5), Color(0xFF0D3F73)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'RÉPUBLIQUE DE CÔTE D\'IVOIRE',
                                style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 6),
                            Text('🇨🇮', style: TextStyle(fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          p.fullName.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        Text(
                          'N° CMU : ${p.cmuNumber ?? "Non affilié"}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Date de naissance : ${p.birthDate ?? "Non renseignée"}',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _InfoRow('Identifiant patient', p.id),
                  _InfoRow('Statut de la carte', status),
                  _InfoRow('Téléphone', p.phone),
                  _InfoRow('Commune / Ville', '${p.commune ?? ""} ${p.city ?? "Abidjan"}'),
                  _InfoRow('Profession', p.profession ?? 'Non renseignée'),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newStatus = isValide ? 'Suspendue' : 'Valide';
              setState(() {
                _cardStatuses[p.id] = newStatus;
              });
              await DatabaseService().updateUserStatus(p.id, isValide ? 'suspended' : 'active');
              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Carte de ${p.fullName} marquée comme $newStatus.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isValide ? AppColors.error : AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: Text(isValide ? 'Suspendre la carte' : 'Valider la carte'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();
    var allPatients = db.getAllPatients();
    if (allPatients.isEmpty) {
      allPatients = [
        DbUser(
          id: 'patient_demo_1',
          role: 'patient',
          firstName: 'Kouamé',
          lastName: 'Koffi',
          phone: '0707070707',
          email: 'patient@mydoctor.ci',
          passwordHash: '',
          cmuNumber: 'CMU-CI123456789',
          birthDate: '1990-05-15',
          gender: 'M',
          commune: 'Cocody',
          city: 'Abidjan',
          profession: 'Enseignant',
          status: 'active',
          createdAt: DateTime.now(),
        ),
        DbUser(
          id: 'patient_demo_2',
          role: 'patient',
          firstName: 'Aminata',
          lastName: 'Touré',
          phone: '0708080808',
          email: 'aminata.toure@email.ci',
          passwordHash: '',
          cmuNumber: 'CMU-CI987654321',
          birthDate: '1995-11-20',
          gender: 'F',
          commune: 'Plateau',
          city: 'Abidjan',
          profession: 'Comptable',
          status: 'active',
          createdAt: DateTime.now(),
        ),
      ];
    }

    final filtered = allPatients.where((p) {
      final status = _getCardStatus(p);
      final hasCmu = p.cmuNumber != null && p.cmuNumber!.isNotEmpty;

      final matchesFilter = _selectedFilter == 'Toutes' ||
          (_selectedFilter == 'Valides CMU' && hasCmu && status == 'Valide') ||
          (_selectedFilter == 'Sans CMU' && !hasCmu);

      final q = _searchQuery.toLowerCase();
      final matchesQuery = q.isEmpty ||
          p.fullName.toLowerCase().contains(q) ||
          p.id.toLowerCase().contains(q) ||
          (p.cmuNumber != null && p.cmuNumber!.toLowerCase().contains(q));

      return matchesFilter && matchesQuery;
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
                hintText: 'Rechercher par nom, identifiant ou numéro CMU...',
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
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Toutes', 'Valides CMU', 'Sans CMU'].map((f) {
                final isSel = _selectedFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f),
                    selected: isSel,
                    onSelected: (_) => setState(() => _selectedFilter = f),
                    selectedColor: const Color(0xFF185FA5),
                    labelStyle: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                      color: isSel ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: filtered.isEmpty
                ? const AdminEmptyState(
                    icon: LucideIcons.id_card,
                    title: 'Aucune carte trouvée',
                    message: 'Aucun dossier de carte ne correspond à vos filtres.',
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final p = filtered[i];
                      final status = _getCardStatus(p);
                      final hasCmu = p.cmuNumber != null && p.cmuNumber!.isNotEmpty;
                      final isValide = status == 'Valide';

                      final statusColor = isValide
                          ? AppColors.success
                          : (status == 'Suspendue' ? AppColors.error : Colors.amber.shade700);

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isNarrow = constraints.maxWidth < 560;

                            final patientInfo = Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF185FA5).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: Icon(LucideIcons.id_card, color: Color(0xFF185FA5), size: 22),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              p.fullName,
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
                                              color: statusColor.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              status,
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: statusColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        hasCmu
                                            ? 'N° CMU : ${p.cmuNumber} • Date de naissance : ${p.birthDate ?? "Non renseignée"}'
                                            : 'Affiliation CMU non renseignée • Profil à compléter',
                                        style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey.shade600),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );

                            final consultBtn = ElevatedButton.icon(
                              onPressed: () => _showCardModal(p),
                              icon: const Icon(LucideIcons.eye, size: 14),
                              label: const Text('Consulter'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF185FA5),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );

                            if (isNarrow) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  patientInfo,
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: consultBtn,
                                  ),
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(child: patientInfo),
                                const SizedBox(width: 12),
                                consultBtn,
                              ],
                            );
                          },
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }
}
