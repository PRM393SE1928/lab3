import 'package:flutter_test/flutter_test.dart';
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

    expect(state.meals, hasLength(initialCount + 1));
    expect(meal.items, hasLength(1));
    expect(state.updateMeal(meal.id, MealType.snack, [state.foods[3]]), isTrue);
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

    expect(evaluation.score, 96);
    expect(state.lastEvaluation, same(evaluation));
    expect(state.evaluationFor(meal), same(evaluation));
    expect(state.weeklyScore, 76);
    expect(state.weeklyScores.last, 80);
    expect(state.todayScore, 80);
    expect(state.streakDays, 2);
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
}
