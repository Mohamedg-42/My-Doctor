import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:allo_docteur/providers/auth_provider.dart';
import 'package:allo_docteur/providers/treating_request_provider.dart';
import 'package:allo_docteur/providers/message_provider.dart';
import 'package:allo_docteur/screens/admin/admin_dashboard_screen.dart';
import 'package:allo_docteur/screens/auth/admin_login_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test each admin tab 0 through 9 renders without exceptions or overflows on multiple screen sizes', (tester) async {
    final auth = AuthProvider();
    final treatingReq = TreatingRequestProvider();
    final msgProvider = MessageProvider();

    final List<FlutterErrorDetails> errors = [];
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      errors.add(details);
      originalOnError?.call(details);
    };

    final testSizes = [
      const Size(1440, 900), // Desktop HD
      const Size(1024, 768), // Tablet Landscape
      const Size(768, 1024), // Tablet Portrait
      const Size(390, 844),  // iPhone 13 / Modern smartphone
      const Size(360, 640),  // Standard Android
    ];

    for (final size in testSizes) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;

      for (int tab = 0; tab <= 9; tab++) {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: auth),
              ChangeNotifierProvider<TreatingRequestProvider>.value(value: treatingReq),
              ChangeNotifierProvider<MessageProvider>.value(value: msgProvider),
            ],
            child: MaterialApp(
              home: AdminDashboardScreen(initialTab: tab),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Check if any error occurred during render
        expect(errors.isEmpty, isTrue,
            reason: 'Render error on tab $tab at size ${size.width}x${size.height}: ${errors.isNotEmpty ? errors.first.toString() : ""}');
      }
    }

    FlutterError.onError = originalOnError;
  });

  testWidgets('Test AdminLoginScreen renders without errors on desktop and mobile', (tester) async {
    final auth = AuthProvider();

    for (final size in [const Size(1280, 800), const Size(390, 844)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ],
          child: const MaterialApp(
            home: AdminLoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Console Administrateur'), findsWidgets);
    }
  });

  testWidgets('Test AdminPatientCardsView modal opens and closes smoothly without freeze', (tester) async {
    final auth = AuthProvider();
    final treatingReq = TreatingRequestProvider();
    final msgProvider = MessageProvider();

    for (final size in [const Size(1440, 900), const Size(390, 844), const Size(360, 640)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
            ChangeNotifierProvider<TreatingRequestProvider>.value(value: treatingReq),
            ChangeNotifierProvider<MessageProvider>.value(value: msgProvider),
          ],
          child: const MaterialApp(
            home: AdminDashboardScreen(initialTab: 1), // Tab 1 = Cartes patient & CMU
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find 'Consulter' button and tap it
      final consultBtn = find.text('Consulter').first;
      expect(consultBtn, findsOneWidget);
      await tester.tap(consultBtn);
      await tester.pumpAndSettle();

      // Verify modal is open
      expect(find.text('Détail Carte Patient & CMU'), findsOneWidget);

      // Tap 'Fermer'
      final closeBtn = find.text('Fermer');
      expect(closeBtn, findsOneWidget);
      await tester.tap(closeBtn);
      await tester.pumpAndSettle();

      // Verify modal is closed
      expect(find.text('Détail Carte Patient & CMU'), findsNothing);
    }
  });

  testWidgets('Test AdminOverviewView compact cards and toggle between 6 and 12 cards', (tester) async {
    final auth = AuthProvider();
    final treatingReq = TreatingRequestProvider();
    final msgProvider = MessageProvider();

    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider<TreatingRequestProvider>.value(value: treatingReq),
          ChangeNotifierProvider<MessageProvider>.value(value: msgProvider),
        ],
        child: const MaterialApp(
          home: AdminDashboardScreen(initialTab: 0), // Tab 0 = Vue d'ensemble
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify reduced view is displayed by default (6 cards)
    expect(find.text('Vue réduite (6 cartes clés)'), findsOneWidget);
    expect(find.text('Afficher tout (12)'), findsOneWidget);

    // Tap toggle to show all 12 cards
    await tester.tap(find.text('Afficher tout (12)'));
    await tester.pumpAndSettle();

    // Verify expanded view
    expect(find.text('Affichage complet (12)'), findsOneWidget);
    expect(find.text('Réduire'), findsOneWidget);

    // Tap toggle to reduce back
    await tester.tap(find.text('Réduire'));
    await tester.pumpAndSettle();

    expect(find.text('Vue réduite (6 cartes clés)'), findsOneWidget);
  });
}

