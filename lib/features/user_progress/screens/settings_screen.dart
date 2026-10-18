import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_card.dart';
import '../../../shared/services/app_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          AppCard(
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Nhắc nhở hằng ngày'),
                  subtitle: Text(
                    'Nhắc lúc ${state.reminderTime.format(context)}',
                  ),
                  value: state.dailyRemindersEnabled,
                  onChanged: (value) =>
                      state.updateNotificationSettings(dailyReminders: value),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.schedule_outlined),
                  title: const Text('Giờ nhắc nhở'),
                  trailing: Text(state.reminderTime.format(context)),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: state.reminderTime,
                    );
                    if (picked != null && context.mounted) {
                      context.read<AppState>().updateNotificationSettings(
                        time: picked,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Tóm tắt tiến độ hằng tuần'),
                  subtitle: const Text(
                    'Hiển thị thông báo khi có tổng kết điểm và thói quen.',
                  ),
                  value: state.weeklySummaryEnabled,
                  onChanged: (value) =>
                      state.updateNotificationSettings(weeklySummary: value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Thông báo khi đạt mục tiêu'),
                  subtitle: const Text(
                    'Báo khi điểm ngày đạt hoặc vượt mục tiêu cá nhân.',
                  ),
                  value: state.progressNotificationsEnabled,
                  onChanged: (value) => state.updateNotificationSettings(
                    progressNotifications: value,
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Nhật ký thu gọn'),
                  subtitle: const Text(
                    'Ưu tiên giao diện danh sách bữa ăn gọn hơn.',
                  ),
                  value: state.compactDiaryEnabled,
                  onChanged: (value) =>
                      state.updateNotificationSettings(compactDiary: value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const AppCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.spa_outlined),
              title: Text('Về Longeva'),
              subtitle: Text(
                'Ứng dụng hỗ trợ ghi nhận bữa ăn, học kiến thức dinh dưỡng và theo dõi tiến độ sống khỏe.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
