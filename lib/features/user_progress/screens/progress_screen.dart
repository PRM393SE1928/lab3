import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_card.dart';
import '../../../shared/services/app_state.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tiến độ',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Cài đặt',
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Stat(value: '${state.meals.length}', label: 'Bữa đã ghi'),
                _Stat(value: '${state.weeklyScore}', label: 'Điểm tuần'),
                _Stat(value: '${state.streakDays}', label: 'Ngày liên tiếp'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Tuần của bạn',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final entry in state.weeklyScores.asMap().entries)
                  Column(
                    children: [
                      Container(
                        width: 22,
                        height: entry.value.toDouble(),
                        decoration: BoxDecoration(
                          color: entry.value > 70
                              ? const Color(0xFF245C4A)
                              : const Color(0xFFB8D1BF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(['M', 'T', 'W', 'T', 'F', 'S', 'S'][entry.key]),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value, label;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
      ),
      Text(label, style: const TextStyle(color: Colors.black54)),
    ],
  );
}
