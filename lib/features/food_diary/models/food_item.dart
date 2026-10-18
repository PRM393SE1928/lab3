class FoodItem {
  const FoodItem({
    required this.id,
    required this.name,
    required this.category,
    this.emoji = '🥗',
    this.ingredients = const [],
    this.cookingTimeMinutes = 15,
    this.estimatedCostVnd = 30000,
    this.description = '',
    this.dietTags = const [],
    this.sourceType = 'adapted',
  });
  final String id, name, category, emoji;
  final List<String> ingredients;
  final int cookingTimeMinutes;
  final int estimatedCostVnd;
  final String description;
  final List<String> dietTags;
  final String sourceType;

  String get categoryLabel => switch (category) {
    'breakfast' => 'Bữa sáng',
    'lunch' => 'Bữa trưa',
    'dinner' => 'Bữa tối',
    'snack' => 'Bữa phụ',
    _ => category,
  };
}

String normalizeFoodText(String value) {
  const replacements = {
    'à': 'a',
    'á': 'a',
    'ạ': 'a',
    'ả': 'a',
    'ã': 'a',
    'â': 'a',
    'ầ': 'a',
    'ấ': 'a',
    'ậ': 'a',
    'ẩ': 'a',
    'ẫ': 'a',
    'ă': 'a',
    'ằ': 'a',
    'ắ': 'a',
    'ặ': 'a',
    'ẳ': 'a',
    'ẵ': 'a',
    'è': 'e',
    'é': 'e',
    'ẹ': 'e',
    'ẻ': 'e',
    'ẽ': 'e',
    'ê': 'e',
    'ề': 'e',
    'ế': 'e',
    'ệ': 'e',
    'ể': 'e',
    'ễ': 'e',
    'ì': 'i',
    'í': 'i',
    'ị': 'i',
    'ỉ': 'i',
    'ĩ': 'i',
    'ò': 'o',
    'ó': 'o',
    'ọ': 'o',
    'ỏ': 'o',
    'õ': 'o',
    'ô': 'o',
    'ồ': 'o',
    'ố': 'o',
    'ộ': 'o',
    'ổ': 'o',
    'ỗ': 'o',
    'ơ': 'o',
    'ờ': 'o',
    'ớ': 'o',
    'ợ': 'o',
    'ở': 'o',
    'ỡ': 'o',
    'ù': 'u',
    'ú': 'u',
    'ụ': 'u',
    'ủ': 'u',
    'ũ': 'u',
    'ư': 'u',
    'ừ': 'u',
    'ứ': 'u',
    'ự': 'u',
    'ử': 'u',
    'ữ': 'u',
    'ỳ': 'y',
    'ý': 'y',
    'ỵ': 'y',
    'ỷ': 'y',
    'ỹ': 'y',
    'đ': 'd',
  };
  final lower = value.toLowerCase();
  return lower
      .split('')
      .map((character) => replacements[character] ?? character)
      .join();
}

List<FoodItem> filterFoodItems(
  Iterable<FoodItem> foods, {
  String? category,
  String query = '',
}) {
  final normalizedQuery = normalizeFoodText(query.trim());
  return foods
      .where((food) => category == null || food.category == category)
      .where(
        (food) =>
            normalizedQuery.isEmpty ||
            normalizeFoodText(food.name).contains(normalizedQuery),
      )
      .toList();
}
