// test/cmu_test.dart
//
// Tests unitaires complets pour le modèle et le provider de la Carte CMU-CI.

import 'package:flutter_test/flutter_test.dart';
import 'package:allo_docteur/models/cmu_model.dart';
import 'package:allo_docteur/providers/cmu_provider.dart';
import 'package:allo_docteur/models/user_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CmuCard Model Tests', () {
    test('Calcul des dates et propriétés de la carte', () {
      final card = CmuCard(
        cmuNumber: 'CMU-CI123456789',
        lastName: 'KOUASSI',
        firstName: 'Jean-Marc',
        gender: 'Homme',
        profession: 'Ingénieur',
        commune: 'Cocody',
        city: 'Abidjan',
        birthDate: DateTime(1988, 7, 14),
        issueDate: DateTime(2024, 1, 1),
        expiryDate: DateTime(2026, 1, 1),
        isActive: true,
      );

      expect(card.fullName, equals('KOUASSI Jean-Marc'));
      expect(card.formattedBirthDate, equals('14/07/1988'));
      expect(card.formattedIssueDate, equals('01/01/2024'));
      expect(card.formattedExpiryDate, equals('01/01/2026'));
      expect(card.isActive, isTrue);
    });
  });

  group('HealthMetric Status Tests', () {
    test('Tension artérielle status labels', () {
      final bpNormal = HealthMetric(
        id: '1',
        type: HealthMetricType.bloodPressure,
        value: 120,
        value2: 80,
        unit: 'mmHg',
        recordedAt: DateTime.now(),
      );
      expect(bpNormal.statusLabel, equals('Normale'));
      expect(bpNormal.displayValue, equals('120/80'));

      final bpLow = HealthMetric(
        id: '2',
        type: HealthMetricType.bloodPressure,
        value: 85,
        value2: 55,
        unit: 'mmHg',
        recordedAt: DateTime.now(),
      );
      expect(bpLow.statusLabel, equals('Basse'));
    });

    test('Glycémie status labels', () {
      final sugarNormal = HealthMetric(
        id: '3',
        type: HealthMetricType.bloodSugar,
        value: 0.98,
        unit: 'g/L',
        recordedAt: DateTime.now(),
      );
      expect(sugarNormal.statusLabel, equals('Normale'));

      final sugarHigh = HealthMetric(
        id: '4',
        type: HealthMetricType.bloodSugar,
        value: 1.45,
        unit: 'g/L',
        recordedAt: DateTime.now(),
      );
      expect(sugarHigh.statusLabel, equals('Diabète'));
    });

    test('Saturation O2 status labels', () {
      final satNormal = HealthMetric(
        id: '5',
        type: HealthMetricType.oxygenSaturation,
        value: 98,
        unit: '%',
        recordedAt: DateTime.now(),
      );
      expect(satNormal.statusLabel, equals('Normale'));

      final satLow = HealthMetric(
        id: '6',
        type: HealthMetricType.oxygenSaturation,
        value: 92,
        unit: '%',
        recordedAt: DateTime.now(),
      );
      expect(satLow.statusLabel, equals('Faible'));
    });
  });

  group('CostComparison Tests', () {
    test('Calcul des économies et pourcentages', () {
      final cost = CostComparison(
        careType: 'Consultation généraliste',
        description: 'Visite chez le médecin traitant',
        withoutCmu: 10000,
        withCmu: 3000,
        category: 'Consultation',
      );

      expect(cost.savings, equals(7000));
      expect(cost.savingsPercent, equals(70.0));
    });

    test('Prestation accouchement normal avec 100% de prise en charge', () {
      final cost = CostComparison(
        careType: 'Accouchement normal',
        description: 'Maternité + séjour 3j',
        withoutCmu: 200000,
        withCmu: 0,
        category: 'Maternité',
      );

      expect(cost.savings, equals(200000));
      expect(cost.savingsPercent, equals(100.0));
    });
  });

  group('CmuProvider Tests', () {
    test('Initialisation dynamique depuis UserModel', () {
      final provider = CmuProvider();
      final user = UserModel(
        id: 'user_pat_1',
        firstName: 'Aminata',
        lastName: 'DIALLO',
        email: 'aminata@example.com',
        phone: '+22507080910',
        role: UserRole.patient,
        cmuNumber: 'CMU-CI556677889',
        commune: 'Plateau',
        city: 'Abidjan',
        createdAt: DateTime(2025, 1, 1),
      );

      provider.initFromUser(user);
      expect(provider.hasCard, isTrue);
      expect(provider.card?.cmuNumber, equals('CMU-CI556677889'));
      expect(provider.card?.fullName, equals('DIALLO Aminata'));

      provider.reset();
      expect(provider.hasCard, isFalse);
    });

    test('Calcul du total des économies et prestations', () {
      final provider = CmuProvider();
      expect(provider.benefits.length, equals(10));
      expect(provider.costComparisons.length, equals(10));
      expect(provider.totalSavings, greaterThan(0));
    });

    test('Parsing flexible de la date de naissance (DD/MM/YYYY et ISO)', () {
      // Format français courant
      final d1 = UserModel.parseFlexibleDate('15/05/1990');
      expect(d1, isNotNull);
      expect(d1!.day, equals(15));
      expect(d1.month, equals(5));
      expect(d1.year, equals(1990));

      // Format ISO
      final d2 = UserModel.parseFlexibleDate('1995-08-22');
      expect(d2, isNotNull);
      expect(d2!.day, equals(22));
      expect(d2.month, equals(8));
      expect(d2.year, equals(1995));

      // DateTime direct
      final d3 = UserModel.parseFlexibleDate(DateTime(1984, 11, 10));
      expect(d3, isNotNull);
      expect(d3!.year, equals(1984));

      // Null ou vide
      expect(UserModel.parseFlexibleDate(null), isNull);
      expect(UserModel.parseFlexibleDate(''), isNull);
    });

    test('UserModel formattedBirthDate et transmission à CmuCard', () {
      final birth = UserModel.parseFlexibleDate('22/08/1995');
      final user = UserModel(
        id: 'pat_test_1',
        firstName: 'Jean',
        lastName: 'Kouassi',
        email: 'jean@test.com',
        phone: '+22501020304',
        role: UserRole.patient,
        birthDate: birth,
        createdAt: DateTime(2025, 1, 1),
      );

      expect(user.formattedBirthDate, equals('22/08/1995'));

      final provider = CmuProvider();
      provider.initFromUser(user);
      expect(provider.card?.formattedBirthDate, equals('22/08/1995'));
    });
  });
}

