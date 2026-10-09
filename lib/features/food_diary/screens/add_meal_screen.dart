import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_button.dart';
import '../../../shared/services/app_state.dart';
import '../models/meal.dart';

class AddMealScreen extends StatefulWidget {
  const AddMealScreen({super.key, this.meal});
  final Meal? meal;
  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  late MealType type;
  late List<dynamic> selected;
  @override
  void initState() {
    super.initState();
    type = widget.meal?.type ?? MealType.breakfast;
    selected = [...(widget.meal?.items ?? [])];
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.meal == null ? 'Thêm bữa ăn' : 'Sửa bữa ăn'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Bạn muốn ghi lại bữa nào?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: MealType.values
                .map(
                  (item) => ChoiceChip(
                    label: Text(item.label),
                    selected: type == item,
                    onSelected: (_) => setState(() => type = item),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 28),
          const Text(
            'Chọn món ăn',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ...state.foods.map((food) {
            final isSelected = selected.contains(food);
            return CheckboxListTile(
              value: isSelected,
              onChanged: (_) => setState(
                () => isSelected ? selected.remove(food) : selected.add(food),
              ),
              title: Text('${food.emoji} ${food.name}'),
              subtitle: Text(food.category),
              contentPadding: EdgeInsets.zero,
            );
          }),
          const SizedBox(height: 20),
          AppButton(
            label: widget.meal == null ? 'Lưu bữa ăn' : 'Cập nhật bữa ăn',
            icon: Icons.check,
            onPressed: selected.isEmpty
                ? null
                : () {
                    if (widget.meal == null) {
                      state.addMeal(type, selected.cast());
                    } else {
                      state.updateMeal(widget.meal!.id, type, selected.cast());
                    }
                    context.pop();
                  },
          ),
        ],
      ),
    );
  }
}
