import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_card.dart';
import '../../../shared/services/app_state.dart';
import '../models/meal.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final meals = state.getMealsForDate(selectedDate);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Nhật ký ăn uống',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Chọn ngày',
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_month_outlined),
          ),
          IconButton(
            tooltip: 'Thêm bữa ăn',
            onPressed: () => context.push('/add-meal'),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          AppCard(
            child: Row(
              children: [
                const Icon(Icons.event_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _dateLabel(selectedDate),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton(onPressed: _pickDate, child: const Text('Đổi ngày')),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (meals.isEmpty)
            AppCard(
              child: Column(
                children: [
                  const Text(
                    'Chưa có bữa ăn nào trong ngày này.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/add-meal'),
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm bữa ăn'),
                  ),
                ],
              ),
            )
          else
            ...meals.map(
              (meal) => _DiaryMealTile(
                meal: meal,
                compact: state.compactDiaryEnabled,
                onDelete: () => _deleteMeal(meal),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-meal'),
        icon: const Icon(Icons.add),
        label: const Text('Thêm bữa ăn'),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: selectedDate,
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  Future<void> _deleteMeal(Meal meal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa bữa ăn?'),
        content: const Text('Bữa ăn sẽ bị xóa khỏi nhật ký.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.read<AppState>().deleteMeal(meal.id);
    }
  }
}

class _DiaryMealTile extends StatelessWidget {
  const _DiaryMealTile({
    required this.meal,
    required this.compact,
    required this.onDelete,
  });
  final Meal meal;
  final bool compact;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      title: Text(
        meal.type.label,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        '${_timeLabel(meal.date)} • ${meal.items.map((item) => item.name).join(', ')}',
        maxLines: compact ? 1 : 2,
        overflow: TextOverflow.ellipsis,
      ),
      dense: compact,
      trailing: PopupMenuButton<String>(
        tooltip: 'Thao tác',
        onSelected: (value) {
          if (value == 'edit') {
            context.push('/add-meal?mealId=${meal.id}');
          }
          if (value == 'delete') {
            onDelete();
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'edit', child: Text('Sửa bữa ăn')),
          PopupMenuItem(value: 'delete', child: Text('Xóa bữa ăn')),
        ],
      ),
      onTap: () => context.push('/meal/${meal.id}'),
    ),
  );
}

String _dateLabel(DateTime date) => '${date.day}/${date.month}/${date.year}';
String _timeLabel(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
