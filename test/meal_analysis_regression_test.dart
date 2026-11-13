import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app_lab_2/features/food_diary/models/food_item.dart';
import 'package:mobile_app_lab_2/features/food_diary/models/meal.dart';
import 'package:mobile_app_lab_2/features/meal_evaluation/screens/meal_result_screen.dart';
import 'package:mobile_app_lab_2/features/meal_evaluation/services/meal_photo_analyzer.dart';
import 'package:mobile_app_lab_2/shared/services/app_state.dart';
import 'package:mobile_app_lab_2/shared/services/mock_repository.dart';
import 'package:provider/provider.dart';

void main() {
  const catalog = [
    FoodItem(id: 'fish', name: 'Cá hấp gừng', category: 'lunch'),
    FoodItem(id: 'tofu', name: 'Đậu phụ và rau củ', category: 'lunch'),
  ];

  test('empty recognition never turns the catalog into detected dishes', () {
    final result = BackendMealPhotoAnalyzer.parseResponse(
      '{"recognizedFoods":[]}',
      catalog,
    );
    expect(result.foods, isEmpty);
  });

  test('wrong catalog ID cannot replace the recognized name', () {
    final result = BackendMealPhotoAnalyzer.parseResponse(
      jsonEncode({
        'recognizedFoods': [
          {'name': 'Đậu phụ và rau củ', 'catalogId': 'fish'},
        ],
      }),
      catalog,
    );
    expect(result.foods.single.name, 'Đậu phụ và rau củ');
    expect(result.foods.single.catalogId, 'tofu');
    final unknown = BackendMealPhotoAnalyzer.parseResponse(
      jsonEncode({
        'recognizedFoods': [
          {'name': 'Bánh xèo', 'catalogId': 'fish'},
        ],
      }),
      catalog,
    );
    expect(unknown.foods.single.name, 'Bánh xèo');
    expect(unknown.foods.single.catalogId, isNull);
  });

  test(
    'manual evaluation preserves the entire confirmed list and advice aliases',
    () {
      final result = BackendMealPhotoAnalyzer.parseResponse(
        jsonEncode({
          'recognizedFoods': [
            {'name': 'Món sai', 'catalogId': 'fish'},
          ],
          'improvementPoints': ['Thêm rau'],
          'suggestions': ['Ưu tiên đậu'],
        }),
        catalog,
        confirmedFoods: catalog,
      );
      expect(result.foods.map((f) => f.name), catalog.map((f) => f.name));
      expect(result.foods.every((f) => f.confirmedByUser), isTrue);
      expect(result.improvements, ['Thêm rau']);
      expect(result.personalizedAdvice, ['Ưu tiên đậu']);
    },
  );

  test('editing a meal invalidates its old analysis', () {
    final state = AppState(MockRepository());
    final meal = state.addMeal(MealType.lunch, catalog);
    state.saveAiMealAnalysis(
      meal.id,
      const MealPhotoAnalysisResult(
        foods: [],
        description: 'Cũ',
        mode: MealPhotoAnalysisMode.backend,
      ),
    );
    state.updateMeal(meal.id, MealType.lunch, [catalog.first]);
    expect(state.aiMealAnalysisFor(meal.id), isNull);
    state.dispose();
  });

  testWidgets('legacy scored records show criteria without any score', (
    tester,
  ) async {
    final state = AppState(MockRepository());
    final meal = state.addMeal(MealType.lunch, catalog);
    state.saveAiMealAnalysis(
      meal.id,
      const MealPhotoAnalysisResult(
        foods: [],
        description: 'Bữa ăn đã xác nhận',
        mode: MealPhotoAnalysisMode.backend,
        criteriaResults: [
          AiCriterionResult(
            name: 'Thực vật',
            sourceType: 'BOOK_VERIFIED',
            status: 'PARTIAL',
            reason: 'Có rau',
            score: 80,
            maxScore: 100,
          ),
        ],
      ),
    );
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: MaterialApp(home: MealResultScreen(meal: meal)),
      ),
    );
    expect(find.text('Thực vật'), findsOneWidget);
    expect(find.textContaining('/100'), findsNothing);
    expect(find.textContaining('Điểm tham khảo'), findsNothing);
    expect(find.text('Đậu phụ và rau củ'), findsOneWidget);
  });
}
