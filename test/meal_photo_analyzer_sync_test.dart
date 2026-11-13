import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app_lab_2/features/food_diary/models/food_item.dart';
import 'package:mobile_app_lab_2/features/meal_evaluation/services/meal_photo_analyzer.dart';

void main() {
  test('keeps all recognized foods instead of truncating the list', () async {
    final catalog = List.generate(
      7,
      (index) => FoodItem(
        id: 'vegetable_$index',
        name: 'Thực phẩm $index',
        category: 'lunch',
      ),
    );

    final result = await const DemoMealPhotoAnalyzer().analyze(
      Uint8List.fromList([1]),
      catalog: catalog,
    );

    expect(result.foods, hasLength(7));
    expect(result.foods.map((food) => food.catalogId), catalog.map((food) => food.id));
  });
}
