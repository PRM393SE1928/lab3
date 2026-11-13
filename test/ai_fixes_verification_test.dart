import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app_lab_2/features/food_diary/models/food_item.dart';
import 'package:mobile_app_lab_2/features/food_diary/models/meal.dart';
import 'package:mobile_app_lab_2/features/meal_evaluation/screens/meal_photo_analysis_screen.dart';
import 'package:mobile_app_lab_2/features/meal_evaluation/screens/meal_result_screen.dart';
import 'package:mobile_app_lab_2/features/meal_evaluation/services/meal_photo_analyzer.dart';
import 'package:mobile_app_lab_2/features/user_progress/models/health_profile.dart';
import 'package:mobile_app_lab_2/features/user_progress/services/health_profile_recommender.dart';
import 'package:mobile_app_lab_2/shared/services/app_state.dart';
import 'package:mobile_app_lab_2/shared/services/mock_repository.dart';
import 'package:provider/provider.dart';

class FakeConfigurableAnalyzer implements MealPhotoAnalyzer {
  FakeConfigurableAnalyzer({required this.analysisResultToReturn});

  MealPhotoAnalysisResult analysisResultToReturn;
  List<FoodItem>? lastAnalyzedFoods;
  Uint8List? lastAnalyzedImageBytes;

  @override
  MealPhotoAnalysisMode get mode => MealPhotoAnalysisMode.backend;

  @override
  Future<MealPhotoAnalysisResult> analyze(
    Uint8List imageBytes, {
    required List<FoodItem> catalog,
    String mealType = 'lunch',
    String profile = '',
    String principles = '',
    String mimeType = 'image/jpeg',
  }) async {
    lastAnalyzedImageBytes = imageBytes;
    return analysisResultToReturn;
  }

  @override
  Future<MealPhotoAnalysisResult> analyzeFoods(
    List<FoodItem> foods, {
    required String mealType,
    String profile = '',
    String principles = '',
  }) async {
    lastAnalyzedFoods = foods;
    return analysisResultToReturn;
  }
}

void main() {
  group('Test A: Gợi ý theo tuổi và hồ sơ sức khỏe', () {
    test('Personalized recommendation respects target age group and excludes allergies', () {
      final recommender = const HealthProfileRecommender();
      final profile = HealthProfile(
        age: 25,
        weightKg: 60,
        heightCm: 170,
        allergies: ['chuối'],
        dislikedFoods: ['nấm'],
      );

      final catalog = [
        const FoodItem(
          id: 'breakfast_banana_oat',
          name: 'Cháo yến mạch chuối',
          category: 'breakfast',
          ingredients: ['yến mạch', 'chuối'],
          ageGroups: [AgeGroup.age18To59],
        ),
        const FoodItem(
          id: 'breakfast_avocado_toast',
          name: 'Bánh mì bơ cà chua',
          category: 'breakfast',
          ingredients: ['bánh mì', 'bơ', 'cà chua'],
          ageGroups: [AgeGroup.age18To59],
        ),
      ];

      final suggestion = recommender.recommend(
        profile: profile,
        foods: catalog,
        mealType: MealType.breakfast,
        targetAgeGroup: AgeGroup.age18To59,
      );

      expect(suggestion, isNotNull);
      expect(suggestion!.food.id, equals('breakfast_avocado_toast'));
      expect(suggestion.food.name, contains('bơ'));
      expect(suggestion.reasons.any((r) => r.contains('Đã loại trừ')), isTrue);
    });

    test(
      'Recommendation targetAgeGroup takes precedence over profile ageGroup',
      () {
        final recommender = const HealthProfileRecommender();
        final profile = HealthProfile(age: 22, weightKg: 55, heightCm: 165);

        final catalog = [
          const FoodItem(
            id: 'food_minor',
            name: 'Súp rau củ học sinh',
            category: 'lunch',
            ageGroups: [AgeGroup.age13To17],
          ),
          const FoodItem(
            id: 'food_adult',
            name: 'Cơm gạo lứt cá hồi',
            category: 'lunch',
            ageGroups: [AgeGroup.age18To59],
          ),
        ];

        final suggestion = recommender.recommend(
          profile: profile,
          foods: catalog,
          mealType: MealType.lunch,
          targetAgeGroup: AgeGroup.age13To17,
        );

        expect(suggestion, isNotNull);
        expect(suggestion!.food.id, equals('food_minor'));
      },
    );
  });

  group('Test B: Nhận diện ảnh và bảo toàn danh sách món ăn (>= 7 món)', () {
    testWidgets(
      'Preserves at least 7 recognized and confirmed foods when saving',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final sevenDishes = List.generate(
          7,
          (i) => RecognizedFood(
            name: 'Món ăn số ${i + 1}',
            catalogId: 'dish_$i',
            confidence: 0.9,
            needsConfirmation: false,
          ),
        );

        final fakeResult = MealPhotoAnalysisResult(
          foods: sevenDishes,
          description: 'Bữa ăn đa dạng với 7 món.',
          mode: MealPhotoAnalysisMode.backend,
          criteriaResults: const [
            AiCriterionResult(
              name: 'Chủ yếu thực vật, có các loại hạt và một phần cá',
              sourceType: 'BOOK_VERIFIED',
              status: 'MATCH',
              reason: 'Bữa ăn đạt đủ thành phần thực vật.',
              sourceChapter: 'Chapter 4',
              sourcePage: 11,
              score: 95,
              maxScore: 100,
            ),
          ],
        );

        final analyzer = FakeConfigurableAnalyzer(
          analysisResultToReturn: fakeResult,
        );
        final repo = MockRepository();
        final appState = AppState(repo);

        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: appState,
            child: MaterialApp(
              home: MealPhotoAnalysisScreen(
                analyzer: analyzer,
                initialManualMode: true,
                initialFoods: sevenDishes
                    .map(
                      (d) => FoodItem(
                        id: d.catalogId!,
                        name: d.name,
                        category: 'lunch',
                      ),
                    )
                    .toList(),
                mealType: MealType.lunch,
              ),
            ),
          ),
        );

        for (var i = 1; i <= 7; i++) {
          expect(find.text('Món ăn số $i'), findsWidgets);
        }

        await tester.tap(find.text('Đánh giá danh sách'));
        await tester.pumpAndSettle();

        expect(analyzer.lastAnalyzedFoods?.length, equals(7));

        await tester.tap(find.text('Xác nhận và lưu bữa ăn'));
        await tester.pumpAndSettle();

        expect(appState.meals.isNotEmpty, isTrue);
        final lastMeal = appState.meals.last;
        expect(lastMeal.items.length, equals(7));

        final savedAnalysis = appState.aiMealAnalysisFor(lastMeal.id);
        expect(savedAnalysis, isNotNull);
        expect(savedAnalysis!.foods.length, equals(7));
        for (var i = 0; i < 7; i++) {
          expect(savedAnalysis.foods[i].name, equals('Món ăn số ${i + 1}'));
        }
      },
    );
  });

  group('Test C: JSON evaluation và không lộ field name kỹ thuật', () {
    test('cleanHumanText strips raw markdown fences and JSON field keys', () {
      const rawText = '''
      ```json
      {"status": "MATCH", "reason": "Bữa ăn giàu chất xơ từ rau củ"}
      ```
      ''';
      final cleaned = cleanHumanText(rawText);
      expect(cleaned, equals('Bữa ăn giàu chất xơ từ rau củ'));
      expect(cleaned.contains('status'), isFalse);
      expect(cleaned.contains('reason'), isFalse);
      expect(cleaned.contains('{'), isFalse);
    });

    test('AiCriterionResult provides Vietnamese status and formatted book reference', () {
      const criterion = AiCriterionResult(
        name: 'Chủ yếu thực vật, có các loại hạt và một phần cá',
        sourceType: 'BOOK_VERIFIED',
        status: 'MATCH',
        reason: 'Có rau bina và hạnh nhân.',
        sourceChapter: 'Chapter 4 - The Five Pillars of Longevity',
        sourcePage: 11,
        score: 85,
        maxScore: 100,
      );

      expect(criterion.statusLabel, equals('Đáp ứng'));
      expect(criterion.sourceLabel, equals('Đã xác minh từ sách'));
      expect(
        criterion.bookReferenceText,
        equals(
          'The Longevity Diet – Chapter 4 - The Five Pillars of Longevity, trang in 11',
        ),
      );
    });

    testWidgets('MealResultScreen does not leak technical field names in UI', (
      tester,
    ) async {
      final meal = Meal(
        id: 'test_meal_1',
        type: MealType.lunch,
        date: DateTime.now(),
        items: const [
          FoodItem(
            id: 'food_1',
            name: 'Đậu phụ sốt cà chua',
            category: 'lunch',
          ),
        ],
      );

      const analysis = MealPhotoAnalysisResult(
        foods: [
          RecognizedFood(
            name: 'Đậu phụ sốt cà chua',
            catalogId: 'food_1',
            confidence: 0.95,
          ),
        ],
        description: 'Bữa ăn thanh đạm.',
        mode: MealPhotoAnalysisMode.backend,
        criteriaResults: [
          AiCriterionResult(
            name: 'Ưu tiên carbohydrate phức hợp từ đậu và thực vật',
            sourceType: 'BOOK_VERIFIED',
            status: 'PARTIAL',
            reason: 'Bữa ăn có đậu phụ là nguồn đạm thực vật tốt.',
            sourceChapter: 'Chapter 4',
            sourcePage: 11,
            score: 75,
            maxScore: 100,
          ),
        ],
      );

      final repo = MockRepository();
      final appState = AppState(repo)..meals.add(meal);
      appState.saveAiMealAnalysis(meal.id, analysis);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: MaterialApp(home: MealResultScreen(meal: meal)),
        ),
      );

      expect(
        find.text('Ưu tiên carbohydrate phức hợp từ đậu và thực vật'),
        findsOneWidget,
      );
      expect(find.text('Đáp ứng một phần'), findsOneWidget);
      expect(
        find.text('Bữa ăn có đậu phụ là nguồn đạm thực vật tốt.'),
        findsOneWidget,
      );
      expect(
        find.text('The Longevity Diet – Chapter 4, trang in 11'),
        findsOneWidget,
      );

      expect(find.text('PARTIAL:'), findsNothing);
      expect(find.text('status:'), findsNothing);
      expect(find.text('sourceChapter:'), findsNothing);
      expect(find.text('sourcePage:'), findsNothing);
      expect(find.text('principleId:'), findsNothing);
    });
  });

  group('Test D: Đánh giá món ăn thủ công không cần upload ảnh', () {
    testWidgets(
      'Manual evaluation from MealResultScreen evaluates foods directly without photo',
      (tester) async {
        final meal = Meal(
          id: 'manual_meal_test',
          type: MealType.lunch,
          date: DateTime.now(),
          items: const [
            FoodItem(id: 'm1', name: 'Canh rau ngót', category: 'lunch'),
            FoodItem(id: 'm2', name: 'Đậu phụ hấp', category: 'lunch'),
            FoodItem(id: 'm3', name: 'Cơm gạo lứt', category: 'lunch'),
          ],
        );

        final repo = MockRepository();
        final appState = AppState(repo)..meals.add(meal);

        final analyzer = FakeConfigurableAnalyzer(
          analysisResultToReturn: const MealPhotoAnalysisResult(
            foods: [
              RecognizedFood(
                name: 'Canh rau ngót',
                catalogId: 'm1',
                confidence: 1.0,
              ),
              RecognizedFood(
                name: 'Đậu phụ hấp',
                catalogId: 'm2',
                confidence: 1.0,
              ),
              RecognizedFood(
                name: 'Cơm gạo lứt',
                catalogId: 'm3',
                confidence: 1.0,
              ),
            ],
            description: 'Đánh giá thủ công thành công.',
            mode: MealPhotoAnalysisMode.backend,
          ),
        );

        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: appState,
            child: MaterialApp(
              home: MealResultScreen(meal: meal, analyzer: analyzer),
            ),
          ),
        );

        expect(find.text('Đánh giá dinh dưỡng bằng AI'), findsOneWidget);
        expect(
          find.text('Chưa có kết quả phân tích AI cho bữa ăn này.'),
          findsOneWidget,
        );

        await tester.tap(find.text('Đánh giá dinh dưỡng bằng AI'));
        await tester.pumpAndSettle();

        final analysis = appState.aiMealAnalysisFor(meal.id);
        expect(analysis, isNotNull);
        expect(analyzer.lastAnalyzedFoods?.length, equals(3));
        expect(
          find.text(
            'Các món trong bữa: Canh rau ngót, Đậu phụ hấp, Cơm gạo lứt',
          ),
          findsOneWidget,
        );
      },
    );
  });
}
