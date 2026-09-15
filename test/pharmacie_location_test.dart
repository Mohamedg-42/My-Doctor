import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:allo_docteur/features/pharmacie/data/models/pharmacie_model.dart';
import 'package:allo_docteur/features/pharmacie/data/services/pharmacie_location_service.dart';
import 'package:allo_docteur/features/pharmacie/presentation/screens/pharmacie_garde_map_screen.dart';

void main() {
  group('Pharmacie Location Service & Geolocation Tests', () {
    final service = PharmacieLocationService.instance;

    test('Default coordinates are set to Abidjan center', () {
      expect(PharmacieLocationService.defaultAbidjanLat, closeTo(5.357, 0.01));
      expect(PharmacieLocationService.defaultAbidjanLng, closeTo(-3.987, 0.01));
    });

    test('calculateDistanceInMeters returns accurate distances between Abidjan communes', () {
      // Cocody (5.3572, -3.9871) to Plateau (5.3235, -4.0195)
      final distance = service.calculateDistanceInMeters(
        fromLat: 5.3572,
        fromLng: -3.9871,
        toLat: 5.3235,
        toLng: -4.0195,
      );

      // Environ 5 km à vol d'oiseau entre Cocody et Plateau
      expect(distance, greaterThan(3000));
      expect(distance, lessThan(8000));
    });

    test('formatDistance formats correctly in meters (<1000m) and kilometers (>=1000m)', () {
      expect(service.formatDistance(450), equals('450 m'));
      expect(service.formatDistance(999), equals('999 m'));
      expect(service.formatDistance(1000), equals('1.0 km'));
      expect(service.formatDistance(2450), equals('2.5 km'));
      expect(service.formatDistance(12800), equals('12.8 km'));
    });

    test('sortPharmaciesByDistance sorts pharmacies nearest first', () {
      final pharmacies = PharmacieDemo.all;
      expect(pharmacies, isNotEmpty);

      // Utilisateur situé à Cocody Saint Jean (5.3444, -4.0042)
      final sorted = service.sortPharmaciesByDistance(
        pharmacies,
        userLat: 5.3444,
        userLng: -4.0042,
      );

      expect(sorted.length, equals(pharmacies.length));
      // La première pharmacie doit être plus proche que la dernière
      expect(sorted.first.distanceMeters, lessThan(sorted.last.distanceMeters));
      // Pharmacie Saint Jean (Cocody) est exactement à cette position (0m)
      expect(sorted.first.pharmacie.commune, equals('Cocody'));
      expect(sorted.first.distanceMeters, lessThan(100));
    });

    test('PharmacieDemo contains realistic Abidjan pharmacies with valid GPS coordinates', () {
      final all = PharmacieDemo.all;
      expect(all.length, greaterThanOrEqualTo(30));

      for (final p in all) {
        expect(p.latitude, isNotNull);
        expect(p.longitude, isNotNull);

        // Bornes GPS du district de Grand Abidjan (de Songon à Bingerville, de Port-Bouët à Anyama)
        expect(p.latitude!, inInclusiveRange(5.20, 5.55));
        expect(p.longitude!, inInclusiveRange(-4.30, -3.85));
        expect(p.telephone, startsWith('+225'));
        expect(p.commune, isNotEmpty);
      }
    });

    test('PharmacieDemo covers all 13 communes of Grand Abidjan', () {
      final communes = PharmacieDemo.all.map((p) => p.commune).toSet();
      final expectedCommunes = {
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
      };
      expect(communes, containsAll(expectedCommunes));
    });

    test('PharmacieModel copyWith preserves accepteCmu and coordinates', () {
      final original = PharmacieDemo.pharma1;
      final copied = original.copyWith(
        accepteCmu: false,
        nomPharmacie: 'Pharmacie Test Modifiée',
      );

      expect(copied.accepteCmu, isFalse);
      expect(copied.nomPharmacie, equals('Pharmacie Test Modifiée'));
      expect(copied.latitude, equals(original.latitude));
      expect(copied.longitude, equals(original.longitude));
    });
  });

  group('PharmacieGardeMapScreen Widget Tests', () {
    testWidgets('PharmacieGardeMapScreen renders, displays header, search, and switches view modes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PharmacieGardeMapScreen(),
        ),
      );

      // Effectue quelques pumps pour initialiser les frames sans bloquer sur les animations en boucle
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Vérifie l'AppBar et le titre
      expect(find.text('Pharmacies de garde'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // Vérifie la présence de chips de commune
      expect(find.text('Toutes'), findsOneWidget);
      expect(find.text('Cocody'), findsOneWidget);

      // Vérifie la vue liste par défaut
      expect(find.text('LA PLUS PROCHE DE VOUS'), findsOneWidget);

      // Bascule vers la vue Carte
      final mapIconButton = find.byTooltip('Vue Carte');
      expect(mapIconButton, findsOneWidget);
      await tester.tap(mapIconButton);
      await tester.pump(const Duration(milliseconds: 100));

      // Vérifie l'info bulle de la carte
      expect(find.textContaining('Touchez un repère vert'), findsOneWidget);

      // Rebascule vers la vue Liste
      final listIconButton = find.byTooltip('Vue Liste');
      expect(listIconButton, findsOneWidget);
      await tester.tap(listIconButton);
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('LA PLUS PROCHE DE VOUS'), findsOneWidget);
    });
  });
}
