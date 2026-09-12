import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:allo_docteur/screens/auth/doctor_register_screen.dart';
import 'package:allo_docteur/providers/auth_provider.dart';
import 'package:allo_docteur/services/database_service.dart';

void main() {
  test('Doctor registration pending status and active filter logic', () {
    final doctorPending = DbUser(
      id: 'doc_test_1',
      role: 'doctor',
      email: 'dr.pending@example.com',
      phone: '+2250102030405',
      passwordHash: 'hash',
      firstName: 'Jean',
      lastName: 'Kouassi',
      status: 'pending',
      createdAt: DateTime.now(),
      specialty: 'Cardiologue',
      orderNumber: '12345',
    );

    expect(doctorPending.status, 'pending');

    final doctorActive = doctorPending.copyWith(status: 'active');
    expect(doctorActive.status, 'active');
  });

  testWidgets('DoctorRegisterScreen renders 2 steps properly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: const MaterialApp(
          home: DoctorRegisterScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify step 1 of 2 is displayed
    expect(find.text('Étape 1 sur 2'), findsOneWidget);
    expect(find.text('Création de compte Médecin'), findsOneWidget);
    expect(find.text('Nom de famille'), findsOneWidget);
    expect(find.text('Prénom(s)'), findsOneWidget);
    expect(find.text('Continuer'), findsOneWidget);

    // Enter name
    await tester.enterText(find.widgetWithText(TextFormField, 'Ex: KOUASSI'), 'KOUASSI');
    await tester.enterText(find.widgetWithText(TextFormField, 'Ex: Jean-Marc'), 'Jean-Marc');
    await tester.pump();

    // Tap Continuer
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();

    // Verify step 2 of 2 is displayed
    expect(find.text('Étape 2 sur 2'), findsOneWidget);
    expect(find.text('Coordonnées & Sécurité'), findsOneWidget);
    expect(find.text('Numéro de téléphone'), findsOneWidget);
    expect(find.text('Mot de passe'), findsOneWidget);
    expect(find.text('Confirmer le mot de passe'), findsOneWidget);
    expect(find.text('Créer mon compte'), findsOneWidget);
  });
}
