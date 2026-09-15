import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:allo_docteur/providers/auth_provider.dart';
import 'package:allo_docteur/providers/treating_request_provider.dart';
import 'package:allo_docteur/providers/message_provider.dart';
import 'package:allo_docteur/screens/admin/admin_dashboard_screen.dart';

void main() {
  testWidgets('Test drawer tab switching on mobile', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => TreatingRequestProvider()),
          ChangeNotifierProvider(create: (_) => MessageProvider()),
        ],
        child: const MaterialApp(
          home: AdminDashboardScreen(initialTab: 1),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scaffold = tester.state<ScaffoldState>(find.byType(Scaffold));
    scaffold.openDrawer();
    await tester.pumpAndSettle();
    expect(scaffold.isDrawerOpen, isTrue);

    // Click on tab 0 (Vue d'ensemble)
    final overviewItem = find.text("Vue d'ensemble");
    expect(overviewItem, findsOneWidget);
    await tester.tap(overviewItem);
    await tester.pumpAndSettle();

    // Is drawer closed and tab changed?
    expect(scaffold.isDrawerOpen, isFalse, reason: 'Drawer should close when item is tapped');
    expect(find.text('Indicateurs clés'), findsOneWidget, reason: 'Tab 0 should be visible');
  });
}
