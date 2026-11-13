import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app_lab_2/features/food_diary/models/food_item.dart';
import 'package:mobile_app_lab_2/features/food_diary/models/meal.dart';
import 'package:mobile_app_lab_2/features/user_progress/models/health_profile.dart';
import 'package:mobile_app_lab_2/features/user_progress/services/health_profile_recommender.dart';
import 'package:mobile_app_lab_2/shared/services/app_state.dart';
import 'package:mobile_app_lab_2/shared/services/mock_repository.dart';

void main() {
  test('maps profile age to the existing age groups', () {
    final profile = HealthProfile(age: 16, weightKg: 55, heightCm: 165);
    expect(profile.ageGroup, AgeGroup.age13To17);
  });

  test('personalized recommendation uses the existing meal catalog', () {
    final state = AppState(MockRepository());
    final suggestion = const HealthProfileRecommender().recommend(
      profile: HealthProfile(age: 35, weightKg: 62.5, heightCm: 168),
      foods: state.foods,
      mealType: MealType.lunch,
    );

    expect(suggestion, isNotNull);
    expect(state.foods, contains(suggestion!.food));
    expect(suggestion.reasons, isNotEmpty);
    expect(suggestion.principles, isNotEmpty);
  });

  test('incomplete profile keeps general suggestions available', () {
    final state = AppState(MockRepository());
    expect(
      const HealthProfileRecommender().recommend(
        profile: state.healthProfile,
        foods: state.foods,
        mealType: MealType.breakfast,
      ),
      isNull,
    );
    expect(
      state.suggestedFoodsFor(MealType.breakfast, ageGroup: AgeGroup.age18To59),
      isNotEmpty,
    );
  });

  test('health profile updates without touching meals or plans', () async {
    final state = AppState(MockRepository());
    final mealCount = state.meals.length;
    await state.updateHealthProfile(age: 42, weightKg: 70.5, heightCm: 172);

    expect(state.healthProfile.age, 42);
    expect(state.healthProfile.weightKg, 70.5);
    expect(state.healthProfile.heightCm, 172);
    expect(state.meals, hasLength(mealCount));
    expect(state.mealPlans, isEmpty);
  });
}
