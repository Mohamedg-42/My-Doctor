// test/admin_navigation_debug_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:allo_docteur/providers/auth_provider.dart';
import 'package:allo_docteur/providers/treating_request_provider.dart';
import 'package:allo_docteur/providers/message_provider.dart';
import 'package:allo_docteur/screens/admin/admin_dashboard_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test all tabs in AdminDashboardScreen without throwing', (WidgetTester tester) async {
    final auth = AuthProvider();
    final treatingReq = TreatingRequestProvider();
    final msgProvider = MessageProvider();

    // Set screen size wide (desktop)
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider<TreatingRequestProvider>.value(value: treatingReq),
          ChangeNotifierProvider<MessageProvider>.value(value: msgProvider),
        ],
        child: const MaterialApp(
          home: AdminDashboardScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Vue d\'ensemble'), findsWidgets);

    // Tester le clic sur "Gestion des médecins" (tab 3) sur Desktop
    final medecinsItem = find.text('Gestion des médecins');
    expect(medecinsItem, findsOneWidget);
    await tester.tap(medecinsItem);
    await tester.pumpAndSettle();

    // Vérifier que la vue a bien changé vers les praticiens
    expect(find.text('Rechercher par nom, spécialité, n° d\'ordre, téléphone...'), findsOneWidget);

    // Tester maintenant sur Mobile (< 960px)
    tester.view.physicalSize = const Size(400, 800);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider<TreatingRequestProvider>.value(value: treatingReq),
          ChangeNotifierProvider<MessageProvider>.value(value: msgProvider),
        ],
        child: const MaterialApp(
          home: AdminDashboardScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // En mode mobile, ouvrir le Drawer via le bouton menu
    final menuBtn = find.byTooltip('Menu');
    expect(menuBtn, findsOneWidget);
    await tester.tap(menuBtn);
    await tester.pumpAndSettle();

    // Le Drawer est ouvert, cliquer sur "Finances & Retraits"
    final financesItem = find.text('Finances & Retraits');
    expect(financesItem, findsOneWidget);
    await tester.tap(financesItem);
    await tester.pumpAndSettle();

    // Vérifier que l'écran des finances est affiché
    expect(find.text('Finances & Retraits praticiens'), findsOneWidget);
  });
}
