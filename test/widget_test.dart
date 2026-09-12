import 'package:flutter_test/flutter_test.dart';
import 'package:allo_docteur/main.dart';
import 'package:allo_docteur/providers/treating_request_provider.dart';

void main() {
  testWidgets('My Doctor app launches', (WidgetTester tester) async {
    final trProvider = TreatingRequestProvider();
    await tester.pumpWidget(AlloDocteurApp(treatingRequestProvider: trProvider));
    expect(find.byType(AlloDocteurApp), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });
}
