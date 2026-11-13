import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_app_lab_2/features/food_diary/models/food_item.dart';
import 'package:mobile_app_lab_2/features/meal_evaluation/services/meal_photo_analyzer.dart';

void main() {
  final catalog = [
    const FoodItem(
      id: 'breakfast_oat_banana',
      name: 'Yến mạch chuối',
      category: 'breakfast',
    ),
    const FoodItem(
      id: 'lunch_vegetable_bowl',
      name: 'Rau củ trộn',
      category: 'lunch',
    ),
    const FoodItem(id: 'snack_apple', name: 'Táo', category: 'snack'),
  ];

  test('Demo analyzer is deterministic and clearly marked', () async {
    const analyzer = DemoMealPhotoAnalyzer();

    final result = await analyzer.analyze(
      Uint8List.fromList([1, 2, 3]),
      catalog: catalog,
    );

    expect(result.mode, MealPhotoAnalysisMode.demo);
    expect(result.foods.map((food) => food.catalogId), [
      'breakfast_oat_banana',
      'lunch_vegetable_bowl',
    ]);
    expect(result.description, contains('Demo'));
  });

  test('empty photos are rejected', () {
    expect(
      () =>
          const DemoMealPhotoAnalyzer().analyze(Uint8List(0), catalog: catalog),
      throwsA(isA<MealPhotoAnalysisException>()),
    );
  });

  test('Backend provider does not silently fall back without an endpoint', () {
    expect(
      () =>
          BackendMealPhotoAnalyzer(endpoint: '')
              .analyze(Uint8List.fromList([1]), catalog: catalog),
      throwsA(isA<MealPhotoAnalysisException>()),
    );
  });
}
