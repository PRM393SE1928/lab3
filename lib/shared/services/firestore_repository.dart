import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../features/food_diary/models/food_item.dart';
import '../../features/food_diary/models/meal.dart';
import '../../features/meal_planner/models/meal_plan.dart';
import '../../features/meal_evaluation/services/meal_photo_analyzer.dart';
import '../../features/user_progress/models/health_profile.dart';
import 'mock_repository.dart';

class FirestoreAppRepository extends MockRepository {
  FirestoreAppRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String? get authenticatedEmail => _auth.currentUser?.email;

  // Production data comes from the signed-in user's subcollection. The
  // mock repository's sample meals are intentionally not exposed here.
  @override
  List<Meal> get meals => const [];

  DocumentReference<Map<String, dynamic>> get _userRef =>
      _firestore.collection('users').doc(_auth.currentUser!.uid);

  Future<void> _write(String path, Future<void> Function() operation) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Không thể lưu dữ liệu khi chưa đăng nhập.');
    }
    try {
      await operation();
      debugPrint(
        '[Firestore] write ok project=${_firestore.app.options.projectId} '
        'uid=${user.uid} path=$path',
      );
    } on FirebaseException catch (error, stackTrace) {
      debugPrint(
        '[Firestore] write failed project=${_firestore.app.options.projectId} '
        'uid=${user.uid} path=$path code=${error.code} message=${error.message}',
      );
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    } on Object catch (error, stackTrace) {
      debugPrint('[Firestore] write failed path=$path error=$error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<RemoteData> loadUserData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const RemoteData();
    final mealSnapshot = await _userRef.collection('meals').get();
    final planSnapshot = await _userRef.collection('mealPlans').get();
    final aiAnalysisSnapshot = await _userRef
        .collection('aiMealAnalyses')
        .get();
    final readingSnapshot = await _userRef.collection('readingProgress').get();
    final settingsSnapshot = await _userRef
        .collection('settings')
        .doc('preferences')
        .get();
    final shoppingSnapshot = await _userRef
        .collection('shopping')
        .doc('current')
        .get();
    final healthProfileSnapshot = await _userRef
        .collection('health_profile')
        .doc('current')
        .get();
    final profileSnapshot = await _userRef.get();
    final analyzedFoodsByMeal = <String, List<FoodItem>>{};
    for (final doc in aiAnalysisSnapshot.docs) {
      final data = doc.data();
      final mealId = data['mealId']?.toString();
      final rawFoods = data['foods'];
      if (mealId == null || rawFoods is! List) continue;
      analyzedFoodsByMeal[mealId] = rawFoods
          .whereType<Map>()
          .map(
            (food) => FoodItem(
              id:
                  food['catalogId']?.toString() ??
                  'ai_${normalizeFoodText(food['name']?.toString() ?? '').replaceAll(' ', '_')}',
              name: food['name']?.toString() ?? '',
              category: 'ai',
              description: 'Món được nhận diện tự động từ ảnh bởi AI.',
            ),
          )
          .where((food) => food.name.isNotEmpty)
          .toList();
    }
    return RemoteData(
      analyses: {
        for (final doc in aiAnalysisSnapshot.docs)
          if (mealSnapshot.docs.any((meal) => meal.id == doc.id))
            doc.id: BackendMealPhotoAnalyzer.parseResponse(
              // Parse stored results through the same schema as API results.
              _analysisJson(doc.data()),
              foods,
            ),
      },
      meals: mealSnapshot.docs
          .map(
            (doc) => MealMapper.tryFromMap(doc.data(), [
              ...foods,
              ...?analyzedFoodsByMeal[doc.data()['id']?.toString() ?? doc.id],
            ], doc.id),
          )
          .whereType<Meal>()
          .toList(),
      plans: planSnapshot.docs
          .map((doc) => MealPlanMapper.tryFromMap(doc.data(), foods, doc.id))
          .whereType<MealPlan>()
          .toList(),
      readArticleIds: readingSnapshot.docs
          .where((doc) => doc.data()['isRead'] == true)
          .map((doc) => doc.id)
          .toSet(),
      profile: profileSnapshot.exists
          ? UserProfileData.fromMap(profileSnapshot.data()!)
          : null,
      settings: settingsSnapshot.exists
          ? NotificationSettingsData.fromMap(settingsSnapshot.data()!)
          : null,
      shoppingItems: ShoppingMapper.fromMap(shoppingSnapshot.data()),
      healthProfile: healthProfileSnapshot.exists
          ? HealthProfileMapper.fromMap(healthProfileSnapshot.data()!)
          : null,
    );
  }

  Future<void> upsertMeal(Meal meal, {bool invalidateAnalysis = false}) async {
    final path = 'users/{uid}/meals/${meal.id}';
    await _write(path, () async {
      final batch = _firestore.batch();
      batch.set(
        _userRef.collection('meals').doc(meal.id),
        MealMapper.toMap(meal),
      );
      if (invalidateAnalysis) {
        batch.delete(_userRef.collection('aiMealAnalyses').doc(meal.id));
      }
      await batch.commit();
    });
  }

  Future<void> deleteMeal(String id) async {
    await _write('users/{uid}/meals/$id', () async {
      final batch = _firestore.batch();
      batch.delete(_userRef.collection('meals').doc(id));
      batch.delete(_userRef.collection('aiMealAnalyses').doc(id));
      await batch.commit();
    });
  }

  Future<void> upsertPlan(MealPlan plan) async {
    await _write(
      'users/{uid}/mealPlans/${plan.id}',
      () => _userRef
          .collection('mealPlans')
          .doc(plan.id)
          .set(MealPlanMapper.toMap(plan)),
    );
  }

  Future<void> deletePlan(String id) async {
    await _write(
      'users/{uid}/mealPlans/$id',
      () => _userRef.collection('mealPlans').doc(id).delete(),
    );
  }

  Future<void> saveAiMealAnalysis(
    String mealId,
    MealPhotoAnalysisResult result,
  ) async {
    await _write('users/{uid}/aiMealAnalyses/$mealId', () {
      return _userRef.collection('aiMealAnalyses').doc(mealId).set({
        'userId': _auth.currentUser?.uid,
        'mealId': mealId,
        'analyzedAt': FieldValue.serverTimestamp(),
        'analysisStatus': 'confirmed',
        ...result.toJson(),
      }, SetOptions(merge: true));
    });
  }

  Future<void> saveReadingProgress(String articleId, bool isRead) async {
    await _write('users/{uid}/readingProgress/$articleId', () {
      return _userRef.collection('readingProgress').doc(articleId).set({
        'articleId': articleId,
        'isRead': isRead,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> saveSettings({
    required bool dailyReminders,
    required bool weeklySummary,
    required bool progressNotifications,
    required bool compactDiary,
    required String reminderTime,
  }) async {
    await _write('users/{uid}/settings/preferences', () {
      return _userRef.collection('settings').doc('preferences').set({
        'dailyReminders': dailyReminders,
        'weeklySummary': weeklySummary,
        'progressNotifications': progressNotifications,
        'compactDiary': compactDiary,
        'reminderTime': reminderTime,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Future<void> saveShoppingList(Iterable<ShoppingItem> items) async {
    await _write('users/{uid}/shopping/current', () {
      return _userRef.collection('shopping').doc('current').set({
        'items': items
            .map(
              (item) => {
                'name': item.name,
                'unit': item.unit,
                'purchased': item.purchased,
              },
            )
            .toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> saveHealthProfile(HealthProfile profile) async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint(
        '[Firestore] skipped write path=users/{uid}/health_profile/current '
        'reason=not-signed-in',
      );
      return;
    }
    await _write(
      'users/{uid}/health_profile/current',
      () => _userRef
          .collection('health_profile')
          .doc('current')
          .set(HealthProfileMapper.toMap(profile), SetOptions(merge: true)),
    );
  }

  Future<void> upsertProfile({required String displayName}) async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint(
        '[Firestore] skipped write path=users/{uid} reason=not-signed-in',
      );
      return;
    }
    await _write(
      'users/{uid}',
      () => _userRef.set({
        'uid': user.uid,
        'email': user.email,
        'displayName': displayName,
        'photoUrl': user.photoURL,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)),
    );
  }

  Future<void> updateProfileFields({
    required String displayName,
    required String email,
    required String goal,
    required String dietaryFocus,
    required int targetScore,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint(
        '[Firestore] skipped write path=users/{uid} reason=not-signed-in',
      );
      return;
    }
    await _write(
      'users/{uid}',
      () => _userRef.set({
        'uid': user.uid,
        'email': email,
        'displayName': displayName,
        'goal': goal,
        'dietaryFocus': dietaryFocus,
        'targetScore': targetScore,
        'photoUrl': user.photoURL,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)),
    );
    if (user.displayName != displayName) {
      await user.updateDisplayName(displayName);
    }
  }
}

class RemoteData {
  const RemoteData({
    this.meals = const [],
    this.plans = const [],
    this.readArticleIds = const {},
    this.profile,
    this.settings,
    this.shoppingItems = const [],
    this.healthProfile,
    this.analyses = const {},
  });
  final List<Meal> meals;
  final List<MealPlan> plans;
  final Set<String> readArticleIds;
  final UserProfileData? profile;
  final NotificationSettingsData? settings;
  final List<ShoppingItem> shoppingItems;
  final HealthProfile? healthProfile;
  final Map<String, MealPhotoAnalysisResult> analyses;
}

class HealthProfileMapper {
  static Map<String, dynamic> toMap(HealthProfile profile) => {
    'age': profile.age,
    'weightKg': profile.weightKg,
    'heightCm': profile.heightCm,
    'allergies': profile.allergies,
    'dislikedFoods': profile.dislikedFoods,
    'dietaryPattern': profile.dietaryPattern,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  static HealthProfile fromMap(Map<String, dynamic> map) => HealthProfile(
    age: (map['age'] as num?)?.toInt(),
    weightKg: (map['weightKg'] as num?)?.toDouble(),
    heightCm: (map['heightCm'] as num?)?.toInt(),
    allergies: (map['allergies'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList(),
    dislikedFoods: (map['dislikedFoods'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList(),
    dietaryPattern: map['dietaryPattern'] as String? ?? '',
    updatedAt: _dateOrNull(map['updatedAt']),
  );
}

class UserProfileData {
  const UserProfileData({
    required this.name,
    required this.email,
    required this.goal,
    required this.dietaryFocus,
    required this.targetScore,
  });

  factory UserProfileData.fromMap(Map<String, dynamic> map) => UserProfileData(
    name: map['displayName'] as String? ?? '',
    email: map['email'] as String? ?? '',
    goal: map['goal'] as String? ?? '',
    dietaryFocus: map['dietaryFocus'] as String? ?? '',
    targetScore: (map['targetScore'] as num?)?.toInt() ?? 80,
  );

  final String name;
  final String email;
  final String goal;
  final String dietaryFocus;
  final int targetScore;
}

class NotificationSettingsData {
  const NotificationSettingsData({
    required this.dailyReminders,
    required this.weeklySummary,
    required this.progressNotifications,
    required this.compactDiary,
    required this.reminderTime,
  });

  factory NotificationSettingsData.fromMap(Map<String, dynamic> map) =>
      NotificationSettingsData(
        dailyReminders: map['dailyReminders'] as bool? ?? true,
        weeklySummary: map['weeklySummary'] as bool? ?? true,
        progressNotifications: map['progressNotifications'] as bool? ?? true,
        compactDiary: map['compactDiary'] as bool? ?? false,
        reminderTime: map['reminderTime'] as String? ?? '20:0',
      );

  final bool dailyReminders;
  final bool weeklySummary;
  final bool progressNotifications;
  final bool compactDiary;
  final String reminderTime;
}

class ShoppingMapper {
  static List<ShoppingItem> fromMap(Map<String, dynamic>? map) {
    final values = map?['items'];
    if (values is! List) return [];
    return values.whereType<Map<String, dynamic>>().map((value) {
      final item = ShoppingItem(
        value['name'] as String,
        unit: value['unit'] as String?,
      );
      item.purchased = value['purchased'] as bool? ?? false;
      return item;
    }).toList();
  }
}

class MealMapper {
  static Map<String, dynamic> toMap(Meal meal) => {
    'id': meal.id,
    'type': meal.type.name,
    'date': Timestamp.fromDate(meal.date),
    'foodIds': meal.items.map((item) => item.id).toList(),
    'foodItems': meal.items
        .map(
          (item) => {
            'id': item.id,
            'name': item.name,
            'category': item.category,
            'emoji': item.emoji,
            'description': item.description,
          },
        )
        .toList(),
    'note': meal.note,
    'plannedMealId': meal.plannedMealId,
    'imageUrl': meal.imageUrl,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  static Meal? tryFromMap(
    Map<String, dynamic> map,
    List<FoodItem> foods,
    String documentId,
  ) {
    try {
      return fromMap(map, foods, documentId);
    } on Object {
      return null;
    }
  }

  static Meal fromMap(
    Map<String, dynamic> map,
    List<FoodItem> foods,
    String documentId,
  ) {
    final embeddedFoods = (map['foodItems'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map(
          (item) => FoodItem(
            id: item['id']?.toString() ?? '',
            name: item['name']?.toString() ?? '',
            category: item['category']?.toString() ?? 'ai',
            emoji: item['emoji']?.toString() ?? '🥗',
            description: item['description']?.toString() ?? '',
          ),
        )
        .where((food) => food.id.isNotEmpty && food.name.isNotEmpty)
        .toList();
    final availableFoods = [...foods, ...embeddedFoods];
    final items = (map['foodIds'] as List<dynamic>? ?? const [])
        .map(
          (id) => availableFoods.cast<FoodItem?>().firstWhere(
            (food) => food?.id == id,
            orElse: () => null,
          ),
        )
        .whereType<FoodItem>()
        .toList();
    return Meal(
      id: map['id'] as String? ?? documentId,
      type: MealType.values.byName(map['type'] as String),
      date: _date(map['date']),
      items: items,
      note: map['note'] as String?,
      plannedMealId: map['plannedMealId'] as String?,
      imageUrl: map['imageUrl'] as String?,
    );
  }
}

class MealPlanMapper {
  static Map<String, dynamic> toMap(MealPlan plan) => {
    'id': plan.id,
    'type': plan.type.name,
    'date': Timestamp.fromDate(plan.date),
    'foodIds': plan.items.map((item) => item.id).toList(),
    'note': plan.note,
    'status': plan.status.name,
    'actualMealId': plan.actualMealId,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  static MealPlan? tryFromMap(
    Map<String, dynamic> map,
    List<FoodItem> foods,
    String documentId,
  ) {
    try {
      return MealPlan(
        id: map['id'] as String? ?? documentId,
        type: MealType.values.byName(map['type'] as String),
        date: _date(map['date']),
        items: (map['foodIds'] as List<dynamic>? ?? const [])
            .map((id) => foods.where((food) => food.id == id).firstOrNull)
            .whereType<FoodItem>()
            .toList(),
        note: map['note'] as String?,
        status: MealPlanStatus.values.byName(
          map['status'] as String? ?? 'planned',
        ),
        actualMealId: map['actualMealId'] as String?,
      );
    } on Object {
      return null;
    }
  }
}

String _analysisJson(Map<String, dynamic> data) => jsonEncode(
  data,
  toEncodable: (value) =>
      value is Timestamp ? value.toDate().toIso8601String() : value.toString(),
);

DateTime _date(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.parse(value);
  throw const FormatException('Missing or invalid date');
}

DateTime? _dateOrNull(Object? value) {
  if (value == null) return null;
  try {
    return _date(value);
  } on Object {
    return null;
  }
}
