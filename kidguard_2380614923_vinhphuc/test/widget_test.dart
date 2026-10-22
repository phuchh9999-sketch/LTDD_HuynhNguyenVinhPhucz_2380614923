import 'package:flutter_test/flutter_test.dart';
import 'package:kidguard_2380614923_vinhphuc/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const KidGuardApp());
    expect(find.byType(KidGuardApp), findsOneWidget);
  });
}
