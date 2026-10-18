import 'package:flutter/material.dart';

import '../../features/food_diary/models/food_item.dart';
import '../../features/food_diary/models/meal.dart';
import '../../features/meal_evaluation/models/meal_evaluation.dart';
import '../../features/meal_evaluation/services/meal_evaluator.dart';
import '../../features/knowledge/models/article.dart';
import '../../features/user_progress/models/user_profile.dart';
import 'app_repository.dart';

class DailyProgress {
  const DailyProgress({
    required this.date,
    required this.averageScore,
    required this.mealCount,
  });

  final DateTime date;
  final int averageScore;
  final int mealCount;
}

class HabitSummary {
  const HabitSummary({
    required this.label,
    required this.value,
    required this.goal,
    required this.icon,
  });

  final String label;
  final int value;
  final int goal;
  final IconData icon;

  double get ratio => goal == 0 ? 0 : (value / goal).clamp(0.0, 1.0);
}

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

  bool dailyRemindersEnabled = true;
  bool weeklySummaryEnabled = true;
  bool progressNotificationsEnabled = true;
  bool compactDiaryEnabled = false;
  TimeOfDay reminderTime = const TimeOfDay(hour: 20, minute: 0);

  MealEvaluation? get lastEvaluation =>
      _evaluations.isEmpty ? null : _evaluations.values.last;

  int get todayScore {
    final scores = _scoresForDate(DateTime.now());
    if (scores.isEmpty) return 0;
    return _average(scores);
  }

  int get weeklyScore {
    final scores = weeklyScores.where((score) => score > 0).toList();
    if (scores.isEmpty) return 0;
    return _average(scores);
  }

  int get mealCountThisWeek {
    final today = _dateOnly(DateTime.now());
    final firstDay = today.subtract(const Duration(days: 6));
    return meals.where((meal) {
      final date = _dateOnly(meal.date);
      return !date.isBefore(firstDay) && !date.isAfter(today);
    }).length;
  }

  int get readArticleCount =>
      articles.where((article) => article.isRead).length;

  double get articleCompletionRatio =>
      articles.isEmpty ? 0 : readArticleCount / articles.length;

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

  List<int> get weeklyScores =>
      weeklyProgress.map((item) => item.averageScore).toList();

  List<DailyProgress> get weeklyProgress {
    final today = _dateOnly(DateTime.now());
    return List.generate(7, (index) {
      final date = today.subtract(Duration(days: 6 - index));
      final scores = _scoresForDate(date);
      return DailyProgress(
        date: date,
        averageScore: scores.isEmpty ? 0 : _average(scores),
        mealCount: meals.where((meal) => _dateOnly(meal.date) == date).length,
      );
    });
  }

  List<HabitSummary> get habitSummaries {
    final recentMeals = _mealsInLastDays(7);
    final plantForward = recentMeals
        .where((meal) => meal.items.any(_isPlantForward))
        .length;
    final wholeFoods = recentMeals
        .where((meal) => meal.items.any(_isWholeFood))
        .length;
    final mindfulMeals = weeklyScores.where((score) => score >= 75).length;

    return [
      HabitSummary(
        label: 'Bữa giàu thực vật',
        value: plantForward,
        goal: 10,
        icon: Icons.eco_outlined,
      ),
      HabitSummary(
        label: 'Thực phẩm nguyên chất',
        value: wholeFoods,
        goal: 8,
        icon: Icons.grain_outlined,
      ),
      HabitSummary(
        label: 'Ngày đạt mục tiêu',
        value: mindfulMeals,
        goal: 5,
        icon: Icons.flag_outlined,
      ),
    ];
  }
  }

  List<Meal> getMealsForDate(DateTime date) {
  final day = _dateOnly(date);
    return meals.where((meal) => _dateOnly(meal.date) == day).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  Meal? getMealById(String mealId) {
    for (final meal in meals) {
      if (meal.id == mealId) return meal;
    }
    return null;
  }

  MealEvaluation? savedEvaluationFor(Meal meal) => _evaluations[meal.id];

  Meal addMeal(
    MealType type,
    List<FoodItem> items, {
    DateTime? date,
    String? note,
  }) {
    _validateItems(items);
    final meal = Meal(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: type,
      date: date ?? DateTime.now(),
      items: List.of(items),
      note: _cleanNote(note),
    );
    meals.add(meal);
    _evaluations[meal.id] = calculateEvaluation(meal);
    notifyListeners();
    return meal;
  }

  bool updateMeal(
    String mealId,
    MealType type,
    List<FoodItem> items, {
    DateTime? date,
    String? note,
  }) {
    _validateItems(items);
    final index = meals.indexWhere((meal) => meal.id == mealId);
    if (index < 0) return false;
    final meal = meals[index];
    final updated = Meal(
      id: meal.id,
      type: type,
      date: date ?? meal.date,
      items: List.of(items),
      note: _cleanNote(note),
    );
    meals[index] = updated;
    _evaluations[mealId] = calculateEvaluation(updated);
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

  MealEvaluation calculateEvaluation(Meal meal) =>
      const RuleBasedMealEvaluator().calculate(meal);

  MealEvaluation evaluateMeal(Meal meal) {
    final evaluation = calculateEvaluation(meal);
    recordEvaluation(meal.id, evaluation);
    return evaluation;
  }

  MealEvaluation evaluationFor(Meal meal) {
    final existing = _evaluations[meal.id];
    if (existing != null) return existing;
    final evaluation = calculateEvaluation(meal);
    _evaluations[meal.id] = evaluation;
    return evaluation;
  }

  void recordEvaluation(String mealId, MealEvaluation evaluation) {
    if (!meals.any((meal) => meal.id == mealId)) return;
    _evaluations.remove(mealId);
    _evaluations[mealId] = evaluation;
    notifyListeners();
  }

  void updateProfile({
    required String name,
    required String email,
    required String goal,
    required String dietaryFocus,
    required int targetScore,
  }) {
    profile
      ..name = name.trim().isEmpty ? profile.name : name.trim()
      ..email = email.trim().isEmpty ? profile.email : email.trim()
      ..goal = goal.trim().isEmpty ? profile.goal : goal.trim()
      ..dietaryFocus = dietaryFocus.trim().isEmpty
          ? profile.dietaryFocus
          : dietaryFocus.trim()
      ..targetScore = targetScore.clamp(50, 100).toInt();
    notifyListeners();
  }

  void updateProfileName(String name) {
    if (name == profile.name) return;
    profile.name = name;
    notifyListeners();
  }

  void updateNotificationSettings({
    bool? dailyReminders,
    bool? weeklySummary,
    bool? progressNotifications,
    bool? compactDiary,
    TimeOfDay? time,
  }) {
    dailyRemindersEnabled = dailyReminders ?? dailyRemindersEnabled;
    weeklySummaryEnabled = weeklySummary ?? weeklySummaryEnabled;
    progressNotificationsEnabled =
        progressNotifications ?? progressNotificationsEnabled;
    compactDiaryEnabled = compactDiary ?? compactDiaryEnabled;
    reminderTime = time ?? reminderTime;
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

  List<int> _scoresForDate(DateTime value) {
    final date = _dateOnly(value);
    return meals
        .where((meal) => _dateOnly(meal.date) == date)
        .map((meal) => evaluationFor(meal).score)
        .toList();
  }

  List<Meal> _mealsInLastDays(int days) {
    final today = _dateOnly(DateTime.now());
    final firstDay = today.subtract(Duration(days: days - 1));
    return meals.where((meal) {
      final date = _dateOnly(meal.date);
      return !date.isBefore(firstDay) && !date.isAfter(today);
    }).toList();
  }

  bool _isPlantForward(FoodItem item) {
    final value = '${item.id} ${item.name} ${item.category}'.toLowerCase();
    return value.contains('rau') ||
        value.contains('salad') ||
        value.contains('đậu') ||
        value.contains('dau') ||
        value.contains('trái cây') ||
        value.contains('trai cay') ||
        value.contains('quả') ||
        value.contains('qua') ||
        value.contains('hạt') ||
        value.contains('hat') ||
        value.contains('oats') ||
        value.contains('nuts') ||
        value.contains('soup');
  }

  bool _isWholeFood(FoodItem item) {
    final value = '${item.id} ${item.name} ${item.category}'.toLowerCase();
    return value.contains('yến mạch') ||
        value.contains('yen mach') ||
        value.contains('ngũ cốc') ||
        value.contains('ngu coc') ||
        value.contains('đậu') ||
        value.contains('dau') ||
        value.contains('hạt') ||
        value.contains('hat') ||
        value.contains('oats') ||
        value.contains('nuts');
  }

  int _average(Iterable<int> values) {
    final list = values.toList();
    if (list.isEmpty) return 0;
    return (list.reduce((a, b) => a + b) / list.length).round();
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  String? _cleanNote(String? note) {
    final value = note?.trim();
    return value == null || value.isEmpty ? null : value;
  }
}
