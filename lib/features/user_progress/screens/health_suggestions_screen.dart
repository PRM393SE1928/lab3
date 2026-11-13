import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_card.dart';
import '../../../shared/services/app_state.dart';
import '../../food_diary/models/food_item.dart';
import '../../food_diary/models/meal.dart';
import '../services/ai_meal_recommendation_service.dart';
import '../services/health_profile_recommender.dart';

class HealthSuggestionsScreen extends StatefulWidget {
  const HealthSuggestionsScreen({super.key, this.service});
  final AiMealRecommendationService? service;

  @override
  State<HealthSuggestionsScreen> createState() =>
      _HealthSuggestionsScreenState();
}

class _HealthSuggestionsScreenState extends State<HealthSuggestionsScreen> {
  late final _service = widget.service ?? AiMealRecommendationService();
  MealType _type = MealType.breakfast;
  PersonalizedMealSuggestion? _suggestion;
  bool _loading = false;
  String? _error;
  int _request = 0;

  @override
  void dispose() {
    _request++;
    if (widget.service == null) _service.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    final state = context.read<AppState>();
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
      _suggestion = null;
    });
    try {
      final result = await _service.recommend(
        profile: state.healthProfile,
        foods: state.foods,
        mealType: _type,
      );
      if (!mounted || request != _request) return;
      setState(() {
        _suggestion = result;
        if (result == null) _error = 'Chưa có món phù hợp với hồ sơ trong danh mục này. Thử loại bữa khác.';
      });
    } on AiRecommendationException catch (error) {
      if (mounted && request == _request) {
        setState(() => _error = error.message);
      }
    } catch (_) {
      if (mounted && request == _request) {
        setState(
          () => _error = 'Không thể phân tích hồ sơ lúc này. Hãy thử lại.',
        );
      }
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final profile = state.healthProfile;
    final suggestion = _suggestion;
    return Scaffold(
      appBar: AppBar(title: const Text('Gợi ý từ hồ sơ sức khỏe')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hồ sơ dùng để phân tích',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  '${profile.age ?? "—"} tuổi · ${profile.weightKg ?? "—"} kg · ${profile.heightCm ?? "—"} cm',
                ),
                Text(
                  'Dị ứng: ${profile.allergies.isEmpty ? "Chưa khai báo" : profile.allergies.join(", ")}',
                ),
                Text(
                  'Không thích: ${profile.dislikedFoods.isEmpty ? "Chưa khai báo" : profile.dislikedFoods.join(", ")}',
                ),
                Text(
                  'Chế độ ăn: ${profile.dietaryPattern.isEmpty ? "Chưa khai báo" : profile.dietaryPattern}',
                ),
                TextButton(
                  onPressed: () => context.go('/profile'),
                  child: const Text('Chỉnh sửa hồ sơ'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'AI xem xét hồ sơ đã lưu và tiêu chí từ sách để đề xuất món trong danh mục. Gợi ý không thay thế tư vấn chuyên môn.',
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<MealType>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'Bữa ăn cần gợi ý'),
            items: MealType.values
                .map(
                  (type) =>
                      DropdownMenuItem(value: type, child: Text(type.label)),
                )
                .toList(),
            onChanged: _loading
                ? null
                : (value) => setState(() {
                    _type = value!;
                    _suggestion = null;
                    _error = null;
                  }),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _loading || state.isHydrating || !profile.isComplete
                ? null
                : _analyze,
            icon: const Icon(Icons.auto_awesome_outlined),
            label: Text(
              _loading ? 'Đang phân tích hồ sơ...' : 'Phân tích hồ sơ và gợi ý',
            ),
          ),
          if (!profile.isComplete)
            const Text(
              'Hãy lưu tuổi, cân nặng và chiều cao trong hồ sơ trước.',
            ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: LinearProgressIndicator(),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (suggestion != null) ...[
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nhận xét hồ sơ',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    suggestion.profileSummary.isEmpty
                        ? 'AI chưa cung cấp nhận xét tổng quan.'
                        : suggestion.profileSummary,
                  ),
                  ...suggestion.considerations.map((item) => Text('• $item')),
                  if (suggestion.missingData.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Thông tin và giới hạn cần lưu ý',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    ...suggestion.missingData.map((item) => Text('• $item')),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${suggestion.food.emoji} ${suggestion.food.name}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  ...suggestion.reasons.map((reason) => Text('• $reason')),
                  ...suggestion.principles.map(
                    (principle) => Text('• $principle'),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () => _plan(suggestion.food),
                    icon: const Icon(Icons.playlist_add),
                    label: const Text('Thêm vào kế hoạch hôm nay'),
                  ),
                ],
              ),
            ),
            if (suggestion.alternatives.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Món thay thế',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              ...suggestion.alternatives.map(
                (food) => ListTile(
                  title: Text(food.name),
                  leading: Text(food.emoji),
                  trailing: IconButton(
                    tooltip: 'Thêm vào kế hoạch',
                    icon: const Icon(Icons.add),
                    onPressed: () => _plan(food),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  void _plan(FoodItem food) {
    context.read<AppState>().addFoodsToMealPlan(_type, [
      food,
    ], date: DateTime.now());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã thêm ${food.name} vào kế hoạch hôm nay.')),
    );
  }
}
