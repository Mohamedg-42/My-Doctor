import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:allo_docteur/screens/doctor/doctor_home_screen.dart';
import 'package:allo_docteur/screens/doctor/doctor_appointments_tab.dart';
import 'package:allo_docteur/providers/auth_provider.dart';
import 'package:allo_docteur/providers/doctor_provider.dart';
import 'package:allo_docteur/providers/app_provider.dart';
import 'package:allo_docteur/providers/message_provider.dart';
import 'package:allo_docteur/providers/treating_request_provider.dart';

void main() {
  testWidgets('Clicking Rendez-vous in Quick Actions navigates to Appointments view', (tester) async {
    tester.view.physicalSize = const Size(400, 850);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final authProvider = AuthProvider();
    final doctorProvider = DoctorProvider();
    final appProvider = AppProvider();
    final messageProvider = MessageProvider();
    final trProvider = TreatingRequestProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<DoctorProvider>.value(value: doctorProvider),
          ChangeNotifierProvider<AppProvider>.value(value: appProvider),
          ChangeNotifierProvider<MessageProvider>.value(value: messageProvider),
          ChangeNotifierProvider<TreatingRequestProvider>.value(value: trProvider),
        ],
        child: const MaterialApp(
          home: DoctorHomeScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Dashboard is initially visible
    expect(find.text('Actions Rapides'), findsOneWidget);
    expect(find.byType(DoctorAppointmentsTab, skipOffstage: false), findsOneWidget); // in IndexedStack index 1

    // Find the 'Rendez-vous' button in Quick Actions
    final rdvCard = find.text('Rendez-vous').first;
    expect(rdvCard, findsOneWidget);

    // Tap on 'Rendez-vous'
    await tester.tap(rdvCard);
    await tester.pumpAndSettle();

    // Verify Appointments view is now active (has 'Mes Rendez-vous' title and tabs)
    expect(find.text('Mes Rendez-vous'), findsOneWidget);
    expect(find.text('Tous'), findsOneWidget);
    expect(find.text('En attente'), findsOneWidget);
    expect(find.text('Confirmés'), findsOneWidget);

    // Tap back to dashboard
    final backBtn = find.byTooltip('Retour au tableau de bord');
    expect(backBtn, findsOneWidget);
    await tester.tap(backBtn);
    await tester.pumpAndSettle();

    // Verify we are back on Dashboard
    expect(find.text('Actions Rapides'), findsOneWidget);
  });
}
