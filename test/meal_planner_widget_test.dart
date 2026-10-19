import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app_lab_2/features/meal_planner/screens/meal_planner_screen.dart';
import 'package:mobile_app_lab_2/shared/services/app_state.dart';
import 'package:mobile_app_lab_2/shared/services/mock_repository.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('shows the current week and an empty planner state', (
    tester,
  ) async {
    final state = AppState(MockRepository());
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: const MaterialApp(home: MealPlannerScreen()),
      ),
    );

    expect(find.text('Lập kế hoạch bữa ăn'), findsOneWidget);
    expect(find.text('Chưa có kế hoạch cho ngày này.'), findsOneWidget);
    expect(find.text('Thêm'), findsOneWidget);
  });

  testWidgets('selecting a day updates the planner date heading', (
    tester,
  ) async {
    final state = AppState(MockRepository());
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: const MaterialApp(home: MealPlannerScreen()),
      ),
    );

    await tester.tap(find.text('T2').first);
    await tester.pump();
    expect(find.textContaining('Ngày '), findsOneWidget);
  });
}
