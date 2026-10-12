class FoodItem {
  const FoodItem({
    required this.id,
    required this.name,
    required this.category,
    this.emoji = '🥗',
  });

  final String id;
  final String name;
  final String category;
  final String emoji;
}
