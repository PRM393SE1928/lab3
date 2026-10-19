enum AgeGroup { under2, age2To5, age6To12, age13To17, age18To59, age60Plus }

extension AgeGroupLabel on AgeGroup {
  String get label => switch (this) {
    AgeGroup.under2 => 'Dưới 2 tuổi',
    AgeGroup.age2To5 => 'Từ 2 đến 5 tuổi',
    AgeGroup.age6To12 => 'Từ 6 đến 12 tuổi',
    AgeGroup.age13To17 => 'Từ 13 đến 17 tuổi',
    AgeGroup.age18To59 => 'Từ 18 đến 59 tuổi',
    AgeGroup.age60Plus => 'Từ 60 tuổi trở lên',
  };

  String get guidance => switch (this) {
    AgeGroup.under2 => 'Chưa có dữ liệu kết cấu, dị nguyên và quy tắc an toàn cho trẻ nhỏ; không tạo gợi ý chuyên biệt.',
    AgeGroup.age60Plus => 'Chưa có dữ liệu bệnh nền, thuốc và nhu cầu dinh dưỡng để đưa ra gợi ý riêng.',
    _ => 'Chỉ hiển thị món đã có metadata độ tuổi trong danh mục.',
  };
}

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
    this.ageGroups = const [],
  });
  final String id, name, category, emoji;
  final List<String> ingredients;
  final int cookingTimeMinutes;
  final int estimatedCostVnd;
  final String description;
  final List<String> dietTags;
  final String sourceType;

  /// Empty means the catalog does not have enough age-specific evidence.
  final List<AgeGroup> ageGroups;

  bool get hasAgeMetadata => ageGroups.isNotEmpty;

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
  AgeGroup? ageGroup,
  String query = '',
}) {
  final normalizedQuery = normalizeFoodText(query.trim());
  return foods
      .where((food) => category == null || food.category == category)
      .where((food) => ageGroup == null || food.ageGroups.contains(ageGroup))
      .where(
        (food) =>
            normalizedQuery.isEmpty ||
            normalizeFoodText(food.name).contains(normalizedQuery),
      )
      .toList();
}
