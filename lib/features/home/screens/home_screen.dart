import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../shared/services/app_state.dart';
import '../../food_diary/models/meal.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final now = DateTime.now();

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
            'Chào bạn, ${state.profile.name.split(' ').first}!',
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            '${_weekday(now.weekday)}, ${now.day} ${_month(now.month)}',
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 24),
          AppCard(
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.paleGreen,
                  child: Icon(Icons.spa_outlined, color: AppColors.deepGreen),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Điểm ăn uống hôm nay',
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${state.todayScore} / 100',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.trending_up, color: AppColors.deepGreen),
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
                child: const Text('Xem tất cả'),
              ),
            ],
          ),
          if (state.meals.isEmpty)
            const Text('Chưa có bữa ăn nào được ghi lại.')
          else
            ...state.meals
                .take(3)
                .map(
                  (meal) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppColors.paleOrange,
                      child: Text(_emoji(meal.type)),
                    ),
                    title: Text(meal.type.label),
                    subtitle: Text(
                      meal.items.map((item) => item.name).join(', '),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/meal-result', extra: meal),
                  ),
                ),
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
          const AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.wb_sunny_outlined, color: AppColors.softOrange),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Thêm một màu sắc vào đĩa ăn tiếp theo. Đa dạng đơn giản là một thói quen hữu ích.',
                    style: TextStyle(height: 1.4),
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

String _month(int value) => [
  '',
  'tháng 1',
  'tháng 2',
  'tháng 3',
  'tháng 4',
  'tháng 5',
  'tháng 6',
  'tháng 7',
  'tháng 8',
  'tháng 9',
  'tháng 10',
  'tháng 11',
  'tháng 12',
][value];

String _emoji(MealType type) => switch (type) {
  MealType.breakfast => '☀️',
  MealType.lunch => '🥗',
  MealType.dinner => '🍲',
  MealType.snack => '🍎',
};
