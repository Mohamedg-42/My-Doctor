// test/patient_home_screen_test.dart
//
// Tests d'intégration et de navigation pour le tableau de bord patient,
// les abonnements et la carte CMU.

import 'package:flutter_test/flutter_test.dart';
import 'package:allo_docteur/models/user_model.dart';
import 'package:allo_docteur/providers/cmu_provider.dart';
import 'package:allo_docteur/providers/patient_subscription_provider.dart';
import 'package:allo_docteur/models/patient_subscription_model.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Patient Dashboard Navigation & Provider Integration Tests', () {
    test('Initialisation conjointe CMU et Abonnement pour patient connecté', () async {
      final patient = UserModel(
        id: 'pat_test_001',
        firstName: 'Kouamé',
        lastName: 'KOFFI',
        email: 'kouame@example.com',
        phone: '+22501020304',
        role: UserRole.patient,
        cmuNumber: 'CMU-CI998877665',
        commune: 'Yopougon',
        city: 'Abidjan',
        createdAt: DateTime(2024, 6, 1),
      );

      // 1. Initialiser CmuProvider
      final cmuProvider = CmuProvider();
      cmuProvider.initFromUser(patient);

      expect(cmuProvider.hasCard, isTrue);
      expect(cmuProvider.card?.cmuNumber, equals('CMU-CI998877665'));
      expect(cmuProvider.card?.fullName, equals('KOFFI Kouamé'));

      // 2. Initialiser PatientSubscriptionProvider
      final subProvider = PatientSubscriptionProvider();
      await subProvider.initFromUser(patient);

      expect(subProvider.currentSubscription, isNotNull);
      expect(subProvider.currentPlan.id, equals('gratuit'));
      expect(subProvider.currentPlan.isFree, isTrue);

      // 3. Souscription au Plan Famille
      final subOk = await subProvider.subscribeToPlan(
        planId: 'famille',
        cycle: SubscriptionBillingCycle.annuel,
        paymentMethod: 'Orange Money',
      );
      expect(subOk, isTrue);
      expect(subProvider.currentPlan.type, equals(PatientPlanType.famille));
      expect(subProvider.selectedCycle, equals(SubscriptionBillingCycle.annuel));
      expect(subProvider.canAddFamilyMember, isTrue);

      // 4. Ajout de membres famille jusqu'à la limite
      for (int i = 1; i <= 6; i++) {
        final added = await subProvider.addFamilyMember(
          FamilyMember(id: 'm_$i', fullName: 'Membre $i', relationship: 'Enfant'),
        );
        expect(added, isTrue);
      }
      expect(subProvider.familyMembersCount, equals(6));
      expect(subProvider.canAddFamilyMember, isFalse);

      // Tentative d'ajout au-delà de 6 membres (doit refuser)
      final overflowAdd = await subProvider.addFamilyMember(
        FamilyMember(id: 'm_7', fullName: 'Membre 7', relationship: 'Autre'),
      );
      expect(overflowAdd, isFalse);
      expect(subProvider.familyMembersCount, equals(6));

      // 5. Rétrogradation vers le Plan Gratuit
      final downgradeOk = await subProvider.downgradeToFree();
      expect(downgradeOk, isTrue);
      expect(subProvider.currentPlan.id, equals('gratuit'));
      expect(subProvider.familyMembersCount, equals(0));

      // 6. Réinitialisation lors de la déconnexion
      cmuProvider.reset();
      subProvider.reset();

      expect(cmuProvider.hasCard, isFalse);
      expect(subProvider.currentSubscription, isNull);
    });
  });
}
