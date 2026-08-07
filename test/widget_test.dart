import 'package:flutter_test/flutter_test.dart';
import 'package:firdan_farma_windows/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FirdanFarmaApp());
    expect(find.byType(FirdanFarmaApp), findsOneWidget);
  });
}
