import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../shared/services/app_state.dart';
import '../../../shared/services/mock_content.dart';
import '../../food_diary/models/meal.dart';
import '../../meal_evaluation/models/meal_evaluation.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final todayMeals = state.getMealsForDate(DateTime.now());
    final evaluations = todayMeals
        .map(state.savedEvaluationFor)
        .whereType<MealEvaluation>()
        .toList();
    final score = evaluations.isEmpty
        ? null
        : (evaluations.map((item) => item.score).reduce((a, b) => a + b) /
                  evaluations.length)
              .round();
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Longeva',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Hồ sơ',
            onPressed: () => context.push('/profile'),
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'Chào buổi sáng, ${state.profile.name.split(' ').first}!',
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            _dateLabel(DateTime.now()),
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 24),
          AppCard(
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.paleGreen,
                  child: Icon(
                    Icons.restaurant_outlined,
                    color: AppColors.deepGreen,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${todayMeals.length} bữa đã ghi hôm nay',
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        score == null ? 'Chưa có đánh giá' : '$score / 100',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                if (score != null)
                  const Icon(
                    Icons.insights_outlined,
                    color: AppColors.deepGreen,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Bữa ăn của bạn',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              TextButton(
                onPressed: () => context.go('/diary'),
                child: const Text('Xem nhật ký'),
              ),
            ],
          ),
          if (todayMeals.isEmpty)
            AppCard(
              child: Column(
                children: [
                  const Text(
                    'Chưa có bữa ăn nào được ghi lại hôm nay.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/add-meal'),
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm bữa ăn'),
                  ),
                ],
              ),
            )
          else
            ...todayMeals.map((meal) => _MealTile(meal: meal)),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => context.push('/add-meal'),
            icon: const Icon(Icons.add),
            label: const Text('Ghi lại bữa ăn'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
          ),
          const SizedBox(height: 26),
          const Text(
            'Gợi ý nhỏ cho hôm nay',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.wb_sunny_outlined,
                  color: AppColors.softOrange,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    dailyTips[DateTime.now().day % dailyTips.length],
                    style: const TextStyle(height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MealTile extends StatelessWidget {
  const _MealTile({required this.meal});
  final Meal meal;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: CircleAvatar(
      backgroundColor: AppColors.paleOrange,
      child: Text(_mealEmoji(meal.type)),
    ),
    title: Text(meal.type.label),
    subtitle: Text(
      '${_timeLabel(meal.date)} • ${meal.items.map((item) => item.name).join(', ')}',
    ),
    trailing: const Icon(Icons.chevron_right),
    onTap: () => context.push('/meal/${meal.id}'),
  );
}

String _dateLabel(DateTime date) =>
    '${_weekday(date.weekday)}, ${date.day}/${date.month}/${date.year}';
String _timeLabel(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
String _weekday(int value) => [
  '',
  'Thứ Hai',
  'Thứ Ba',
  'Thứ Tư',
  'Thứ Năm',
  'Thứ Sáu',
  'Thứ Bảy',
  'Chủ Nhật',
][value];
String _mealEmoji(MealType type) => switch (type) {
  MealType.breakfast => '☀️',
  MealType.lunch => '🥗',
  MealType.dinner => '🍲',
  MealType.snack => '🍎',
};
