import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_card.dart';
import '../../../shared/services/app_state.dart';
import '../models/meal_plan.dart';
import '../../food_diary/models/food_item.dart';
import '../../food_diary/models/meal.dart';
import '../../food_diary/widgets/food_picker_sheet.dart';
import '../widgets/meal_suggestion_sheet.dart';

class MealPlannerScreen extends StatefulWidget {
  const MealPlannerScreen({super.key});
  @override
  State<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends State<MealPlannerScreen> {
  late DateTime _week;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    _selected = DateTime.now();
    _week = _monday(_selected);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final days = List.generate(7, (i) => _week.add(Duration(days: i)));
    final plans = state.getPlansForDate(_selected);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lập kế hoạch bữa ăn'),
        actions: [
          IconButton(
            tooltip: 'Danh sách mua sắm',
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => context.push('/planner/shopping'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => _move(-7),
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                '${_week.day}/${_week.month} – ${days.last.day}/${days.last.month}/${days.last.year}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              IconButton(
                onPressed: () => _move(7),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          SizedBox(
            height: 78,
            child: Row(
              children: days.map((day) {
                final selected = _same(day, _selected);
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selected = day),
                    child: Container(
                      margin: const EdgeInsets.all(3),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Text(_short(day.weekday)),
                          const SizedBox(height: 5),
                          Text(
                            '${day.day}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ngày ${_selected.day}/${_selected.month}',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              TextButton.icon(
                onPressed: () =>
                    context.push('/planner/edit?date=${_iso(_selected)}'),
                icon: const Icon(Icons.add),
                label: const Text('Thêm'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SuggestionEntry(date: _selected),
          const SizedBox(height: 8),
          if (plans.isEmpty)
            AppCard(
              child: Column(
                children: [
                  const Icon(Icons.event_note_outlined, size: 42),
                  const SizedBox(height: 8),
                  const Text('Chưa có kế hoạch cho ngày này.'),
                ],
              ),
            )
          else
            ...plans.map(
              (plan) => Card(
                child: ListTile(
                  leading: Text(
                    _emoji(plan.type),
                    style: const TextStyle(fontSize: 26),
                  ),
                  title: Text(plan.type.label),
                  subtitle: Text(
                    '${plan.items.map((i) => i.name).join(', ')}\n${plan.status == MealPlanStatus.completed ? 'Đã thực hiện' : 'Đã lên kế hoạch'}',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/planner/detail/${plan.id}'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _move(int days) => setState(() {
    _week = _week.add(Duration(days: days));
    _selected = _week;
  });
}

class _SuggestionEntry extends StatelessWidget {
  const _SuggestionEntry({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.auto_awesome_outlined),
            title: Text(
              'Gợi ý món ăn',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text('Chọn món theo loại bữa rồi thêm vào kế hoạch.'),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: MealType.values.map((type) {
              final food = state.suggestedFoodFor(type, date);
              return ActionChip(
                avatar: Text(_emoji(type)),
                label: Text(
                  food == null ? '${type.label}: Chưa có món' : food.name,
                  overflow: TextOverflow.ellipsis,
                ),
                onPressed: food == null
                    ? null
                    : () => _addSuggestion(context, type, food),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _addSuggestion(BuildContext context, MealType type, FoodItem food) {
    try {
      final selection = MealSuggestionSelection(type: type, foods: [food]);
      context.read<AppState>().addFoodsToMealPlan(type, [food], date: date);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${selection.foods.length} món đã thêm vào kế hoạch.'),
        ),
      );
    } on ArgumentError catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể thêm món: ${error.message}')),
      );
    }
  }
}

class MealPlanEditorScreen extends StatefulWidget {
  const MealPlanEditorScreen({super.key, this.plan, this.date});
  final MealPlan? plan;
  final DateTime? date;
  @override
  State<MealPlanEditorScreen> createState() => _MealPlanEditorScreenState();
}

class _MealPlanEditorScreenState extends State<MealPlanEditorScreen> {
  MealType? _type;
  late DateTime _date;
  late List<dynamic> _selected;
  final _note = TextEditingController();
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    _type = widget.plan?.type;
    _date = widget.plan?.date ?? widget.date ?? DateTime.now();
    _selected = [...(widget.plan?.items ?? const [])];
    _note.text = widget.plan?.note ?? '';
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.plan == null ? 'Tạo kế hoạch' : 'Sửa kế hoạch'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Loại bữa ăn', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: MealType.values
                .map(
                  (t) => ChoiceChip(
                    label: Text(t.label),
                    selected: _type == t,
                    onSelected: (_) => setState(() => _type = t),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today),
            label: Text('${_date.day}/${_date.month}/${_date.year}'),
          ),
          const SizedBox(height: 18),
          Text('Thực phẩm', style: Theme.of(context).textTheme.titleMedium),
          ..._selected.map(
            (food) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(food.name),
              trailing: IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () => setState(() => _selected.remove(food)),
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () async {
              final result = await showFoodPicker(
                context,
                catalog: state.foods,
                initialSelection: _selected.cast(),
              );
              if (result != null && mounted) {
                setState(() => _selected = result);
              }
            },
            icon: const Icon(Icons.restaurant_menu),
            label: const Text('Chọn thực phẩm'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Ghi chú (tùy chọn)'),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Đang lưu...' : 'Lưu kế hoạch'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: _date,
    );
    if (picked != null) {
      setState(
        () => _date = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _date.hour,
          _date.minute,
        ),
      );
    }
  }

  void _save() {
    if (_type == null || _selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chọn loại bữa và ít nhất một thực phẩm.'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    final state = context.read<AppState>();
    if (widget.plan == null) {
      state.addMealPlan(
        _type!,
        _selected.cast(),
        date: _date,
        note: _note.text,
      );
    } else {
      state.updateMealPlan(
        widget.plan!.id,
        _type!,
        _selected.cast(),
        date: _date,
        note: _note.text,
      );
    }
    if (mounted) context.pop();
  }
}

class MealPlanDetailScreen extends StatelessWidget {
  const MealPlanDetailScreen({super.key, required this.planId});
  final String planId;
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final plan = state.getMealPlanById(planId);
    if (plan == null) {
      return const Scaffold(
        body: Center(child: Text('Kế hoạch không còn tồn tại.')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết kế hoạch'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: plan.status == MealPlanStatus.completed
                ? null
                : () => context.push('/planner/edit?planId=${plan.id}'),
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'delete') {
                final ok = await _confirm(context);
                if (ok && context.mounted) {
                  state.deleteMealPlan(plan.id);
                  context.pop();
                }
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'delete', child: Text('Xóa kế hoạch')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            plan.type.label,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text('${plan.date.day}/${plan.date.month}/${plan.date.year}'),
          const SizedBox(height: 18),
          Text(
            plan.status == MealPlanStatus.completed
                ? 'Đã thực hiện'
                : 'Đã lên kế hoạch',
          ),
          const Divider(),
          ...plan.items.map(
            (f) => ListTile(
              leading: Text(f.emoji),
              title: Text(f.name),
              subtitle: Text(f.categoryLabel),
            ),
          ),
          if (plan.note != null) Text('Ghi chú: ${plan.note}'),
          const SizedBox(height: 20),
          if (plan.status == MealPlanStatus.planned)
            FilledButton.icon(
              onPressed: () => _complete(context, plan),
              icon: const Icon(Icons.check),
              label: const Text('Đánh dấu đã thực hiện'),
            )
          else
            OutlinedButton.icon(
              onPressed: plan.actualMealId == null
                  ? null
                  : () => context.push('/meal/${plan.actualMealId}'),
              icon: const Icon(Icons.restaurant),
              label: const Text('Mở bữa ăn thực tế'),
            ),
        ],
      ),
    );
  }

  Future<void> _complete(BuildContext context, MealPlan plan) async {
    final state = context.read<AppState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Lưu vào nhật ký?'),
        content: const Text('Thao tác này tạo bữa ăn thực tế từ kế hoạch.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      final meal = state.completeMealPlan(plan.id);
      if (meal != null) context.push('/meal-result', extra: meal);
    }
  }

  Future<bool> _confirm(BuildContext context) async =>
      await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Xóa kế hoạch?'),
          content: const Text('Không thể hoàn tác.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Xóa'),
            ),
          ],
        ),
      ) ??
      false;
}

class ShoppingListScreen extends StatelessWidget {
  const ShoppingListScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final items = state.shoppingItems;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách mua sắm'),
        actions: [
          IconButton(
            tooltip: 'Tạo từ các kế hoạch',
            icon: const Icon(Icons.refresh),
            onPressed: () => state.buildShoppingList(state.mealPlans),
          ),
        ],
      ),
      body: items.isEmpty
          ? const Center(child: Text('Chưa tạo danh sách mua sắm.'))
          : ListView(
              children: items
                  .map(
                    (item) => Dismissible(
                      key: ValueKey(item.key),
                      onDismissed: (_) => state.removeShoppingItem(item),
                      child: CheckboxListTile(
                        value: item.purchased,
                        onChanged: (value) => state.setShoppingItemPurchased(
                          item,
                          value ?? false,
                        ),
                        title: Text(item.name),
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

DateTime _monday(DateTime d) {
  final day = DateTime(d.year, d.month, d.day);
  return day.subtract(Duration(days: day.weekday - 1));
}

bool _same(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
String _iso(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
String _short(int day) =>
    const ['', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'][day];
String _emoji(MealType type) => const {
  MealType.breakfast: '☀️',
  MealType.lunch: '🥗',
  MealType.dinner: '🍲',
  MealType.snack: '🍎',
}[type]!;
