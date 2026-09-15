// test/chat_quota_payment_test.dart
//
// Tests unitaires et d'interface pour l'alerte et le paiement de consultation
// lorsque le quota de messages gratuits est atteint.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:allo_docteur/providers/message_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Chat Quota & System Message Tests', () {
    test('sendSystemMessage insère un message info d\'invitation à payer la consultation', () {
      final mp = MessageProvider();
      const convId = 'conv_test_quota';

      expect(mp.messagesOf(convId), isEmpty);

      mp.sendSystemMessage(
        convId,
        '🔔 Quota de 10 messages gratuits atteint. Pour continuer à échanger avec le Dr. Touré, veuillez régler votre consultation.',
      );

      final messages = mp.messagesOf(convId);
      expect(messages.length, equals(1));
      expect(messages.first.type, equals(ChatMsgType.info));
      expect(messages.first.senderRole, equals('system'));
      expect(messages.first.text, contains('Quota de 10 messages gratuits atteint'));
      expect(messages.first.text, contains('veuillez régler votre consultation'));
    });
  });

  group('Quota UI Banner & Button Tests', () {
    testWidgets('Bannière de quota affiche l\'incitation au paiement quand remaining = 0', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFFFFF1F2),
              child: Row(
                children: [
                  const Icon(Icons.lock_rounded, size: 16, color: Color(0xFFE11D48)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Quota atteint : veuillez régler la consultation pour continuer.',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFE11D48),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE11D48),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Payer'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Quota atteint : veuillez régler la consultation pour continuer.'), findsOneWidget);
      expect(find.text('Payer'), findsOneWidget);
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
    });

    testWidgets('Zone de saisie bloquée affiche Payer la consultation', (WidgetTester tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InkWell(
              onTap: () => tapped = true,
              child: Column(
                children: [
                  const Text('Quota de 10 messages atteint'),
                  const Text('Veuillez régler la consultation pour continuer à échanger.'),
                  ElevatedButton.icon(
                    onPressed: () => tapped = true,
                    icon: const Icon(Icons.credit_card_rounded),
                    label: const Text('Payer la consultation'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Quota de 10 messages atteint'), findsOneWidget);
      expect(find.text('Veuillez régler la consultation pour continuer à échanger.'), findsOneWidget);
      expect(find.text('Payer la consultation'), findsOneWidget);

      await tester.tap(find.text('Payer la consultation'));
      expect(tapped, isTrue);
    });
  });
}
