import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool reminders = true;
  bool compact = false;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Cài đặt')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SwitchListTile(
          title: const Text('Nhắc nhở hằng ngày'),
          subtitle: const Text('Chưa triển khai trong bản demo này'),
          value: reminders,
          onChanged: null,
        ),
        SwitchListTile(
          title: const Text('Nhật ký thu gọn'),
          subtitle: const Text('Chưa triển khai trong bản demo này'),
          value: compact,
          onChanged: null,
        ),
        const ListTile(
          title: Text('Về Longeva'),
          subtitle: Text(
            'Ứng dụng demo giúp xây dựng thói quen ăn uống lành mạnh.',
          ),
        ),
      ],
    ),
  );
}
