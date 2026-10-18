import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app_lab_2/features/food_diary/models/food_item.dart';
import 'package:mobile_app_lab_2/features/food_diary/models/meal.dart';
import 'package:mobile_app_lab_2/shared/services/app_state.dart';
import 'package:mobile_app_lab_2/shared/services/mock_repository.dart';

void main() {
  late AppState state;

  setUp(() {
    state = AppState(MockRepository());
  });

  test('adds, updates and deletes meals through the shared contract', () {
    final initialCount = state.meals.length;
    final meal = state.addMeal(MealType.dinner, [state.foods[2]]);
    final snack = state.foods.firstWhere((food) => food.id == 'nuts');

    expect(state.meals, hasLength(initialCount + 1));
    expect(meal.items, hasLength(1));
    expect(state.updateMeal(meal.id, MealType.snack, [snack]), isTrue);
    expect(state.meals.last.type, MealType.snack);
    expect(state.meals.last.items.single.id, 'nuts');
    expect(state.deleteMeal(meal.id), isTrue);
    expect(state.meals, hasLength(initialCount));
    expect(state.deleteMeal(meal.id), isFalse);
  });

  test('rejects meals without food and unknown meal IDs', () {
    expect(() => state.addMeal(MealType.dinner, []), throwsArgumentError);
    expect(
      state.updateMeal('missing', MealType.dinner, [state.foods.first]),
      isFalse,
    );
    expect(state.deleteMeal('missing'), isFalse);
  });

  test('uses one score rule for evaluation and progress', () {
    final meal = state.addMeal(MealType.dinner, [
      state.foods[0],
      state.foods[1],
    ]);
    final evaluation = state.evaluateMeal(meal);

    expect(evaluation.score, 100);
    expect(state.lastEvaluation, same(evaluation));
    expect(state.evaluationFor(meal), same(evaluation));

    expect(state.streakDays, 1);
  });

  test('does not count an unevaluated meal in progress scores', () {
    final meal = state.addMeal(MealType.dinner, [state.foods[2]]);

    expect(state.savedEvaluationFor(meal.id), isNull);
    expect(state.todayScore, 0);
    expect(state.weeklyScore, 0);

    state.evaluateMeal(meal);

    expect(state.savedEvaluationFor(meal.id), isNotNull);
    expect(state.todayScore, greaterThan(0));
  });

  test('marks known articles once and ignores unknown articles', () {
    expect(state.articles.first.isRead, isFalse);
    expect(state.markArticleRead(state.articles.first.id), isTrue);
    expect(state.articles.first.isRead, isTrue);
    expect(state.markArticleRead(state.articles.first.id), isFalse);
    expect(state.markArticleRead('missing'), isFalse);
  });

  test('updates profile through AppState', () {
    state.updateProfileName('Alex');
    expect(state.profile.name, 'Alex');
    state.updateProfile(
      name: 'Alex Nguyen',
      email: 'alex@example.com',
      goal: 'Eat more plants',
      dietaryFocus: 'Beans and vegetables',
      targetScore: 90,
    );
    expect(state.profile.email, 'alex@example.com');
    expect(state.profile.targetScore, 90);
  });

  test('updates notification settings through AppState', () {
    state.updateNotificationSettings(
      dailyReminders: false,
      weeklySummary: false,
      progressNotifications: false,
      compactDiary: true,
    );

    expect(state.dailyRemindersEnabled, isFalse);
    expect(state.weeklySummaryEnabled, isFalse);
    expect(state.progressNotificationsEnabled, isFalse);
    expect(state.compactDiaryEnabled, isTrue);
  });

  test('filters meals by date and safely resolves unknown IDs', () {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final meal = state.addMeal(
      MealType.snack,
      [state.foods[3]],
      date: yesterday,
      note: 'Ăn nhẹ',
    );

    expect(state.getMealsForDate(yesterday), contains(meal));
    expect(state.getMealsForDate(DateTime.now()), isNot(contains(meal)));
    expect(state.getMealById(meal.id), same(meal));
    expect(state.getMealById('missing'), isNull);
    expect(meal.note, 'Ăn nhẹ');
  });

  test('clears a saved evaluation when meal contents change', () {
    final meal = state.addMeal(MealType.dinner, [state.foods[2]]);
    state.evaluateMeal(meal);
    expect(state.savedEvaluationFor(meal), isNotNull);

    state.updateMeal(meal.id, MealType.dinner, [state.foods[4]]);

    expect(state.savedEvaluationFor(state.getMealById(meal.id)!), isNull);
  });

  test('provides exactly 50 unique foods in the required categories', () {
    final foods = state.foods;
    final categoryCounts = <String, int>{};
    for (final food in foods) {
      categoryCounts[food.category] = (categoryCounts[food.category] ?? 0) + 1;
    }

    expect(foods, hasLength(50));
    expect(foods.map((food) => food.id).toSet(), hasLength(50));
    expect(categoryCounts, {
      'breakfast': 12,
      'lunch': 15,
      'dinner': 15,
      'snack': 8,
    });
    expect(foods.every((food) => food.sourceType == 'adapted'), isTrue);
  });

  test('normalizes Vietnamese accents for food search', () {
    expect(normalizeFoodText('yen mach'), contains('yen mach'));
    expect(filterFoodItems(state.foods, query: 'yen mach'), isNotEmpty);
    expect(filterFoodItems(state.foods, category: 'breakfast'), hasLength(12));
    expect(
      filterFoodItems(state.foods, category: 'lunch', query: 'yen mach'),
      isEmpty,
    );
  });
}
