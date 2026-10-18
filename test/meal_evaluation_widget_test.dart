import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app_lab_2/core/router/app_router.dart';
import 'package:mobile_app_lab_2/features/food_diary/models/meal.dart';
import 'package:mobile_app_lab_2/features/meal_evaluation/models/meal_evaluation.dart';
import 'package:mobile_app_lab_2/features/meal_evaluation/screens/meal_result_screen.dart';
import 'package:mobile_app_lab_2/features/meal_evaluation/screens/suggestions_screen.dart';
import 'package:mobile_app_lab_2/features/meal_evaluation/services/meal_evaluator.dart';
import 'package:mobile_app_lab_2/shared/services/app_state.dart';
import 'package:mobile_app_lab_2/shared/services/mock_repository.dart';

class ControlledEvaluator implements MealEvaluator {
  final pending = <Completer<MealEvaluation>>[];
  final inputs = <Meal>[];
  @override
  Future<MealEvaluation> evaluate(Meal meal) {
    inputs.add(meal);
    final completer = Completer<MealEvaluation>();
    pending.add(completer);
    return completer.future;
  }

  void succeed() => pending.last.complete(
    const RuleBasedMealEvaluator().calculate(inputs.last),
  );
}

void main() {
  late AppState state;
  late ControlledEvaluator evaluator;
  setUp(() {
    state = AppState(MockRepository());
    evaluator = ControlledEvaluator();
  });

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: MaterialApp(
          home: MealResultScreen(meal: state.meals.first, evaluator: evaluator),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets(
    'Member 1 meal route connects result and correct suggestions on mobile',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final meal = state.addMeal(MealType.dinner, [state.foods.last]);
      AppRouter.router.go('/meal-result', extra: meal);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: state,
          child: MaterialApp.router(routerConfig: AppRouter.router),
        ),
      );
      await tester.pumpAndSettle();
      expect(state.savedEvaluationFor(meal.id)?.score, 20);
      await tester.scrollUntilVisible(find.text('Xem gợi ý'), 300);
      await tester.tap(find.text('Xem gợi ý'));
      await tester.pumpAndSettle();
      expect(find.text('Bữa tối · 20/100'), findsOneWidget);
    },
  );

  testWidgets('loading -> error -> retry -> result shared with progress', (
    tester,
  ) async {
    await open(tester);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(state.lastEvaluation, isNull);
    evaluator.pending.last.completeError(Exception('unavailable'));
    await tester.pumpAndSettle();
    expect(find.text('Thử lại'), findsOneWidget);
    expect(state.lastEvaluation, isNull);
    await tester.tap(find.text('Thử lại'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    evaluator.succeed();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('meal-score')), findsOneWidget);
    expect(state.lastEvaluation?.score, 66);
    expect(state.evaluationFor(state.meals.first), same(state.lastEvaluation));
  });

  testWidgets('change foods, failure leaves original; retry applies draft', (
    tester,
  ) async {
    await open(tester);
    evaluator.succeed();
    await tester.pumpAndSettle();
    final original = state.meals.first;
    final edit = find.text('Đổi món và đánh giá lại');
    await tester.scrollUntilVisible(edit, 300);
    await tester.tap(edit);
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(CheckboxListTile, state.foods[1].name),
    );
    await tester.tap(find.text('Đánh giá lại'));
    await tester.pump();
    expect(state.meals.first, same(original));
    evaluator.pending.last.completeError(Exception('offline'));
    await tester.pumpAndSettle();
    expect(state.meals.first, same(original));
    expect(state.savedEvaluationFor(original.id)?.score, 66);
    await tester.tap(find.text('Thử lại'));
    await tester.pump();
    expect(evaluator.inputs.last.items, hasLength(2));
    evaluator.succeed();
    await tester.pumpAndSettle();
    expect(state.meals.first.items, hasLength(2));
    expect(state.meals.first.id, original.id);
    expect(state.meals.first.date, original.date);
    expect(state.lastEvaluation?.score, 100);
  });

  testWidgets('cancel food editor leaves meal and score unchanged', (
    tester,
  ) async {
    await open(tester);
    evaluator.succeed();
    await tester.pumpAndSettle();
    final original = state.meals.first;
    final edit = find.text('Đổi món và đánh giá lại');
    await tester.scrollUntilVisible(edit, 300);
    await tester.tap(edit);
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(CheckboxListTile, state.foods.first.name),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Đánh giá lại'),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();
    expect(state.meals.first, same(original));
    expect(evaluator.inputs, hasLength(1));
  });

  testWidgets(
    'updated meal rejects stale async result then retries latest input',
    (tester) async {
      await open(tester);
      final original = state.meals.first;
      state.updateMeal(original.id, original.type, [state.foods[4]]);
      evaluator.succeed();
      await tester.pumpAndSettle();
      expect(state.lastEvaluation, isNull);
      expect(find.text('Thử lại'), findsOneWidget);
      await tester.tap(find.text('Thử lại'));
      await tester.pump();
      expect(evaluator.inputs.last.items.single.id, 'soup');
      evaluator.succeed();
      await tester.pumpAndSettle();
      expect(state.lastEvaluation?.score, 20);
    },
  );

  testWidgets('deleted meal cannot receive in-flight result', (tester) async {
    await open(tester);
    state.deleteMeal(state.meals.first.id);
    evaluator.succeed();
    await tester.pumpAndSettle();
    expect(state.lastEvaluation, isNull);
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.textContaining('không còn trong nhật ký'), findsOneWidget);
    expect(evaluator.inputs, hasLength(1));
  });

  testWidgets('leaving while loading does not record an abandoned result', (
    tester,
  ) async {
    await open(tester);
    await tester.pumpWidget(const SizedBox());
    evaluator.succeed();
    await tester.pumpAndSettle();
    expect(state.lastEvaluation, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'suggestions use requested meal, never another latest evaluation',
    (tester) async {
      final first = state.meals.first;
      state.evaluateMeal(first);
      state.evaluateMeal(state.meals.last);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: state,
          child: MaterialApp(home: SuggestionsScreen(mealId: first.id)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('${first.type.label} · 66/100'), findsOneWidget);
      state.updateMeal(first.id, first.type, [state.foods[4]]);
      await tester.pumpAndSettle();
      expect(find.textContaining('Chưa có kết quả'), findsOneWidget);
    },
  );
}
