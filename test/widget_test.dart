import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app_lab_2/app.dart';

void main() {
  testWidgets('starts on the Home screen with seeded meals', (tester) async {
    await tester.pumpWidget(const LongevaApp());
    await tester.pumpAndSettle();

    expect(find.text('Longeva'), findsOneWidget);
    expect(find.text('Bữa ăn của bạn'), findsOneWidget);
    expect(find.text('Ghi lại bữa ăn'), findsOneWidget);
  });
}
