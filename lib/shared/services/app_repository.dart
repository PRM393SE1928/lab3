import '../../features/food_diary/models/food_item.dart';
import '../../features/food_diary/models/meal.dart';
import '../../features/knowledge/models/article.dart';

abstract interface class AppRepository {
  List<FoodItem> get foods;
  List<Meal> get meals;
  List<Article> get articles;
}
