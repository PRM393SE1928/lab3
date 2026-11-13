import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_view.dart';
import '../../../shared/services/app_state.dart';
import '../../food_diary/models/meal.dart';

class SuggestionsScreen extends StatelessWidget {
  const SuggestionsScreen({super.key, this.mealId});

  final String? mealId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final id = mealId;
    final result = id == null ? null : state.aiMealAnalysisFor(id);
    final meal = id == null ? null : state.getMealById(id);
    return Scaffold(
      appBar: AppBar(title: const Text('Gợi ý cải thiện')),
      body: result == null || meal == null
          ? const AppEmptyView(
              message: 'Chưa có phân tích AI cho bữa ăn này. Hãy phân tích ảnh trước.',
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  meal.type.label,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(meal.items.map((food) => food.name).join(', ')),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Gợi ý từ AI',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...result.improvements.map((item) => Text('• $item')),
                      ...result.personalizedAdvice.map(
                        (item) => Text('• $item'),
                      ),
                      if (result.improvements.isEmpty &&
                          result.personalizedAdvice.isEmpty)
                        const Text('AI chưa có gợi ý bổ sung cho bữa ăn này.'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => context.push('/meal-result', extra: meal),
                  icon: const Icon(Icons.restaurant),
                  label: const Text('Xem toàn bộ phân tích AI'),
                ),
              ],
            ),
    );
  }
}
