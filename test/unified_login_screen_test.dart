// ════════════════════════════════════════════════════════════
//  unified_login_screen_test.dart
//  Tests pour la nouvelle page de connexion unifiée My Doctor
// ════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:allo_docteur/models/user_model.dart';
import 'package:allo_docteur/screens/auth/login_screen.dart';
import 'package:allo_docteur/screens/auth/patient_login_screen.dart';
import 'package:allo_docteur/screens/auth/doctor_login_screen.dart';
import 'package:allo_docteur/widgets/common/app_logo.dart';
import 'package:allo_docteur/providers/auth_provider.dart';

Widget _buildTestApp({
  UserRole role = UserRole.patient,
  Size screenSize = const Size(390, 844),
}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: screenSize),
      child: ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: LoginScreen(initialRole: role),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LoginScreen Tests UI & Fonctionnels', () {
    testWidgets('Affiche tous les composants graphiques de la maquette', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // 1. Logo My Doctor
      expect(find.byType(AppLogo), findsOneWidget);

      // 2. Titre "Connexion"
      expect(find.text('Connexion'), findsOneWidget);

      // 3. Commutateur de profil Patient et Médecin
      expect(find.text('Patient'), findsOneWidget);
      expect(find.text('Médecin'), findsOneWidget);
      expect(find.byType(DoctorSilhouetteIcon), findsOneWidget);

      // 4. Champs de formulaire
      expect(find.text('Téléphone ou e-mail'), findsOneWidget);
      expect(find.text('Mot de passe'), findsOneWidget);

      // 5. Lien mot de passe oublié
      expect(find.text('Mot de passe oublié ?'), findsOneWidget);

      // 6. Boutons d'action
      expect(find.text('Se connecter'), findsOneWidget);
      expect(find.text('Créer un compte'), findsOneWidget);

      // 7. Onde ECG
      expect(find.byType(EcgPulseDivider), findsOneWidget);
    });

    testWidgets('Bascule entre profil Patient et Médecin au clic', (tester) async {
      await tester.pumpWidget(_buildTestApp(role: UserRole.patient));
      await tester.pumpAndSettle();

      // Clic sur l'onglet Médecin
      await tester.tap(find.text('Médecin'));
      await tester.pumpAndSettle();

      // Clic retour sur l'onglet Patient
      await tester.tap(find.text('Patient'));
      await tester.pumpAndSettle();
    });

    testWidgets('Validation du formulaire sur champs vides', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Clic sur "Se connecter" sans remplir les champs
      await tester.tap(find.text('Se connecter'));
      await tester.pumpAndSettle();

      expect(find.text('Veuillez saisir votre numéro ou e-mail'), findsOneWidget);
      expect(find.text('Veuillez saisir votre mot de passe'), findsOneWidget);
    });

    testWidgets('Bascule de visibilité du mot de passe avec icône œil', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Saisie du mot de passe
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Mot de passe'),
        'secret123',
      );
      await tester.pumpAndSettle();

      // Trouver le champ et vérifier obscureText = true par défaut
      final editableFinder = find.byWidgetPredicate(
        (w) => w is EditableText && w.obscureText == true,
      );
      expect(editableFinder, findsOneWidget);

      // Clic sur l'icône de l'œil
      await tester.tap(find.byIcon(LucideIcons.eye));
      await tester.pumpAndSettle();

      // Vérifier que l'icône bascule en mode masqué barré (eye_off)
      expect(find.byIcon(LucideIcons.eye_off), findsOneWidget);

      // Clic à nouveau pour re-masquer
      await tester.tap(find.byIcon(LucideIcons.eye_off));
      await tester.pumpAndSettle();
      expect(find.byIcon(LucideIcons.eye), findsOneWidget);
    });

    testWidgets('Affichage du modal mot de passe oublié', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mot de passe oublié ?'));
      await tester.pumpAndSettle();

      expect(find.text('Entrez votre adresse e-mail ou numéro de téléphone pour recevoir les instructions de réinitialisation.'), findsOneWidget);
      expect(find.text('Envoyer'), findsOneWidget);
    });

    testWidgets('Vérification stricte anti-overflow sur petit écran (320x568)', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildTestApp(screenSize: const Size(320, 568)));
      await tester.pumpAndSettle();

      // Vérifier qu'aucune exception d'overflow Flutter n'est levée
      expect(tester.takeException(), isNull);
    });

    testWidgets('Rétrocompatibilité de PatientLoginScreen et DoctorLoginScreen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => AuthProvider(),
            child: const PatientLoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(AppLogo), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => AuthProvider(),
            child: const DoctorLoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(AppLogo), findsOneWidget);
    });
  });
}
