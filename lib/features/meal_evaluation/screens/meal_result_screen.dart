import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../shared/services/app_state.dart';
import '../../food_diary/models/food_item.dart';
import '../../food_diary/models/meal.dart';
import '../models/meal_evaluation.dart';
import '../services/meal_evaluator.dart';
import 'meal_food_editor.dart';

class MealResultScreen extends StatefulWidget {
  const MealResultScreen({
    super.key,
    required this.meal,
    this.evaluator = const RuleBasedMealEvaluator(),
  });
  final Meal meal;
  final MealEvaluator evaluator;
  @override
  State<MealResultScreen> createState() => _MealResultScreenState();
}

class _MealResultScreenState extends State<MealResultScreen> {
  MealEvaluation? _evaluation;
  Meal? _evaluatedMeal;
  List<FoodItem>? _draft;
  Meal? _draftSource;
  String? _error;
  bool _loading = true;
  int _request = 0;
  int? _previousScore;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _evaluate();
    });
  }

  @override
  void didUpdateWidget(covariant MealResultScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.meal.id != widget.meal.id) {
      _draft = null;
      _draftSource = null;
      _evaluation = null;
      _previousScore = null;
      _evaluate();
    }
  }

  Meal? _current(AppState state) {
    for (final meal in state.meals) {
      if (meal.id == widget.meal.id) return meal;
    }
    return null;
  }

  Future<void> _evaluate() async {
    final request = ++_request;
    final state = context.read<AppState>();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final source = _current(state);
      if (source == null) {
        throw const EvaluationException(
          'Bữa ăn không còn trong nhật ký. Hãy quay lại chọn bữa khác.',
        );
      }
      if (_draft != null && !identical(_draftSource, source)) {
        _draft = null;
        _draftSource = null;
        throw const EvaluationException(
          'Bữa ăn đã thay đổi. Thử lại để đánh giá dữ liệu mới nhất.',
        );
      }
      final input = Meal(
        id: source.id,
        type: source.type,
        date: source.date,
        items: List.unmodifiable(_draft ?? source.items),
      );
      final result = await widget.evaluator.evaluate(input);
      if (!mounted || request != _request) return;
      if (result.mealId != null && result.mealId != source.id) {
        throw const EvaluationException(
          'Kết quả đánh giá không thuộc bữa ăn đang mở.',
        );
      }
      if (result.score < 0 || result.score > 100) {
        throw const EvaluationException(
          'Kết quả đánh giá không hợp lệ. Hãy thử lại.',
        );
      }
      if (!identical(source, _current(state))) {
        _draft = null;
        throw const EvaluationException(
          'Bữa ăn đã thay đổi. Thử lại để đánh giá dữ liệu mới nhất.',
        );
      }
      if (_draft != null) {
        _previousScore = _evaluation?.score;
        state.updateMeal(source.id, source.type, input.items);
      }
      state.recordEvaluation(source.id, result);
      setState(() {
        _evaluation = result;
        _evaluatedMeal = _current(state);
        _draft = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || request != _request) return;
      setState(() {
        _loading = false;
        _error = error is EvaluationException ? error.message : 'Không thể đánh giá bữa ăn lúc này. Các thay đổi chưa được áp dụng.';
      });
    }
  }

  Future<void> _edit() async {
    final state = context.read<AppState>();
    final meal = _current(state);
    if (meal == null) {
      await _evaluate();
      return;
    }
    final items = await showDialog<List<FoodItem>>(
      context: context,
      builder: (_) =>
          MealFoodEditor(items: _draft ?? meal.items, catalog: state.foods),
    );
    if (!mounted || items == null) return;
    _draft = items;
    _draftSource = meal;
    await _evaluate();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final evaluation = _evaluation;
    final stale =
        evaluation != null && !identical(_evaluatedMeal, _current(state));
    return Scaffold(
      appBar: AppBar(title: const Text('Kết quả đánh giá')),
      body: SafeArea(
        child: _loading
            ? const AppLoading()
            : _error != null
            ? SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(_error!, textAlign: TextAlign.center),
                    ),
                    AppErrorView(onRetry: _evaluate),
                    TextButton(
                      onPressed: _edit,
                      child: const Text('Điều chỉnh món ăn'),
                    ),
                  ],
                ),
              )
            : stale
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Bữa ăn đã thay đổi. Cần đánh giá lại.'),
                    FilledButton(
                      onPressed: _evaluate,
                      child: const Text('Đánh giá lại'),
                    ),
                  ],
                ),
              )
            : evaluation == null
            ? const SizedBox.shrink()
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    _evaluatedMeal!.type.label,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    _evaluatedMeal!.items.map((food) => food.name).join(', '),
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    child: Column(
                      children: [
                        const Text('Meal Score'),
                        Text(
                          '${evaluation.score}',
                          key: const Key('meal-score'),
                          style: const TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text('trên 100 điểm'),
                        if (_previousScore != null)
                          Text(
                            'Trước điều chỉnh: $_previousScore → ${evaluation.score}',
                          ),
                        Text(evaluation.summary, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(MealEvaluation.scoreExplanation),
                  ...evaluation.warnings.map(
                    (warning) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(warning),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tiêu chí tốt / cần cải thiện',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  ...evaluation.criteria.entries.map(
                    (entry) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        entry.value == 25
                            ? Icons.check_circle_outline
                            : Icons.info_outline,
                      ),
                      title: Text('${entry.key}: ${entry.value}/25'),
                      subtitle: Text(
                        '${entry.value == 25 ? 'Đạt' : 'Cần cải thiện'} · ${evaluation.explanations[entry.key] ?? ''}',
                      ),
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () =>
                        context.push('/suggestions', extra: _evaluatedMeal),
                    icon: const Icon(Icons.lightbulb_outline),
                    label: const Text('Xem gợi ý'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _edit,
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('Đổi món và đánh giá lại'),
                  ),
                ],
              ),
      ),
    );
  }
}
