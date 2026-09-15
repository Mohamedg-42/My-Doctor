import 'package:flutter_test/flutter_test.dart';
import 'package:allo_docteur/main.dart';
import 'package:allo_docteur/providers/treating_request_provider.dart';
import 'package:allo_docteur/screens/auth/login_screen.dart';

void main() {
  testWidgets('My Doctor app launches', (WidgetTester tester) async {
    final trProvider = TreatingRequestProvider();
    await tester.pumpWidget(AlloDocteurApp(treatingRequestProvider: trProvider));
    expect(find.byType(AlloDocteurApp), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
