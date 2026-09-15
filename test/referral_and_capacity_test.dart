import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:allo_docteur/models/treating_doctor_request_model.dart';
import 'package:allo_docteur/services/database_service.dart';
import 'package:allo_docteur/providers/treating_request_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('my_doctor_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return tempDir.path;
      },
    );
    await DatabaseService().initialize();
    final tr = TreatingRequestProvider();
    await tr.initialize();
  });

  tearDownAll(() async {
    await Hive.close();
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  group('Referral and Doctor Patient Capacity Tests', () {
    test('TreatingDoctorRequest supports referral fields and status', () {
      final req = TreatingDoctorRequest(
        id: 'req_test_1',
        patientId: 'pat_1',
        patientName: 'Kouamé Jean',
        doctorId: 'doc_1',
        doctorName: 'Dr. Yao',
        doctorSpecialty: 'Cardiologie',
        message: 'Demande de suivi cardiologique',
        amount: 750.0,
        createdAt: DateTime.now(),
        status: TreatingDoctorStatus.referred,
        referredFromDoctorId: 'doc_origin',
        referredFromDoctorName: 'Dr. Konan',
        referredToDoctorId: 'doc_1',
        referredToDoctorName: 'Dr. Yao',
        referralNote: 'Besoin d\'un suivi cardiologique spécialisé.',
      );

      expect(req.isReferred, isTrue);
      expect(req.status.label, 'Référée');

      final json = req.toJson();
      expect(json['status'], 'referred');
      expect(json['referred_from_doctor_id'], 'doc_origin');
      expect(json['referred_from_doctor_name'], 'Dr. Konan');
      expect(json['referred_to_doctor_id'], 'doc_1');
      expect(json['referral_note'], 'Besoin d\'un suivi cardiologique spécialisé.');

      final fromJson = TreatingDoctorRequest.fromJson(json);
      expect(fromJson.isReferred, isTrue);
      expect(fromJson.referredFromDoctorName, 'Dr. Konan');
      expect(fromJson.referralNote, 'Besoin d\'un suivi cardiologique spécialisé.');
    });

    test('DbUser patientCapacity defaults to 50 and can be updated', () async {
      final db = DatabaseService();
      final doctors = db.getAllDoctors(onlyActive: false);
      expect(doctors.isNotEmpty, isTrue);

      final doc = doctors.first;
      expect(doc.patientCapacity, greaterThan(0));

      // Test updating patient capacity
      await db.updateDoctorPatientCapacity(doc.id, 85);
      final updatedCap = db.getDoctorPatientCapacity(doc.id);
      expect(updatedCap, 85);
    });

    test('TreatingRequestProvider.referRequest reassigns doctor and records referral', () async {
      final trProvider = TreatingRequestProvider();
      await trProvider.initialize();

      // Send a test request
      final successSend = await trProvider.sendRequest(
        patientId: 'patient_alpha',
        patientName: 'Mamadou Traoré',
        patientPhone: '+22505050505',
        doctorId: 'doc_initial_1',
        doctorName: 'Dr. Initial',
        doctorSpecialty: 'Généraliste',
        paymentMethod: 'orange',
      );

      expect(successSend, isTrue);
      final createdReq = trProvider.allRequests.firstWhere((r) => r.patientId == 'patient_alpha');
      expect(createdReq.doctorId, 'doc_initial_1');

      // Refer request to another doctor
      await trProvider.referRequest(
        requestId: createdReq.id,
        targetDoctorId: 'doc_confrere_2',
        targetDoctorName: 'Dr. Confrère Spécialiste',
        targetDoctorSpecialty: 'Cardiologue',
        referralNote: 'Patient référé pour avis complémentaire',
      );

      final updated = trProvider.allRequests.firstWhere((r) => r.id == createdReq.id);
      expect(updated.doctorId, 'doc_confrere_2');
      expect(updated.doctorName, 'Dr. Confrère Spécialiste');
      expect(updated.referredFromDoctorId, 'doc_initial_1');
      expect(updated.referredFromDoctorName, 'Dr. Initial');
      expect(updated.referralNote, 'Patient référé pour avis complémentaire');
      expect(updated.isReferred, isTrue);
      expect(updated.status, TreatingDoctorStatus.pending);
    });
  });
}
