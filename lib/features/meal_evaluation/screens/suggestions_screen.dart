import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_view.dart';
import '../../../shared/services/app_state.dart';
import '../../food_diary/models/meal.dart';

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
      appBar: AppBar(title: const Text('Gợi ý cải thiện')),
      body: SafeArea(
        child: evaluation == null || currentMeal == null
            ? const AppEmptyView(
                message: 'Chưa có kết quả cho bữa ăn này. Hãy mở bữa ăn từ Nhật ký và đánh giá trước.',
              )
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    '${currentMeal.type.label} · ${evaluation.score}/100',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(currentMeal.items.map((food) => food.name).join(', ')),
                  const SizedBox(height: 16),
                  ...evaluation.warnings.map((warning) => Text(warning)),
                  ...evaluation.suggestions.asMap().entries.map(
                    (entry) => AppCard(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(child: Text('${entry.key + 1}')),
                        title: Text(entry.value),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () =>
                        context.push('/meal-result', extra: currentMeal),
                    icon: const Icon(Icons.restaurant),
                    label: const Text('Mở bữa ăn để đổi món'),
                  ),
                ],
              ),
      ),
    );
  }
}
