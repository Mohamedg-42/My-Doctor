import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:allo_docteur/providers/auth_provider.dart';
import 'package:allo_docteur/providers/message_provider.dart';
import 'package:allo_docteur/screens/doctor/doctor_call_settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('DoctorCallSettingsScreen renders without overflow on multiple screen sizes from 320px to 1440px', (tester) async {
    final auth = AuthProvider();
    final msg = MessageProvider();

    final List<FlutterErrorDetails> errors = [];
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      errors.add(details);
      originalOnError?.call(details);
    };

    final testSizes = [
      const Size(320, 568), // Ultra compact mobile
      const Size(360, 640), // Standard Android
      const Size(375, 667), // iPhone SE
      const Size(390, 844), // iPhone 13/14
      const Size(412, 915), // Pixel 7
      const Size(768, 1024), // Tablet
      const Size(1440, 900), // Desktop
    ];

    for (final size in testSizes) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
            ChangeNotifierProvider<MessageProvider>.value(value: msg),
          ],
          child: const MaterialApp(
            home: DoctorCallSettingsScreen(doctorId: 'doc_test_1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(DoctorCallSettingsScreen), findsOneWidget);
      expect(find.text('Autoriser les patients abonnés'), findsOneWidget);
      expect(find.text('Recevoir des appels directs'), findsOneWidget);
    }

    addTearDown(() {
      FlutterError.onError = originalOnError;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    expect(errors, isEmpty, reason: 'There should be no layout overflow or rendering errors on any screen size');
  });
}
