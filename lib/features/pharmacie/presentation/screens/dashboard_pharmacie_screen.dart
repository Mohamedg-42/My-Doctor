import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pharmacie_provider.dart';
import '../../data/models/ordonnance_model.dart';
import '../../data/models/pharmacie_model.dart';
import '../widgets/ordonnance_card_widget.dart';
import '../widgets/statut_badge_widget.dart';
import 'detail_ordonnance_screen.dart';

class DashboardPharmacieScreen extends StatefulWidget {
  const DashboardPharmacieScreen({super.key});

  @override
  State<DashboardPharmacieScreen> createState() => _DashboardPharmacieScreenState();
}

class _DashboardPharmacieScreenState extends State<DashboardPharmacieScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PharmacieProvider>();
    final pharma = provider.pharmacieCourante;

    if (pharma == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F1),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: PharmacieColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: _Header(pharma: pharma, provider: provider),
            ),
            bottom: TabBar(
              controller: _tabCtrl,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 12,
                  fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 12),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              tabs: [
                Tab(
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.receipt_long_rounded, size: 15),
                    const SizedBox(width: 5),
                    const Text('Ordonnances'),
                    if (provider.totalEnAttente > 0) ...[
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF39C12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('${provider.totalEnAttente}',
                            style: const TextStyle(fontSize: 10,
                                fontWeight: FontWeight.w800, color: Colors.white)),
                      ),
                    ],
                  ]),
                ),
                const Tab(icon: Icon(Icons.history_rounded, size: 15),
                    text: 'Historique'),
                const Tab(icon: Icon(Icons.store_rounded, size: 15),
                    text: 'Mon Profil'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _OrdonnancesTab(provider: provider),
            _HistoriqueTab(provider: provider),
            _ProfilTab(pharma: pharma, provider: provider),
          ],
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final PharmacieModel pharma;
  final PharmacieProvider provider;
  const _Header({required this.pharma, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: PharmacieColors.gradient),
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar initiales
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                ),
                child: Center(
                  child: Text(pharma.initialesTitulaire,
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 20,
                          fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pharma.nomPharmacie,
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 15,
                            fontWeight: FontWeight.w800, color: Colors.white),
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('Ph. ${pharma.prenomTitulaire} ${pharma.nomTitulaire}',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.8))),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.location_on_rounded, size: 11, color: Colors.white70),
                      const SizedBox(width: 3),
                      Text(pharma.commune,
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 10,
                              color: Colors.white70)),
                      const SizedBox(width: 8),
                      if (pharma.estDeGarde)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF39C12).withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('🌙 DE GARDE',
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 8,
                                  fontWeight: FontWeight.w800, color: Colors.white)),
                        ),
                    ]),
                  ],
                ),
              ),
              // Stats rapides
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () async {
                      await provider.rafraichir();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Actualisé'),
                              duration: Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_formatMontant(provider.chiffreAffaireJour)} FCFA',
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 12,
                        fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  const Text("CA aujourd'hui",
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 8,
                          color: Colors.white60)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),
          // KPIs
          Row(
            children: [
              _KpiChip(label: 'En attente', value: provider.totalEnAttente,
                  color: const Color(0xFFF39C12)),
              const SizedBox(width: 8),
              _KpiChip(label: 'Validées', value: provider.totalValidees,
                  color: Colors.white),
              const SizedBox(width: 8),
              _KpiChip(label: 'Payées', value: provider.totalPayees,
                  color: const Color(0xFF9C27B0)),
            ],
          ),
        ],
      ),
    );
  }

  String _formatMontant(double m) {
    if (m >= 1000000) return '${(m / 1000000).toStringAsFixed(1)}M';
    if (m >= 1000) return '${(m / 1000).toStringAsFixed(0)}k';
    return m.toInt().toString();
  }
}

class _KpiChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _KpiChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 6, height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text('$value $label',
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 10,
                fontWeight: FontWeight.w700, color: Colors.white)),
      ]),
    );
  }
}

// ─── Onglet Ordonnances ───────────────────────────────────────────────────────
class _OrdonnancesTab extends StatelessWidget {
  final PharmacieProvider provider;
  const _OrdonnancesTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    final filtres = [null, StatutOrdonnance.enAttente, StatutOrdonnance.validee,
        StatutOrdonnance.payee, StatutOrdonnance.prete, StatutOrdonnance.livree];

    return Column(
      children: [
        // Filtres par statut
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: filtres.map((s) {
                final isActive = provider.filtreStatut == s;
                final label = s == null ? 'Toutes' : s.label;
                final color = s == null ? PharmacieColors.primary : s.color;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => provider.setFiltreStatut(s),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: isActive ? color : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: isActive ? color : Colors.grey.shade300),
                      ),
                      child: Text(label,
                          style: TextStyle(
                            fontFamily: 'Poppins', fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isActive ? Colors.white : Colors.grey.shade600,
                          )),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // Liste ordonnances
        Expanded(
          child: provider.ordonnances.isEmpty
              ? _EmptyState(
                  icon: Icons.receipt_long_rounded,
                  message: provider.filtreStatut == null
                      ? 'Aucune ordonnance reçue'
                      : 'Aucune ordonnance "${provider.filtreStatut!.label}"',
                )
              : RefreshIndicator(
                  onRefresh: provider.rafraichir,
                  color: PharmacieColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.ordonnances.length,
                    itemBuilder: (ctx, i) {
                      final ord = provider.ordonnances[i];
                      return OrdonnanceCardWidget(
                        ordonnance: ord,
                        onTap: () => Navigator.push(ctx,
                          MaterialPageRoute(builder: (_) =>
                              DetailOrdonnanceScreen(ordonnanceId: ord.id))),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

// ─── Onglet Historique ────────────────────────────────────────────────────────
class _HistoriqueTab extends StatefulWidget {
  final PharmacieProvider provider;
  const _HistoriqueTab({required this.provider});
  @override
  State<_HistoriqueTab> createState() => _HistoriqueTabState();
}

class _HistoriqueTabState extends State<_HistoriqueTab> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    // Toutes ordonnances sans filtre de statut
    final toutes = widget.provider.ordonnances;
    final filtrees = toutes.where((o) =>
        _searchQuery.isEmpty ||
        o.patientNomComplet.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        o.id.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F8F1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Rechercher un patient, une ordonnance...',
                      hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 12,
                          color: Color(0xFFB0BEC5)),
                      prefixIcon: Icon(Icons.search_rounded,
                          color: PharmacieColors.primary, size: 18),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _showExportDialog(context),
                child: Container(
                  height: 40, width: 40,
                  decoration: BoxDecoration(
                    color: PharmacieColors.primaryUltraLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: PharmacieColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.picture_as_pdf_rounded,
                      color: PharmacieColors.primary, size: 20),
                ),
              ),
            ],
          ),
        ),

        // Résumé stats
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              _StatCard(label: 'Total', value: '${toutes.length}',
                  color: PharmacieColors.primary),
              const SizedBox(width: 8),
              _StatCard(label: 'Payées',
                  value: '${toutes.where((o) => o.statut == StatutOrdonnance.payee
                      || o.statut == StatutOrdonnance.prete
                      || o.statut == StatutOrdonnance.livree).length}',
                  color: const Color(0xFF9C27B0)),
              const SizedBox(width: 8),
              _StatCard(label: 'Refusées',
                  value: '${toutes.where((o) => o.statut == StatutOrdonnance.refusee).length}',
                  color: const Color(0xFFE74C3C)),
            ],
          ),
        ),

        Expanded(
          child: filtrees.isEmpty
              ? _EmptyState(icon: Icons.search_off_rounded,
                  message: 'Aucun résultat pour "$_searchQuery"')
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtrees.length,
                  itemBuilder: (ctx, i) {
                    final ord = filtrees[i];
                    return _HistoriqueRow(ordonnance: ord, onTap: () =>
                        Navigator.push(ctx, MaterialPageRoute(
                            builder: (_) => DetailOrdonnanceScreen(ordonnanceId: ord.id))));
                  },
                ),
        ),
      ],
    );
  }

  void _showExportDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('Exporter l\'historique',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 16,
                    fontWeight: FontWeight.w700, color: Color(0xFF1A2340))),
            const SizedBox(height: 20),
            const _ExportOption(icon: Icons.today_rounded, label: 'Aujourd\'hui', color: PharmacieColors.primary),
            const _ExportOption(icon: Icons.date_range_rounded, label: 'Cette semaine', color: Color(0xFF2196F3)),
            const _ExportOption(icon: Icons.calendar_month_rounded, label: 'Ce mois', color: Color(0xFF9C27B0)),
            const _ExportOption(icon: Icons.date_range_rounded, label: 'Personnalisé...', color: Color(0xFFF39C12)),
          ],
        ),
      ),
    );
  }
}

class _HistoriqueRow extends StatelessWidget {
  final OrdonnanceModel ordonnance;
  final VoidCallback onTap;
  const _HistoriqueRow({required this.ordonnance, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: ordonnance.statut.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(ordonnance.statut.icon,
                color: ordonnance.statut.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(ordonnance.patientNomComplet,
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 12,
                    fontWeight: FontWeight.w700, color: Color(0xFF1A2340))),
            Text('#${ordonnance.id} · ${ordonnance.nombreMedicaments} méd.',
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 10,
                    color: Color(0xFF7A8BA0))),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            StatutBadgeWidget(statut: ordonnance.statut, compact: true),
            const SizedBox(height: 4),
            if (ordonnance.montantTotal != null)
              Text('${ordonnance.montantTotal!.toInt()} F',
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 11,
                      fontWeight: FontWeight.w800, color: PharmacieColors.primary)),
          ]),
        ]),
      ),
    );
  }
}

class _ExportOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _ExportOption({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20)),
      title: Text(label, style: const TextStyle(fontFamily: 'Poppins',
          fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A2340))),
      trailing: const Icon(Icons.download_rounded, color: Color(0xFF7A8BA0), size: 18),
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Export PDF "$label" en cours...'),
          backgroundColor: PharmacieColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      },
    );
  }
}

// ─── Onglet Profil ────────────────────────────────────────────────────────────
class _ProfilTab extends StatelessWidget {
  final PharmacieModel pharma;
  final PharmacieProvider provider;
  const _ProfilTab({required this.pharma, required this.provider});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Statut vérification
          if (!pharma.estVerifiee)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF39C12).withValues(alpha: 0.4)),
              ),
              child: const Row(children: [
                Icon(Icons.pending_rounded, color: Color(0xFFF39C12), size: 20),
                SizedBox(width: 10),
                Expanded(child: Text('Votre dossier est en cours de vérification par l\'équipe Allo Docteur.',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 11,
                        color: Color(0xFFF39C12)))),
              ]),
            ),

          // Carte profil
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                ),
                child: Center(child: Text(pharma.initialesTitulaire,
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 22,
                        fontWeight: FontWeight.bold, color: Colors.white))),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(pharma.nomPharmacie,
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 15,
                        fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 2),
                Text('${pharma.prenomTitulaire} ${pharma.nomTitulaire}',
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 11,
                        color: Colors.white70)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('OPCI: ${pharma.numeroOrdreOPCI}',
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 10,
                          fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ])),
            ]),
          ),
          const SizedBox(height: 16),

          // Toggles
          _ToggleCard(
            icon: Icons.medical_services_rounded,
            title: 'Accepte les ordonnances',
            subtitle: 'Les patients peuvent vous envoyer des ordonnances',
            value: pharma.accepteOrdonnances,
            onChanged: (v) => provider.mettreAJourProfil(accepteOrdonnances: v),
          ),
          const SizedBox(height: 10),
          _ToggleCard(
            icon: Icons.nightlight_round,
            title: 'Pharmacie de garde',
            subtitle: 'Service disponible 24h/24 et les jours fériés',
            value: pharma.estDeGarde,
            onChanged: (v) => provider.mettreAJourProfil(estDeGarde: v),
          ),
          const SizedBox(height: 16),

          // Infos
          _InfoSection(pharma: pharma),
          const SizedBox(height: 16),

          // Horaires
          _HorairesSection(horaires: pharma.horaires),
          const SizedBox(height: 20),

          // Déconnexion
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                provider.deconnecter();
                Navigator.pushNamedAndRemoveUntil(context, '/welcome', (_) => false);
              },
              icon: const Icon(Icons.logout_rounded, color: Color(0xFFE74C3C)),
              label: const Text('Se déconnecter',
                  style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700,
                      color: Color(0xFFE74C3C))),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE74C3C)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text('Allo Docteur v2.0 · Module Pharmacie',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: Color(0xFFB0BEC5))),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ToggleCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleCard({required this.icon, required this.title,
      required this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8, offset: const Offset(0, 2))]),
      child: ListTile(
        leading: Container(padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: (value ? PharmacieColors.primary : Colors.grey.shade400)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon,
                color: value ? PharmacieColors.primary : Colors.grey.shade400, size: 20)),
        title: Text(title, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13,
            fontWeight: FontWeight.w600, color: Color(0xFF1A2340))),
        subtitle: Text(subtitle, style: const TextStyle(fontFamily: 'Poppins', fontSize: 10,
            color: Color(0xFF7A8BA0))),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: PharmacieColors.primary,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final PharmacieModel pharma;
  const _InfoSection({required this.pharma});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.info_outline_rounded, color: PharmacieColors.primary, size: 18),
          SizedBox(width: 8),
          Text('Informations', style: TextStyle(fontFamily: 'Poppins', fontSize: 13,
              fontWeight: FontWeight.w700, color: Color(0xFF1A2340))),
        ]),
        const SizedBox(height: 12),
        _InfoRow(icon: Icons.phone_rounded, label: 'Téléphone', value: pharma.telephone),
        _InfoRow(icon: Icons.email_outlined, label: 'Email', value: pharma.email),
        _InfoRow(icon: Icons.location_on_rounded, label: 'Adresse', value: pharma.adresseComplete),
        _InfoRow(icon: Icons.badge_rounded, label: 'N° OPCI', value: pharma.numeroOrdreOPCI),
        _InfoRow(icon: Icons.verified_rounded, label: 'Licence',
            value: pharma.numeroLicenceExploitation),
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: PharmacieColors.primaryUltraLight,
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: PharmacieColors.primary, size: 14)),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 9,
              color: Color(0xFF7A8BA0))),
          Text(value, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12,
              fontWeight: FontWeight.w600, color: Color(0xFF1A2340))),
        ]),
      ]),
    );
  }
}

class _HorairesSection extends StatelessWidget {
  final Map<String, String> horaires;
  const _HorairesSection({required this.horaires});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.schedule_rounded, color: PharmacieColors.primary, size: 18),
          SizedBox(width: 8),
          Text('Horaires d\'ouverture', style: TextStyle(fontFamily: 'Poppins',
              fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A2340))),
        ]),
        const SizedBox(height: 12),
        ...horaires.entries.map((e) {
          final ferme = e.value == 'Fermé';
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              SizedBox(width: 90,
                  child: Text(e.key, style: const TextStyle(fontFamily: 'Poppins',
                      fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF7A8BA0)))),
              Container(width: 6, height: 6,
                  decoration: BoxDecoration(
                      color: ferme ? const Color(0xFFE74C3C) : PharmacieColors.primary,
                      shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(e.value,
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: ferme ? const Color(0xFFE74C3C) : const Color(0xFF1A2340))),
            ]),
          );
        }),
      ]),
    );
  }
}

// ─── Widgets partagés ─────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(children: [
          Text(value, style: TextStyle(fontFamily: 'Poppins', fontSize: 20,
              fontWeight: FontWeight.w800, color: color)),
          Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 10,
              color: Color(0xFF7A8BA0))),
        ]),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(color: PharmacieColors.primaryUltraLight,
              shape: BoxShape.circle),
          child: Icon(icon, size: 48, color: PharmacieColors.primary.withValues(alpha: 0.5))),
      const SizedBox(height: 16),
      Text(message, style: const TextStyle(fontFamily: 'Poppins', fontSize: 14,
          color: Color(0xFF7A8BA0)), textAlign: TextAlign.center),
    ]));
  }
}
