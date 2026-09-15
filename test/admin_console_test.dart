// test/admin_console_test.dart
//
// Tests unitaires et d'interface pour le module Administrateur de My Doctor.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:allo_docteur/models/user_model.dart';
import 'package:allo_docteur/core/routing/route_persistence_service.dart';
import 'package:allo_docteur/models/treating_doctor_request_model.dart';
import 'package:allo_docteur/screens/admin/components/admin_header.dart';
import 'package:allo_docteur/screens/admin/components/admin_kpi_card.dart';
import 'package:allo_docteur/screens/admin/components/admin_empty_state.dart';
import 'package:allo_docteur/screens/admin/components/admin_error_view.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await RoutePersistenceService.init();
  });

  group('Admin UserModel & Role Authorization Tests', () {
    final activeAdmin = UserModel(
      id: 'admin-1',
      firstName: 'Admin',
      lastName: 'Super',
      phone: '0101010101',
      email: 'admin@mydoctor.ci',
      role: UserRole.admin,
      status: AccountStatus.active,
      createdAt: DateTime.now(),
    );

    final suspendedAdmin = UserModel(
      id: 'admin-2',
      firstName: 'Admin',
      lastName: 'Blocked',
      phone: '0101010102',
      email: 'blocked@mydoctor.ci',
      role: UserRole.admin,
      status: AccountStatus.suspended,
      createdAt: DateTime.now(),
    );

    final patientUser = UserModel(
      id: 'pat-1',
      firstName: 'Jean',
      lastName: 'Kouassi',
      phone: '0707070707',
      email: 'jean@patient.ci',
      role: UserRole.patient,
      status: AccountStatus.active,
      createdAt: DateTime.now(),
    );

    final doctorUser = UserModel(
      id: 'doc-1',
      firstName: 'Fatou',
      lastName: 'Diallo',
      phone: '0505050505',
      email: 'fatou@doctor.ci',
      role: UserRole.doctor,
      status: AccountStatus.active,
      createdAt: DateTime.now(),
    );

    test('Identification correcte des rôles et statuts d\'accès administrateur', () {
      bool canAccessAdmin(UserModel? u) =>
          u != null && u.role == UserRole.admin && u.status == AccountStatus.active;

      expect(canAccessAdmin(activeAdmin), isTrue);
      expect(canAccessAdmin(suspendedAdmin), isFalse);
      expect(canAccessAdmin(patientUser), isFalse);
      expect(canAccessAdmin(doctorUser), isFalse);
      expect(canAccessAdmin(null), isFalse);
    });

    test('Propriétés utilisateur admin formatées', () {
      expect(activeAdmin.fullName, equals('SUPER Admin'));
      expect(activeAdmin.role, equals(UserRole.admin));
      expect(activeAdmin.status, equals(AccountStatus.active));
    });
  });

  group('Admin Route Persistence & Clamping Tests', () {
    test('Clamping de tab admin sécurisé', () async {
      await RoutePersistenceService.saveTab('admin', 15);
      expect(RoutePersistenceService.getCachedTab('admin'), equals(9));

      await RoutePersistenceService.saveTab('admin', -5);
      expect(RoutePersistenceService.getCachedTab('admin'), equals(0));

      await RoutePersistenceService.saveTab('admin', 3);
      expect(RoutePersistenceService.getCachedTab('admin'), equals(3));
    });
  });

  group('TreatingDoctorRequest Status Tests', () {
    test('Calcul des statuts et helpers de demande médecin traitant', () {
      final reqPending = TreatingDoctorRequest(
        id: 'req-1',
        patientId: 'p-1',
        patientName: 'Kouassi Marc',
        doctorId: 'd-1',
        doctorName: 'Diallo Fatou',
        doctorSpecialty: 'Cardiologue',
        message: 'Demande de suivi régulier',
        status: TreatingDoctorStatus.pending,
        createdAt: DateTime.now(),
      );
      expect(reqPending.isPending, isTrue);
      expect(reqPending.isAccepted, isFalse);
      expect(reqPending.isRejected, isFalse);
      expect(reqPending.isCancelled, isFalse);
      expect(reqPending.status.label, equals('En attente'));

      final reqAccepted = TreatingDoctorRequest(
        id: 'req-2',
        patientId: 'p-1',
        patientName: 'Kouassi Marc',
        doctorId: 'd-1',
        doctorName: 'Diallo Fatou',
        doctorSpecialty: 'Cardiologue',
        message: 'Demande de suivi',
        status: TreatingDoctorStatus.accepted,
        createdAt: DateTime.now(),
      );
      expect(reqAccepted.isAccepted, isTrue);
      expect(reqAccepted.isPending, isFalse);
      expect(reqAccepted.status.label, equals('Acceptée'));
    });
  });

  group('Admin UI Components Tests', () {
    testWidgets('AdminHeader affiche le titre, sous-titre et déclenche le refresh', (WidgetTester tester) async {
      bool refreshed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AdminHeader(
              title: 'Gestion des Médecins',
              subtitle: '12 praticiens inscrits',
              onRefresh: () {
                refreshed = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Gestion des Médecins'), findsOneWidget);
      expect(find.text('12 praticiens inscrits'), findsOneWidget);

      final refreshBtn = find.byIcon(LucideIcons.refresh_cw);
      expect(refreshBtn, findsOneWidget);
      await tester.tap(refreshBtn);
      expect(refreshed, isTrue);
    });

    testWidgets('AdminKpiCard affiche valeur, label et répond aux clics', (WidgetTester tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminKpiCard(
              title: 'Médecins Actifs',
              value: '48',
              icon: LucideIcons.stethoscope,
              accentColor: Colors.blue,
              subtitle: '+3 cette semaine',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Médecins Actifs'), findsOneWidget);
      expect(find.text('48'), findsOneWidget);
      expect(find.text('+3 cette semaine'), findsOneWidget);

      await tester.tap(find.byType(AdminKpiCard));
      expect(tapped, isTrue);
    });

    testWidgets('AdminEmptyState affiche le message et le titre', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdminEmptyState(
              title: 'Aucun élément trouvé',
              message: 'Essayez de modifier vos filtres',
              icon: LucideIcons.search,
            ),
          ),
        ),
      );

      expect(find.text('Aucun élément trouvé'), findsOneWidget);
      expect(find.text('Essayez de modifier vos filtres'), findsOneWidget);
    });

    testWidgets('AdminErrorView affiche l\'erreur et déclenche le réessai', (WidgetTester tester) async {
      bool retried = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminErrorView(
              message: 'Erreur réseau simulée',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      expect(find.text('Erreur réseau simulée'), findsOneWidget);
      final retryBtn = find.text('Réessayer');
      expect(retryBtn, findsOneWidget);
      await tester.tap(retryBtn);
      expect(retried, isTrue);
    });
  });
}
