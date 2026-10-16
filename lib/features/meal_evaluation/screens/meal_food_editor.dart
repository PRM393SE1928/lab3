import 'package:flutter/material.dart';

import '../../food_diary/models/food_item.dart';

/// Full-screen mobile editor. Cancellation never changes AppState.
class MealFoodEditor extends StatefulWidget {
  const MealFoodEditor({super.key, required this.items, required this.catalog});
  final List<FoodItem> items;
  final List<FoodItem> catalog;
  @override
  State<MealFoodEditor> createState() => _MealFoodEditorState();
}

class _MealFoodEditorState extends State<MealFoodEditor> {
  late final selected = widget.items.map((food) => food.id).toSet();
  late final foods = {
    for (final food in [...widget.catalog, ...widget.items]) food.id: food,
  };
  @override
  Widget build(BuildContext context) => Dialog.fullscreen(
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Điều chỉnh món ăn'),
        leading: IconButton(
          tooltip: 'Hủy',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Bỏ chọn món muốn thay và chọn món mới. Thay đổi chỉ được áp dụng khi đánh giá thành công.',
                  ),
                  const SizedBox(height: 12),
                  ...foods.values.map(
                    (food) => CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(food.name),
                      value: selected.contains(food.id),
                      onChanged: (value) => setState(() {
                        if (value == true) {
                          selected.add(food.id);
                        } else {
                          selected.remove(food.id);
                        }
                      }),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    onPressed: selected.isEmpty
                        ? null
                        : () => Navigator.pop(
                            context,
                            foods.values
                                .where((food) => selected.contains(food.id))
                                .toList(),
                          ),
                    child: const Text('Đánh giá lại'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Hủy'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
