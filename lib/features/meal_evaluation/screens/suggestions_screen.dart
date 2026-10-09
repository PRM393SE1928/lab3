import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_card.dart';
import '../../../shared/services/app_state.dart';

class SuggestionsScreen extends StatelessWidget {
  const SuggestionsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final suggestions =
        context.watch<AppState>().lastEvaluation?.suggestions ??
        [
          'Thêm một loại rau củ nhiều màu sắc',
          'Uống nước cùng bữa ăn này',
          'Thử thêm một món từ ngũ cốc nguyên hạt',
        ];
    return Scaffold(
      appBar: AppBar(title: const Text('Gợi ý')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Thay đổi nhỏ, lặp lại mỗi ngày',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          ...suggestions.asMap().entries.map(
            (entry) => AppCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(child: Text('${entry.key + 1}')),
                title: Text(entry.value),
                subtitle: const Text(
                  'Một gợi ý nhẹ nhàng, không phải quy tắc.',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
