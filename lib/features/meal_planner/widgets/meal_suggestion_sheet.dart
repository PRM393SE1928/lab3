import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../food_diary/models/food_item.dart';
import '../../food_diary/models/meal.dart';
import '../../../shared/services/app_state.dart';

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
    builder: (_) => MealSuggestionSheet(date: date, initialType: initialType),
  );
}

class MealSuggestionSheet extends StatefulWidget {
  const MealSuggestionSheet({super.key, required this.date, this.initialType});

  final DateTime date;
  final MealType? initialType;

  @override
  State<MealSuggestionSheet> createState() => _MealSuggestionSheetState();
}

class _MealSuggestionSheetState extends State<MealSuggestionSheet> {
  MealType? _type;
  String _query = '';
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final foods = _type == null
        ? const <FoodItem>[]
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
      initialChildSize: 0.82,
      minChildSize: 0.55,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Gợi ý món ăn',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                FilledButton(
                  onPressed: selectedFoods.isEmpty || _type == null
                      ? null
                      : () => Navigator.pop(
                          context,
                          MealSuggestionSelection(
                            type: _type!,
                            foods: selectedFoods,
                          ),
                        ),
                  child: Text('Thêm vào kế hoạch (${selectedFoods.length})'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Ngày ${widget.date.day}/${widget.date.month}/${widget.date.year}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          SizedBox(
            height: 58,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
              scrollDirection: Axis.horizontal,
              itemCount: MealType.values.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                final type = MealType.values[index];
                return ChoiceChip(
                  label: Text(type.label),
                  selected: _type == type,
                  onSelected: (_) => setState(() {
                    _type = type;
                    _query = '';
                    _selectedIds.clear();
                  }),
                );
              },
            ),
          ),
          if (_type != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Tìm món ăn',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
          Expanded(
            child: _type == null
                ? const Center(child: Text('Hãy chọn loại bữa để xem gợi ý.'))
                : foods.isEmpty
                ? Center(
                    child: Text(
                      _query.trim().isEmpty
                          ? 'Chưa có món gợi ý cho loại bữa này.'
                          : 'Không tìm thấy món phù hợp.',
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    itemCount: foods.length,
                    itemBuilder: (_, index) {
                      final food = foods[index];
                      final selected = _selectedIds.contains(food.id);
                      return Card(
                        child: ListTile(
                          onTap: () => setState(() {
                            if (selected) {
                              _selectedIds.remove(food.id);
                            } else {
                              _selectedIds.add(food.id);
                            }
                          }),
                          leading: CircleAvatar(child: Text(food.emoji)),
                          title: Text(food.name),
                          subtitle: Text(
                            food.description.isEmpty
                                ? food.categoryLabel
                                : '${food.categoryLabel} • ${food.description}',
                          ),
                          trailing: Icon(
                            selected
                                ? Icons.check_circle
                                : Icons.add_circle_outline,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _categoryFor(MealType type) => switch (type) {
    MealType.breakfast => 'breakfast',
    MealType.lunch => 'lunch',
    MealType.dinner => 'dinner',
    MealType.snack => 'snack',
  };
}
