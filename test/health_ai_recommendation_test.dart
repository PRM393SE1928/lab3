import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile_app_lab_2/features/food_diary/models/food_item.dart';
import 'package:mobile_app_lab_2/features/food_diary/models/meal.dart';
import 'package:mobile_app_lab_2/features/user_progress/models/health_profile.dart';
import 'package:mobile_app_lab_2/features/user_progress/screens/health_suggestions_screen.dart';
import 'package:mobile_app_lab_2/features/user_progress/services/ai_meal_recommendation_service.dart';
import 'package:mobile_app_lab_2/shared/services/app_state.dart';
import 'package:mobile_app_lab_2/shared/services/mock_repository.dart';
import 'package:provider/provider.dart';

void main() {
  test(
    'sends full profile and excludes allergies, dislikes and dietary conflicts',
    () async {
      final service = AiMealRecommendationService(
        tokenProvider: () async => 'test',
        client: MockClient((request) async {
          final body = jsonDecode(request.body) as Map;
          expect(body['profile']['weightKg'], 60.5);
          expect(body['profile']['heightCm'], 170);
          expect((body['catalog'] as List).map((food) => food['id']), ['safe']);
          return http.Response(
            jsonEncode({
              'ageGroup': 'age18To59',
              'profileAnalysis': {
                'summary': 'Ưu tiên món thực vật theo hồ sơ.',
                'considerations': ['Tránh chuối'],
                'missingData': ['Chưa có mức vận động'],
              },
              'recommendations': [
                {
                  'catalogId': 'safe',
                  'reason': 'Đúng chế độ chay',
                  'alternatives': ['allergen', 'fish'],
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      addTearDown(service.dispose);
      final result = await service.recommend(
        profile: HealthProfile(
          age: 25,
          weightKg: 60.5,
          heightCm: 170,
          allergies: ['chuối'],
          dislikedFoods: ['nấm'],
          dietaryPattern: 'ăn chay',
        ),
        foods: const [
          FoodItem(
            id: 'safe',
            name: 'Cháo yến mạch táo',
            category: 'breakfast',
          ),
          FoodItem(
            id: 'allergen',
            name: 'Yến mạch chuối',
            category: 'breakfast',
          ),
          FoodItem(id: 'fish', name: 'Cá hồi', category: 'breakfast'),
          FoodItem(id: 'dislike', name: 'Cháo nấm', category: 'breakfast'),
          FoodItem(id: 'other', name: 'Đậu phụ', category: 'dinner'),
        ],
        mealType: MealType.breakfast,
      );
      expect(result!.food.id, 'safe');
      expect(result.profileSummary, contains('thực vật'));
      expect(result.alternatives, isEmpty);
    },
  );

  test('rejects a recommendation outside the filtered catalog', () async {
    final service = AiMealRecommendationService(
      tokenProvider: () async => 'test',
      client: MockClient(
        (_) async =>
            http.Response('{"recommendations":[{"catalogId":"unsafe"}]}', 200),
      ),
    );
    addTearDown(service.dispose);
    await expectLater(
      service.recommend(
        profile: HealthProfile(age: 25),
        foods: const [FoodItem(id: 'safe', name: 'Rau củ', category: 'lunch')],
        mealType: MealType.lunch,
      ),
      throwsA(isA<AiRecommendationException>()),
    );
  });

  testWidgets(
    'profile analysis displays AI context and adds the suggested food to the plan',
    (tester) async {
      final state = AppState(MockRepository());
      await state.updateHealthProfile(age: 25, weightKg: 60, heightCm: 170);
      final food = state.foods.first;
      final service = AiMealRecommendationService(
        tokenProvider: () async => 'test',
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'ageGroup': 'age18To59',
              'profileAnalysis': {
                'summary': 'Nhận xét hồ sơ từ AI',
                'considerations': [],
                'missingData': [],
              },
              'recommendations': [
                {'catalogId': food.id, 'reason': 'Gợi ý bữa sáng'},
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
      );
      addTearDown(service.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: state,
          child: MaterialApp(home: HealthSuggestionsScreen(service: service)),
        ),
      );
      await tester.ensureVisible(find.text('Phân tích hồ sơ và gợi ý'));
      await tester.tap(find.text('Phân tích hồ sơ và gợi ý'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Thêm vào kế hoạch hôm nay'),
        250,
      );
      await tester.tap(find.text('Thêm vào kế hoạch hôm nay'));
      await tester.pump();
      expect(state.mealPlans.single.items.single.id, food.id);
      expect(state.mealPlans.single.type, MealType.breakfast);
      expect(tester.takeException(), isNull);
    },
  );
}
