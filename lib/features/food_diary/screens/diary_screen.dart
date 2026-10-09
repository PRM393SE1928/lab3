import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_empty_view.dart';
import '../../../shared/services/app_state.dart';
import '../models/meal.dart';

class DiaryScreen extends StatelessWidget {
  const DiaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Nhật ký ăn uống',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Thêm bữa ăn',
            onPressed: () => context.push('/add-meal'),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: state.meals.isEmpty
          ? const AppEmptyView(
              message: 'Nhật ký của bạn đang chờ bữa ăn đầu tiên.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: state.meals.length,
              separatorBuilder: (_, index) => const SizedBox(height: 8),
              itemBuilder: (_, index) {
                final meal = state.meals[index];
                return Dismissible(
                  key: ValueKey(meal.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red.shade100,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete_outline),
                  ),
                  onDismissed: (_) => state.deleteMeal(meal.id),
                  child: Card(
                    child: ListTile(
                      title: Text(
                        meal.type.label,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        meal.items
                            .map((item) => '${item.emoji} ${item.name}')
                            .join('\n'),
                      ),
                      isThreeLine: true,
                      trailing: IconButton(
                        tooltip: 'Sửa bữa ăn',
                        onPressed: () => context.push('/add-meal', extra: meal),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      onTap: () => context.push('/meal-result', extra: meal),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
