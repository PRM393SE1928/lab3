import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_card.dart';
import '../../../shared/services/app_state.dart';
import '../../../shared/services/crash_reporting_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, this.crashReporting});

  final CrashReportingService? crashReporting;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          if (!kIsWeb &&
              defaultTargetPlatform == TargetPlatform.android &&
              const bool.fromEnvironment('CRASHLYTICS_DEMO')) ...[
            AppCard(
              child: ListTile(
                leading: const Icon(Icons.bug_report_outlined),
                title: const Text('Thử nghiệm Crashlytics'),
                subtitle: const Text(
                  'Cố ý đóng ứng dụng để kiểm tra báo cáo lỗi.',
                ),
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Gây lỗi thử nghiệm?'),
                      content: const Text(
                        'Ứng dụng sẽ đóng ngay. Hãy mở lại ứng dụng để gửi báo cáo.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Hủy'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Gây crash'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    final reporter =
                        crashReporting ?? CrashReportingService.instance;
                    await reporter.log(
                      'Crashlytics demo requested from settings',
                    );
                    reporter.crash();
                  }
                },
              ),
            ),
            const SizedBox(height: 14),
          ],
          AppCard(
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Nhắc nhở hằng ngày'),
                  subtitle: Text(
                    'Chưa hỗ trợ đặt lịch thông báo · ${state.reminderTime.format(context)}',
                  ),
                  value: state.dailyRemindersEnabled,
                  onChanged: null,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.schedule_outlined),
                  title: const Text('Giờ nhắc nhở'),
                  trailing: Text(state.reminderTime.format(context)),
                  onTap: null,
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
                    'Lưu tùy chọn trong phiên demo; chưa đặt lịch thông báo nền.',
                  ),
                  value: state.weeklySummaryEnabled,
                  onChanged: null,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Thông báo khi đạt mục tiêu'),
                  subtitle: const Text(
                    'Lưu tùy chọn trong phiên demo; chưa kết nối thông báo hệ thống.',
                  ),
                  value: state.progressNotificationsEnabled,
                  onChanged: null,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Nhật ký thu gọn'),
                  subtitle: const Text(
                    'Lưu tùy chọn trong phiên demo; áp dụng khi mở lại nhật ký.',
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
