import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../../food_diary/models/food_item.dart';

enum MealPhotoAnalysisMode { demo, real }

class RecognizedFood {
  const RecognizedFood({
    required this.name,
    this.catalogId,
    this.confidence,
    this.needsConfirmation = true,
  });

  final String name;
  final String? catalogId;
  final double? confidence;
  final bool needsConfirmation;
}

class MealPhotoAnalysisResult {
  const MealPhotoAnalysisResult({
    required this.foods,
    required this.description,
    required this.mode,
    this.warning,
  });

  final List<RecognizedFood> foods;
  final String description;
  final MealPhotoAnalysisMode mode;
  final String? warning;

  bool get hasFoods => foods.isNotEmpty;
}

class MealPhotoAnalysisException implements Exception {
  const MealPhotoAnalysisException(this.message);
  final String message;
}

abstract interface class MealPhotoAnalyzer {
  MealPhotoAnalysisMode get mode;

  Future<MealPhotoAnalysisResult> analyze(
    Uint8List imageBytes, {
    required List<FoodItem> catalog,
  });
}

class DemoMealPhotoAnalyzer implements MealPhotoAnalyzer {
  const DemoMealPhotoAnalyzer();

  @override
  MealPhotoAnalysisMode get mode => MealPhotoAnalysisMode.demo;

  @override
  Future<MealPhotoAnalysisResult> analyze(
    Uint8List imageBytes, {
    required List<FoodItem> catalog,
  }) async {
    if (imageBytes.isEmpty) {
      throw const MealPhotoAnalysisException('Ảnh không có dữ liệu.');
    }
    final matches = catalog
        .where(
          (food) =>
              food.id.contains('oat') ||
              food.id.contains('vegetable') ||
              food.id.contains('salad'),
        )
        .take(2)
        .map((food) => RecognizedFood(name: food.name, catalogId: food.id))
        .toList();
    return MealPhotoAnalysisResult(
      foods: List.unmodifiable(matches),
      description: 'Đây là kết quả minh họa từ chế độ Demo, không phải nhận diện AI thật.',
      mode: mode,
      warning: matches.isEmpty
          ? 'Demo chưa có món phù hợp trong catalog. Hãy nhập món thủ công.'
          : 'Hãy xác nhận hoặc chỉnh sửa các món trước khi lưu.',
    );
  }
}

class RealAiMealPhotoAnalyzer implements MealPhotoAnalyzer {
  RealAiMealPhotoAnalyzer({
    required this.apiKey,
    this.endpoint = 'https://api.openai.com/v1/chat/completions',
    this.model = 'gpt-4o-mini',
    HttpClient? client,
  }) : _client = client ?? HttpClient();

  final String apiKey;
  final String endpoint;
  final String model;
  final HttpClient _client;

  @override
  MealPhotoAnalysisMode get mode => MealPhotoAnalysisMode.real;

  @override
  Future<MealPhotoAnalysisResult> analyze(
    Uint8List imageBytes, {
    required List<FoodItem> catalog,
  }) async {
    if (apiKey.trim().isEmpty) {
      throw const MealPhotoAnalysisException(
        'Real AI chưa được cấu hình API key. Hãy dùng chế độ Demo.',
      );
    }
    if (imageBytes.isEmpty) {
      throw const MealPhotoAnalysisException('Ảnh không có dữ liệu.');
    }
    final request = await _client.postUrl(Uri.parse(endpoint));
    request.headers
      ..set(HttpHeaders.authorizationHeader, 'Bearer $apiKey')
      ..contentType = ContentType.json;
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $apiKey');
    request.write(
      jsonEncode({
        'model': model,
        'temperature': 0,
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': 'Identify visible foods only. Return JSON with keys foods (array of objects with name and optional catalogId), description, and warning. Do not estimate calories or medical facts.',
              },
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:image/jpeg;base64,${base64Encode(imageBytes)}',
                },
              },
            ],
          },
        ],
      }),
    );
    final response = await request.close().timeout(const Duration(seconds: 30));
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const MealPhotoAnalysisException(
        'Real AI từ chối yêu cầu hoặc đang tạm thời không khả dụng.',
      );
    }
    try {
      final envelope = jsonDecode(body) as Map<String, dynamic>;
      final content =
          (envelope['choices'] as List).first['message']['content'] as String;
      final payload = jsonDecode(content) as Map<String, dynamic>;
      final foods = (payload['foods'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map((item) {
            final name = (item['name'] as String?)?.trim() ?? '';
            final requestedId = (item['catalogId'] as String?)?.trim();
            final catalogFood = catalog.cast<FoodItem?>().firstWhere(
              (food) =>
                  food?.id == requestedId ||
                  (name.isNotEmpty &&
                      food != null &&
                      normalizeFoodText(food.name) == normalizeFoodText(name)),
              orElse: () => null,
            );
            return RecognizedFood(
              name: catalogFood?.name ?? name,
              catalogId: catalogFood?.id,
            );
          })
          .where((food) => food.name.isNotEmpty && food.catalogId != null)
          .fold<List<RecognizedFood>>(
            [],
            (unique, food) =>
                unique.any((item) => item.catalogId == food.catalogId)
                ? unique
                : [...unique, food],
          );
      return MealPhotoAnalysisResult(
        foods: List.unmodifiable(foods),
        description: (payload['description'] as String?)?.trim() ?? '',
        warning: (payload['warning'] as String?)?.trim(),
        mode: mode,
      );
    } catch (_) {
      throw const MealPhotoAnalysisException(
        'Real AI trả về dữ liệu không đúng định dạng.',
      );
    }
  }
}

MealPhotoAnalyzer configuredMealPhotoAnalyzer() {
  const mode = String.fromEnvironment('MEAL_AI_MODE', defaultValue: 'demo');
  const key = String.fromEnvironment('MEAL_AI_API_KEY');
  if (mode == 'real') {
    return RealAiMealPhotoAnalyzer(apiKey: key);
  }
  return const DemoMealPhotoAnalyzer();
}
