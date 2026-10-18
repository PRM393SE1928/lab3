import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_view.dart';
import '../../../shared/services/app_state.dart';
import '../../food_diary/models/meal.dart';
import '../models/meal_evaluation.dart';

class SuggestionsScreen extends StatefulWidget {
  const SuggestionsScreen({super.key, this.mealId});
  final String? mealId;
  @override
  State<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends State<SuggestionsScreen> {
  late String? _mealId =
      widget.mealId ?? context.read<AppState>().lastEvaluation?.mealId;

  @override
  void didUpdateWidget(covariant SuggestionsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mealId != widget.mealId) {
      _mealId =
          widget.mealId ?? context.read<AppState>().lastEvaluation?.mealId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final mealId = _mealId;
    final evaluation = mealId == null ? null : state.savedEvaluationFor(mealId);
    Meal? meal;
    for (final item in state.meals) {
      if (item.id == _mealId) meal = item;
    }
    final currentMeal = meal;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gợi ý cải thiện',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: evaluation == null || currentMeal == null
            ? const AppEmptyView(
                message: 'Chưa có kết quả cho bữa ăn này. Hãy mở bữa ăn từ Nhật ký và đánh giá trước.',
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  _MealHeader(meal: currentMeal, evaluation: evaluation),
                  const SizedBox(height: 20),
                  _SectionTitle(
                    icon: Icons.lightbulb_outline,
                    title: evaluation.suggestions.isEmpty
                        ? 'Trạng thái bữa ăn'
                        : 'Gợi ý cho bữa ăn này',
                  ),
                  const SizedBox(height: 10),
                  if (evaluation.warnings.isNotEmpty) ...[
                    _InfoCard(
                      icon: Icons.info_outline,
                      title: 'Lưu ý về dữ liệu',
                      message: evaluation.warnings.join('\n'),
                      color: Theme.of(context).colorScheme.tertiaryContainer,
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (evaluation.suggestions.isEmpty)
                    const _InfoCard(
                      icon: Icons.check_circle_outline,
                      title: 'Bạn đang làm tốt',
                      message: 'Bữa ăn đã đạt đủ tiêu chí hiện tại; không cần thêm món để tăng điểm.',
                      color: AppColors.paleGreen,
                    )
                  else
                    ...evaluation.suggestions.map(
                      (suggestion) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _SuggestionCard(
                          suggestion: suggestion,
                          index: evaluation.suggestions.indexOf(suggestion),
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: () =>
                        context.push('/meal-result', extra: currentMeal),
                    icon: const Icon(Icons.restaurant),
                    label: const Text('Mở bữa ăn để xem hoặc đổi món'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _MealHeader extends StatelessWidget {
  const _MealHeader({required this.meal, required this.evaluation});

  final Meal meal;
  final MealEvaluation evaluation;

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor(context, evaluation.score);
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            meal.type.label,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            meal.items.map((food) => food.name).join(', '),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 92,
                height: 92,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: evaluation.score / 100,
                      strokeWidth: 9,
                      backgroundColor: color.withValues(alpha: 0.14),
                      color: color,
                    ),
                    Center(
                      child: Text(
                        '${evaluation.score}',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _scoreLabel(evaluation.score),
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${evaluation.score}/100 điểm',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      evaluation.summary,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        height: 1.35,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: AppColors.deepGreen),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
    ],
  );
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.suggestion, required this.index});

  final String suggestion;
  final int index;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.paleGreen,
          foregroundColor: AppColors.deepGreen,
          child: Text('${index + 1}'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            suggestion,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(height: 1.45),
          ),
        ),
      ],
    ),
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(16),
    child: Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.deepGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 5),
                Text(message, style: const TextStyle(height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Color _scoreColor(BuildContext context, int score) {
  if (score >= 75) return AppColors.deepGreen;
  if (score >= 50) return Theme.of(context).colorScheme.secondary;
  return Theme.of(context).colorScheme.error;
}

String _scoreLabel(int score) {
  if (score >= 100) return 'Đã đạt tối đa';
  if (score >= 75) return 'Đang duy trì tốt';
  if (score >= 50) return 'Có thể cải thiện';
  return 'Nên xem lại bữa ăn';
}
