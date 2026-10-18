import 'package:flutter/material.dart';

import '../models/food_item.dart';

Future<List<FoodItem>?> showFoodPicker(
  BuildContext context, {
  required List<FoodItem> catalog,
  required List<FoodItem> initialSelection,
}) {
  return showModalBottomSheet<List<FoodItem>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) =>
        FoodPickerSheet(catalog: catalog, initialSelection: initialSelection),
  );
}

class FoodPickerSheet extends StatefulWidget {
  const FoodPickerSheet({
    super.key,
    required this.catalog,
    required this.initialSelection,
  });

  final List<FoodItem> catalog;
  final List<FoodItem> initialSelection;

  @override
  State<FoodPickerSheet> createState() => _FoodPickerSheetState();
}

class _FoodPickerSheetState extends State<FoodPickerSheet> {
  late final TextEditingController _searchController;
  late List<FoodItem> _selected;
  String _query = '';
  String? _category;

  List<String> get _categories => [
    'Tất cả',
    ...widget.catalog.map((food) => food.category).toSet(),
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _selected = _uniqueFoods(widget.initialSelection);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = filterFoodItems(
      widget.catalog,
      category: _category,
      query: _query,
    );
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.88,
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
                  Expanded(
                    child: Text(
                      'Chọn món ăn',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Hủy'),
                  ),
                  FilledButton(
                    onPressed: _selected.isEmpty
                        ? null
                        : () => Navigator.pop(context, _selected),
                    child: Text('Xong (${_selected.length})'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Tìm theo tên món',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Xóa tìm kiếm',
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.clear),
                        ),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            SizedBox(
              height: 52,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final selected = category == 'Tất cả'
                      ? _category == null
                      : _category == category;
                  return ChoiceChip(
                    key: ValueKey('food-category-$category'),
                    label: Text(
                      category == 'Tất cả'
                          ? category
                          : _categoryLabel(category),
                    ),
                    selected: selected,
                    onSelected: (_) => setState(
                      () => _category = category == 'Tất cả' ? null : category,
                    ),
                  );
                },
              ),
            ),
            if (_selected.isNotEmpty)
              _SelectedFoods(foods: _selected, onRemove: _removeFood),
            if (_query.trim().isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _addManualFood,
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm món đang nhập thủ công'),
                ),
              ),
            Expanded(
              child: filtered.isEmpty
                  ? _EmptyResults(query: _query, onAddManual: _addManualFood)
                  : ListView.builder(
                      controller: scrollController,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final food = filtered[index];
                        final isSelected = _containsFood(food);
                        return _FoodTile(
                          food: food,
                          selected: isSelected,
                          onTap: () => _toggleFood(food),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleFood(FoodItem food) {
    setState(() {
      if (_containsFood(food)) {
        _selected.removeWhere((item) => item.id == food.id);
      } else {
        _selected.add(food);
      }
    });
  }

  void _removeFood(FoodItem food) {
    setState(() => _selected.removeWhere((item) => item.id == food.id));
  }

  void _addManualFood() {
    final name = _searchController.text.trim();
    if (name.isEmpty) return;
    final normalized = normalizeFoodText(name);
    final existing = _selected.where(
      (food) => normalizeFoodText(food.name) == normalized,
    );
    if (existing.isEmpty) {
      setState(() {
        _selected.add(
          FoodItem(
            id: 'custom_$normalized',
            name: name,
            category: 'custom',
            sourceType: 'user_entered',
          ),
        );
      });
    }
  }

  bool _containsFood(FoodItem food) =>
      _selected.any((item) => item.id == food.id);

  List<FoodItem> _uniqueFoods(Iterable<FoodItem> foods) {
    final byId = <String, FoodItem>{};
    for (final food in foods) {
      byId[food.id] = food;
    }
    return byId.values.toList();
  }

  String _categoryLabel(String category) => switch (category) {
    'breakfast' => 'Bữa sáng',
    'lunch' => 'Bữa trưa',
    'dinner' => 'Bữa tối',
    'snack' => 'Bữa phụ',
    _ => category,
  };
}

class _SelectedFoods extends StatelessWidget {
  const _SelectedFoods({required this.foods, required this.onRemove});

  final List<FoodItem> foods;
  final ValueChanged<FoodItem> onRemove;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      scrollDirection: Axis.horizontal,
      itemCount: foods.length,
      separatorBuilder: (_, _) => const SizedBox(width: 6),
      itemBuilder: (_, index) {
        final food = foods[index];
        return InputChip(
          avatar: Text(food.emoji),
          label: Text(food.name, overflow: TextOverflow.ellipsis),
          deleteButtonTooltipMessage: 'Bỏ chọn ${food.name}',
          onDeleted: () => onRemove(food),
        );
      },
    ),
  );
}

class _FoodTile extends StatelessWidget {
  const _FoodTile({
    required this.food,
    required this.selected,
    required this.onTap,
  });

  final FoodItem food;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    key: ValueKey('food-item-${food.id}'),
    margin: const EdgeInsets.only(top: 6),
    child: ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        child: Text(food.emoji),
      ),
      title: Text(food.name, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(food.categoryLabel),
      trailing: Icon(
        selected ? Icons.check_circle : Icons.add_circle_outline,
        color: selected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.outline,
      ),
    ),
  );
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({required this.query, required this.onAddManual});

  final String query;
  final VoidCallback onAddManual;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_outlined, size: 42),
          const SizedBox(height: 8),
          Text(
            query.trim().isEmpty
                ? 'Chưa có món trong danh mục này'
                : 'Không tìm thấy món phù hợp',
            textAlign: TextAlign.center,
          ),
          if (query.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onAddManual,
              icon: const Icon(Icons.add),
              label: const Text('Thêm món thủ công'),
            ),
          ],
        ],
      ),
    ),
  );
}
