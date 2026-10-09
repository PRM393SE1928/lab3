import 'package:flutter/material.dart';

import '../../features/food_diary/models/food_item.dart';
import '../../features/food_diary/models/meal.dart';
import '../../features/meal_evaluation/models/meal_evaluation.dart';
import '../../features/knowledge/models/article.dart';
import '../../features/user_progress/models/user_profile.dart';
import 'app_repository.dart';

class AppState extends ChangeNotifier {
  AppState(this.repository)
    : foods = List.of(repository.foods),
      meals = List.of(repository.meals),
      articles = List.of(repository.articles);
  final AppRepository repository;
  final List<FoodItem> foods;
  final List<Meal> meals;
  final List<Article> articles;
  final profile = UserProfile();
  final Map<String, MealEvaluation> _evaluations = {};

  MealEvaluation? get lastEvaluation =>
      _evaluations.isEmpty ? null : _evaluations.values.last;

  int get weeklyScore {
    final scores = weeklyScores.where((score) => score > 0).toList();
    if (scores.isEmpty) return 0;
    return (scores.reduce((a, b) => a + b) / scores.length).round();
  }

  int get streakDays {
    final today = _dateOnly(DateTime.now());
    final loggedDates = meals.map((meal) => _dateOnly(meal.date)).toSet();
    if (!loggedDates.contains(today)) return 0;
    var streak = 0;
    var date = today;
    while (loggedDates.contains(date)) {
      streak++;
      date = date.subtract(const Duration(days: 1));
    }
    return streak;
  }

  List<int> get weeklyScores {
    final today = _dateOnly(DateTime.now());
    return List.generate(7, (index) {
      final date = today.subtract(Duration(days: 6 - index));
      final dayMeals = meals
          .where((meal) => _dateOnly(meal.date) == date)
          .toList();
      if (dayMeals.isEmpty) return 0;
      final total = dayMeals
          .map((meal) => evaluationFor(meal).score)
          .reduce((a, b) => a + b);
      return (total / dayMeals.length).round();
    });
  }

  Meal addMeal(MealType type, List<FoodItem> items) {
    _validateItems(items);
    final meal = Meal(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: type,
      date: DateTime.now(),
      items: List.of(items),
    );
    meals.add(meal);
    notifyListeners();
    return meal;
  }

  bool updateMeal(String mealId, MealType type, List<FoodItem> items) {
    _validateItems(items);
    final index = meals.indexWhere((meal) => meal.id == mealId);
    if (index < 0) return false;
    final meal = meals[index];
    meals[index] = Meal(
      id: meal.id,
      type: type,
      date: meal.date,
      items: List.of(items),
    );
    _evaluations.remove(mealId);
    notifyListeners();
    return true;
  }

  bool deleteMeal(String mealId) {
    final removed = meals.any((meal) => meal.id == mealId);
    if (!removed) return false;
    meals.removeWhere((meal) => meal.id == mealId);
    _evaluations.remove(mealId);
    notifyListeners();
    return true;
  }

  bool markArticleRead(String articleId) {
    Article? article;
    for (final item in articles) {
      if (item.id == articleId) {
        article = item;
        break;
      }
    }
    if (article == null || article.isRead) return false;
    article.isRead = true;
    notifyListeners();
    return true;
  }

  MealEvaluation calculateEvaluation(Meal meal) {
    final score = (58 + meal.items.length * 12).clamp(0, 100);
    return MealEvaluation(
      score: score,
      summary: score >= 70
          ? 'Một lựa chọn bổ dưỡng với nền tảng tốt.'
          : 'Một khởi đầu đáng ghi nhận, nhưng vẫn có thể đa dạng hơn.',
      criteria: {
        'Đa dạng': (score + 6).clamp(0, 100),
        'Thực phẩm nguyên chất': (score - 4).clamp(0, 100),
        'Cân bằng thực vật': (score + 2).clamp(0, 100),
      },
      suggestions: [
        'Thêm một loại rau củ nhiều màu sắc',
        'Uống nước cùng bữa ăn này',
        'Thử thêm một món từ ngũ cốc nguyên hạt',
      ],
    );
  }

  MealEvaluation evaluateMeal(Meal meal) {
    final evaluation = calculateEvaluation(meal);
    recordEvaluation(meal.id, evaluation);
    return evaluation;
  }

  MealEvaluation evaluationFor(Meal meal) =>
      _evaluations[meal.id] ?? calculateEvaluation(meal);

  void recordEvaluation(String mealId, MealEvaluation evaluation) {
    if (!meals.any((meal) => meal.id == mealId)) return;
    _evaluations[mealId] = evaluation;
    notifyListeners();
  }

  void updateProfileName(String name) {
    if (name == profile.name) return;
    profile.name = name;
    notifyListeners();
  }

  void _validateItems(List<FoodItem> items) {
    if (items.isEmpty) {
      throw ArgumentError.value(
        items,
        'items',
        'Bữa ăn cần có ít nhất một món.',
      );
    }
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
