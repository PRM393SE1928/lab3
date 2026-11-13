import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../shared/services/app_state.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tiến độ',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Hồ sơ',
            onPressed: () => context.push('/profile'),
            icon: const Icon(Icons.person_outline),
          ),
          IconButton(
            tooltip: 'Cài đặt',
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          AppCard(
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 34,
                  backgroundColor: AppColors.paleGreen,
                  child: Icon(
                    Icons.auto_awesome_outlined,
                    color: AppColors.deepGreen,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Text(
                    '${state.todayMealCount} bữa ăn hôm nay. '
                    'Phân tích bằng AI để nhận nhận xét và gợi ý cụ thể.',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  value: '${state.mealCountThisWeek}',
                  label: 'Bữa tuần này',
                  icon: Icons.restaurant_menu_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  value: '${state.todayMealCount}',
                  label: 'Bữa hôm nay',
                  icon: Icons.today_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  value: '${state.streakDays}',
                  label: 'Ngày liên tiếp',
                  icon: Icons.local_fire_department_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Theo dõi 7 ngày',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final item in state.weeklyProgress)
                  _DayBar(
                    label: _weekdayShort(item.date.weekday),
                    score: item.averageScore,
                    mealCount: item.mealCount,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Thói quen ăn uống',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ...state.habitSummaries.map(
            (habit) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                child: Row(
                  children: [
                    CircleAvatar(child: Icon(habit.icon)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            habit.label,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(value: habit.ratio),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${habit.value}/${habit.goal}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.auto_stories_outlined),
              title: const Text('Tiến độ kiến thức'),
              subtitle: Text(
                '${state.readArticleCount}/${state.articles.length} bài đã đọc',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/learn'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(12),
    child: Column(
      children: [
        Icon(icon, color: AppColors.deepGreen),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    ),
  );
}

class _DayBar extends StatelessWidget {
  const _DayBar({
    required this.label,
    required this.score,
    required this.mealCount,
  });

  final String label;
  final int score;
  final int mealCount;

  @override
  Widget build(BuildContext context) {
    final height = score == 0 ? 8.0 : 24 + (score * 0.78);
    return SizedBox(
      width: 38,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            score == 0 ? '-' : '$score',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Container(
            width: 24,
            height: height,
            decoration: BoxDecoration(
              color: score >= 75
                  ? AppColors.deepGreen
                  : score > 0
                  ? AppColors.sage
                  : AppColors.paleGreen,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
          Text(
            '$mealCount bữa',
            style: const TextStyle(fontSize: 10, color: Colors.black45),
          ),
        ],
      ),
    );
  }
}

String _weekdayShort(int value) =>
    ['', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'][value];
