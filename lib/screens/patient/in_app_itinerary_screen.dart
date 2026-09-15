import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';

enum TravelMode { driving, walking }

class RouteStepItem {
  final String instruction;
  final String distanceText;
  final IconData icon;

  const RouteStepItem({
    required this.instruction,
    required this.distanceText,
    this.icon = LucideIcons.arrow_up,
  });
}

class InAppItineraryScreen extends StatefulWidget {
  final String destinationTitle;
  final String destinationSubtitle;
  final String destinationAddress;
  final double destinationLatitude;
  final double destinationLongitude;
  final String? destinationPhone;
  final String destinationCategory;

  const InAppItineraryScreen({
    super.key,
    required this.destinationTitle,
    this.destinationSubtitle = '',
    this.destinationAddress = 'Abidjan, Côte d\'Ivoire',
    required this.destinationLatitude,
    required this.destinationLongitude,
    this.destinationPhone,
    this.destinationCategory = 'Destination',
  });

  @override
  State<InAppItineraryScreen> createState() => _InAppItineraryScreenState();
}

class _InAppItineraryScreenState extends State<InAppItineraryScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();

  // Position par défaut à Abidjan (Plateau / Cocody) si GPS non accessible
  static const LatLng _defaultAbidjanCenter = LatLng(5.3400, -4.0150);

  LatLng? _userLocation;
  late LatLng _destinationLocation;
  List<LatLng> _routePoints = [];
  List<RouteStepItem> _steps = [];

  bool _isLoadingGps = true;
  bool _isLoadingRoute = true;
  bool _isRealGps = false;
  TravelMode _travelMode = TravelMode.driving;

  double _distanceKm = 0.0;
  int _durationMinutes = 0;
  bool _isGuidanceActive = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _destinationLocation = LatLng(
      widget.destinationLatitude,
      widget.destinationLongitude,
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initGpsAndRoute();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initGpsAndRoute() async {
    setState(() {
      _isLoadingGps = true;
      _isLoadingRoute = true;
    });

    LatLng userPos = _defaultAbidjanCenter;
    bool hasRealGps = false;

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 4),
          ),
        );
        userPos = LatLng(position.latitude, position.longitude);
        hasRealGps = true;
      }
    } catch (_) {
      // Si timeout ou refus, repli gracieux sur position standard
      userPos = _defaultAbidjanCenter;
    }

    if (!mounted) return;
    setState(() {
      _userLocation = userPos;
      _isRealGps = hasRealGps;
      _isLoadingGps = false;
    });

    await _calculateRoute(userPos, _destinationLocation, _travelMode);
    _fitCameraToBounds();
  }

  Future<void> _calculateRoute(
    LatLng start,
    LatLng end,
    TravelMode mode,
  ) async {
    setState(() => _isLoadingRoute = true);

    final profile = mode == TravelMode.driving ? 'driving' : 'walking';
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/$profile/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson&steps=true',
    );

    List<LatLng> points = [];
    List<RouteStepItem> steps = [];
    double distanceKm = 0.0;
    int durationMinutes = 0;

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final routes = data['routes'] as List?;
        if (routes != null && routes.isNotEmpty) {
          final firstRoute = routes[0];
          final geometry = firstRoute['geometry'];
          final coords = geometry['coordinates'] as List?;
          if (coords != null) {
            points = coords
                .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
                .toList();
          }

          final distMeters = (firstRoute['distance'] as num?)?.toDouble() ?? 0.0;
          final durSeconds = (firstRoute['duration'] as num?)?.toDouble() ?? 0.0;
          distanceKm = distMeters / 1000.0;
          durationMinutes = (durSeconds / 60.0).ceil();

          // Étapes de navigation
          final legs = firstRoute['legs'] as List?;
          if (legs != null && legs.isNotEmpty) {
            final rawSteps = legs[0]['steps'] as List?;
            if (rawSteps != null) {
              for (final s in rawSteps) {
                final man = s['maneuver'];
                final type = man?['type'] as String? ?? 'straight';
                final mod = man?['modifier'] as String? ?? '';
                final name = s['name'] as String? ?? '';
                final stepDist = (s['distance'] as num?)?.toDouble() ?? 0.0;

                String instruction = 'Continuer tout droit';
                IconData icon = LucideIcons.arrow_up;

                if (type == 'depart') {
                  instruction = 'Départ depuis votre position actuelle';
                  icon = LucideIcons.map_pin;
                } else if (type == 'arrive') {
                  instruction = 'Arrivée à ${widget.destinationTitle}';
                  icon = LucideIcons.flag;
                } else if (mod.contains('left')) {
                  instruction = name.isNotEmpty
                      ? 'Tourner à gauche sur $name'
                      : 'Tourner à gauche';
                  icon = LucideIcons.arrow_up_left;
                } else if (mod.contains('right')) {
                  instruction = name.isNotEmpty
                      ? 'Tourner à droite sur $name'
                      : 'Tourner à droite';
                  icon = LucideIcons.arrow_up_right;
                } else if (name.isNotEmpty) {
                  instruction = 'Suivre $name';
                }

                String distLabel = stepDist > 1000
                    ? '${(stepDist / 1000).toStringAsFixed(1)} km'
                    : '${stepDist.round()} m';

                steps.add(RouteStepItem(
                  instruction: instruction,
                  distanceText: distLabel,
                  icon: icon,
                ));
              }
            }
          }
        }
      }
    } catch (_) {
      // Fallback local hors-ligne / timeout
    }

    // Si le service externe n'a pas répondu ou liste vide, tracé géodésique fluide
    if (points.isEmpty) {
      points = _generateFallbackRoute(start, end);
      final rawDistKm = _calculateHaversineKm(start, end) * 1.35; // Facteur route urbaine
      distanceKm = double.parse(rawDistKm.toStringAsFixed(1));
      final speedKmh = mode == TravelMode.driving ? 32.0 : 4.5;
      durationMinutes = math.max(1, ((distanceKm / speedKmh) * 60).round());

      steps = [
        const RouteStepItem(
          instruction: 'Départ depuis votre position',
          distanceText: '0 m',
          icon: LucideIcons.map_pin,
        ),
        RouteStepItem(
          instruction: 'Prendre la voie principale vers ${widget.destinationAddress}',
          distanceText: '${(distanceKm * 0.4).toStringAsFixed(1)} km',
          icon: LucideIcons.arrow_up,
        ),
        RouteStepItem(
          instruction: 'Continuer tout droit en direction de la destination',
          distanceText: '${(distanceKm * 0.4).toStringAsFixed(1)} km',
          icon: LucideIcons.navigation,
        ),
        RouteStepItem(
          instruction: 'Arrivée à ${widget.destinationTitle}',
          distanceText: '${(distanceKm * 0.2).toStringAsFixed(1)} km',
          icon: LucideIcons.flag,
        ),
      ];
    }

    if (!mounted) return;
    setState(() {
      _routePoints = points;
      _steps = steps;
      _distanceKm = distanceKm;
      _durationMinutes = durationMinutes;
      _isLoadingRoute = false;
    });
  }

  List<LatLng> _generateFallbackRoute(LatLng start, LatLng end) {
    final List<LatLng> list = [start];
    // Points intermédiaires simulant les artères routières
    final midLat1 = start.latitude + (end.latitude - start.latitude) * 0.35 + 0.0015;
    final midLng1 = start.longitude + (end.longitude - start.longitude) * 0.30 - 0.0012;
    final midLat2 = start.latitude + (end.latitude - start.latitude) * 0.70 - 0.0010;
    final midLng2 = start.longitude + (end.longitude - start.longitude) * 0.75 + 0.0015;

    list.add(LatLng(midLat1, midLng1));
    list.add(LatLng(midLat2, midLng2));
    list.add(end);
    return list;
  }

  double _calculateHaversineKm(LatLng p1, LatLng p2) {
    const r = 6371.0;
    final dLat = _degToRad(p2.latitude - p1.latitude);
    final dLng = _degToRad(p2.longitude - p1.longitude);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(p1.latitude)) *
            math.cos(_degToRad(p2.latitude)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  double _degToRad(double deg) => deg * (math.pi / 180.0);

  void _fitCameraToBounds() {
    if (_userLocation == null) return;
    try {
      final points = [_userLocation!, _destinationLocation];
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(points),
          padding: const EdgeInsets.only(
            top: 100,
            left: 50,
            right: 50,
            bottom: 260,
          ),
        ),
      );
    } catch (_) {
      // Évite tout crash si la caméra s'anime avant build complet
    }
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom + 1.0);
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom - 1.0);
  }

  Future<void> _callDestination() async {
    if (widget.destinationPhone == null || widget.destinationPhone!.isEmpty) return;
    final cleanPhone = widget.destinationPhone!.replaceAll(RegExp(r'[\s\-]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openExternalMaps() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${widget.destinationLatitude},${widget.destinationLongitude}&travelmode=${_travelMode == TravelMode.driving ? 'driving' : 'walking'}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final startPos = _userLocation ?? _defaultAbidjanCenter;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── 1. Carte Interactive OpenStreetMap (FlutterMap) ──
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: startPos,
                initialZoom: 13.5,
                minZoom: 4.0,
                maxZoom: 18.5,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.allodocteur.my_doctor',
                ),

                // Tracé d'itinéraire (Polyline)
                if (_routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      // Ombre / halo extérieur contrasté
                      Polyline(
                        points: _routePoints,
                        strokeWidth: 8.0,
                        color: const Color(0xFF1E3A8A).withValues(alpha: 0.25),
                      ),
                      // Ligne dynamique de navigation
                      Polyline(
                        points: _routePoints,
                        strokeWidth: 4.5,
                        color: _travelMode == TravelMode.driving
                            ? AppColors.brandBlue
                            : const Color(0xFF059669),
                      ),
                    ],
                  ),

                // Marqueurs : Patient + Destination
                MarkerLayer(
                  markers: [
                    // Marqueur Départ (Utilisateur)
                    Marker(
                      point: startPos,
                      width: 50,
                      height: 50,
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 34 * _pulseAnimation.value,
                                height: 34 * _pulseAnimation.value,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.brandBlue.withValues(alpha: 0.25),
                                ),
                              ),
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.brandBlue,
                                  border: Border.all(color: Colors.white, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.25),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.my_location_rounded,
                                  size: 11,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    // Marqueur Arrivée (Cabinet Médical / Pharmacie)
                    Marker(
                      point: _destinationLocation,
                      width: 70,
                      height: 70,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.brandNavy,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Text(
                              'Arrivée',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFDC2626),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFDC2626).withValues(alpha: 0.45),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              LucideIcons.cross,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── 2. Barre Supérieure Flottante (Retour + Titre Destination) ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.textPrimary,
                    ),
                    tooltip: 'Retour',
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.destinationTitle,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          widget.destinationAddress,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (_isLoadingRoute || _isLoadingGps)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: AppColors.brandBlue,
                        ),
                      ),
                    )
                  else
                    IconButton(
                      icon: const Icon(LucideIcons.maximize_2, size: 18),
                      color: AppColors.textSecondary,
                      tooltip: 'Recentrer',
                      onPressed: _fitCameraToBounds,
                    ),
                ],
              ),
            ),
          ),

          // ── Bannière indicative si GPS approximatif ──
          if (!_isRealGps && !_isLoadingGps)
            Positioned(
              top: MediaQuery.of(context).padding.top + 72,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.warningBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      LucideIcons.info,
                      size: 14,
                      color: AppColors.warning,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Position GPS de départ estimée (Abidjan)',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.warning,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── 3. Boutons Contrôles Flottants de la Carte (Zoom & Recadrer) ──
          Positioned(
            right: 16,
            bottom: 250,
            child: Column(
              children: [
                _buildMapFloatingButton(
                  icon: Icons.add_rounded,
                  onTap: _zoomIn,
                  tooltip: 'Zoom avant',
                ),
                const SizedBox(height: 8),
                _buildMapFloatingButton(
                  icon: Icons.remove_rounded,
                  onTap: _zoomOut,
                  tooltip: 'Zoom arrière',
                ),
                const SizedBox(height: 8),
                _buildMapFloatingButton(
                  icon: Icons.my_location_rounded,
                  onTap: () {
                    if (_userLocation != null) {
                      _mapController.move(_userLocation!, 15.0);
                    }
                  },
                  tooltip: 'Ma position',
                  iconColor: AppColors.brandBlue,
                ),
              ],
            ),
          ),

          // ── 4. Feuille de Route Inférieure (Itinéraire In-App) ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildMapFloatingButton({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
    Color? iconColor,
  }) {
    return Material(
      color: Colors.white,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(
            icon,
            size: 20,
            color: iconColor ?? AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    final etaTime = DateTime.now().add(Duration(minutes: _durationMinutes));
    final etaHour = etaTime.hour.toString().padLeft(2, '0');
    final etaMinute = etaTime.minute.toString().padLeft(2, '0');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Barre de préhension
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sélecteur de mode de transport (Voiture vs Marche)
                  Row(
                    children: [
                      Expanded(
                        child: _buildModeTab(
                          title: 'En voiture',
                          mode: TravelMode.driving,
                          icon: LucideIcons.car,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildModeTab(
                          title: 'À pied',
                          mode: TravelMode.walking,
                          icon: LucideIcons.footprints,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Résumé du trajet (Temps • Distance • Heure d'arrivée)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (_travelMode == TravelMode.driving
                                    ? AppColors.brandBlue
                                    : const Color(0xFF059669))
                                .withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _travelMode == TravelMode.driving
                                ? LucideIcons.navigation_2
                                : LucideIcons.footprints,
                            size: 20,
                            color: _travelMode == TravelMode.driving
                                ? AppColors.brandBlue
                                : const Color(0xFF059669),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      '$_durationMinutes min',
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      '($_distanceKm km)',
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'Arrivée estimée à $etaHour:$etaMinute',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Bouton d'action pour déplier les étapes
                        TextButton.icon(
                          onPressed: _showStepsModal,
                          icon: const Icon(LucideIcons.list, size: 14),
                          label: const Text(
                            'Étapes',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.brandBlue,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Actions principales : Démarrer guidage + Appeler + Option Maps
                  Row(
                    children: [
                      // Bouton principal de guidage in-app
                      Expanded(
                        flex: 3,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _isGuidanceActive = !_isGuidanceActive;
                            });
                            if (_isGuidanceActive && _userLocation != null) {
                              _mapController.move(_userLocation!, 16.5);
                            }
                          },
                          icon: Icon(
                            _isGuidanceActive ? LucideIcons.pause : LucideIcons.navigation,
                            size: 16,
                            color: Colors.white,
                          ),
                          label: Text(
                            _isGuidanceActive ? 'Arrêter guidage' : 'Démarrer guidage',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isGuidanceActive
                                ? AppColors.brandCoral
                                : AppColors.brandBlue,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),

                      // Bouton Appeler (si numéro fourni)
                      if (widget.destinationPhone != null &&
                          widget.destinationPhone!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: OutlinedButton(
                            onPressed: _callDestination,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.brandTurquoise),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              foregroundColor: AppColors.brandTurquoise,
                            ),
                            child: const Icon(Icons.phone_rounded, size: 18),
                          ),
                        ),
                      ],

                      // Bouton d'échappement vers Google Maps externe (au besoin)
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: OutlinedButton(
                          onPressed: _openExternalMaps,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.borderSubtle),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            foregroundColor: AppColors.textSecondary,
                          ),
                          child: const Icon(LucideIcons.external_link, size: 18),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeTab({
    required String title,
    required TravelMode mode,
    required IconData icon,
  }) {
    final isSelected = _travelMode == mode;
    return InkWell(
      onTap: () {
        if (!isSelected) {
          setState(() => _travelMode = mode);
          if (_userLocation != null) {
            _calculateRoute(_userLocation!, _destinationLocation, mode);
          }
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandBlue : AppColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.brandBlue : AppColors.borderSubtle,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStepsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.7,
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(LucideIcons.list_ordered, size: 20, color: AppColors.brandBlue),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Feuille de route détaillée',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: _steps.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucune étape détaillée disponible.',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _steps.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final step = _steps[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceSubtle,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                step.icon,
                                size: 18,
                                color: AppColors.brandBlue,
                              ),
                            ),
                            title: Text(
                              step.instruction,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            trailing: Text(
                              step.distanceText,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
