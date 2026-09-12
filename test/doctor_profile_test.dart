import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:allo_docteur/models/user_model.dart';
import 'package:allo_docteur/models/doctor_model.dart';
import 'package:allo_docteur/providers/auth_provider.dart';
import 'package:allo_docteur/services/database_service.dart';
import 'package:allo_docteur/screens/doctor/edit_profile_screen.dart';

void main() {
  test('DbUser copyWith correctly updates doctor profile fields', () {
    final original = DbUser(
      id: 'doc_test',
      role: 'doctor',
      email: 'dr.koffi@medilink.ci',
      phone: '+2250708091011',
      passwordHash: 'hash',
      firstName: 'Marc',
      lastName: 'KOFFI',
      status: 'active',
      createdAt: DateTime.now(),
    );

    final updated = original.copyWith(
      specialty: 'Cardiologie',
      orderNumber: '12345',
      bio: 'Spécialiste en chirurgie cardiaque et prévention.',
      city: 'Abidjan',
      commune: 'Cocody',
    );

    expect(updated.specialty, 'Cardiologie');
    expect(updated.orderNumber, '12345');
    expect(updated.bio, 'Spécialiste en chirurgie cardiaque et prévention.');
    expect(updated.city, 'Abidjan');
    expect(updated.commune, 'Cocody');
  });

  test('DoctorModel initials and fullName compute correctly', () {
    final doctor = DoctorModel(
      id: 'doc_1',
      userId: 'usr_doc_1',
      firstName: 'Marc',
      lastName: 'KOFFI',
      email: 'dr.koffi@medilink.ci',
      phone: '+2250708091011',
      specialty: 'Pédiatrie',
      orderNumber: '54321',
      createdAt: DateTime.now(),
      consultationPrice: 20000,
    );

    expect(doctor.fullName, 'Dr. Marc KOFFI');
    expect(doctor.initials, 'MK');
    expect(doctor.formattedPrice, '20000 F CFA');
  });

  testWidgets('Doctor EditProfileScreen renders form fields properly', (WidgetTester tester) async {
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
    expect(find.text('Mon Profil Praticien'), findsOneWidget);
    expect(find.text('Identité & Spécialité Médicale'), findsOneWidget);
    expect(find.text('Coordonnées Professionnelles & Cabinet'), findsOneWidget);
    expect(find.text('Tarifs & Expérience'), findsOneWidget);
    expect(find.text('Enregistrer mon profil praticien'), findsOneWidget);
  });
}
