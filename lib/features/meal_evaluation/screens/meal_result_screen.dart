import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_card.dart';
import '../../../shared/services/app_state.dart';
import '../../food_diary/models/meal.dart';
import '../models/book_principle.dart';
import '../services/meal_photo_analyzer.dart';

class MealResultScreen extends StatefulWidget {
  const MealResultScreen({
    super.key,
    required this.meal,
    this.analyzer,
    @Deprecated('Legacy rule evaluation is no longer used.') Object? evaluator,
  });

  final Meal meal;
  final MealPhotoAnalyzer? analyzer;

  @override
  State<MealResultScreen> createState() => _MealResultScreenState();
}

class _MealResultScreenState extends State<MealResultScreen> {
  bool _evaluating = false;
  String? _evaluationError;

  Future<void> _evaluateManually(Meal currentMeal) async {
    setState(() {
      _evaluating = true;
      _evaluationError = null;
    });

    final state = context.read<AppState>();
    final profile = state.healthProfile;
    final analyzer = widget.analyzer ?? configuredMealPhotoAnalyzer();
    const principlesRepo = BookPrinciplesRepository();

    try {
      final result = await analyzer.analyzeFoods(
        currentMeal.items,
        mealType: currentMeal.type.name,
        profile: jsonEncode({
          'age': profile.age,
          'ageGroup': profile.ageGroup?.name,
          'allergies': profile.allergies,
          'dislikedFoods': profile.dislikedFoods,
          'dietaryPattern': profile.dietaryPattern,
        }),
        principles: jsonEncode(principlesRepo.forAi),
      );

      if (!mounted) return;
      if (!identical(state.getMealById(currentMeal.id), currentMeal)) {
        setState(
          () => _evaluationError = 'Bữa ăn đã thay đổi. Hãy đánh giá lại.',
        );
        return;
      }
      state.saveAiMealAnalysis(currentMeal.id, result);
    } on MealPhotoAnalysisException catch (error) {
      if (mounted) {
        setState(() => _evaluationError = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _evaluationError =
              'Không thể đánh giá món ăn lúc này. Hãy thử lại.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _evaluating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final currentMeal = state.getMealById(widget.meal.id);
    final analysis = state.aiMealAnalysisFor(widget.meal.id);
    if (currentMeal == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.home_outlined),
            tooltip: 'Home',
          ),
          title: const Text('Kết quả phân tích'),
        ),
        body: const Center(child: Text('Bữa ăn không còn trong nhật ký.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.home_outlined),
          tooltip: 'Home',
        ),
        title: const Text('Kết quả phân tích'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            currentMeal.type.label,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Các món trong bữa: ${currentMeal.items.map((food) => food.name).join(', ')}',
            style: const TextStyle(color: Colors.black87),
          ),
          const SizedBox(height: 16),
          if (analysis == null)
            AppCard(
              child: Column(
                children: [
                  const Text(
                    'Chưa có kết quả phân tích AI cho bữa ăn này.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Bạn có thể đánh giá ngay dựa trên danh sách món đã chọn mà không cần tải ảnh.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  if (_evaluationError != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _evaluationError!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _evaluating
                        ? null
                        : () => _evaluateManually(currentMeal),
                    icon: _evaluating
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome_outlined),
                    label: Text(
                      _evaluating
                          ? 'Đang đánh giá...'
                          : 'Đánh giá dinh dưỡng bằng AI',
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _evaluating
                        ? null
                        : () => context.push('/analyze-meal'),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Chụp ảnh để phân tích'),
                  ),
                ],
              ),
            )
          else
            _AiAnalysisCard(result: analysis, meal: currentMeal),
        ],
      ),
    );
  }
}

class _AiAnalysisCard extends StatelessWidget {
  const _AiAnalysisCard({required this.result, required this.meal});

  final MealPhotoAnalysisResult result;
  final Meal meal;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome_outlined),
            const SizedBox(width: 8),
            Text(
              result.mode == MealPhotoAnalysisMode.demo
                  ? 'Đánh giá AI (Chế độ Demo)'
                  : 'Đánh giá từ AI LONGEVA',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        if (result.description.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(result.description),
        ],
        const SizedBox(height: 12),
        const Text(
          'Món ăn đã xác nhận trong bữa',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        ...meal.items.map(
          (food) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Text(food.emoji),
            title: Text(food.name),
          ),
        ),
        if (result.ingredients.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Thành phần quan sát được: ${result.ingredients.join(', ')}'),
        ],
        if (result.foodGroups.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Nhóm thực phẩm: ${result.foodGroups.join(', ')}'),
        ],
        if (result.foodVarietyExplanation.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Đa dạng thực phẩm: ${result.foodVarietyExplanation}'),
        ],
        if (result.strengths.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text(
            'Điểm tích cực',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          ...result.strengths.map((item) => Text('• $item')),
        ],
        if (result.improvements.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text(
            'Cần cải thiện',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          ...result.improvements.map((item) => Text('• $item')),
        ],
        if (result.criteriaResults.isNotEmpty) ...[
          const SizedBox(height: 14),
          const Text(
            'Đối chiếu nguyên tắc dinh dưỡng',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          ...result.criteriaResults.map(
            (item) => Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor(
                              item.status,
                              context,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.statusLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _statusColor(item.status, context),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (item.reason.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(item.reason),
                    ],
                    if (item.bookReferenceText != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        item.bookReferenceText!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 4),
                      Text(
                        item.sourceLabel,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: Colors.black54),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
        if (result.personalizedAdvice.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text(
            'Gợi ý cá nhân hóa',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          ...result.personalizedAdvice.map((item) => Text('• $item')),
        ],
        if (result.insufficientData.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Chưa đủ dữ liệu: ${result.insufficientData.join('; ')}'),
        ],
        if (result.unknownInformation.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Thông tin chưa thể xác định: '
            '${result.unknownInformation.join('; ')}',
          ),
        ],
      ],
    ),
  );
}

Color _statusColor(String status, BuildContext context) {
  return switch (status.toUpperCase()) {
    'MATCH' => Colors.green.shade700,
    'PARTIAL' => Colors.orange.shade800,
    'NOT_MATCH' => Colors.red.shade700,
    _ => Theme.of(context).colorScheme.outline,
  };
}
