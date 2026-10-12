import 'food_item.dart';

enum MealType { breakfast, lunch, dinner, snack }

extension MealTypeLabel on MealType {
  String get label => switch (this) {
    MealType.breakfast => 'Bữa sáng',
    MealType.lunch => 'Bữa trưa',
    MealType.dinner => 'Bữa tối',
    MealType.snack => 'Bữa phụ',
  };
}

class Meal {
  Meal({
    required this.id,
    required this.type,
    required this.date,
    required this.items,
  });

  final String id;
  final MealType type;
  final DateTime date;
  final List<FoodItem> items;
}
