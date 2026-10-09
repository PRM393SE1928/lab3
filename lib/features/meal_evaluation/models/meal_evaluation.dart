class MealEvaluation {
  const MealEvaluation({
    required this.score,
    required this.summary,
    required this.criteria,
    required this.suggestions,
  });
  final int score;
  final String summary;
  final Map<String, int> criteria;
  final List<String> suggestions;
}
