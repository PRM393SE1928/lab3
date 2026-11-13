import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../food_diary/models/food_item.dart';
import '../../food_diary/models/meal.dart';
import '../models/health_profile.dart';
import 'health_profile_recommender.dart';
import 'food_suitability.dart';
import '../../../shared/services/ai_error_message.dart';
import '../../meal_evaluation/models/book_principle.dart';

class AiMealRecommendationService {
  AiMealRecommendationService({
    String? endpoint,
    Future<String?> Function()? tokenProvider,
    http.Client? client,
  }) : endpoint =
           endpoint ??
           (const String.fromEnvironment('MEAL_AI_RECOMMENDATIONS_URL')
                   .isNotEmpty
               ? const String.fromEnvironment('MEAL_AI_RECOMMENDATIONS_URL')
               : kIsWeb
               ? 'http://localhost:51889/api/ai/meal-recommendations'
               : 'http://10.0.2.2:51889/api/ai/meal-recommendations'),
       _client = client ?? http.Client(),
       _tokenProvider =
           tokenProvider ??
           (() async => FirebaseAuth.instance.currentUser?.getIdToken());

  final String endpoint;
  final http.Client _client;

  void dispose() => _client.close();
  final Future<String?> Function() _tokenProvider;

  Future<PersonalizedMealSuggestion?> recommend({
    required HealthProfile profile,
    required Iterable<FoodItem> foods,
    required MealType mealType,
    AgeGroup? targetAgeGroup,
  }) async {
    final effectiveAgeGroup = targetAgeGroup ?? profile.ageGroup;
    if (endpoint.trim().isEmpty) return null;
    if (effectiveAgeGroup == AgeGroup.under2) {
      throw const AiRecommendationException(
        'Chưa có dữ liệu phù hợp để AI gợi ý cho trẻ dưới 2 tuổi.',
      );
    }
    final candidates = foods
        .where((food) => food.category == mealType.name)
        .where((food) => foodMatchesProfile(food, profile))
        .where(
          (food) =>
              food.ageGroups.isEmpty ||
              effectiveAgeGroup == null ||
              food.ageGroups.contains(effectiveAgeGroup),
        )
        .toList();
    if (candidates.isEmpty) return null;
    final token = await _tokenProvider();
    if (token == null || token.isEmpty) {
      throw const AiRecommendationException('Bạn cần đăng nhập để dùng AI.');
    }
    final response = await _client
        .post(
          Uri.parse(endpoint),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'profile': {
              'age': profile.age,
              'ageGroup': effectiveAgeGroup?.name ?? profile.ageGroup?.name,
              'weightKg': profile.weightKg,
              'heightCm': profile.heightCm,
              'allergies': profile.allergies,
              'dislikedFoods': profile.dislikedFoods,
              'dietaryPattern': profile.dietaryPattern,
            },
            'targetAgeGroup': effectiveAgeGroup?.name,
            'mealType': mealType.name,
            'catalog': candidates
                .map(
                  (food) => {
                    'id': food.id,
                    'name': food.name,
                    'category': food.category,
                    'description': food.description,
                    'ingredients': food.ingredients,
                    'ageGroups': food.ageGroups
                        .map((group) => group.name)
                        .toList(),
                  },
                )
                .toList(),
            'verifiedPrinciples': const BookPrinciplesRepository().forAi,
          }),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AiRecommendationException(aiErrorMessage(response.statusCode));
    }
    try {
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final returnedAgeGroup = payload['ageGroup']?.toString();
      final expectedAgeGroup = effectiveAgeGroup?.name;
      if (returnedAgeGroup != null &&
          expectedAgeGroup != null &&
          returnedAgeGroup != expectedAgeGroup) {
        throw const AiRecommendationException(
          'AI trả về nhóm tuổi không khớp lựa chọn hiện tại.',
        );
      }
      final items = payload['recommendations'] as List<dynamic>? ?? const [];
      if (items.isEmpty) return null;
      final item = items.first as Map<String, dynamic>;
      final id = item['catalogId'] as String?;
      final food = candidates.cast<FoodItem?>().firstWhere(
        (candidate) => candidate?.id == id,
        orElse: () => null,
      );
      if (food == null) {
        throw const AiRecommendationException(
          'AI đề xuất món ngoài danh mục phù hợp. Hãy thử lại.',
        );
      }
      final analysis =
          payload['profileAnalysis'] as Map<String, dynamic>? ?? const {};
      List<String> strings(Object? value) =>
          value is List ? value.whereType<String>().toList() : [];
      return PersonalizedMealSuggestion(
        food: food,
        profileSummary: analysis['summary'] as String? ?? '',
        considerations: strings(analysis['considerations']),
        missingData:
            strings(analysis['missingData']) +
            [
              'Danh mục chưa có đầy đủ thành phần và nguy cơ nhiễm chéo; kiểm tra dị ứng trước khi dùng.',
            ],
        reasons: [item['reason'] as String? ?? 'Gợi ý từ AI backend.'],
        principles: (item['principles'] as List<dynamic>? ?? const [])
            .whereType<String>()
            .toList(),
        alternatives: (item['alternatives'] as List<dynamic>? ?? const [])
            .whereType<String>()
            .map(
              (alternative) => candidates.cast<FoodItem?>().firstWhere(
                (candidate) => candidate?.id == alternative,
                orElse: () => null,
              ),
            )
            .whereType<FoodItem>()
            .toList(),
      );
    } on FormatException {
      throw const AiRecommendationException(
        'AI backend trả về dữ liệu không đúng định dạng.',
      );
    } on TypeError {
      throw const AiRecommendationException(
        'AI backend trả về dữ liệu không đúng định dạng.',
      );
    }
  }
}

class AiRecommendationException implements Exception {
  const AiRecommendationException(this.message);
  final String message;
}
