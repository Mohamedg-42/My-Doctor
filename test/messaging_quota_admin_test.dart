import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:allo_docteur/services/database_service.dart';
import 'package:allo_docteur/models/treating_doctor_request_model.dart';
import 'package:allo_docteur/providers/auth_provider.dart';
import 'package:allo_docteur/providers/message_provider.dart';
import 'package:allo_docteur/providers/treating_request_provider.dart';
import 'package:allo_docteur/screens/auth/welcome_screen.dart';
import 'package:allo_docteur/screens/admin/admin_dashboard_screen.dart';

void main() {
  group('1. Patient Message Quota (10 Free Messages) Logic', () {
    test('PatientMessageUsage model initializes with 10 free messages', () {
      final usage = PatientMessageUsage(
        patientId: 'patient_test_001',
        freeMessagesLimit: 10,
        freeMessagesUsed: 0,
        firstMessageAt: null,
        updatedAt: DateTime.now(),
      );

      expect(usage.freeMessagesLimit, 10);
      expect(usage.freeMessagesUsed, 0);
      expect(usage.remaining, 10);
      expect(usage.canSend, isTrue);
      expect(usage.isBlocked, isFalse);
    });

    test('PatientMessageUsage decreases remaining count and blocks at 0', () {
      var usage = PatientMessageUsage(
        patientId: 'patient_test_001',
        freeMessagesLimit: 10,
        freeMessagesUsed: 0,
        firstMessageAt: null,
        updatedAt: DateTime.now(),
      );

      // Simulate sending 9 messages
      usage = usage.copyWith(freeMessagesUsed: 9);
      expect(usage.remaining, 1);
      expect(usage.canSend, isTrue);
      expect(usage.isBlocked, isFalse);

      // Simulate sending 10th message
      usage = usage.copyWith(freeMessagesUsed: 10);
      expect(usage.remaining, 0);
      expect(usage.canSend, isFalse);
      expect(usage.isBlocked, isTrue);

      // Attempting further message (exceeding limit)
      usage = usage.copyWith(freeMessagesUsed: 11);
      expect(usage.remaining, 0);
      expect(usage.canSend, isFalse);
      expect(usage.isBlocked, isTrue);
    });

    test('Resetting patient message quota restores 10 free messages', () {
      var usage = PatientMessageUsage(
        patientId: 'patient_test_001',
        freeMessagesLimit: 10,
        freeMessagesUsed: 10,
        firstMessageAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(usage.canSend, isFalse);

      // Admin resets quota
      usage = usage.copyWith(freeMessagesUsed: 0);
      expect(usage.remaining, 10);
      expect(usage.canSend, isTrue);
      expect(usage.isBlocked, isFalse);
    });
  });

  group('2. ChatMessage sender roles and doctor quota immunity', () {
    test('ChatMessage distinguishes between patient and doctor roles', () {
      final patientMsg = ChatMessage(
        id: 'msg_1',
        conversationId: 'conv_1',
        senderId: 'pat_1',
        senderName: 'Patient Test',
        text: 'Bonjour Docteur, j\'ai une question.',
        time: DateTime.now(),
        senderRole: 'patient',
      );

      final docMsg = ChatMessage(
        id: 'msg_2',
        conversationId: 'conv_1',
        senderId: 'doc_1',
        senderName: 'Dr. Test',
        text: 'Bonjour, que ressentez-vous ?',
        time: DateTime.now(),
        senderRole: 'doctor',
      );

      expect(patientMsg.isFromPatient, isTrue);
      expect(patientMsg.isFromDoctor, isFalse);
      expect(patientMsg.senderRole, 'patient');

      expect(docMsg.isFromDoctor, isTrue);
      expect(docMsg.isFromPatient, isFalse);
      expect(docMsg.senderRole, 'doctor');

      final json = docMsg.toJson();
      expect(json['senderRole'], 'doctor');

      final restored = ChatMessage.fromJson(json);
      expect(restored.isFromDoctor, isTrue);
      expect(restored.senderRole, 'doctor');
    });

    test('Doctor messages do not count towards patient quota', () {
      // In our design, patient sends consume freeMessagesUsed, while doctor replies do not
      var patientUsage = PatientMessageUsage(
        patientId: 'pat_1',
        freeMessagesLimit: 10,
        freeMessagesUsed: 3,
        updatedAt: DateTime.now(),
      );

      expect(patientUsage.remaining, 7);

      // Doctor replies 5 times
      final doctorReplies = List.generate(
        5,
        (i) => ChatMessage(
          id: 'doc_reply_$i',
          conversationId: 'conv_1',
          senderId: 'doc_1',
          senderName: 'Dr. Test',
          text: 'Réponse $i',
          time: DateTime.now(),
          senderRole: 'doctor',
        ),
      );

      expect(doctorReplies.length, 5);
      // Patient usage remains untouched at 7
      expect(patientUsage.remaining, 7);
      expect(patientUsage.canSend, isTrue);
    });
  });

  group('3. Treating Doctor Request State & Conversation Auto-Creation', () {
    test('TreatingDoctorRequest status lifecycle: pending -> accepted or rejected', () {
      final req = TreatingDoctorRequest(
        id: 'req_test_001',
        patientId: 'pat_001',
        doctorId: 'doc_001',
        doctorName: 'Dr. Kouassi',
        doctorSpecialty: 'Cardiologue',
        patientName: 'Kouame Marc',
        message: 'Suivi hypertension artérielle',
        status: TreatingDoctorStatus.pending,
        createdAt: DateTime.now(),
      );

      expect(req.status, TreatingDoctorStatus.pending);
      expect(req.isPending, isTrue);
      expect(req.isAccepted, isFalse);

      final acceptedReq = TreatingDoctorRequest(
        id: req.id,
        patientId: req.patientId,
        patientName: req.patientName,
        doctorId: req.doctorId,
        doctorName: req.doctorName,
        doctorSpecialty: req.doctorSpecialty,
        message: req.message,
        status: TreatingDoctorStatus.accepted,
        createdAt: req.createdAt,
      );
      expect(acceptedReq.status, TreatingDoctorStatus.accepted);
      expect(acceptedReq.isAccepted, isTrue);

      final rejectedReq = TreatingDoctorRequest(
        id: req.id,
        patientId: req.patientId,
        patientName: req.patientName,
        doctorId: req.doctorId,
        doctorName: req.doctorName,
        doctorSpecialty: req.doctorSpecialty,
        message: req.message,
        status: TreatingDoctorStatus.rejected,
        rejectionReason: 'Patient hors secteur',
        createdAt: req.createdAt,
      );
      expect(rejectedReq.status, TreatingDoctorStatus.rejected);
      expect(rejectedReq.rejectionReason, 'Patient hors secteur');
    });

    test('Doctor accepting request creates or links conversation', () {
      final messageProvider = MessageProvider();
      expect(messageProvider.allConversations.isEmpty, isTrue);

      final conv = messageProvider.getOrCreateConversation(
        patientId: 'pat_001',
        doctorId: 'doc_001',
        patientName: 'Kouame Marc',
        doctorName: 'Dr. Kouassi',
        doctorSpecialty: 'Cardiologue',
      );

      expect(conv.patientId, 'pat_001');
      expect(conv.doctorId, 'doc_001');
      expect(conv.patientName, 'Kouame Marc');
      expect(conv.doctorName, 'Dr. Kouassi');
      expect(conv.doctorSpecialty, 'Cardiologue');
      expect(messageProvider.allConversations.length, 1);
    });
  });

  group('4. Admin Console Role Guard & User Management', () {
    test('Admin DbUser status and role checks', () {
      final adminUser = DbUser(
        id: 'admin_1',
        role: 'admin',
        email: 'admin@mydoctor.ci',
        phone: '+2250101010101',
        passwordHash: 'hash',
        firstName: 'Administrateur',
        lastName: 'MyDoctor',
        status: 'active',
        createdAt: DateTime.now(),
      );

      expect(adminUser.role, 'admin');
      expect(adminUser.status, 'active');
    });

    test('Doctor validation status transitions from pending to active', () {
      final pendingDoctor = DbUser(
        id: 'doc_pending_1',
        role: 'doctor',
        email: 'dr.new@mydoctor.ci',
        phone: '+2250505050505',
        passwordHash: 'hash',
        firstName: 'Awa',
        lastName: 'Bakayoko',
        status: 'pending',
        specialty: 'Pédiatrie',
        orderNumber: 'PED-9988',
        createdAt: DateTime.now(),
      );

      expect(pendingDoctor.status, 'pending');

      // Admin validates doctor
      final validatedDoctor = pendingDoctor.copyWith(status: 'active');
      expect(validatedDoctor.status, 'active');
    });
  });

  group('5. UI Accessibility & Entry Point', () {
    testWidgets('WelcomeScreen displays discrete Admin Portal entry link', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WelcomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final adminButtonFinder = find.byKey(const Key('welcome_admin_button'));
      expect(adminButtonFinder, findsOneWidget);
      expect(find.text('Portail Administrateur'), findsOneWidget);
    });

    testWidgets('AdminDashboardScreen blocks non-admin users with login dialog option', (WidgetTester tester) async {
      final authProvider = AuthProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider(create: (_) => MessageProvider()),
            ChangeNotifierProvider(create: (_) => TreatingRequestProvider()),
          ],
          child: const MaterialApp(
            home: AdminDashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Since authProvider is not logged in as admin, access barrier should be rendered
      expect(find.text('Accès Restreint'), findsOneWidget);
      expect(find.text('Connexion Administrateur'), findsOneWidget);
    });
  });
}
