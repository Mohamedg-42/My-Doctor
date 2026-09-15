import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:allo_docteur/screens/auth/patient_register_screen.dart';
import 'package:allo_docteur/providers/auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Date of birth field is present, scrollable and responsive', (tester) async {
    final auth = AuthProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: auth,
        child: const MaterialApp(
          home: PatientRegisterScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify presence of Date of birth field
    expect(find.text('Date de naissance *'), findsOneWidget);
    final hintFinder = find.text('JJ/MM/AAAA');
    expect(hintFinder, findsOneWidget);

    // Scroll into view
    await tester.ensureVisible(hintFinder);
    await tester.pumpAndSettle();

    // Tap on the date of birth field
    await tester.tap(hintFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify the date picker is displayed
    expect(find.byType(DatePickerDialog), findsOneWidget);

    // Tap cancel button to dismiss cleanly
    final cancelButton = find.text('ANNULER');
    expect(cancelButton, findsOneWidget);
    await tester.tap(cancelButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(DatePickerDialog), findsNothing);
  });
}
