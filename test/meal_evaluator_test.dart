import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app_lab_2/features/food_diary/models/food_item.dart';
import 'package:mobile_app_lab_2/features/food_diary/models/meal.dart';
import 'package:mobile_app_lab_2/features/meal_evaluation/services/meal_evaluator.dart';
import 'package:mobile_app_lab_2/shared/services/app_state.dart';
import 'package:mobile_app_lab_2/shared/services/mock_repository.dart';

void main() {
  const evaluator = RuleBasedMealEvaluator();
  final foods = MockRepository().foods;
  Meal meal(List<FoodItem> items) => Meal(
    id: 'test',
    type: MealType.lunch,
    date: DateTime(2026, 10, 12),
    items: items,
  );

  test('scores depend on groups, not item count; duplicates add no points', () {
    const soupFood = FoodItem(id: 'soup', name: 'Súp rau', category: 'lunch');
    final soup = evaluator.calculate(meal([soupFood]));
    final oats = evaluator.calculate(
      meal([
        const FoodItem(id: 'oats', name: 'Yến mạch', category: 'breakfast'),
      ]),
    );
    expect(soup.score, 20);
    expect(oats.score, 66);
    expect(evaluator.calculate(meal([soupFood, soupFood])).score, soup.score);
    final balanced = evaluator.calculate(meal([foods[0], foods[1]]));
    expect(balanced.score, 100);
    expect(balanced.criteria.values.reduce((a, b) => a + b), balanced.score);
    expect(balanced.suggestions, isEmpty);
    expect(balanced.mealId, 'test');
  });

  test('unknown food does not get invented groups; empty meal fails', () {
    final result = evaluator.calculate(
      meal([const FoodItem(id: 'unknown', name: 'Món mới', category: 'Rau')]),
    );
    expect(result.score, 0);
    expect(result.warnings.single, contains('Món mới'));
    expect(
      () => evaluator.calculate(meal([])),
      throwsA(isA<EvaluationException>()),
    );
  });

  test('representative catalog combinations stay bounded with immutable result collections', () {
    final combinations = <List<FoodItem>>[
      for (final food in foods) [food],
      for (var index = 0; index < foods.length - 1; index++)
        [foods[index], foods[index + 1]],
      foods,
    ];
    for (final items in combinations) {
      final result = evaluator.calculate(meal(items));
      expect(result.score, inInclusiveRange(0, 100));
      expect(
        result.criteria.values.every((value) => value >= 0 && value <= 25),
        isTrue,
      );
      expect(() => result.criteria.clear(), throwsUnsupportedError);
      expect(() => result.suggestions.clear(), throwsUnsupportedError);
    }
  });

  test(
    'recording again updates latest; edits/deletes invalidate saved result',
    () {
      final state = AppState(MockRepository());
      final first = state.meals.first;
      final second = state.meals.last;
      state.evaluateMeal(first);
      state.evaluateMeal(second);
      state.evaluateMeal(first);
      expect(state.lastEvaluation?.mealId, first.id);
      state.updateMeal(first.id, first.type, [foods[4]]);
      expect(state.savedEvaluationFor(first.id), isNull);
      state.deleteMeal(second.id);
      expect(state.savedEvaluationFor(second.id), isNull);
    },
  );

  test('does not save an evaluation under a different meal ID', () {
    final state = AppState(MockRepository());
    final meal = state.meals.first;
    final result = const RuleBasedMealEvaluator().calculate(
      Meal(
        id: 'different-meal',
        type: MealType.lunch,
        date: DateTime(2026, 10, 12),
        items: [FoodItem(id: 'oats', name: 'Yến mạch', category: 'breakfast')],
      ),
    );

    state.recordEvaluation(meal.id, result);

    expect(state.savedEvaluationFor(meal.id), isNull);
  });
}
