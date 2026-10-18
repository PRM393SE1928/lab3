import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../shared/services/app_state.dart';
import '../models/food_item.dart';
import '../models/meal.dart';
import '../widgets/food_picker_sheet.dart';

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
          OutlinedButton.icon(
            onPressed: widget.meal == null
                ? () => context.push('/analyze-meal')
                : null,
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Phân tích từ ảnh (Demo)'),
          ),
          const SizedBox(height: 16),
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
          _SelectedMealsSection(
            selected: selected,
            onRemove: (food) => setState(() => selected.remove(food)),
            onChoose: () async {
              final result = await showFoodPicker(
                context,
                catalog: state.foods,
                initialSelection: selected,
              );
              if (result != null && mounted) {
                setState(() => selected = result);
              }
            },
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
}

class _SelectedMealsSection extends StatelessWidget {
  const _SelectedMealsSection({
    required this.selected,
    required this.onRemove,
    required this.onChoose,
  });

  final List<FoodItem> selected;
  final ValueChanged<FoodItem> onRemove;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Expanded(
            child: Text(
              'Món ăn',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            '${selected.length} món',
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ],
      ),
      const SizedBox(height: 8),
      if (selected.isEmpty)
        const Text('Chưa chọn món nào. Hãy chọn một hoặc nhiều món.')
      else
        ...selected.map(
          (food) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Text(food.emoji),
            title: Text(food.name),
            subtitle: Text(
              food.sourceType == 'user_entered'
                  ? 'Món nhập thủ công'
                  : food.categoryLabel,
            ),
            trailing: IconButton(
              tooltip: 'Xóa ${food.name}',
              onPressed: () => onRemove(food),
              icon: const Icon(Icons.remove_circle_outline),
            ),
          ),
        ),
      OutlinedButton.icon(
        onPressed: onChoose,
        icon: const Icon(Icons.restaurant_menu_outlined),
        label: Text(selected.isEmpty ? 'Chọn món ăn' : 'Chỉnh sửa món đã chọn'),
      ),
    ],
  );
}
