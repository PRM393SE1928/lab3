import 'package:flutter/material.dart';

import '../../features/food_diary/models/food_item.dart';
import '../../features/food_diary/models/meal.dart';
import '../../features/meal_evaluation/services/meal_photo_analyzer.dart';
import '../../features/knowledge/models/article.dart';
import '../../features/user_progress/models/user_profile.dart';
import '../../features/user_progress/models/health_profile.dart';
import '../../features/meal_planner/models/meal_plan.dart';
import 'app_repository.dart';
import 'firestore_repository.dart';

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
  final healthProfile = HealthProfile();
  final Map<String, MealPhotoAnalysisResult> _aiMealAnalyses = {};
  final List<MealPlan> mealPlans = [];
  final List<ShoppingItem> shoppingItems = [];
  bool isHydrating = false;
  String? hydrateError;
  String? lastPersistenceError;
  bool _disposed = false;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void clearPersistenceError() {
    if (lastPersistenceError == null) return;
    lastPersistenceError = null;
    notifyListeners();
  }

  Future<void> hydrate() async {
    if (repository is! FirestoreAppRepository) return;
    isHydrating = true;
    hydrateError = null;
    notifyListeners();
    try {
      final data = await (repository as FirestoreAppRepository).loadUserData();
      if (_disposed) return;
      _aiMealAnalyses
        ..clear()
        ..addAll(data.analyses);
      meals
        ..clear()
        ..addAll(data.meals);
      mealPlans
        ..clear()
        ..addAll(data.plans);
      for (final article in articles) {
        article.isRead = data.readArticleIds.contains(article.id);
      }
      final authenticatedEmail = repository is FirestoreAppRepository
          ? (repository as FirestoreAppRepository).authenticatedEmail
          : null;
      if (authenticatedEmail != null && authenticatedEmail.isNotEmpty) {
        profile.email = authenticatedEmail;
      }
      final remoteProfile = data.profile;
      if (remoteProfile != null) {
        profile
          ..name = remoteProfile.name.isEmpty
              ? profile.name
              : remoteProfile.name
          ..goal = remoteProfile.goal.isEmpty
              ? profile.goal
              : remoteProfile.goal
          ..dietaryFocus = remoteProfile.dietaryFocus.isEmpty
              ? profile.dietaryFocus
              : remoteProfile.dietaryFocus
          ..targetScore = remoteProfile.targetScore.clamp(50, 100).toInt();
      }
      final remoteHealthProfile = data.healthProfile;
      if (remoteHealthProfile != null && remoteHealthProfile.isComplete) {
        healthProfile
          ..age = remoteHealthProfile.age
          ..weightKg = remoteHealthProfile.weightKg
          ..heightCm = remoteHealthProfile.heightCm
          ..allergies = remoteHealthProfile.allergies
          ..dislikedFoods = remoteHealthProfile.dislikedFoods
          ..dietaryPattern = remoteHealthProfile.dietaryPattern
          ..updatedAt = remoteHealthProfile.updatedAt;
      }
      final remoteSettings = data.settings;
      if (remoteSettings != null) {
        dailyRemindersEnabled = remoteSettings.dailyReminders;
        weeklySummaryEnabled = remoteSettings.weeklySummary;
        progressNotificationsEnabled = remoteSettings.progressNotifications;
        compactDiaryEnabled = remoteSettings.compactDiary;
        final parts = remoteSettings.reminderTime.split(':');
        final hour = int.tryParse(parts.first);
        final minute = parts.length > 1 ? int.tryParse(parts[1]) : null;
        if (hour != null &&
            minute != null &&
            hour >= 0 &&
            hour < 24 &&
            minute >= 0 &&
            minute < 60) {
          reminderTime = TimeOfDay(hour: hour, minute: minute);
        }
      }
      shoppingItems
        ..clear()
        ..addAll(data.shoppingItems);
      notifyListeners();
    } catch (error) {
      hydrateError = error.toString();
      debugPrint('[Firestore] hydrate failed error=$error');
      notifyListeners();
    } finally {
      isHydrating = false;
      notifyListeners();
    }
  }

  bool dailyRemindersEnabled = true;
  bool weeklySummaryEnabled = true;
  bool progressNotificationsEnabled = true;
  bool compactDiaryEnabled = false;
  TimeOfDay reminderTime = const TimeOfDay(hour: 20, minute: 0);

  int get mealCountThisWeek {
    final today = _dateOnly(DateTime.now());
    final firstDay = today.subtract(const Duration(days: 6));
    return meals.where((meal) {
      final date = _dateOnly(meal.date);
      return !date.isBefore(firstDay) && !date.isAfter(today);
    }).length;
  }

  int get todayMealCount => getMealsForDate(DateTime.now()).length;

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

  List<DailyProgress> get weeklyProgress {
    final today = _dateOnly(DateTime.now());
    return List.generate(7, (index) {
      final date = today.subtract(Duration(days: 6 - index));
      return DailyProgress(
        date: date,
        averageScore: 0,
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
    final analyzedMeals = recentMeals
        .where((meal) => aiMealAnalysisFor(meal.id) != null)
        .length;

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
        label: 'Bữa đã phân tích',
        value: analyzedMeals,
        goal: 5,
        icon: Icons.flag_outlined,
      ),
    ];
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

  MealPhotoAnalysisResult? aiMealAnalysisFor(String mealId) =>
      _aiMealAnalyses[mealId];

  Meal addMeal(
    MealType type,
    List<FoodItem> items, {
    DateTime? date,
    String? note,
    String? plannedMealId,
    String? imageUrl,
  }) {
    _validateItems(items);
    final meal = Meal(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: type,
      date: date ?? DateTime.now(),
      items: List.of(items),
      note: _cleanNote(note),
      plannedMealId: plannedMealId,
      imageUrl: imageUrl,
    );
    meals.add(meal);
    _persist(() => (repository as FirestoreAppRepository).upsertMeal(meal));
    notifyListeners();
    return meal;
  }

  List<MealPlan> getPlansForDate(DateTime date) {
    final day = _dateOnly(date);
    return mealPlans.where((p) => _dateOnly(p.date) == day).toList()
      ..sort((a, b) => a.type.index.compareTo(b.type.index));
  }

  MealPlan? getMealPlanById(String id) {
    for (final plan in mealPlans) {
      if (plan.id == id) return plan;
    }
    return null;
  }

  /// Returns a deterministic, catalog-only suggestion for the requested meal.
  /// It does not create a plan, meal, nutrition value, or score.
  FoodItem? suggestedFoodFor(
    MealType type,
    DateTime date, {
    AgeGroup? ageGroup,
  }) {
    final category = switch (type) {
      MealType.breakfast => 'breakfast',
      MealType.lunch => 'lunch',
      MealType.dinner => 'dinner',
      MealType.snack => 'snack',
    };
    final matches = foods
        .where((food) => food.category == category)
        .where((food) => ageGroup == null || food.ageGroups.contains(ageGroup))
        .toList();
    if (matches.isEmpty) return null;
    final index = (date.day + date.month + type.index) % matches.length;
    return matches[index];
  }

  /// Returns only explicitly annotated catalog items. Missing metadata is
  /// intentionally treated as unknown, never as universally suitable.
  List<FoodItem> suggestedFoodsFor(
    MealType type, {
    required AgeGroup ageGroup,
    String query = '',
  }) {
    final category = switch (type) {
      MealType.breakfast => 'breakfast',
      MealType.lunch => 'lunch',
      MealType.dinner => 'dinner',
      MealType.snack => 'snack',
    };
    return filterFoodItems(
      foods,
      category: category,
      query: query,
      ageGroup: ageGroup,
    );
  }

  MealPlan addMealPlan(
    MealType type,
    List<FoodItem> items, {
    required DateTime date,
    String? note,
  }) {
    _validateItems(items);
    final day = _dateOnly(date);
    final existing = mealPlans.where(
      (p) =>
          _dateOnly(p.date) == day &&
          p.type == type &&
          p.status == MealPlanStatus.planned,
    );
    if (existing.isNotEmpty) return existing.first;
    final plan = MealPlan(
      id: 'plan-${DateTime.now().microsecondsSinceEpoch}',
      date: date,
      type: type,
      items: List.of(items),
      note: _cleanNote(note),
    );
    mealPlans.add(plan);
    _persist(() => (repository as FirestoreAppRepository).upsertPlan(plan));
    notifyListeners();
    return plan;
  }

  /// Adds catalog items to the planned meal for a day without creating
  /// duplicate food entries when the confirmation is repeated.
  MealPlan addFoodsToMealPlan(
    MealType type,
    Iterable<FoodItem> items, {
    required DateTime date,
  }) {
    final selected = _uniqueFoods(items);
    _validateItems(selected);
    final day = _dateOnly(date);
    final existing = mealPlans.where(
      (plan) =>
          _dateOnly(plan.date) == day &&
          plan.type == type &&
          plan.status == MealPlanStatus.planned,
    );
    if (existing.isEmpty) {
      return addMealPlan(type, selected, date: date);
    }

    final plan = existing.first;
    final existingIds = plan.items.map((food) => food.id).toSet();
    final additions = selected
        .where((food) => !existingIds.contains(food.id))
        .toList();
    if (additions.isNotEmpty) {
      plan.items.addAll(additions);
      _persist(() => (repository as FirestoreAppRepository).upsertPlan(plan));
      notifyListeners();
    }
    return plan;
  }

  bool updateMealPlan(
    String id,
    MealType type,
    List<FoodItem> items, {
    DateTime? date,
    String? note,
  }) {
    _validateItems(items);
    final plan = getMealPlanById(id);
    if (plan == null || plan.status == MealPlanStatus.completed) return false;
    // Replace the immutable value while keeping the plan ID and completion link.
    final index = mealPlans.indexOf(plan);
    mealPlans[index] = MealPlan(
      id: plan.id,
      date: date ?? plan.date,
      type: type,
      items: List.of(items),
      note: _cleanNote(note),
      status: plan.status,
      actualMealId: plan.actualMealId,
    );
    _persist(
      () => (repository as FirestoreAppRepository).upsertPlan(mealPlans[index]),
    );
    notifyListeners();
    return true;
  }

  bool deleteMealPlan(String id) {
    final before = mealPlans.length;
    mealPlans.removeWhere((p) => p.id == id);
    final removed = mealPlans.length != before;
    if (removed) {
      notifyListeners();
      _persist(() => (repository as FirestoreAppRepository).deletePlan(id));
    }
    return removed;
  }

  void _persist(Future<void> Function() operation) {
    if (repository is FirestoreAppRepository) {
      operation().catchError((error) {
        lastPersistenceError = error.toString();
        debugPrint('[Firestore] persistence failed error=$error');
        notifyListeners();
      });
    }
  }

  Meal? actualMealForPlan(String planId) {
    final plan = getMealPlanById(planId);
    if (plan?.actualMealId == null) return null;
    return getMealById(plan!.actualMealId!);
  }

  Meal? completeMealPlan(
    String planId, {
    List<FoodItem>? actualItems,
    String? note,
  }) {
    final plan = getMealPlanById(planId);
    if (plan == null) return null;
    if (plan.actualMealId != null) return getMealById(plan.actualMealId!);
    final meal = addMeal(
      plan.type,
      actualItems ?? plan.items,
      date: plan.date,
      note: note ?? plan.note,
      plannedMealId: plan.id,
    );
    plan.status = MealPlanStatus.completed;
    plan.actualMealId = meal.id;
    _persist(() => (repository as FirestoreAppRepository).upsertPlan(plan));
    notifyListeners();
    return meal;
  }

  List<ShoppingItem> buildShoppingList(Iterable<MealPlan> plans) {
    final merged = <String, ShoppingItem>{};
    for (final plan in plans) {
      for (final food in plan.items) {
        // The current catalog may not have ingredient metadata. In that case
        // keep the food name as a safe, non-quantified shopping item.
        final ingredients = food.ingredients.isEmpty
            ? <String>[food.name]
            : food.ingredients;
        for (final ingredient in ingredients) {
          final item = ShoppingItem(ingredient);
          merged.putIfAbsent(item.key, () => item);
        }
      }
    }
    shoppingItems
      ..clear()
      ..addAll(merged.values);
    notifyListeners();
    _persist(
      () => (repository as FirestoreAppRepository).saveShoppingList(
        shoppingItems,
      ),
    );
    return List.unmodifiable(shoppingItems);
  }

  void setShoppingItemPurchased(ShoppingItem item, bool value) {
    item.purchased = value;
    notifyListeners();
    _persist(
      () => (repository as FirestoreAppRepository).saveShoppingList(
        shoppingItems,
      ),
    );
  }

  void removeShoppingItem(ShoppingItem item) {
    shoppingItems.remove(item);
    notifyListeners();
    _persist(
      () => (repository as FirestoreAppRepository).saveShoppingList(
        shoppingItems,
      ),
    );
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
      plannedMealId: meal.plannedMealId,
      imageUrl: meal.imageUrl,
    );
    meals[index] = updated;
    _aiMealAnalyses.remove(mealId);
    _persist(
      () => (repository as FirestoreAppRepository).upsertMeal(
        updated,
        invalidateAnalysis: true,
      ),
    );
    notifyListeners();
    return true;
  }

  bool deleteMeal(String mealId) {
    final removed = meals.any((meal) => meal.id == mealId);
    if (!removed) return false;
    meals.removeWhere((meal) => meal.id == mealId);
    _aiMealAnalyses.remove(mealId);
    _persist(() => (repository as FirestoreAppRepository).deleteMeal(mealId));
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
    _persist(
      () => (repository as FirestoreAppRepository).saveReadingProgress(
        articleId,
        true,
      ),
    );
    return true;
  }

  void saveAiMealAnalysis(String mealId, MealPhotoAnalysisResult result) {
    if (!meals.any((meal) => meal.id == mealId)) return;
    _aiMealAnalyses[mealId] = result;
    notifyListeners();
    _persist(
      () => (repository as FirestoreAppRepository).saveAiMealAnalysis(
        mealId,
        result,
      ),
    );
  }

  void updateProfile({
    required String name,
    required String email,
    required String goal,
    required String dietaryFocus,
    required int targetScore,
  }) {
    final authenticatedEmail = repository is FirestoreAppRepository
        ? (repository as FirestoreAppRepository).authenticatedEmail
        : null;
    profile
      ..name = name.trim().isEmpty ? profile.name : name.trim()
      ..email = authenticatedEmail?.isNotEmpty == true
          ? authenticatedEmail!
          : email.trim().isEmpty
          ? profile.email
          : email.trim()
      ..goal = goal.trim().isEmpty ? profile.goal : goal.trim()
      ..dietaryFocus = dietaryFocus.trim().isEmpty
          ? profile.dietaryFocus
          : dietaryFocus.trim()
      ..targetScore = targetScore.clamp(50, 100).toInt();
    notifyListeners();
    _persist(
      () => (repository as FirestoreAppRepository).updateProfileFields(
        displayName: profile.name,
        email: profile.email,
        goal: profile.goal,
        dietaryFocus: profile.dietaryFocus,
        targetScore: profile.targetScore,
      ),
    );
  }

  void updateProfileName(String name) {
    if (name == profile.name) return;
    profile.name = name;
    notifyListeners();
    _persist(
      () => (repository as FirestoreAppRepository).updateProfileFields(
        displayName: profile.name,
        email: profile.email,
        goal: profile.goal,
        dietaryFocus: profile.dietaryFocus,
        targetScore: profile.targetScore,
      ),
    );
  }

  Future<void> updateHealthProfile({
    required int age,
    required double weightKg,
    required int heightCm,
    List<String> allergies = const [],
    List<String> dislikedFoods = const [],
    String dietaryPattern = '',
  }) async {
    if (age <= 0 ||
        age > 130 ||
        weightKg <= 0 ||
        weightKg > 500 ||
        heightCm <= 0 ||
        heightCm > 300) {
      throw ArgumentError('Thông tin sức khỏe không hợp lệ.');
    }
    healthProfile.setValues(
      newAge: age,
      newWeightKg: weightKg,
      newHeightCm: heightCm,
      newAllergies: allergies,
      newDislikedFoods: dislikedFoods,
      newDietaryPattern: dietaryPattern,
    );
    notifyListeners();
    if (repository is FirestoreAppRepository) {
      try {
        await (repository as FirestoreAppRepository).saveHealthProfile(
          healthProfile,
        );
      } catch (error) {
        lastPersistenceError = error.toString();
        notifyListeners();
        rethrow;
      }
    }
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
    _persist(
      () => (repository as FirestoreAppRepository).saveSettings(
        dailyReminders: dailyRemindersEnabled,
        weeklySummary: weeklySummaryEnabled,
        progressNotifications: progressNotificationsEnabled,
        compactDiary: compactDiaryEnabled,
        reminderTime: '${reminderTime.hour}:${reminderTime.minute}',
      ),
    );
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

  List<FoodItem> _uniqueFoods(Iterable<FoodItem> values) {
    final byId = <String, FoodItem>{};
    for (final food in values) {
      byId[food.id] = food;
    }
    return byId.values.toList();
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

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  String? _cleanNote(String? note) {
    final value = note?.trim();
    return value == null || value.isEmpty ? null : value;
  }
}
