import '../../food_diary/models/food_item.dart';
import '../../food_diary/models/meal.dart';

enum MealPlanStatus { planned, completed }

class MealPlan {
  MealPlan({
    required this.id,
    required this.date,
    required this.type,
    required this.items,
    this.note,
    this.status = MealPlanStatus.planned,
    this.actualMealId,
  });

  final String id;
  final DateTime date;
  final MealType type;
  final List<FoodItem> items;
  final String? note;
  MealPlanStatus status;
  String? actualMealId;
}

class ShoppingItem {
  ShoppingItem(this.name, {this.unit});
  final String name;
  final String? unit;
  bool purchased = false;

  String get key => '${name.toLowerCase()}|${unit ?? ''}';
}
