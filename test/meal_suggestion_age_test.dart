import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app_lab_2/features/food_diary/models/food_item.dart';
import 'package:mobile_app_lab_2/features/food_diary/models/meal.dart';
import 'package:mobile_app_lab_2/features/meal_planner/widgets/meal_suggestion_sheet.dart';
import 'package:mobile_app_lab_2/shared/services/app_state.dart';
import 'package:mobile_app_lab_2/shared/services/mock_repository.dart';
import 'package:provider/provider.dart';

void main() {
  test('age filtering never treats missing metadata as suitable', () {
    final state = AppState(MockRepository());
    expect(
      state.suggestedFoodsFor(MealType.breakfast, ageGroup: AgeGroup.age18To59),
      isNotEmpty,
    );
    expect(
      state.suggestedFoodsFor(MealType.breakfast, ageGroup: AgeGroup.age6To12),
      isEmpty,
    );
    expect(
      state.suggestedFoodsFor(MealType.breakfast, ageGroup: AgeGroup.under2),
      isEmpty,
    );
  });

  test('age metadata supports every meal type without creating a plan', () {
    final state = AppState(MockRepository());
    for (final type in MealType.values) {
      expect(
        state.suggestedFoodsFor(type, ageGroup: AgeGroup.age18To59),
        isNotEmpty,
      );
    }
    expect(state.mealPlans, isEmpty);
    expect(state.meals, isNotEmpty);
  });

  test('explicit metadata can be used for a non-adult group', () {
    const food = FoodItem(
      id: 'annotated',
      name: 'Annotated food',
      category: 'snack',
      ageGroups: [AgeGroup.age2To5],
    );
    final state = AppState(MockRepository())..foods.add(food);
    expect(
      state.suggestedFoodsFor(MealType.snack, ageGroup: AgeGroup.age2To5),
      contains(food),
    );
    expect(
      state.suggestedFoodsFor(MealType.snack, ageGroup: AgeGroup.age6To12),
      isNot(contains(food)),
    );
  });

  testWidgets('suggestion sheet exposes age controls', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: AppState(MockRepository()),
        child: MaterialApp(
          home: Scaffold(
            body: MealSuggestionSheet(
              date: DateTime(2026, 10, 19),
              initialAgeGroup: AgeGroup.age6To12,
            ),
          ),
        ),
      ),
    );
    expect(
      find.byKey(const ValueKey('meal-suggestion-age-group')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('meal-suggestion-age-guidance')),
      findsOneWidget,
    );
    await tester.tap(find.byType(ChoiceChip).first);
    await tester.pump();
    expect(
      find.byKey(const ValueKey('meal-suggestion-general-catalog-warning')),
      findsOneWidget,
    );
  });
}
