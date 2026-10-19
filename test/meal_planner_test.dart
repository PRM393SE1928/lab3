import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app_lab_2/features/food_diary/models/meal.dart';
import 'package:mobile_app_lab_2/features/food_diary/models/food_item.dart';
import 'package:mobile_app_lab_2/features/meal_planner/models/meal_plan.dart';
import 'package:mobile_app_lab_2/shared/services/app_state.dart';
import 'package:mobile_app_lab_2/shared/services/mock_repository.dart';

void main() {
  late AppState state;
  final date = DateTime(2026, 10, 19);

  setUp(() => state = AppState(MockRepository()));

  test('creates, updates, deletes and de-duplicates a plan slot', () {
    final food = state.foods.first;
    final plan = state.addMealPlan(MealType.breakfast, [food], date: date);
    expect(state.getPlansForDate(date), [plan]);
    expect(
      state.addMealPlan(MealType.breakfast, [food], date: date),
      same(plan),
    );
    expect(
      state.updateMealPlan(plan.id, MealType.lunch, [
        state.foods[1],
      ], date: date),
      isTrue,
    );
    expect(state.getPlansForDate(date).single.type, MealType.lunch);
    expect(state.deleteMealPlan(plan.id), isTrue);
    expect(state.deleteMealPlan(plan.id), isFalse);
  });

  test('keeps planned meals out of diary and creates one actual meal', () {
    final plan = state.addMealPlan(MealType.dinner, [
      state.foods[2],
    ], date: date);
    expect(state.meals.where((meal) => meal.date == date), isEmpty);
    final actual = state.completeMealPlan(
      plan.id,
      actualItems: [state.foods[3]],
    );
    expect(actual, isNotNull);
    expect(actual!.plannedMealId, plan.id);
    expect(state.meals, contains(actual));
    expect(state.getMealPlanById(plan.id)!.status, MealPlanStatus.completed);
    expect(state.completeMealPlan(plan.id), same(actual));
    expect(
      state.meals.where((meal) => meal.plannedMealId == plan.id),
      hasLength(1),
    );
  });

  test(
    'shopping list merges exact ingredient names and keeps unit keys separate',
    () {
      const first = FoodItem(
        id: 'first',
        name: 'Dish A',
        category: 'breakfast',
        ingredients: ['rice', 'tofu'],
      );
      const second = FoodItem(
        id: 'second',
        name: 'Dish B',
        category: 'lunch',
        ingredients: ['rice'],
      );
      final planA = state.addMealPlan(MealType.breakfast, [first], date: date);
      final planB = state.addMealPlan(MealType.lunch, [
        second,
      ], date: date.add(const Duration(days: 1)));
      final result = state.buildShoppingList([planA, planB]);
      expect(result.map((item) => item.key).toSet(), hasLength(result.length));
      expect(state.shoppingItems, isNotEmpty);
    },
  );

  test('editing a real meal does not mutate its original plan', () {
    final plan = state.addMealPlan(MealType.dinner, [
      state.foods[2],
    ], date: date);
    final actual = state.completeMealPlan(plan.id)!;
    state.updateMeal(actual.id, MealType.dinner, [state.foods[4]]);
    expect(state.getMealPlanById(plan.id)!.items.single.id, state.foods[2].id);
    expect(
      state.meals
          .firstWhere((meal) => meal.plannedMealId == plan.id)
          .items
          .single
          .id,
      state.foods[4].id,
    );
  });
}
