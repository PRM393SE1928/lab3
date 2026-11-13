import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../food_diary/models/food_item.dart';
import '../../../shared/services/ai_error_message.dart';

enum MealPhotoAnalysisMode { demo, backend }

class RecognizedFood {
  const RecognizedFood({
    required this.name,
    this.catalogId,
    this.confidence,
    this.needsConfirmation = true,
    this.source = 'AI_RECOGNITION',
    this.confirmedByUser = false,
  });

  final String name;
  final String? catalogId;
  final double? confidence;
  final bool needsConfirmation;
  final String source;
  final bool confirmedByUser;

  Map<String, Object?> toJson() => {
    'name': name,
    'catalogId': catalogId,
    if (confidence != null) 'confidence': confidence,
    'needsConfirmation': needsConfirmation,
    'source': source,
    'confirmedByUser': confirmedByUser,
  };
}

int? _parseScore(Object? value, Object? maxValue) {
  if (value is! num || maxValue is! num) return null;
  final score = value.toInt();
  final maximum = maxValue.toInt();
  return maximum > 0 && score >= 0 && score <= maximum ? score : null;
}

class AiCriterionResult {
  const AiCriterionResult({
    required this.name,
    required this.sourceType,
    required this.status,
    required this.reason,
    this.sourceChapter,
    this.sourcePage,
    this.sourcePdfPage,
    this.score,
    this.maxScore,
  });
  final String name;
  final String sourceType;
  final String status;
  final String reason;
  final String? sourceChapter;
  final int? sourcePage;
  final int? sourcePdfPage;
  final int? score;
  final int? maxScore;

  String get statusLabel => switch (status.toUpperCase()) {
    'MATCH' => 'Đáp ứng',
    'PARTIAL' => 'Đáp ứng một phần',
    'NOT_MATCH' => 'Chưa đáp ứng',
    'INSUFFICIENT_DATA' => 'Chưa đủ dữ liệu',
    _ => 'Chưa đủ dữ liệu',
  };

  String get sourceLabel => switch (sourceType.toUpperCase()) {
    'BOOK_VERIFIED' || 'BOOKVERIFIED' => 'Đã xác minh từ sách',
    'LONGEVA_CRITERIA' || 'LONGEVACRITERIA' => 'Tiêu chí LONGEVA',
    'GENERAL_NUTRITION' || 'GENERALNUTRITION' => 'Dinh dưỡng tham khảo',
    _ => 'Dinh dưỡng tham khảo',
  };

  String? get bookReferenceText {
    if (sourceChapter != null && sourceChapter!.trim().isNotEmpty) {
      final page = sourcePage != null ? ', trang in $sourcePage' : '';
      final pdf = sourcePdfPage != null ? ' (PDF $sourcePdfPage)' : '';
      return 'The Longevity Diet – ${sourceChapter!.trim()}$page$pdf';
    }
    return null;
  }
}

class MealPhotoAnalysisResult {
  const MealPhotoAnalysisResult({
    required this.foods,
    required this.description,
    required this.mode,
    this.warning,
    this.ingredients = const [],
    this.foodGroups = const [],
    this.foodVarietyStatus,
    this.foodVarietyExplanation = '',
    this.criteriaResults = const [],
    this.strengths = const [],
    this.improvements = const [],
    this.personalizedAdvice = const [],
    this.uncertainItems = const [],
    this.insufficientData = const [],
    this.unknownInformation = const [],
    this.references = const [],
    this.confidence,
  });

  final List<RecognizedFood> foods;
  final String description;
  final MealPhotoAnalysisMode mode;
  final String? warning;
  final List<String> ingredients;
  final List<String> foodGroups;
  final String? foodVarietyStatus;
  final String foodVarietyExplanation;
  final List<AiCriterionResult> criteriaResults;
  final List<String> strengths;
  final List<String> improvements;
  final List<String> personalizedAdvice;
  final List<String> uncertainItems;
  final List<String> insufficientData;
  final List<String> unknownInformation;
  final List<String> references;
  final String? confidence;

  /// Returns a normalized 0-100 score via weighted average across all criteria
  /// that have both [score] and [maxScore]. Returns null when none are scored.
  int? get totalScore {
    final scored = criteriaResults
        .where(
          (item) =>
              item.score != null && item.maxScore != null && item.maxScore! > 0,
        )
        .toList();
    if (scored.isEmpty) return null;
    final sumScore = scored.fold<int>(0, (t, item) => t + item.score!);
    final sumMax = scored.fold<int>(0, (t, item) => t + item.maxScore!);
    // Normalize to 0-100 regardless of how many criteria / what maxScore values are used
    return ((sumScore / sumMax) * 100).round().clamp(0, 100);
  }

  MealPhotoAnalysisResult copyWith({
    List<RecognizedFood>? foods,
    String? description,
    MealPhotoAnalysisMode? mode,
    String? warning,
    List<String>? ingredients,
    List<String>? foodGroups,
    String? foodVarietyStatus,
    String? foodVarietyExplanation,
    List<AiCriterionResult>? criteriaResults,
    List<String>? strengths,
    List<String>? improvements,
    List<String>? personalizedAdvice,
    List<String>? uncertainItems,
    List<String>? insufficientData,
    List<String>? unknownInformation,
    List<String>? references,
    String? confidence,
  }) {
    return MealPhotoAnalysisResult(
      foods: foods ?? this.foods,
      description: description ?? this.description,
      mode: mode ?? this.mode,
      warning: warning ?? this.warning,
      ingredients: ingredients ?? this.ingredients,
      foodGroups: foodGroups ?? this.foodGroups,
      foodVarietyStatus: foodVarietyStatus ?? this.foodVarietyStatus,
      foodVarietyExplanation:
          foodVarietyExplanation ?? this.foodVarietyExplanation,
      criteriaResults: criteriaResults ?? this.criteriaResults,
      strengths: strengths ?? this.strengths,
      improvements: improvements ?? this.improvements,
      personalizedAdvice: personalizedAdvice ?? this.personalizedAdvice,
      uncertainItems: uncertainItems ?? this.uncertainItems,
      insufficientData: insufficientData ?? this.insufficientData,
      unknownInformation: unknownInformation ?? this.unknownInformation,
      references: references ?? this.references,
      confidence: confidence ?? this.confidence,
    );
  }

  Map<String, Object?> toJson() => {
    'foods': foods.map((food) => food.toJson()).toList(),
    'mode': mode.name,
    'ingredients': ingredients,
    'foodGroups': foodGroups,
    'foodVarietyStatus': foodVarietyStatus,
    'foodVarietyExplanation': foodVarietyExplanation,
    'criteriaResults': criteriaResults
        .map(
          (item) => {
            'name': item.name,
            'sourceType': item.sourceType,
            'status': item.status,
            'reason': item.reason,
            'sourceChapter': item.sourceChapter,
            'sourcePage': item.sourcePage,
            'sourcePdfPage': item.sourcePdfPage,
            'score': item.score,
            'maxScore': item.maxScore,
          },
        )
        .toList(),
    'strengths': strengths,
    'improvements': improvements,
    'personalizedAdvice': personalizedAdvice,
    'uncertainItems': uncertainItems,
    'insufficientData': insufficientData,
    'unknownInformation': unknownInformation,
    'references': references,
    'description': description,
    'confidence': confidence,
  };
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
    String mealType,
    String profile,
    String principles = '',
    String mimeType = 'image/jpeg',
  });

  Future<MealPhotoAnalysisResult> analyzeFoods(
    List<FoodItem> foods, {
    required String mealType,
    String profile,
    String principles,
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
    String mealType = 'lunch',
    String profile = '',
    String principles = '',
    String mimeType = 'image/jpeg',
  }) async {
    if (imageBytes.isEmpty) {
      throw const MealPhotoAnalysisException('Ảnh không có dữ liệu.');
    }
    final matches = catalog
        .where(
          (food) =>
              food.id.contains('oat') ||
              food.id.contains('vegetable') ||
              food.id.contains('salad') ||
              food.category == mealType,
        )
        .map(
          (food) => RecognizedFood(
            name: food.name,
            catalogId: food.id,
            confidence: 0.9,
            needsConfirmation: true,
            source: 'AI_RECOGNITION',
          ),
        )
        .toList();
    final effectiveMatches = matches.isNotEmpty
        ? matches
        : catalog
              .take(4)
              .map(
                (f) => RecognizedFood(
                  name: f.name,
                  catalogId: f.id,
                  confidence: 0.85,
                  needsConfirmation: true,
                  source: 'AI_RECOGNITION',
                ),
              )
              .toList();

    return MealPhotoAnalysisResult(
      foods: List.unmodifiable(effectiveMatches),
      description: 'Đây là kết quả minh họa từ chế độ Demo, không phải nhận diện AI thật.',
      mode: mode,
      warning: matches.isEmpty
          ? 'Demo chưa có món phù hợp trong catalog. Hãy nhập món thủ công.'
          : 'Hãy xác nhận hoặc chỉnh sửa các món trước khi lưu.',
      strengths: const ['Bữa ăn có các thực phẩm giàu thực vật.'],
      improvements: const ['Thêm các loại hạt hoặc đậu để tăng dinh dưỡng.'],
      criteriaResults: const [
        AiCriterionResult(
          name: 'Chủ yếu thực vật, có các loại hạt và một phần cá',
          sourceType: 'BOOK_VERIFIED',
          status: 'MATCH',
          reason: 'Bữa ăn chứa các thực phẩm từ thực vật phù hợp định hướng.',
          sourceChapter: 'Chapter 4 – The Longevity Diet',
          sourcePage: 79,
          sourcePdfPage: 11,
        ),
      ],
    );
  }

  @override
  Future<MealPhotoAnalysisResult> analyzeFoods(
    List<FoodItem> foods, {
    required String mealType,
    String profile = '',
    String principles = '',
  }) async => MealPhotoAnalysisResult(
    foods: foods
        .map(
          (food) => RecognizedFood(
            name: food.name,
            catalogId: food.id,
            confidence: 1.0,
            needsConfirmation: false,
            source: 'USER_CONFIRMED',
            confirmedByUser: true,
          ),
        )
        .toList(growable: false),
    description: 'Kết quả đánh giá từ danh sách thực phẩm bạn đã chọn.',
    mode: mode,
    strengths: const ['Danh sách món ăn được chọn từ thực phẩm lành mạnh.'],
    criteriaResults: const [
      AiCriterionResult(
        name: 'Chủ yếu thực vật, có các loại hạt và một phần cá',
        sourceType: 'BOOK_VERIFIED',
        status: 'MATCH',
        reason: 'Các món được chọn phù hợp với nguyên tắc thực vật.',
        sourceChapter: 'Chapter 4 – The Longevity Diet',
        sourcePage: 79,
        sourcePdfPage: 11,
      ),
    ],
  );
}

class BackendMealPhotoAnalyzer implements MealPhotoAnalyzer {
  BackendMealPhotoAnalyzer({
    required this.endpoint,
    Future<String?> Function()? tokenProvider,
  }) : _tokenProvider =
           tokenProvider ??
           (() async => FirebaseAuth.instance.currentUser?.getIdToken());

  final String endpoint;
  final Future<String?> Function() _tokenProvider;

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
    if (endpoint.trim().isEmpty) {
      throw const MealPhotoAnalysisException(
        'AI backend chưa được cấu hình. Hãy cấu hình MEAL_AI_BACKEND_URL.',
      );
    }
    if (imageBytes.isEmpty) {
      throw const MealPhotoAnalysisException('Ảnh không có dữ liệu.');
    }
    final token = await _tokenProvider();
    if (token == null || token.isEmpty) {
      throw const MealPhotoAnalysisException(
        'Bạn cần đăng nhập để sử dụng phân tích AI.',
      );
    }
    final request = http.MultipartRequest('POST', Uri.parse(endpoint))
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['mealType'] = mealType
      ..fields['profile'] = profile
      ..fields['principles'] = principles
      ..fields['catalog'] = jsonEncode(
        catalog
            .map(
              (food) => {
                'id': food.id,
                'name': food.name,
                'category': food.category,
                'description': food.description,
              },
            )
            .toList(),
      )
      ..files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: 'meal.${mimeType.split('/').last}',
          contentType: MediaType.parse(mimeType),
        ),
      );
    final response = await http.Response.fromStream(
      await request.send().timeout(const Duration(seconds: 30)),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MealPhotoAnalysisException(aiErrorMessage(response.statusCode));
    }

    return parseResponse(response.body, catalog);
  }

  @override
  Future<MealPhotoAnalysisResult> analyzeFoods(
    List<FoodItem> foods, {
    required String mealType,
    String profile = '',
    String principles = '',
  }) async {
    if (endpoint.trim().isEmpty) {
      throw const MealPhotoAnalysisException('AI backend chưa được cấu hình.');
    }
    if (foods.isEmpty) {
      throw const MealPhotoAnalysisException(
        'Hãy chọn ít nhất một thực phẩm để đánh giá.',
      );
    }
    final token = await _tokenProvider();
    if (token == null || token.isEmpty) {
      throw const MealPhotoAnalysisException(
        'Bạn cần đăng nhập để sử dụng phân tích AI.',
      );
    }
    final manualEndpoint = endpoint.replaceFirst(
      '/api/ai/meal-evaluation',
      '/api/ai/meal-evaluation/manual',
    );
    final response = await http
        .post(
          Uri.parse(manualEndpoint),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'mealType': mealType,
            'profile': profile,
            'principles': principles,
            'confirmedFoods': foods
                .map(
                  (food) => {
                    'id': food.id,
                    'name': food.name,
                    'category': food.category,
                    'description': food.description,
                  },
                )
                .toList(),
          }),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MealPhotoAnalysisException(aiErrorMessage(response.statusCode));
    }
    return parseResponse(response.body, foods, confirmedFoods: foods);
  }

  static String _toVietnameseFoodName(String name) {
    const translations = {
      'yogurt': 'Sữa chua',
      'walnuts': 'Óc chó',
      'walnut': 'Óc chó',
      'honey': 'Mật ong',
      'greek yogurt': 'Sữa chua Hy Lạp',
      'oats': 'Yến mạch',
      'oatmeal': 'Cháo yến mạch',
      'banana': 'Chuối',
      'apple': 'Táo',
      'salad': 'Salad',
      'vegetables': 'Rau củ',
      'vegetable': 'Rau củ',
      'chicken': 'Thịt gà',
      'rice': 'Cơm',
      'egg': 'Trứng',
      'eggs': 'Trứng',
      'fish': 'Cá',
      'milk': 'Sữa',
    };
    return translations[normalizeFoodText(name)] ?? name;
  }

  static MealPhotoAnalysisResult parseResponse(
    String body,
    List<FoodItem> catalog, {
    List<FoodItem>? confirmedFoods,
  }) {
    try {
      final payload = jsonDecode(body);
      if (payload is! Map<String, dynamic>) {
        throw const FormatException();
      }
      final rawFoods =
          (payload['foods'] ?? payload['recognizedFoods']) as List? ?? const [];
      final List<RecognizedFood> foods;
      if (confirmedFoods != null) {
        // In manual evaluation, preserve all supplied confirmed foods!
        foods = confirmedFoods
            .map(
              (f) => RecognizedFood(
                name: f.name,
                catalogId: f.id,
                confidence: 1.0,
                needsConfirmation: false,
                confirmedByUser: true,
                source: 'USER_CONFIRMED',
              ),
            )
            .toList();
      } else {
        foods = rawFoods
            .map(
              (item) => item is String ? <String, dynamic>{'name': item} : item,
            )
            .whereType<Map<String, dynamic>>()
            .map((item) {
              final rawName =
                  (item['name'] ?? item['foodName'] ?? item['label'] as String?)
                      ?.toString()
                      .trim() ??
                  '';
              final name = _toVietnameseFoodName(rawName);
              final id = (item['catalogId'] as String?)?.trim();
              final catalogFood = catalog.cast<FoodItem?>().firstWhere(
                (food) =>
                    (food?.id == id &&
                        food != null &&
                        normalizeFoodText(food.name) ==
                            normalizeFoodText(name)) ||
                    (name.isNotEmpty &&
                        food != null &&
                        (normalizeFoodText(food.name) ==
                                normalizeFoodText(name) ||
                            normalizeFoodText(food.name) ==
                                normalizeFoodText(rawName))),
                orElse: () => null,
              );
              return RecognizedFood(
                name: catalogFood?.name ?? name,
                catalogId: catalogFood?.id,
                confidence: _parseConfidence(item['confidence']),
                needsConfirmation: item['needsConfirmation'] as bool? ?? true,
                source: item['source']?.toString() ?? 'AI_RECOGNITION',
                confirmedByUser: item['confirmedByUser'] as bool? ?? false,
              );
            })
            .where((food) => food.name.isNotEmpty)
            .toList();
      }

      final description = cleanHumanText(
        (payload['description'] ?? payload['overallSummary'] as String?)
                ?.toString() ??
            '',
      );

      return MealPhotoAnalysisResult(
        foods: List.unmodifiable(foods),
        description: description,
        warning: (payload['warning'] as String?)?.trim(),
        mode: payload['mode'] == 'demo'
            ? MealPhotoAnalysisMode.demo
            : MealPhotoAnalysisMode.backend,
        ingredients: _parseCleanStrings(
          payload['visibleIngredients'] ?? payload['ingredients'],
        ),
        foodGroups: _parseCleanStrings(payload['foodGroups']),
        foodVarietyStatus: (payload['foodVariety'] as Map?)?['status']
            ?.toString(),
        foodVarietyExplanation: cleanHumanText(
          ((payload['foodVariety'] as Map?)?['explanation'] ?? '').toString(),
        ),
        criteriaResults: _parseCriteria(
          payload['principleAnalyses'] ?? payload['criteriaResults'],
        ),
        strengths: _parseCleanStrings(payload['strengths']),
        improvements: _parseCleanStrings(
          payload['improvements'] ?? payload['improvementPoints'],
        ),
        personalizedAdvice: _parseCleanStrings(
          payload['personalizedAdvice'] ?? payload['suggestions'],
        ),
        uncertainItems: _parseCleanStrings(payload['uncertainItems']),
        insufficientData: _parseCleanStrings(payload['insufficientData']),
        unknownInformation: _parseCleanStrings(payload['unknownInformation']),
        references: _parseCleanStrings(payload['references']),
        confidence: payload['confidence']?.toString(),
      );
    } on FormatException {
      throw const MealPhotoAnalysisException(
        'AI backend trả về dữ liệu không đúng định dạng.',
      );
    } on TypeError {
      throw const MealPhotoAnalysisException(
        'AI backend trả về dữ liệu không đúng định dạng.',
      );
    }
  }
}

String cleanHumanText(String text) {
  var cleaned = text.trim();
  if (cleaned.isEmpty) return cleaned;
  // If text starts with markdown code block
  if (cleaned.startsWith('```')) {
    final end = cleaned.lastIndexOf('```');
    if (end > 3) {
      final firstNewline = cleaned.indexOf('\n');
      if (firstNewline >= 0 && firstNewline < end) {
        cleaned = cleaned.substring(firstNewline + 1, end).trim();
      }
    }
  }
  // If it's a JSON object string, extract reasonable text
  if (cleaned.startsWith('{') && cleaned.endsWith('}')) {
    try {
      final decoded = jsonDecode(cleaned);
      if (decoded is Map) {
        final reason =
            decoded['reason'] ??
            decoded['assessment'] ??
            decoded['explanation'] ??
            decoded['message'] ??
            decoded['overallSummary'];
        if (reason != null && reason.toString().trim().isNotEmpty) {
          return cleanHumanText(reason.toString());
        }
      }
    } catch (_) {}
  }
  // Strip common technical field prefixes if leaked verbatim in text
  const technicalPrefixes = [
    'sourceChapter:',
    'sourcePage:',
    'principleId:',
    'principleName:',
    'assessment:',
    'status:',
    'reason:',
    '"sourceChapter":',
    '"sourcePage":',
    '"principleId":',
    '"principleName":',
    '"assessment":',
    '"status":',
    '"reason":',
  ];
  for (final prefix in technicalPrefixes) {
    if (cleaned.toLowerCase().startsWith(prefix.toLowerCase())) {
      cleaned = cleaned.substring(prefix.length).trim();
    }
  }
  return cleaned;
}

List<String> _parseCleanStrings(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<String>()
      .map(cleanHumanText)
      .where((s) => s.isNotEmpty)
      .toList();
}

double? _parseConfidence(Object? value) {
  if (value is num) return value.toDouble();
  return switch (value?.toString().toLowerCase()) {
    'high' => 1,
    'medium' => 0.6,
    'low' => 0.3,
    _ => null,
  };
}

List<AiCriterionResult> _parseCriteria(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) {
        final rawName = item['principleName'] ?? item['name'] ?? '';
        final rawReason =
            item['reason'] ?? item['assessment'] ?? item['explanation'] ?? '';
        final name = cleanHumanText(rawName.toString());
        final reason = cleanHumanText(rawReason.toString());
        final status = (item['status']?.toString() ?? 'INSUFFICIENT_DATA')
            .trim();
        final rawSourcePage = item['sourcePage'];
        int? sourcePage;
        if (rawSourcePage is num) {
          sourcePage = rawSourcePage.toInt();
        } else if (rawSourcePage != null) {
          sourcePage = int.tryParse(rawSourcePage.toString());
        }

        return AiCriterionResult(
          name: name,
          sourceType: item['sourceType']?.toString() ?? 'BOOK_VERIFIED',
          status: status,
          reason: reason,
          sourceChapter: item['sourceChapter']?.toString().trim(),
          sourcePage: sourcePage,
          sourcePdfPage: int.tryParse(item['sourcePdfPage']?.toString() ?? ''),
          score: _parseScore(
            item['fitScore'] ?? item['score'],
            item['maxScore'] ?? 100,
          ),
          maxScore:
              (item['maxScore'] as num?)?.toInt() ??
              (item['fitScore'] is num ? 100 : null),
        );
      })
      .where((item) => item.name.isNotEmpty)
      .toList();
}

MealPhotoAnalyzer configuredMealPhotoAnalyzer() {
  const mode = String.fromEnvironment('MEAL_AI_MODE', defaultValue: 'backend');
  const configuredEndpoint = String.fromEnvironment('MEAL_AI_BACKEND_URL');
  final endpoint = configuredEndpoint.isNotEmpty
      ? configuredEndpoint
      : kIsWeb
      ? 'http://localhost:51889/api/ai/meal-evaluation'
      : 'http://192.168.137.1:5054/api/ai/meal-evaluation';
  return mode == 'demo'
      ? const DemoMealPhotoAnalyzer()
      : BackendMealPhotoAnalyzer(endpoint: endpoint);
}
