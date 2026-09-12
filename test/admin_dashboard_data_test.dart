import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:allo_docteur/services/database_service.dart';
import 'package:allo_docteur/providers/treating_request_provider.dart';
import 'package:allo_docteur/providers/message_provider.dart';
import 'package:allo_docteur/models/treating_doctor_request_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('admin_data_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => tempDir.path,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/shared_preferences'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getAll') return <String, dynamic>{};
        return true;
      },
    );
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('DatabaseService seedDemoData populates diverse doctors and patients', () async {
    final db = DatabaseService();
    await db.initialize();

    // Verify doctors
    final allDocs = db.getAllDoctors(onlyActive: false);
    expect(allDocs.length, greaterThanOrEqualTo(6));

    final activeDocs = db.getAllDoctors(onlyActive: true);
    expect(activeDocs.length, greaterThanOrEqualTo(3));

    final pendingDocs = allDocs.where((d) => d.status == 'pending').toList();
    expect(pendingDocs.length, greaterThanOrEqualTo(2)); // Dr. Koffi Brou & Dr. Estelle N'Guessan

    final suspendedDocs = allDocs.where((d) => d.status == 'suspended').toList();
    expect(suspendedDocs.length, greaterThanOrEqualTo(1)); // Dr. Ibrahim Sanogo

    // Verify patients
    final allPatients = db.getAllPatients();
    expect(allPatients.length, greaterThanOrEqualTo(4));

    // Verify message usages
    final sekou = allPatients.firstWhere((p) => p.phone == '0707070709');
    final sekouUsage = db.getPatientMessageUsage(sekou.id);
    expect(sekouUsage.isBlocked, isTrue); // 10/10 messages used

    final marieAnge = allPatients.firstWhere((p) => p.phone == '0707070708');
    final marieUsage = db.getPatientMessageUsage(marieAnge.id);
    expect(marieUsage.freeMessagesUsed, equals(8));
  });

  test('TreatingRequestProvider seedDemoRequests populates diverse requests', () async {
    final trProvider = TreatingRequestProvider();
    await trProvider.initialize();

    final all = trProvider.allRequests;
    expect(all.length, equals(4));

    final pending = all.where((r) => r.status == TreatingDoctorStatus.pending).toList();
    expect(pending.length, equals(1));

    final accepted = all.where((r) => r.status == TreatingDoctorStatus.accepted).toList();
    expect(accepted.length, equals(2));

    final rejected = all.where((r) => r.status == TreatingDoctorStatus.rejected).toList();
    expect(rejected.length, equals(1));
  });

  test('MessageProvider seedDemoConversations creates active demo chats', () async {
    final msgProvider = MessageProvider();
    await msgProvider.seedDemoConversations(force: true);

    expect(msgProvider.conversations.length, equals(2));
    expect(msgProvider.totalMessagesCount, greaterThanOrEqualTo(7));

    final c1 = msgProvider.conversations.firstWhere((c) => c.id == 'conv_pat1_doc1');
    expect(c1.patientName, equals('Jean Kouassi'));
    expect(c1.doctorName, equals('Dr. Sarah Touré'));

    final m1 = msgProvider.messagesOf(c1.id);
    expect(m1.length, equals(4));
  });
}
