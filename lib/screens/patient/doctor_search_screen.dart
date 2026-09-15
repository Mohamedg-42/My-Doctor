import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/patient_provider.dart';
import '../../providers/treating_request_provider.dart';
import '../../widgets/patient/doctor_card.dart';
import 'doctor_profile_screen.dart';

class DoctorSearchScreen extends StatefulWidget {
  const DoctorSearchScreen({super.key});

  @override
  State<DoctorSearchScreen> createState() => _DoctorSearchScreenState();
}

class _DoctorSearchScreenState extends State<DoctorSearchScreen> {
  final _searchCtrl = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 📡 Plus besoin de rafraîchir manuellement - le Stream le fait automatiquement
      final auth = context.read<AuthProvider>();
      // auth.refreshDoctors(); ← SUPPRIMÉ - géré par Stream

      // Filtrer les médecins avec demande pending/accepted
      final trProvider = context.read<TreatingRequestProvider>();
      final patientId = auth.currentUser?.id ?? '';
      final excluded = trProvider.allRequests
          .where((r) =>
              r.patientId == patientId &&
              (r.status.name == 'pending' || r.status.name == 'accepted'))
          .map((r) => r.doctorId)
          .toSet();

      context.read<PatientProvider>().setDoctors(
        auth.mockDoctors,
        excludedDoctorIds: excluded,
      );
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patient = context.watch<PatientProvider>();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Trouver un médecin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => _showAdvancedFilters(context, patient),
            tooltip: 'Filtres avancés',
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Barre de recherche ───────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            color: AppColors.backgroundCard,
            child: Column(
              children: [
                // Champ de recherche principal
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.backgroundGrey),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    focusNode: _focusNode,
                    onChanged: patient.searchDoctors,
                    decoration: InputDecoration(
                      hintText: 'Nom, prénom, spécialité, ville...',
                      hintStyle: AppTextStyles.body2.copyWith(color: AppColors.textLight),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 22),
                      suffixIcon: patient.searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, color: AppColors.textSecondary),
                              onPressed: () {
                                _searchCtrl.clear();
                                patient.searchDoctors('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // ─── Filtres rapides spécialité ──────────────────────────
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: ['Tous', ...AppConstants.specialties.take(7)].length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final items = ['Tous', ...AppConstants.specialties.take(7)];
                      final isSelected = i == 0
                          ? patient.selectedSpecialty.isEmpty
                          : patient.selectedSpecialty == items[i];
                      return GestureDetector(
                        onTap: () => patient.filterBySpecialty(i == 0 ? '' : items[i]),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : AppColors.backgroundGrey,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isSelected ? AppColors.primary : Colors.transparent),
                          ),
                          child: Text(
                            items[i],
                            style: AppTextStyles.caption.copyWith(
                              color: isSelected ? AppColors.textWhite : AppColors.textSecondary,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // ─── En-tête résultats ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Compteur + tags actifs
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        '${patient.doctors.length} médecin${patient.doctors.length > 1 ? 's' : ''}',
                        style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (patient.selectedCity.isNotEmpty || patient.maxPrice < 100000 || patient.selectedAvailability.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: patient.resetFilters,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.close_rounded, size: 12, color: AppColors.error),
                                SizedBox(width: 3),
                                Text('Effacer', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.error, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Tri
                GestureDetector(
                  onTap: () => _showSortOptions(context, patient),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primaryUltraLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sort_rounded, size: 15, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(_getSortLabel(patient.sortBy), style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ─── Filtres actifs chips ─────────────────────────────────────
          if (patient.selectedCity.isNotEmpty || patient.maxPrice < 100000 || patient.selectedAvailability.isNotEmpty)
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  if (patient.selectedCity.isNotEmpty)
                    _ActiveFilter(label: patient.selectedCity, onRemove: () => patient.setCity('')),
                  if (patient.maxPrice < 100000)
                    _ActiveFilter(label: '≤ ${patient.maxPrice.toStringAsFixed(0)} F', onRemove: () => patient.setMaxPrice(100000)),
                  if (patient.selectedAvailability.isNotEmpty)
                    _ActiveFilter(
                      label: patient.selectedAvailability == 'today' ? 'Aujourd\'hui' : patient.selectedAvailability == 'week' ? 'Cette semaine' : 'Disponible',
                      onRemove: () => patient.setAvailability(''),
                    ),
                ],
              ),
            ),

          // ─── Liste des médecins ───────────────────────────────────────
          Expanded(
            child: patient.doctors.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off_rounded, size: 64, color: AppColors.textLight),
                        const SizedBox(height: 16),
                        Text('Aucun médecin trouvé', style: AppTextStyles.body1.copyWith(color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        Text('Modifiez vos critères de recherche', style: AppTextStyles.body2.copyWith(color: AppColors.textLight)),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () {
                            _searchCtrl.clear();
                            patient.resetFilters();
                          },
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Réinitialiser', style: TextStyle(fontFamily: 'Poppins')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: patient.doctors.length,
                    itemBuilder: (_, i) => DoctorCard(
                      doctor: patient.doctors[i],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          settings: RouteSettings(name: '/patient/doctor-profile', arguments: patient.doctors[i].id),
                          builder: (_) => DoctorProfileScreen(doctor: patient.doctors[i]),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _getSortLabel(String sort) {
    switch (sort) {
      case 'rating': return 'Mieux notés';
      case 'price': return 'Prix ↑';
      case 'price_desc': return 'Prix ↓';
      case 'experience': return 'Expérience';
      case 'distance': return 'Proximité';
      case 'reviews': return 'Avis';
      default: return 'Trier';
    }
  }

  void _showSortOptions(BuildContext context, PatientProvider patient) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.backgroundGrey, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              const Text('Trier par', style: AppTextStyles.heading3),
              const SizedBox(height: 16),
              ...[
                ('rating', Icons.star_rounded, 'Mieux notés'),
                ('reviews', Icons.rate_review_outlined, 'Plus d\'avis'),
                ('price', Icons.arrow_upward_rounded, 'Prix croissant'),
                ('price_desc', Icons.arrow_downward_rounded, 'Prix décroissant'),
                ('experience', Icons.work_outline_rounded, 'Expérience'),
                ('distance', Icons.location_on_outlined, 'Plus proche'),
              ].map((item) => ListTile(
                leading: Icon(item.$2, color: patient.sortBy == item.$1 ? AppColors.primary : AppColors.textSecondary),
                title: Text(item.$3, style: AppTextStyles.body1.copyWith(
                  color: patient.sortBy == item.$1 ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: patient.sortBy == item.$1 ? FontWeight.w700 : FontWeight.normal,
                )),
                trailing: patient.sortBy == item.$1 ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
                onTap: () {
                  patient.setSortBy(item.$1);
                  Navigator.pop(context);
                },
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              )),
            ],
          ),
        ),
      ),
    );
  }

  void _showAdvancedFilters(BuildContext context, PatientProvider patient) {
    double tempMaxPrice = patient.maxPrice;
    String tempCity = patient.selectedCity;
    String tempAvail = patient.selectedAvailability;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, controller) => SingleChildScrollView(
            controller: controller,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.backgroundGrey, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Filtres avancés', style: AppTextStyles.heading3),
                    TextButton(
                      onPressed: () {
                        setModalState(() {
                          tempMaxPrice = 100000;
                          tempCity = '';
                          tempAvail = '';
                        });
                      },
                      child: const Text('Réinitialiser', style: TextStyle(fontFamily: 'Poppins', color: AppColors.error)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ─── Prix max ─────────────────────────────────────────────
                Text('Prix maximum de consultation', style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('5 000 F CFA', style: AppTextStyles.caption),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(color: AppColors.primaryUltraLight, borderRadius: BorderRadius.circular(10)),
                        child: Text(
                          tempMaxPrice >= 100000 ? 'Tous les prix' : '${tempMaxPrice.toStringAsFixed(0)} F CFA',
                          style: AppTextStyles.body2.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const Text('100 000 F', style: AppTextStyles.caption),
                  ],
                ),
                Slider(
                  value: tempMaxPrice.clamp(5000, 100000),
                  min: 5000,
                  max: 100000,
                  divisions: 19,
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.primaryUltraLight,
                  onChanged: (v) => setModalState(() => tempMaxPrice = v),
                ),
                const SizedBox(height: 20),

                // ─── Ville ────────────────────────────────────────────────
                Text('Ville', style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['Abidjan', 'Cocody', 'Plateau', 'Yopougon', 'Bouaké', 'Korhogo', 'San-Pédro'].map((city) {
                    final isSelected = tempCity == city;
                    return GestureDetector(
                      onTap: () => setModalState(() => tempCity = isSelected ? '' : city),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.backgroundGrey,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isSelected ? AppColors.primary : Colors.transparent),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected) ...[const Icon(Icons.check_rounded, size: 14, color: Colors.white), const SizedBox(width: 4)],
                            Text(city, style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: isSelected ? Colors.white : AppColors.textSecondary, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // ─── Disponibilité ────────────────────────────────────────
                Text('Disponibilité', style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ('available', Icons.check_circle_outline_rounded, 'Disponible'),
                    ('today', Icons.today_rounded, 'Aujourd\'hui'),
                    ('week', Icons.date_range_rounded, 'Cette semaine'),
                  ].map((item) {
                    final isSelected = tempAvail == item.$1;
                    return GestureDetector(
                      onTap: () => setModalState(() => tempAvail = isSelected ? '' : item.$1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.success : AppColors.backgroundGrey,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(item.$2, size: 15, color: isSelected ? Colors.white : AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Text(item.$3, style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: isSelected ? Colors.white : AppColors.textSecondary, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // ─── Bouton Appliquer ─────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      patient.setMaxPrice(tempMaxPrice);
                      patient.setCity(tempCity);
                      patient.setAvailability(tempAvail);
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text('Appliquer les filtres', style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Chip filtre actif ────────────────────────────────────────────────────────
class _ActiveFilter extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _ActiveFilter({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
          const SizedBox(width: 5),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded, size: 14, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
