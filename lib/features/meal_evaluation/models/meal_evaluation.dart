class MealEvaluation {
  const MealEvaluation({
    required this.score,
    required this.summary,
    required this.criteria,
    required this.suggestions,
    this.mealId,
    this.explanations = const {},
    this.warnings = const [],
  });
  final int score;
  final String summary;
  final Map<String, int> criteria;
  final List<String> suggestions;
  final String? mealId;
  final Map<String, String> explanations;
  final List<String> warnings;
  static const ruleVersion = 'meal-groups-v1';
  static const scoreExplanation =
      'Điểm quy tắc của app: 4 tiêu chí, mỗi tiêu chí tối đa 25 điểm. '
      'Dựa trên nhóm món, chưa xét khẩu phần, năng lượng hay nhu cầu cá nhân; '
      'không phải đánh giá y khoa hoặc dự đoán tuổi thọ.';
}
