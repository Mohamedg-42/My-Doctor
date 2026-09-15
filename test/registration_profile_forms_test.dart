import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:allo_docteur/providers/auth_provider.dart';
import 'package:allo_docteur/screens/auth/patient_register_screen.dart';
import 'package:allo_docteur/screens/auth/doctor_register_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Registration Profile Forms Tests', () {
    testWidgets('PatientRegisterScreen displays profile fields and renders without overflow', (tester) async {
      final auth = AuthProvider();

      final List<FlutterErrorDetails> errors = [];
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        errors.add(details);
        originalOnError?.call(details);
      };

      final testSizes = [
        const Size(320, 568),
        const Size(360, 640),
        const Size(390, 844),
      ];

      for (final size in testSizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: auth),
            ],
            child: const MaterialApp(
              home: PatientRegisterScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Check identity / profile fields in step 0
        expect(find.byType(PatientRegisterScreen), findsOneWidget);
        expect(find.text('Informations personnelles'), findsOneWidget);
        expect(find.text('Nom de famille *'), findsOneWidget);
        expect(find.text('Prénom(s) *'), findsOneWidget);
        expect(find.text('Genre / Sexe *'), findsOneWidget);
        expect(find.text('Homme'), findsOneWidget);
        expect(find.text('Femme'), findsOneWidget);
        expect(find.text('Date de naissance *'), findsOneWidget);
        expect(find.text('Profession'), findsOneWidget);

        // Check no RenderFlex overflow
        final overflowErrors = errors.where((e) => e.toString().contains('overflowed')).toList();
        expect(overflowErrors, isEmpty, reason: 'RenderFlex overflow detected on size $size');
      }

      addTearDown(() {
        FlutterError.onError = originalOnError;
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('DoctorRegisterScreen displays profile fields and renders without overflow', (tester) async {
      final auth = AuthProvider();

      final List<FlutterErrorDetails> errors = [];
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        errors.add(details);
        originalOnError?.call(details);
      };

      final testSizes = [
        const Size(320, 568),
        const Size(360, 640),
        const Size(390, 844),
      ];

      for (final size in testSizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: auth),
            ],
            child: const MaterialApp(
              home: DoctorRegisterScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Check step 1 fields: Identité, Contact, Ville, Commune
        expect(find.byType(DoctorRegisterScreen), findsOneWidget);
        expect(find.text('Identité & Coordonnées'), findsOneWidget);
        expect(find.text('Nom de famille *'), findsOneWidget);
        expect(find.text('Prénom(s) *'), findsOneWidget);
        expect(find.text('Numéro de téléphone *'), findsOneWidget);
        expect(find.text('Email professionnel'), findsOneWidget);
        expect(find.text('Ville *'), findsOneWidget);
        expect(find.text('Commune *'), findsOneWidget);

        final overflowErrors = errors.where((e) => e.toString().contains('overflowed')).toList();
        expect(overflowErrors, isEmpty, reason: 'RenderFlex overflow detected on size $size');
      }

      addTearDown(() {
        FlutterError.onError = originalOnError;
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });
  });
}
