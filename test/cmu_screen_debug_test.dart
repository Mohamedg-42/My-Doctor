
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:allo_docteur/models/user_model.dart';
import 'package:allo_docteur/providers/auth_provider.dart';
import 'package:allo_docteur/providers/cmu_provider.dart';
import 'package:allo_docteur/screens/patient/cmu_screen.dart';
import 'package:allo_docteur/screens/admin/views/admin_patient_cards_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test CmuScreen with user card on multiple resolutions', (tester) async {
    final cmuProvider = CmuProvider();
    final user = UserModel(
      id: 'patient_test',
      firstName: 'Kouame',
      lastName: 'KOFFI',
      email: 'kouame@example.ci',
      phone: '0707070707',
      role: UserRole.patient,
      cmuNumber: 'CMU-CI123456789',
      commune: 'Cocody',
      city: 'Abidjan',
      profession: 'Ingénieur en télécommunications et réseaux',
      birthDate: DateTime(1985, 5, 20),
      createdAt: DateTime(2025, 1, 1),
    );
    cmuProvider.initFromUser(user);

    for (final size in [
      const Size(1280, 800),
      const Size(390, 844),
      const Size(360, 640),
    ]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CmuProvider>.value(value: cmuProvider),
          ],
          child: const MaterialApp(
            home: CmuScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('CMU-CI'), findsOneWidget);
    }
  });

  testWidgets('Test AdminPatientCardsView and show modal', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AdminPatientCardsView(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final consultBtn = find.text('Consulter');
    if (consultBtn.evaluate().isNotEmpty) {
      await tester.tap(consultBtn.first);
      await tester.pumpAndSettle();
      expect(find.text('Détail Carte Patient & CMU'), findsOneWidget);
    }
  });
}
