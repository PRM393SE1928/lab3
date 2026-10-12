import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../shared/services/app_state.dart';
import '../models/meal.dart';

class MealDetailScreen extends StatelessWidget {
  const MealDetailScreen({super.key, required this.mealId});
  final String mealId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final meal = state.getMealById(mealId);
    if (meal == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết bữa ăn')),
        body: const Center(child: Text('Bữa ăn này không còn tồn tại.')),
      );
    }
    final evaluation = state.savedEvaluationFor(meal);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết bữa ăn'),
        actions: [
          IconButton(
            tooltip: 'Sửa bữa ăn',
            onPressed: () => context.push('/add-meal?mealId=${meal.id}'),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Xóa bữa ăn',
            onPressed: () => _confirmDelete(context, meal),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppCard(
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.paleOrange,
                  child: Text(_mealEmoji(meal.type)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal.type.label,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _dateTimeLabel(meal.date),
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Món ăn',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          AppCard(
            child: Column(
              children: meal.items
                  .map(
                    (item) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Text(
                        item.emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(item.name),
                      subtitle: Text(item.categoryLabel),
                    ),
                  )
                  .toList(),
            ),
          ),
          if (meal.note != null) ...[
            const SizedBox(height: 20),
            const Text(
              'Ghi chú',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            AppCard(child: Text(meal.note!)),
          ],
          const SizedBox(height: 20),
          if (evaluation == null)
            FilledButton.tonalIcon(
              onPressed: () => context.push('/meal-result', extra: meal),
              icon: const Icon(Icons.insights_outlined),
              label: const Text('Đánh giá bữa ăn'),
            )
          else ...[
            AppCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Điểm đánh giá gần nhất'),
                  Text(
                    '${evaluation.score}/100',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: () => context.push('/meal-result', extra: meal),
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('Xem đánh giá'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Meal meal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa bữa ăn?'),
        content: const Text('Bữa ăn sẽ bị xóa khỏi nhật ký.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<AppState>().deleteMeal(meal.id);
      context.pop();
    }
  }
}

String _dateTimeLabel(DateTime date) =>
    '${date.day}/${date.month}/${date.year} lúc ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

String _mealEmoji(MealType type) => switch (type) {
  MealType.breakfast => '☀️',
  MealType.lunch => '🥗',
  MealType.dinner => '🍲',
  MealType.snack => '🍎',
};
