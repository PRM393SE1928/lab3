class FoodItem {
  const FoodItem({
    required this.id,
    required this.name,
    required this.category,
    this.emoji = '🥗',
  });
  final String id, name, category, emoji;
}
