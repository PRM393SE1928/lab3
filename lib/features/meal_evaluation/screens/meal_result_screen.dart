import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_card.dart';
import '../../../shared/services/app_state.dart';
import '../models/meal_evaluation.dart';
import '../../food_diary/models/meal.dart';

class MealResultScreen extends StatefulWidget {
  const MealResultScreen({super.key, required this.meal});
  final Meal meal;

  @override
  State<MealResultScreen> createState() => _MealResultScreenState();
}

class _MealResultScreenState extends State<MealResultScreen> {
  late final MealEvaluation evaluation;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    evaluation = state.calculateEvaluation(widget.meal);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        state.recordEvaluation(widget.meal.id, evaluation);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kết quả đánh giá')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppCard(
            child: Column(
              children: [
                Text(
                  '${evaluation.score}',
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Text(
                  'trên 100 điểm',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 12),
                Text(evaluation.summary, textAlign: TextAlign.center),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Các yếu tố tạo nên điểm số',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ...evaluation.criteria.entries.map(
            (entry) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(entry.key),
              trailing: Text(
                '${entry.value}%',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: () => context.push('/suggestions'),
            icon: const Icon(Icons.lightbulb_outline),
            label: const Text('Xem gợi ý'),
          ),
        ],
      ),
    );
  }
}
