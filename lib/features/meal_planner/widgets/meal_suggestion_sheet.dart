import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../shared/services/app_state.dart';
import '../../food_diary/models/food_item.dart';
import '../../food_diary/models/meal.dart';
import '../../user_progress/services/health_profile_recommender.dart';
import '../../user_progress/services/ai_meal_recommendation_service.dart';

class MealSuggestionSelection {
  const MealSuggestionSelection({required this.type, required this.foods});

  final MealType type;
  final List<FoodItem> foods;
}

Future<MealSuggestionSelection?> showMealSuggestionSheet(
  BuildContext context, {
  required DateTime date,
  MealType? initialType,
}) {
  return showModalBottomSheet<MealSuggestionSelection>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => MealSuggestionSheet(date: date, initialType: initialType),
  );
}

class MealSuggestionSheet extends StatefulWidget {
  const MealSuggestionSheet({
    super.key,
    required this.date,
    this.initialType,
    this.initialAgeGroup,
  });

  final DateTime date;
  final MealType? initialType;
  final AgeGroup? initialAgeGroup;

  @override
  State<MealSuggestionSheet> createState() => _MealSuggestionSheetState();
}

class _MealSuggestionSheetState extends State<MealSuggestionSheet> {
  MealType? _type;
  late AgeGroup _ageGroup;
  String _query = '';
  final Set<String> _selectedIds = {};
  PersonalizedMealSuggestion? _remoteSuggestion;
  String? _remoteError;
  bool _remoteLoading = false;
  int _requestId = 0;
  late final _recommendations = AiMealRecommendationService();

  @override
  void dispose() {
    _requestId++;
    _recommendations.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _type = widget.initialType ?? MealType.breakfast;
    _ageGroup =
        widget.initialAgeGroup ??
        context.read<AppState>().healthProfile.ageGroup ??
        AgeGroup.age18To59;
    _loadRemoteSuggestion();
  }

  Future<void> _loadRemoteSuggestion() async {
    final requestId = ++_requestId;
    final state = context.read<AppState>();
    final type = _type;
    if (type == null) return;
    setState(() {
      _remoteLoading = true;
      _remoteSuggestion = null;
      _remoteError = null;
    });
    try {
      final suggestion = await _recommendations.recommend(
        profile: state.healthProfile,
        foods: state.foods,
        mealType: type,
        targetAgeGroup: _ageGroup,
      );
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _remoteSuggestion = suggestion;
        _remoteLoading = false;
      });
    } on AiRecommendationException catch (error) {
      if (mounted && requestId == _requestId) {
        setState(() {
          _remoteError = error.message;
          _remoteLoading = false;
        });
      }
    } catch (_) {
      if (mounted && requestId == _requestId) {
        setState(() {
          _remoteError = 'Không thể tải gợi ý AI lúc này.';
          _remoteLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final localPersonalized = _type == null
        ? null
        : const HealthProfileRecommender().recommend(
            profile: state.healthProfile,
            foods: state.foods,
            mealType: _type!,
            targetAgeGroup: _ageGroup,
          );
    final personalized =
        _remoteSuggestion ??
        (_remoteError == null && !_remoteLoading ? localPersonalized : null);
    final ageMatchedFoods = _type == null
        ? const <FoodItem>[]
        : filterFoodItems(
            state.foods,
            category: _categoryFor(_type!),
            ageGroup: _ageGroup,
          );
    final hasAgeSpecificSuggestions = ageMatchedFoods.isNotEmpty;
    final foods = _type == null
        ? const <FoodItem>[]
        : hasAgeSpecificSuggestions
        ? filterFoodItems(ageMatchedFoods, query: _query)
        : filterFoodItems(
            state.foods,
            category: _categoryFor(_type!),
            query: _query,
          );
    final selectedFoods = state.foods
        .where((food) => _selectedIds.contains(food.id))
        .toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.86,
      minChildSize: 0.62,
      maxChildSize: 0.96,
      builder: (context, scrollController) => Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          _buildHeader(context),
          if (_type != null && !hasAgeSpecificSuggestions)
            _buildGeneralCatalogWarning(context),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              children: [
                _buildDate(context),
                _buildAgeSelector(context),
                if (!state.healthProfile.isComplete)
                  _buildProfilePrompt(context)
                else if (personalized != null)
                  _buildPersonalizedSuggestion(context, personalized),
                if (_remoteLoading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: LinearProgressIndicator(),
                  ),
                if (_remoteError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _remoteError!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _loadRemoteSuggestion,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                _buildMealTypeSelector(),
                if (_type != null) _buildSearchField(),
                if (_type == null)
                  const Center(child: Text('Hãy chọn loại bữa để xem món.'))
                else if (foods.isEmpty)
                  Center(
                    child: Text(
                      _query.trim().isEmpty
                          ? 'Chưa có món trong danh mục này.'
                          : 'Không tìm thấy món phù hợp.',
                    ),
                  )
                else
                  ...foods.map(
                    (food) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildFoodTile(food),
                    ),
                  ),
              ],
            ),
          ),
          _buildBottomActions(context, selectedFoods),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 14, 12, 4),
    child: Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gợi ý món ăn',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 3),
              Text('Chọn món rồi xác nhận để thêm vào kế hoạch.'),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Đóng',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
      ],
    ),
  );

  Widget _buildDate(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Ngày ${widget.date.day}/${widget.date.month}/${widget.date.year}',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
  );

  Widget _buildAgeSelector(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 4, 20, 2),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<AgeGroup>(
          key: const ValueKey('meal-suggestion-age-group'),
          initialValue: _ageGroup,
          decoration: const InputDecoration(
            labelText: 'Gợi ý theo độ tuổi',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.family_restroom_outlined),
          ),
          items: AgeGroup.values
              .map(
                (group) => DropdownMenuItem(
                  key: ValueKey('age-option-${group.name}'),
                  value: group,
                  child: Text(group.label),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _ageGroup = value;
              _selectedIds.clear();
              _remoteSuggestion = null;
              _remoteError = null;
            });
            _loadRemoteSuggestion();
          },
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${_ageGroup.label}. ${_ageGroup.guidance}',
            key: const ValueKey('meal-suggestion-age-guidance'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    ),
  );

  Widget _buildMealTypeSelector() => SizedBox(
    height: 62,
    child: ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
      scrollDirection: Axis.horizontal,
      itemCount: MealType.values.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (_, index) {
        final type = MealType.values[index];
        return ChoiceChip(
          avatar: Icon(_iconFor(type), size: 18),
          label: Text(type.label),
          selected: _type == type,
          onSelected: (_) {
            setState(() {
              _type = type;
              _query = '';
              _selectedIds.clear();
              _remoteSuggestion = null;
              _remoteError = null;
            });
            _loadRemoteSuggestion();
          },
        );
      },
    ),
  );

  Widget _buildProfilePrompt(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
    child: Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: ListTile(
        leading: const Icon(Icons.person_outline),
        title: const Text('Hoàn thiện hồ sơ để cá nhân hóa'),
        subtitle: const Text(
          'Bạn vẫn có thể dùng gợi ý chung theo danh mục và độ tuổi.',
        ),
        trailing: TextButton(
          onPressed: () => context.push('/profile'),
          child: const Text('Mở hồ sơ'),
        ),
      ),
    ),
  );

  Widget _buildPersonalizedSuggestion(
    BuildContext context,
    PersonalizedMealSuggestion suggestion,
  ) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
    child: Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'GỢI Ý DÀNH RIÊNG CHO BẠN',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(child: Text(suggestion.food.emoji)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    suggestion.food.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Lý do phù hợp',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            ...suggestion.reasons.map((item) => _bullet(item)),
            const SizedBox(height: 6),
            const Text(
              'Định hướng dinh dưỡng áp dụng',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            ...suggestion.principles.map((item) => _bullet(item)),
            if (suggestion.alternatives.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Gợi ý thay thế: ${suggestion.alternatives.map((item) => item.name).join(', ')}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    ),
  );

  Widget _bullet(String text) => Padding(
    padding: const EdgeInsets.only(top: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• '),
        Expanded(child: Text(text)),
      ],
    ),
  );

  Widget _buildSearchField() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 2, 20, 6),
    child: TextField(
      decoration: InputDecoration(
        hintText: 'Tìm món ăn',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _query.isEmpty
            ? null
            : IconButton(
                tooltip: 'Xóa tìm kiếm',
                onPressed: () => setState(() => _query = ''),
                icon: const Icon(Icons.clear),
              ),
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: (value) => setState(() => _query = value),
    ),
  );

  Widget _buildGeneralCatalogWarning(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
    child: Text(
      'Danh mục chung — chưa được kiểm chứng theo độ tuổi; không phải gợi ý phù hợp tuổi.',
      key: const ValueKey('meal-suggestion-general-catalog-warning'),
      style: Theme.of(context).textTheme.bodySmall
          ?.copyWith(color: Theme.of(context).colorScheme.error),
    ),
  );

  Widget _buildFoodTile(FoodItem food) {
    final selected = _selectedIds.contains(food.id);
    return Card(
      margin: EdgeInsets.zero,
      child: CheckboxListTile(
        value: selected,
        onChanged: (_) => setState(() {
          if (selected) {
            _selectedIds.remove(food.id);
          } else {
            _selectedIds.add(food.id);
          }
        }),
        secondary: CircleAvatar(child: Text(food.emoji)),
        title: Text(food.name),
        subtitle: Text(
          food.description.isEmpty
              ? food.categoryLabel
              : '${food.categoryLabel} • ${food.description}',
        ),
        controlAffinity: ListTileControlAffinity.trailing,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }

  // Kept as a small compatibility helper for callers from older feature code.
  // ignore: unused_element
  Widget _buildFoodList(
    BuildContext context,
    List<FoodItem> foods,
    ScrollController scrollController,
  ) {
    if (_type == null) {
      return const Center(child: Text('Hãy chọn loại bữa để xem món.'));
    }
    if (foods.isEmpty) {
      return Center(
        child: Text(
          _query.trim().isEmpty
              ? 'Chưa có món trong danh mục này.'
              : 'Không tìm thấy món phù hợp.',
        ),
      );
    }
    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 20),
      itemCount: foods.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, index) {
        final food = foods[index];
        final selected = _selectedIds.contains(food.id);
        return Card(
          margin: EdgeInsets.zero,
          child: CheckboxListTile(
            value: selected,
            onChanged: (_) => setState(() {
              if (selected) {
                _selectedIds.remove(food.id);
              } else {
                _selectedIds.add(food.id);
              }
            }),
            secondary: CircleAvatar(child: Text(food.emoji)),
            title: Text(food.name),
            subtitle: Text(
              food.description.isEmpty
                  ? food.categoryLabel
                  : '${food.categoryLabel} • ${food.description}',
            ),
            controlAffinity: ListTileControlAffinity.trailing,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        );
      },
    );
  }

  Widget _buildBottomActions(
    BuildContext context,
    List<FoodItem> selectedFoods,
  ) => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: selectedFoods.isEmpty || _type == null
                  ? null
                  : () => Navigator.pop(
                      context,
                      MealSuggestionSelection(
                        type: _type!,
                        foods: selectedFoods,
                      ),
                    ),
              icon: const Icon(Icons.playlist_add),
              label: Text('Thêm (${selectedFoods.length})'),
            ),
          ),
        ],
      ),
    ),
  );

  String _categoryFor(MealType type) => switch (type) {
    MealType.breakfast => 'breakfast',
    MealType.lunch => 'lunch',
    MealType.dinner => 'dinner',
    MealType.snack => 'snack',
  };

  IconData _iconFor(MealType type) => switch (type) {
    MealType.breakfast => Icons.wb_sunny_outlined,
    MealType.lunch => Icons.lunch_dining_outlined,
    MealType.dinner => Icons.dinner_dining_outlined,
    MealType.snack => Icons.apple,
  };
}
