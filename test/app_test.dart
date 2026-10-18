import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app_lab_2/app.dart';
import 'package:mobile_app_lab_2/core/router/app_router.dart';
import 'package:mobile_app_lab_2/features/home/screens/home_screen.dart';
import 'package:mobile_app_lab_2/shared/services/app_state.dart';
import 'package:mobile_app_lab_2/shared/services/mock_repository.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('shows the Longeva home screen', (tester) async {
    await tester.pumpWidget(const LongevaApp());
    await tester.pumpAndSettle();
    expect(find.text('Longeva'), findsOneWidget);
    expect(find.text('Bữa ăn của bạn'), findsOneWidget);
  });

  testWidgets('shows a safe error for a meal route without valid extra', (
    tester,
  ) async {
    await tester.pumpWidget(const LongevaApp());
    AppRouter.router.go('/meal-result');
    await tester.pumpAndSettle();

    expect(find.text('Cần có bữa ăn để xem kết quả đánh giá.'), findsOneWidget);
    expect(find.text('Về trang chủ'), findsOneWidget);
  });

  testWidgets('settings toggles are available', (tester) async {
    await tester.pumpWidget(const LongevaApp());
    AppRouter.router.go('/settings');
    await tester.pumpAndSettle();

    final switches = tester.widgetList<SwitchListTile>(
      find.byType(SwitchListTile),
    );
    expect(switches, hasLength(4));
    expect(switches.every((item) => item.onChanged != null), isTrue);
    expect(find.text('Nhắc nhở hằng ngày'), findsOneWidget);
  });

  testWidgets('shows an empty Home state without fake meals', (tester) async {
    final state = AppState(MockRepository())..meals.clear();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    expect(find.text('0 bữa đã ghi hôm nay'), findsOneWidget);
    expect(
      find.text('Chưa có bữa ăn nào được ghi lại hôm nay.'),
      findsOneWidget,
    );
    expect(find.text('Chưa có đánh giá'), findsOneWidget);
  });
}
