import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../shared/services/app_state.dart';
import '../models/food_item.dart';
import '../models/meal.dart';

class AddMealScreen extends StatefulWidget {
  const AddMealScreen({super.key, this.meal});
  final Meal? meal;

  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  MealType? type;
  late List<FoodItem> selected;
  late DateTime date;
  late final TextEditingController noteController;
  String query = '';
  String? errorMessage;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    type = widget.meal?.type;
    selected = [...(widget.meal?.items ?? <FoodItem>[])];
    date = widget.meal?.date ?? DateTime.now();
    noteController = TextEditingController(text: widget.meal?.note ?? '');
  }

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final selectedCategory = _categoryFor(type);
    final categoryFoods = filterFoodItems(
      state.foods,
      category: selectedCategory,
    );
    final foods = filterFoodItems(categoryFoods, query: query);
    final emptyMessage =
        categoryFoods.isEmpty &&
            selectedCategory != null &&
            query.trim().isEmpty
        ? 'Chưa có món ăn trong danh mục này'
        : 'Không tìm thấy món ăn phù hợp';
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.meal == null ? 'Thêm bữa ăn' : 'Sửa bữa ăn'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const Text(
            'Loại bữa ăn',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
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
          const SizedBox(height: 24),
          const Text(
            'Ngày và thời gian',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text('${date.day}/${date.month}/${date.year}'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.schedule_outlined),
                  label: Text(
                    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Món ăn',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(
              hintText: 'Tìm món ăn',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) => setState(() => query = value),
          ),
          const SizedBox(height: 8),
          if (foods.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(emptyMessage, textAlign: TextAlign.center),
            )
          else
            ...foods.map(
              (food) => CheckboxListTile(
                value: selected.any((item) => item.id == food.id),
                onChanged: (_) => _toggleFood(food),
                title: Text('${food.emoji} ${food.name}'),
                subtitle: Text(food.categoryLabel),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          const SizedBox(height: 16),
          TextField(
            controller: noteController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Ghi chú (tùy chọn)',
              alignLabelWithHint: true,
            ),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: saving ? null : _save,
            icon: saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(widget.meal == null ? 'Lưu bữa ăn' : 'Cập nhật bữa ăn'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleFood(FoodItem food) {
    setState(() {
      final index = selected.indexWhere((item) => item.id == food.id);
      if (index >= 0) {
        selected.removeAt(index);
      } else {
        selected.add(food);
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: date,
    );
    if (picked != null) {
      setState(
        () => date = DateTime(
          picked.year,
          picked.month,
          picked.day,
          date.hour,
          date.minute,
        ),
      );
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(date),
    );
    if (picked != null) {
      setState(
        () => date = DateTime(
          date.year,
          date.month,
          date.day,
          picked.hour,
          picked.minute,
        ),
      );
    }
  }

  void _save() {
    if (type == null) {
      setState(() => errorMessage = 'Vui lòng chọn loại bữa ăn.');
      return;
    }
    if (selected.isEmpty) {
      setState(() => errorMessage = 'Vui lòng chọn ít nhất một món ăn.');
      return;
    }
    setState(() {
      saving = true;
      errorMessage = null;
    });
    final state = context.read<AppState>();
    try {
      if (widget.meal == null) {
        state.addMeal(type!, selected, date: date, note: noteController.text);
      } else if (!state.updateMeal(
        widget.meal!.id,
        type!,
        selected,
        date: date,
        note: noteController.text,
      )) {
        throw StateError('Bữa ăn không còn tồn tại.');
      }
      if (mounted) context.pop();
    } on ArgumentError catch (error) {
      setState(() {
        saving = false;
        errorMessage =
            error.message?.toString() ?? 'Dữ liệu bữa ăn chưa hợp lệ.';
      });
    } on StateError catch (error) {
      setState(() {
        saving = false;
        errorMessage = error.message;
      });
    }
  }

  String? _categoryFor(MealType? value) => switch (value) {
    MealType.breakfast => 'breakfast',
    MealType.lunch => 'lunch',
    MealType.dinner => 'dinner',
    MealType.snack => 'snack',
    null => null,
  };
}
