import '../../food_diary/models/food_item.dart';

class HealthProfile {
  HealthProfile({
    this.age,
    this.weightKg,
    this.heightCm,
    this.allergies = const [],
    this.dislikedFoods = const [],
    this.dietaryPattern = '',
    this.updatedAt,
  });

  int? age;
  double? weightKg;
  int? heightCm;
  List<String> allergies;
  List<String> dislikedFoods;
  String dietaryPattern;
  DateTime? updatedAt;

  bool get isComplete => age != null && weightKg != null && heightCm != null;

  AgeGroup? get ageGroup {
    final value = age;
    if (value == null) return null;
    if (value < 2) return AgeGroup.under2;
    if (value <= 5) return AgeGroup.age2To5;
    if (value <= 12) return AgeGroup.age6To12;
    if (value <= 17) return AgeGroup.age13To17;
    if (value <= 59) return AgeGroup.age18To59;
    return AgeGroup.age60Plus;
  }

  void setValues({
    required int newAge,
    required double newWeightKg,
    required int newHeightCm,
    List<String> newAllergies = const [],
    List<String> newDislikedFoods = const [],
    String newDietaryPattern = '',
  }) {
    age = newAge;
    weightKg = newWeightKg;
    heightCm = newHeightCm;
    allergies = List.unmodifiable(newAllergies);
    dislikedFoods = List.unmodifiable(newDislikedFoods);
    dietaryPattern = newDietaryPattern.trim();
    updatedAt = DateTime.now();
  }
}
