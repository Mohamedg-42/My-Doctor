import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:allo_docteur/models/user_model.dart';
import 'package:allo_docteur/providers/auth_provider.dart';
import 'package:allo_docteur/services/database_service.dart';
import 'package:allo_docteur/screens/patient/edit_profile_screen.dart';

void main() {
  test('DbUser copyWith correctly updates all profile fields', () {
    final original = DbUser(
      id: 'p_test',
      role: 'patient',
      email: 'test@medilink.ci',
      phone: '+2250102030405',
      passwordHash: 'hash',
      firstName: 'Patient',
      lastName: '',
      status: 'active',
      createdAt: DateTime.now(),
    );

    final updated = original.copyWith(
      firstName: 'Jean-Marc',
      lastName: 'KOUASSI',
      gender: 'M',
      birthDate: '1990-05-15',
      city: 'Abidjan',
      commune: 'Cocody',
      profession: 'Ingénieur',
      cmuNumber: 'CMU-CI12345678',
    );

    expect(updated.firstName, 'Jean-Marc');
    expect(updated.lastName, 'KOUASSI');
    expect(updated.gender, 'M');
    expect(updated.birthDate, '1990-05-15');
    expect(updated.city, 'Abidjan');
    expect(updated.commune, 'Cocody');
    expect(updated.profession, 'Ingénieur');
    expect(updated.cmuNumber, 'CMU-CI12345678');
  });

  test('UserModel initials and displayName compute correctly', () {
    final user = UserModel(
      id: 'usr_1',
      firstName: 'Jean-Marc',
      lastName: 'KOUASSI',
      email: 'jean@medilink.ci',
      phone: '+2250102030405',
      role: UserRole.patient,
      createdAt: DateTime.now(),
      city: 'Abidjan',
      gender: 'M',
    );

    expect(user.displayName, 'KOUASSI Jean-Marc');
    expect(user.initials, 'JK');
  });

  testWidgets('EditProfileScreen renders form fields properly', (WidgetTester tester) async {
    final authProvider = AuthProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: authProvider,
        child: const MaterialApp(
          home: EditProfileScreen(),
        ),
      ),
    );

    // Verify title and main fields
    expect(find.text('Mon Profil Patient'), findsOneWidget);
    expect(find.text('Identité & État Civil'), findsOneWidget);
    expect(find.text('Coordonnées & Résidence'), findsOneWidget);
    expect(find.text('Enregistrer les informations'), findsOneWidget);
    expect(find.text('Homme (M)'), findsOneWidget);
    expect(find.text('Femme (F)'), findsOneWidget);
  });
}
