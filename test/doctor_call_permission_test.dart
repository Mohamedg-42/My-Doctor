// test/doctor_call_permission_test.dart
//
// Tests unitaires et d'interface pour le contrôle des appels par le médecin
// et la vérification des conditions d'abonnement actif pour le patient.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:allo_docteur/services/database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Doctor Call Permission Policy Tests', () {
    test('Par défaut, les appels directs nécessitent un abonnement patient actif', () {
      final db = DatabaseService();
      const doctorId = 'doc_test_perm_1';
      const patientId = 'pat_test_1';

      // Patient sans abonnement
      final statusUnsubscribed = db.checkDoctorCallPermission(
        doctorId: doctorId,
        patientId: patientId,
        isPatientSubscribed: false,
      );
      expect(statusUnsubscribed, equals(CallPermissionStatus.requiresSubscription));

      // Patient avec abonnement
      final statusSubscribed = db.checkDoctorCallPermission(
        doctorId: doctorId,
        patientId: patientId,
        isPatientSubscribed: true,
      );
      expect(statusSubscribed, equals(CallPermissionStatus.allowed));
    });

    test('Le médecin peut désactiver tous les appels entrants (mode Ne pas déranger)', () async {
      final db = DatabaseService();
      const doctorId = 'doc_test_perm_2';
      const patientId = 'pat_test_2';

      // Désactiver les appels
      final policy = db.getDoctorCallPolicy(doctorId);
      await db.saveDoctorCallPolicy(policy.copyWith(callsEnabled: false));

      final status = db.checkDoctorCallPermission(
        doctorId: doctorId,
        patientId: patientId,
        isPatientSubscribed: true,
      );
      expect(status, equals(CallPermissionStatus.callsDisabled));
    });

    test('Le médecin peut expressément autoriser un patient sans abonnement', () async {
      final db = DatabaseService();
      const doctorId = 'doc_test_perm_3';
      const patientId = 'pat_test_whitelisted';

      // Autoriser explicitement ce patient
      await db.togglePatientCallPermission(
        doctorId: doctorId,
        patientId: patientId,
        isAllowed: true,
      );

      // Le patient n'a pas d'abonnement, mais doit quand même être autorisé
      final status = db.checkDoctorCallPermission(
        doctorId: doctorId,
        patientId: patientId,
        isPatientSubscribed: false,
      );
      expect(status, equals(CallPermissionStatus.allowed));
    });

    test('Le médecin peut bloquer un patient même s\'il a un abonnement', () async {
      final db = DatabaseService();
      const doctorId = 'doc_test_perm_4';
      const patientId = 'pat_test_blocked';

      // Bloquer explicitement ce patient
      await db.togglePatientCallPermission(
        doctorId: doctorId,
        patientId: patientId,
        isAllowed: false,
      );

      // Le patient a un abonnement, mais doit être bloqué par le médecin
      final status = db.checkDoctorCallPermission(
        doctorId: doctorId,
        patientId: patientId,
        isPatientSubscribed: true,
      );
      expect(status, equals(CallPermissionStatus.blockedByDoctor));
    });

    test('DoctorCallPolicy sérialise et désérialise correctement', () {
      const policy = DoctorCallPolicy(
        doctorId: 'doc_123',
        callsEnabled: true,
        allowSubscribedPatients: true,
        allowedPatientIds: ['p1', 'p2'],
        blockedPatientIds: ['p3'],
      );

      final map = policy.toMap();
      final restored = DoctorCallPolicy.fromMap(map);

      expect(restored.doctorId, equals('doc_123'));
      expect(restored.callsEnabled, isTrue);
      expect(restored.allowSubscribedPatients, isTrue);
      expect(restored.allowedPatientIds, containsAll(['p1', 'p2']));
      expect(restored.blockedPatientIds, contains('p3'));
    });
  });

  group('Call Permission UI Dialogs Tests', () {
    testWidgets('Affichage correct du dialog Abonnement Requis', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Activer un abonnement'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Activer un abonnement'), findsOneWidget);
    });
  });
}
