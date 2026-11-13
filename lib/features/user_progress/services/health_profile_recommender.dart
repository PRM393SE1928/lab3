import '../../food_diary/models/food_item.dart';
import '../../food_diary/models/meal.dart';
import '../models/health_profile.dart';
import 'food_suitability.dart';

class PersonalizedMealSuggestion {
  const PersonalizedMealSuggestion({
    required this.food,
    required this.reasons,
    required this.principles,
    required this.alternatives,
    this.profileSummary = '',
    this.considerations = const [],
    this.missingData = const [],
  });

  final FoodItem food;
  final List<String> reasons;
  final List<String> principles;
  final List<FoodItem> alternatives;
  final String profileSummary;
  final List<String> considerations;
  final List<String> missingData;
}

class HealthProfileRecommender {
  const HealthProfileRecommender();

  PersonalizedMealSuggestion? recommend({
    required HealthProfile profile,
    required Iterable<FoodItem> foods,
    required MealType mealType,
    AgeGroup? targetAgeGroup,
  }) {
    final ageGroup = targetAgeGroup ?? profile.ageGroup;
    if (ageGroup == null || ageGroup == AgeGroup.under2) {
      return null;
    }

    final category = _categoryFor(mealType);
    final excluded = [
      ...profile.allergies,
      ...profile.dislikedFoods,
    ].map(normalizeFoodText).where((item) => item.isNotEmpty).toList();
    final categoryFoods = foods
        .where((food) => food.category == category)
        .where((food) => foodMatchesProfile(food, profile))
        .where(
          (food) => !excluded.any(
            (term) => normalizeFoodText(
              '${food.name} ${food.description} ${food.ingredients.join(' ')}',
            ).contains(term),
          ),
        )
        .toList();
    if (categoryFoods.isEmpty) return null;

    final ageSpecific = categoryFoods
        .where((food) => food.ageGroups.contains(ageGroup))
        .toList();
    final candidates = ageSpecific.isNotEmpty ? ageSpecific : categoryFoods;
    final primary = candidates.first;
    final alternatives = candidates
        .where((food) => food.id != primary.id)
        .take(3)
        .toList();

    return PersonalizedMealSuggestion(
      food: primary,
      reasons: _reasons(profile, ageGroup, primary, ageSpecific.isNotEmpty),
      principles: _principles(primary),
      alternatives: alternatives,
    );
  }

  String _categoryFor(MealType type) => switch (type) {
    MealType.breakfast => 'breakfast',
    MealType.lunch => 'lunch',
    MealType.dinner => 'dinner',
    MealType.snack => 'snack',
  };

  List<String> _reasons(
    HealthProfile profile,
    AgeGroup ageGroup,
    FoodItem food,
    bool hasAgeMetadata,
  ) {
    final reasons = <String>[
      'Được chọn cho nhóm ${ageGroup.label.toLowerCase()} trong danh mục món hiện có.',
    ];
    if (profile.weightKg != null && profile.heightCm != null) {
      reasons.add(
        'Cân nặng ${_format(profile.weightKg!)} kg và chiều cao ${profile.heightCm} cm chỉ được dùng làm ngữ cảnh hồ sơ, không dùng để kết luận y khoa hoặc đặt mục tiêu cân nặng.',
      );
    }
    if (profile.dietaryPattern.isNotEmpty) {
      reasons.add(
        'Phù hợp với chế độ ăn đã khai báo: ${profile.dietaryPattern}.',
      );
    }
    if (profile.allergies.isNotEmpty) {
      reasons.add('Đã loại trừ các dị ứng được khai báo.');
    }
    if (!hasAgeMetadata) {
      reasons.add(
        'Món này chưa có metadata tuổi riêng trong catalog, nên được hiển thị như gợi ý chung để bạn cân nhắc.',
      );
    }
    if (food.description.isNotEmpty) reasons.add(food.description);
    return reasons;
  }

  List<String> _principles(FoodItem food) {
    final principles = <String>[];
    final text = '${food.name} ${food.description}'.toLowerCase();
    if (text.contains('yến mạch') ||
        text.contains('gạo lứt') ||
        text.contains('đậu') ||
        text.contains('nấm')) {
      principles.add('Ưu tiên carbohydrate phức hợp từ thực vật.');
    }
    if (text.contains('óc chó') ||
        text.contains('hạt') ||
        text.contains('cá') ||
        text.contains('bơ')) {
      principles.add('Chủ yếu thực vật, bổ sung các loại hạt và chất béo tốt.');
    }
    return principles;
  }

  String _format(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
}
