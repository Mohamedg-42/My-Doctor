// lib/features/pharmacie/data/services/pharmacie_location_service.dart
//
// Service de géolocalisation et calcul de proximité des pharmacies de garde.

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/pharmacie_model.dart';

/// Pharmacie enrichie de sa distance par rapport à l'utilisateur
class PharmacieDistanceItem {
  final PharmacieModel pharmacie;
  final double distanceMeters;
  final String formattedDistance;

  const PharmacieDistanceItem({
    required this.pharmacie,
    required this.distanceMeters,
    required this.formattedDistance,
  });
}

class PharmacieLocationService {
  static final PharmacieLocationService _instance =
      PharmacieLocationService._internal();
  static PharmacieLocationService get instance => _instance;

  PharmacieLocationService._internal();

  /// Coordonnées par défaut (Centre d'Abidjan - Cocody / Plateau)
  static const double defaultAbidjanLat = 5.3572;
  static const double defaultAbidjanLng = -3.9871;

  /// Vérifie et demande la permission de géolocalisation
  Future<bool> requestLocationPermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('⚠️ [PharmacieLocationService] Service GPS désactivé');
        return false;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('⚠️ [PharmacieLocationService] Permission GPS refusée');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('⚠️ [PharmacieLocationService] Permission GPS refusée définitivement');
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('❌ [PharmacieLocationService] Erreur permission GPS: $e');
      return false;
    }
  }

  /// Récupère la position GPS actuelle avec timeout court
  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
    } catch (e) {
      debugPrint('⚠️ [PharmacieLocationService] Erreur récupération position: $e');
      return null;
    }
  }

  /// Calcule la distance entre deux points GPS (en mètres)
  double calculateDistanceInMeters({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) {
    try {
      return Geolocator.distanceBetween(fromLat, fromLng, toLat, toLng);
    } catch (_) {
      // Formule Haversine de secours en cas d'environnement sans channel natif
      const r = 6371000.0; // Rayon de la Terre en mètres
      final dLat = (toLat - fromLat) * (pi / 180.0);
      final dLng = (toLng - fromLng) * (pi / 180.0);
      final a = sin(dLat / 2) * sin(dLat / 2) +
          cos(fromLat * (pi / 180.0)) *
              cos(toLat * (pi / 180.0)) *
              sin(dLng / 2) *
              sin(dLng / 2);
      final c = 2 * atan2(sqrt(a), sqrt(1 - a));
      return r * c;
    }
  }

  /// Formate la distance en mètres ou kilomètres
  String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m';
    }
    final km = distanceInMeters / 1000.0;
    return '${km.toStringAsFixed(1)} km';
  }

  /// Trie une liste de pharmacies par proximité croissante
  List<PharmacieDistanceItem> sortPharmaciesByDistance(
    List<PharmacieModel> pharmacies, {
    double? userLat,
    double? userLng,
  }) {
    final lat = userLat ?? defaultAbidjanLat;
    final lng = userLng ?? defaultAbidjanLng;

    final items = pharmacies.map((p) {
      final pLat = p.latitude ?? defaultAbidjanLat;
      final pLng = p.longitude ?? defaultAbidjanLng;
      final meters = calculateDistanceInMeters(
        fromLat: lat,
        fromLng: lng,
        toLat: pLat,
        toLng: pLng,
      );
      return PharmacieDistanceItem(
        pharmacie: p,
        distanceMeters: meters,
        formattedDistance: formatDistance(meters),
      );
    }).toList();

    items.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    return items;
  }

  /// Lance l'itinéraire GPS dans l'application de navigation (Google Maps, Waze, Apple Maps)
  Future<bool> launchGpsItinerary({
    required double latitude,
    required double longitude,
    required String destinationName,
  }) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving',
    );
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('❌ [PharmacieLocationService] Erreur ouverture itinéraire: $e');
    }
    return false;
  }

  /// Compose le numéro de téléphone de la pharmacie
  Future<bool> callPharmacy(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('❌ [PharmacieLocationService] Erreur appel téléphone: $e');
    }
    return false;
  }
}
