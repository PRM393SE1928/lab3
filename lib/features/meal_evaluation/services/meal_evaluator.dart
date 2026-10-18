import '../../food_diary/models/meal.dart';
import '../models/meal_evaluation.dart';

enum FoodGroup { vegetables, fruit, wholeGrains, legumes, fish, nuts }

/// Explicit catalog metadata, not inferred from translated names/categories.
/// These are qualitative demo recipe tags, not measured nutrient quantities.
const mealFoodGroups = <String, Set<FoodGroup>>{
  'oats': {FoodGroup.wholeGrains, FoodGroup.fruit},
  'salad': {FoodGroup.vegetables, FoodGroup.legumes},
  'salmon': {FoodGroup.fish},
  'nuts': {FoodGroup.nuts, FoodGroup.fruit},
  'soup': {FoodGroup.vegetables},
};

class EvaluationException implements Exception {
  const EvaluationException(this.message);
  final String message;
}

/// Replace this boundary with an API implementation without changing screens.
abstract interface class MealEvaluator {
  Future<MealEvaluation> evaluate(Meal meal);
}

class RuleBasedMealEvaluator implements MealEvaluator {
  const RuleBasedMealEvaluator();

  @override
  Future<MealEvaluation> evaluate(Meal meal) => Future(() => calculate(meal));

  Set<FoodGroup>? _groupsFromCatalogId(String id) {
    final value = id.toLowerCase();
    final groups = <FoodGroup>{};
    if (value.contains('oat') ||
        value.contains('rice') ||
        value.contains('grain') ||
        value.contains('barley') ||
        value.contains('pasta') ||
        value.contains('bread') ||
        value.contains('cereal')) {
      groups.add(FoodGroup.wholeGrains);
    }
    if (value.contains('vegetable') ||
        value.contains('tomato') ||
        value.contains('spinach') ||
        value.contains('mushroom') ||
        value.contains('broccoli') ||
        value.contains('pumpkin') ||
        value.contains('zucchini') ||
        value.contains('eggplant') ||
        value.contains('greens')) {
      groups.add(FoodGroup.vegetables);
    }
    if (value.contains('banana') ||
        value.contains('apple') ||
        value.contains('pear') ||
        value.contains('fruit') ||
        value.contains('guava') ||
        value.contains('orange') ||
        value.contains('tangerine') ||
        value.contains('lemon')) {
      groups.add(FoodGroup.fruit);
    }
    if (value.contains('tofu') ||
        value.contains('bean') ||
        value.contains('chickpea') ||
        value.contains('lentil') ||
        value.contains('soy') ||
        value.contains('edamame') ||
        value.contains('hummus')) {
      groups.add(FoodGroup.legumes);
    }
    if (value.contains('fish') ||
        value.contains('salmon') ||
        value.contains('sardine')) {
      groups.add(FoodGroup.fish);
    }
    if (value.contains('nut') ||
        value.contains('almond') ||
        value.contains('walnut')) {
      groups.add(FoodGroup.nuts);
    }
    return groups.isEmpty ? null : groups;
  }

  MealEvaluation calculate(Meal meal) {
    if (meal.items.isEmpty) {
      throw const EvaluationException(
        'Bữa ăn chưa có món. Hãy chọn ít nhất một món.',
      );
    }
    final groups = <FoodGroup>{};
    final unknown = <String>[];
    for (final food in meal.items) {
      final tags = mealFoodGroups[food.id] ?? _groupsFromCatalogId(food.id);
      if (tags == null) {
        unknown.add(food.name);
      } else {
        groups.addAll(tags);
      }
    }
    final plants = groups.where((group) => group != FoodGroup.fish).length;
    final protein = groups.any(
      (group) =>
          {FoodGroup.legumes, FoodGroup.fish, FoodGroup.nuts}.contains(group),
    );
    final grain = groups.contains(FoodGroup.wholeGrains);
    final diversity = groups.length >= 3;
    final criteria = <String, int>{
      'Đa dạng nhóm thực phẩm': diversity
          ? 25
          : (groups.length * 25 / 3).floor(),
      'Nhóm thực vật': plants >= 2 ? 25 : plants * 12,
      'Ngũ cốc nguyên hạt': grain ? 25 : 0,
      'Nguồn đạm': protein ? 25 : 0,
    };
    final score = criteria.values.fold(0, (total, value) => total + value);
    return MealEvaluation(
      mealId: meal.id,
      score: score,
      summary: score >= 75
          ? 'Bữa ăn đáp ứng nhiều tiêu chí của app.'
          : 'Bữa ăn còn một số nhóm thực phẩm có thể bổ sung.',
      criteria: Map.unmodifiable(criteria),
      explanations: Map.unmodifiable({
        'Đa dạng nhóm thực phẩm':
            '${groups.length} nhóm đã nhận diện; từ 3 nhóm đạt 25 điểm.',
        'Nhóm thực vật': '$plants nhóm thực vật; từ 2 nhóm đạt 25 điểm.',
        'Ngũ cốc nguyên hạt': grain
            ? 'Có món được gắn nhóm ngũ cốc nguyên hạt.'
            : 'Chưa có món được gắn nhóm ngũ cốc nguyên hạt.',
        'Nguồn đạm': protein
            ? 'Có đậu, cá hoặc hạt trong dữ liệu món.'
            : 'Chưa nhận diện đậu, cá hoặc hạt trong bữa ăn.',
      }),
      suggestions: List.unmodifiable(
        score == 100
            ? const <String>[]
            : [
                if (!diversity) 'Thử kết hợp thêm nhóm thực phẩm khác; thêm lại cùng một món không tăng điểm.',
                if (plants < 2) 'Có thể chọn salad đậu, súp rau củ hoặc trái cây và hạt để đa dạng nhóm thực vật.',
                if (!grain)
                  'Có thể thêm hoặc đổi sang món yến mạch trong danh mục.',
                if (!protein)
                  'Có thể chọn salad đậu, cá hồi hoặc hạt để bổ sung nhóm đạm.',
              ],
      ),
      warnings: List.unmodifiable([
        if (unknown.isNotEmpty)
          'Chưa có dữ liệu nhóm cho: ${unknown.join(', ')}. Điểm tạm tính chỉ dựa trên món đã nhận diện.',
      ]),
    );
  }
}
