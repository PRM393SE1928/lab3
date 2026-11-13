import '../../food_diary/models/food_item.dart';
import '../models/health_profile.dart';

/// Excludes explicit conflicts. Missing ingredient data is still unknown.
bool foodMatchesProfile(FoodItem food, HealthProfile profile) {
  final text = normalizeFoodText(
    '${food.name} ${food.description} ${food.ingredients.join(' ')}',
  );
  final exclusions = [...profile.allergies, ...profile.dislikedFoods]
      .map((term) => normalizeFoodText(term.trim()))
      .where((term) => term.isNotEmpty);
  if (exclusions.any(text.contains)) return false;
  final diet = normalizeFoodText(profile.dietaryPattern);
  final vegetarian =
      diet.contains('chay') ||
      diet.contains('vegetarian') ||
      diet.contains('vegan');
  const meat = [
    'thit',
    'ga nuong',
    'ga luoc',
    'ga hap',
    'bo ham',
    'heo',
    'lon ',
    'chicken',
    'beef',
    'pork',
  ];
  const seafood = [
    'ca hoi',
    'ca hap',
    'ca moi',
    'ca nuong',
    'tom',
    'cua',
    'muc',
    'fish',
    'salmon',
    'sardine',
  ];
  bool containsFood(String term) =>
      RegExp(r'\b' + RegExp.escape(term) + r'\b').hasMatch(text);
  if (vegetarian && [...meat, ...seafood].any(containsFood)) return false;
  if ((diet.contains('thuan chay') || diet.contains('vegan')) &&
      [
        'trung',
        'mat ong',
        'pho mai',
        'egg',
        'honey',
        'cheese',
      ].any(text.contains)) {
    return false;
  }
  return true;
}
