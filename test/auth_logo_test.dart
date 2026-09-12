import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:allo_docteur/widgets/common/app_logo.dart';
import 'package:allo_docteur/screens/auth/patient_login_screen.dart';
import 'package:allo_docteur/screens/auth/doctor_login_screen.dart';
import 'package:allo_docteur/screens/auth/choose_register_screen.dart';
import 'package:allo_docteur/screens/auth/patient_register_screen.dart';
import 'package:allo_docteur/screens/auth/doctor_register_screen.dart';
import 'package:allo_docteur/screens/auth/otp_screen.dart';
import 'package:allo_docteur/providers/auth_provider.dart';

void main() {
  testWidgets('AppLogo renders properly with fallback or asset', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppLogo(height: 40),
        ),
      ),
    );

    expect(find.byType(AppLogo), findsOneWidget);
  });

  testWidgets('ChooseRegisterScreen contains AppLogo', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ChooseRegisterScreen(),
      ),
    );

    expect(find.byType(AppLogo), findsOneWidget);
  });

  testWidgets('PatientLoginScreen contains AppLogo', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => AuthProvider(),
          child: const PatientLoginScreen(),
        ),
      ),
    );

    expect(find.byType(AppLogo), findsOneWidget);
  });

  testWidgets('DoctorLoginScreen contains AppLogo', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => AuthProvider(),
          child: const DoctorLoginScreen(),
        ),
      ),
    );

    expect(find.byType(AppLogo), findsOneWidget);
  });

  testWidgets('PatientRegisterScreen contains AppLogo', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => AuthProvider(),
          child: const PatientRegisterScreen(),
        ),
      ),
    );

    expect(find.byType(AppLogo), findsOneWidget);
  });

  testWidgets('DoctorRegisterScreen contains AppLogo', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => AuthProvider(),
          child: const DoctorRegisterScreen(),
        ),
      ),
    );

    expect(find.byType(AppLogo), findsOneWidget);
  });

  testWidgets('OtpScreen contains AppLogo', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => AuthProvider(),
          child: const OtpScreen(identifier: '+22501020304', role: 'patient'),
        ),
      ),
    );

    expect(find.byType(AppLogo), findsOneWidget);
  });
}
