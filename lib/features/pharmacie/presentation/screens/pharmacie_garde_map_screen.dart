// lib/features/pharmacie/presentation/screens/pharmacie_garde_map_screen.dart
//
// Écran complet de géolocalisation des pharmacies de garde avec détection GPS,
// calcul de distance en temps réel, filtres et lancement direct d'itinéraires.

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/pharmacie_model.dart';
import '../../data/services/pharmacie_location_service.dart';

enum _ViewMode { liste, carte }

class PharmacieGardeMapScreen extends StatefulWidget {
  const PharmacieGardeMapScreen({super.key});

  @override
  State<PharmacieGardeMapScreen> createState() => _PharmacieGardeMapScreenState();
}

class _PharmacieGardeMapScreenState extends State<PharmacieGardeMapScreen> {
  final _searchCtrl = TextEditingController();
  final PharmacieLocationService _locationService = PharmacieLocationService.instance;

  _ViewMode _viewMode = _ViewMode.liste;
  Position? _userPosition;
  bool _isLoadingGps = false;
  String _gpsStatusText = 'Recherche de votre position GPS...';

  String _searchQuery = '';
  String _selectedCommune = 'Toutes';
  bool _onlyCmu = false;
  final bool _onlyGarde = true;

  PharmacieModel? _selectedForPreview;

  final List<String> _communes = const [
    'Toutes',
    'Cocody',
    'Plateau',
    'Yopougon',
    'Marcory',
    'Koumassi',
    'Treichville',
    'Port-Bouët',
    'Abobo',
    'Adjamé',
    'Attécoubé',
    'Bingerville',
    'Anyama',
    'Songon',
  ];

  @override
  void initState() {
    super.initState();
    _detectLocation();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _detectLocation() async {
    if (!mounted) return;
    setState(() {
      _isLoadingGps = true;
      _gpsStatusText = 'Localisation GPS en cours...';
    });

    final position = await _locationService.getCurrentPosition();

    if (!mounted) return;
    setState(() {
      _isLoadingGps = false;
      _userPosition = position;
      if (position != null) {
        _gpsStatusText = 'Position GPS détectée (Précision: ${position.accuracy.toStringAsFixed(0)} m)';
      } else {
        _gpsStatusText = 'GPS inactif • Centré sur Abidjan';
      }
    });
  }

  List<PharmacieDistanceItem> get _filteredAndSortedPharmacies {
    final all = PharmacieDemo.all;

    // 1. Filtrage
    final filtered = all.where((p) {
      if (_onlyGarde && !p.estDeGarde) return false;
      if (_onlyCmu && !p.accepteCmu) return false;
      if (_selectedCommune != 'Toutes' && p.commune.toLowerCase() != _selectedCommune.toLowerCase()) {
        return false;
      }
      final q = _searchQuery.trim().toLowerCase();
      if (q.isNotEmpty) {
        final matchesName = p.nomPharmacie.toLowerCase().contains(q);
        final matchesCommune = p.commune.toLowerCase().contains(q);
        final matchesAddress = p.adresseComplete.toLowerCase().contains(q);
        if (!matchesName && !matchesCommune && !matchesAddress) return false;
      }
      return true;
    }).toList();

    // 2. Tri par proximité
    return _locationService.sortPharmaciesByDistance(
      filtered,
      userLat: _userPosition?.latitude,
      userLng: _userPosition?.longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredAndSortedPharmacies;
    final nearest = items.isNotEmpty ? items.first : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: AppColors.textPrimary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pharmacies de garde',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF059669),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    'Abidjan • ${items.length} disponible${items.length > 1 ? 's' : ''}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: Color(0xFF059669),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Toggle Liste / Carte
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEDF2F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildViewModeButton(
                  icon: LucideIcons.list,
                  mode: _ViewMode.liste,
                  tooltip: 'Vue Liste',
                ),
                _buildViewModeButton(
                  icon: LucideIcons.map,
                  mode: _ViewMode.carte,
                  tooltip: 'Vue Carte',
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Barre Statut GPS & Détection ──────────────────────────────────
          _buildGpsStatusBar(),

          // ─── Barre de recherche et filtres ─────────────────────────────────
          _buildSearchAndFilters(),

          // ─── Contenu (Vue Liste ou Vue Carte) ──────────────────────────────
          Expanded(
            child: _viewMode == _ViewMode.liste
                ? _buildListView(items, nearest)
                : _buildMapView(items, nearest),
          ),
        ],
      ),
    );
  }

  Widget _buildViewModeButton({
    required IconData icon,
    required _ViewMode mode,
    required String tooltip,
  }) {
    final isSelected = _viewMode == mode;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () => setState(() => _viewMode = mode),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF059669) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildGpsStatusBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _userPosition != null
            ? const Color(0xFF059669).withValues(alpha: 0.08)
            : const Color(0xFF6C3CE1).withValues(alpha: 0.08),
        border: Border(
          bottom: BorderSide(
            color: (_userPosition != null ? const Color(0xFF059669) : const Color(0xFF6C3CE1))
                .withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _userPosition != null ? LucideIcons.navigation : LucideIcons.map_pin,
            size: 15,
            color: _userPosition != null ? const Color(0xFF059669) : const Color(0xFF6C3CE1),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _gpsStatusText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _userPosition != null ? const Color(0xFF059669) : const Color(0xFF6C3CE1),
              ),
            ),
          ),
          if (_isLoadingGps)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF059669)),
            )
          else
            InkWell(
              onTap: _detectLocation,
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Row(
                  children: [
                    Icon(LucideIcons.refresh_cw, size: 12, color: Color(0xFF059669)),
                    SizedBox(width: 4),
                    Text(
                      'Actualiser',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: Color(0xFF059669),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        children: [
          // Champ de recherche
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Rechercher une pharmacie, une rue, un quartier...',
                hintStyle: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: AppColors.textLight,
                ),
                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textLight),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Chips de filtres & communes
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // Filtre CMU
                FilterChip(
                  label: const Text('Agrée CMU 💚'),
                  selected: _onlyCmu,
                  onSelected: (val) => setState(() => _onlyCmu = val),
                  selectedColor: const Color(0xFF185FA5),
                  labelStyle: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _onlyCmu ? Colors.white : const Color(0xFF185FA5),
                  ),
                  backgroundColor: const Color(0xFF185FA5).withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                const SizedBox(width: 8),

                // Communes
                ..._communes.map((commune) {
                  final isSelected = commune == _selectedCommune;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(commune),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedCommune = commune),
                      labelStyle: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                      selectedColor: const Color(0xFF059669),
                      backgroundColor: const Color(0xFFF7FAFC),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isSelected ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(List<PharmacieDistanceItem> items, PharmacieDistanceItem? nearest) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.pill, color: Color(0xFF059669), size: 36),
              ),
              const SizedBox(height: 16),
              const Text(
                'Aucune pharmacie trouvée',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Essayez d’élargir vos filtres de recherche ou de changer de commune.',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length + (nearest != null ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, idx) {
        // Mettre en avant la plus proche en haut
        if (nearest != null && idx == 0) {
          return _buildNearestPharmacyBanner(nearest);
        }

        final item = nearest != null ? items[idx - 1] : items[idx];
        return _buildPharmacyCard(item);
      },
    );
  }

  Widget _buildNearestPharmacyBanner(PharmacieDistanceItem item) {
    final p = item.pharmacie;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF047857)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.sparkles, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'LA PLUS PROCHE DE VOUS',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.formattedDistance,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF047857),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            p.nomPharmacie,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(LucideIcons.map_pin, size: 12, color: Colors.white70),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  p.adresseComplete,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final lat = p.latitude ?? PharmacieLocationService.defaultAbidjanLat;
                    final lng = p.longitude ?? PharmacieLocationService.defaultAbidjanLng;
                    _locationService.launchGpsItinerary(
                      latitude: lat,
                      longitude: lng,
                      destinationName: p.nomPharmacie,
                    );
                  },
                  icon: const Icon(LucideIcons.navigation, size: 14, color: Color(0xFF047857)),
                  label: const Text(
                    'Itinéraire GPS',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF047857),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () => _locationService.callPharmacy(p.telephone),
                icon: const Icon(LucideIcons.phone, size: 14, color: Colors.white),
                label: const Text(
                  'Appeler',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPharmacyCard(PharmacieDistanceItem item) {
    final p = item.pharmacie;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre & Distance
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.nomPharmacie,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(LucideIcons.map_pin, size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${p.commune} • ${p.adresseComplete}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.formattedDistance,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF059669),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Badges (24h/24 & CMU)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.moon, size: 10, color: Color(0xFF059669)),
                    SizedBox(width: 4),
                    Text(
                      'Garde 24h/24',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
              ),
              if (p.accepteCmu) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF185FA5).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Agrée CMU',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF185FA5),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // Boutons Actions Rapides
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    final lat = p.latitude ?? PharmacieLocationService.defaultAbidjanLat;
                    final lng = p.longitude ?? PharmacieLocationService.defaultAbidjanLng;
                    _locationService.launchGpsItinerary(
                      latitude: lat,
                      longitude: lng,
                      destinationName: p.nomPharmacie,
                    );
                  },
                  icon: const Icon(LucideIcons.navigation, size: 13, color: Color(0xFF059669)),
                  label: const Text(
                    'Itinéraire',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF059669),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF059669)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _locationService.callPharmacy(p.telephone),
                icon: const Icon(LucideIcons.phone, size: 13, color: Colors.white),
                label: const Text(
                  'Appeler',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Vue Carte Interactive ──────────────────────────────────────────────────
  Widget _buildMapView(List<PharmacieDistanceItem> items, PharmacieDistanceItem? nearest) {
    return Stack(
      children: [
        // Carte visuelle stylisée et interactive
        Positioned.fill(
          child: Container(
            color: const Color(0xFFE8F4F8),
            child: CustomPaint(
              painter: _AbidjanMapPainter(
                pharmacies: items,
                selectedPharma: _selectedForPreview,
              ),
              child: InkWell(
                onTapDown: (details) {
                  // Trouver le marqueur le plus proche du clic
                  final size = MediaQuery.of(context).size;
                  for (final item in items) {
                    final lat = item.pharmacie.latitude ?? 5.3572;
                    final lng = item.pharmacie.longitude ?? -3.9871;
                    final x = _lngToX(lng, size.width);
                    final y = _latToY(lat, size.height * 0.7);

                    final dist = (details.localPosition.dx - x).abs() +
                        (details.localPosition.dy - y).abs();
                    if (dist < 40) {
                      setState(() => _selectedForPreview = item.pharmacie);
                      return;
                    }
                  }
                },
              ),
            ),
          ),
        ),

        // Badge d'info en haut de la carte
        Positioned(
          top: 12,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6),
              ],
            ),
            child: const Row(
              children: [
                Icon(LucideIcons.info, size: 14, color: Color(0xFF059669)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Touchez un repère vert pour afficher les détails et l’itinéraire GPS.',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Card flottante de la pharmacie sélectionnée
        if (_selectedForPreview != null)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedForPreview!.nomPharmacie,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18, color: AppColors.textLight),
                        onPressed: () => setState(() => _selectedForPreview = null),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${_selectedForPreview!.commune} • ${_selectedForPreview!.adresseComplete}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final lat = _selectedForPreview!.latitude ?? 5.3572;
                            final lng = _selectedForPreview!.longitude ?? -3.9871;
                            _locationService.launchGpsItinerary(
                              latitude: lat,
                              longitude: lng,
                              destinationName: _selectedForPreview!.nomPharmacie,
                            );
                          },
                          icon: const Icon(LucideIcons.navigation, size: 14, color: Colors.white),
                          label: const Text(
                            'Itinéraire GPS direct',
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => _locationService.callPharmacy(_selectedForPreview!.telephone),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF059669)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        child: const Icon(LucideIcons.phone, size: 16, color: Color(0xFF059669)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  static double _lngToX(double lng, double width) {
    // Échelle longitude Grand Abidjan [-4.26 (Songon) à -3.87 (Bingerville)]
    const minLng = -4.26;
    const maxLng = -3.87;
    final ratio = (lng - minLng) / (maxLng - minLng);
    return (ratio * width).clamp(20, width - 20);
  }

  static double _latToY(double lat, double height) {
    // Échelle latitude Grand Abidjan [5.23 (Port-Bouët) à 5.51 (Anyama)]
    const minLat = 5.23;
    const maxLat = 5.51;
    final ratio = 1.0 - ((lat - minLat) / (maxLat - minLat));
    return (ratio * height).clamp(40, height - 40);
  }
}

/// Peintre personnalisé représentant la lagune Ébrié, les axes routiers et les repères de pharmacies
class _AbidjanMapPainter extends CustomPainter {
  final List<PharmacieDistanceItem> pharmacies;
  final PharmacieModel? selectedPharma;

  const _AbidjanMapPainter({
    required this.pharmacies,
    this.selectedPharma,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFF3F7F5);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Tracé stylisé de la Lagune Ébrié
    final waterPaint = Paint()
      ..color = const Color(0xFFBCE3F5)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.48);
    path.cubicTo(
      size.width * 0.25,
      size.height * 0.52,
      size.width * 0.55,
      size.height * 0.42,
      size.width,
      size.height * 0.50,
    );
    path.lineTo(size.width, size.height * 0.65);
    path.cubicTo(
      size.width * 0.60,
      size.height * 0.62,
      size.width * 0.30,
      size.height * 0.70,
      0,
      size.height * 0.63,
    );
    path.close();
    canvas.drawPath(path, waterPaint);

    // Axes routiers stylisés (Pont HKB, VGE, Mitterrand)
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    // Boulevard Mitterrand
    canvas.drawLine(
      Offset(size.width * 0.2, size.height * 0.2),
      Offset(size.width * 0.85, size.height * 0.42),
      roadPaint,
    );
    // Boulevard VGE
    canvas.drawLine(
      Offset(size.width * 0.4, size.height * 0.65),
      Offset(size.width * 0.9, size.height * 0.9),
      roadPaint,
    );
    // Pont HKB reliant Marcory à Riviera
    canvas.drawLine(
      Offset(size.width * 0.58, size.height * 0.44),
      Offset(size.width * 0.62, size.height * 0.66),
      roadPaint..strokeWidth = 4.5..color = const Color(0xFFCBD5E1),
    );

    // Repères des pharmacies
    for (int i = 0; i < pharmacies.length; i++) {
      final item = pharmacies[i];
      final p = item.pharmacie;
      final lat = p.latitude ?? 5.3572;
      final lng = p.longitude ?? -3.9871;

      final x = _PharmacieGardeMapScreenState._lngToX(lng, size.width);
      final y = _PharmacieGardeMapScreenState._latToY(lat, size.height);

      final isSelected = selectedPharma?.id == p.id;
      final isNearest = i == 0;

      // Ombre du marqueur
      canvas.drawCircle(
        Offset(x, y + 2),
        isSelected ? 16 : (isNearest ? 14 : 11),
        Paint()..color = Colors.black.withValues(alpha: 0.15),
      );

      // Cercle externe du marqueur
      canvas.drawCircle(
        Offset(x, y),
        isSelected ? 16 : (isNearest ? 14 : 11),
        Paint()..color = isSelected
            ? const Color(0xFF6C3CE1)
            : (isNearest ? const Color(0xFF047857) : const Color(0xFF059669)),
      );

      // Bordure blanche
      canvas.drawCircle(
        Offset(x, y),
        isSelected ? 13 : (isNearest ? 11 : 9),
        Paint()..color = Colors.white,
      );

      // Croix médicale centrale
      final crossPaint = Paint()
        ..color = isSelected
            ? const Color(0xFF6C3CE1)
            : (isNearest ? const Color(0xFF047857) : const Color(0xFF059669))
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;

      const halfCross = 4.0;
      canvas.drawLine(Offset(x - halfCross, y), Offset(x + halfCross, y), crossPaint);
      canvas.drawLine(Offset(x, y - halfCross), Offset(x, y + halfCross), crossPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AbidjanMapPainter oldDelegate) {
    return oldDelegate.pharmacies != pharmacies ||
        oldDelegate.selectedPharma != selectedPharma;
  }
}
