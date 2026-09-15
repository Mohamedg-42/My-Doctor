// test/patient_subscription_test.dart
//
// Tests unitaires complets pour le module Abonnements Santé patient.

import 'package:flutter_test/flutter_test.dart';
import 'package:allo_docteur/models/patient_subscription_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PatientSubscriptionPlan Tests', () {
    final plans = PatientSubscriptionPlan.defaultPlans;

    test('Contient exactement 4 formules', () {
      expect(plans.length, equals(4));
      expect(plans.map((p) => p.id).toList(), equals(['gratuit', 'essentiel', 'confort', 'famille']));
    });

    test('Plan Gratuit configuration exacte', () {
      final freePlan = plans.firstWhere((p) => p.id == 'gratuit');
      expect(freePlan.name, equals('Plan Gratuit'));
      expect(freePlan.monthlyPrice, equals(0));
      expect(freePlan.yearlyPrice, equals(0));
      expect(freePlan.isFree, isTrue);
      expect(freePlan.maxFamilyMembers, equals(1));
      expect(freePlan.teleconsultationsIncluded, equals(0));
      expect(freePlan.priceFormatted(SubscriptionBillingCycle.mensuel), equals('0 FCFA/mois'));
      expect(freePlan.priceFormatted(SubscriptionBillingCycle.annuel), equals('0 FCFA/an'));
    });

    test('Plan Essentiel configuration exacte', () {
      final essentiel = plans.firstWhere((p) => p.id == 'essentiel');
      expect(essentiel.name, equals('Plan Essentiel'));
      expect(essentiel.monthlyPrice, equals(1500));
      expect(essentiel.yearlyPrice, equals(15000));
      expect(essentiel.teleconsultationsIncluded, equals(1));
      expect(essentiel.maxFamilyMembers, equals(1));
      expect(essentiel.priceFormatted(SubscriptionBillingCycle.mensuel), equals('1 500 FCFA/mois'));
      expect(essentiel.priceFormatted(SubscriptionBillingCycle.annuel), equals('15 000 FCFA/an'));
    });

    test('Plan Confort configuration exacte', () {
      final confort = plans.firstWhere((p) => p.id == 'confort');
      expect(confort.name, equals('Plan Confort'));
      expect(confort.monthlyPrice, equals(3500));
      expect(confort.yearlyPrice, equals(35000));
      expect(confort.teleconsultationsIncluded, equals(3));
      expect(confort.maxFamilyMembers, equals(1));
      expect(confort.priceFormatted(SubscriptionBillingCycle.mensuel), equals('3 500 FCFA/mois'));
      expect(confort.priceFormatted(SubscriptionBillingCycle.annuel), equals('35 000 FCFA/an'));
    });

    test('Plan Famille configuration exacte', () {
      final famille = plans.firstWhere((p) => p.id == 'famille');
      expect(famille.name, equals('Plan Famille'));
      expect(famille.monthlyPrice, equals(6500));
      expect(famille.yearlyPrice, equals(65000));
      expect(famille.teleconsultationsIncluded, equals(6));
      expect(famille.maxFamilyMembers, equals(6));
      expect(famille.priceFormatted(SubscriptionBillingCycle.mensuel), equals('6 500 FCFA/mois'));
      expect(famille.priceFormatted(SubscriptionBillingCycle.annuel), equals('65 000 FCFA/an'));
    });
  });

  group('FamilyMember Model Tests', () {
    test('Sérialisation et désérialisation JSON', () {
      final member = FamilyMember(
        id: 'mem_1',
        fullName: 'KOUAME Aude',
        relationship: 'Conjoint(e)',
        cmuNumber: 'CMU-CI987654321',
        birthDate: DateTime(1995, 5, 20),
      );

      final json = member.toJson();
      expect(json['id'], equals('mem_1'));
      expect(json['fullName'], equals('KOUAME Aude'));
      expect(json['relationship'], equals('Conjoint(e)'));
      expect(json['cmuNumber'], equals('CMU-CI987654321'));

      final reconstructed = FamilyMember.fromJson(json);
      expect(reconstructed.id, equals(member.id));
      expect(reconstructed.fullName, equals(member.fullName));
      expect(reconstructed.relationship, equals(member.relationship));
      expect(reconstructed.cmuNumber, equals(member.cmuNumber));
      expect(reconstructed.birthDate?.year, equals(1995));
    });
  });

  group('PatientSubscription Model Tests', () {
    test('Calcul expiration et état gratuit', () {
      final now = DateTime.now();
      final activeSub = PatientSubscription(
        patientId: 'pat_001',
        planId: 'famille',
        cycle: SubscriptionBillingCycle.annuel,
        startDate: now,
        endDate: now.add(const Duration(days: 365)),
        paymentMethod: 'Orange Money',
      );

      expect(activeSub.isExpired, isFalse);
      expect(activeSub.isFree, isFalse);

      final expiredSub = activeSub.copyWith(
        endDate: now.subtract(const Duration(days: 1)),
      );
      expect(expiredSub.isExpired, isTrue);

      final freeSub = activeSub.copyWith(planId: 'gratuit');
      expect(freeSub.isFree, isTrue);
    });

    test('Conversion JSON avec membres de la famille', () {
      final now = DateTime.now();
      final sub = PatientSubscription(
        patientId: 'pat_123',
        planId: 'famille',
        cycle: SubscriptionBillingCycle.mensuel,
        startDate: now,
        endDate: now.add(const Duration(days: 30)),
        paymentMethod: 'Wave',
        familyMembers: [
          FamilyMember(id: 'f1', fullName: 'Membre 1', relationship: 'Enfant'),
          FamilyMember(id: 'f2', fullName: 'Membre 2', relationship: 'Parent (Père/Mère)'),
        ],
      );

      final json = sub.toJson();
      expect(json['patientId'], equals('pat_123'));
      expect(json['planId'], equals('famille'));
      expect(json['cycle'], equals('mensuel'));
      expect((json['familyMembers'] as List).length, equals(2));

      final restored = PatientSubscription.fromJson(json);
      expect(restored.patientId, equals('pat_123'));
      expect(restored.familyMembers.length, equals(2));
      expect(restored.familyMembers.first.fullName, equals('Membre 1'));
    });
  });
}
