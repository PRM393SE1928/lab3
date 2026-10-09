import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_button.dart';
import '../../../shared/services/app_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController nameController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(
      text: context.read<AppState>().profile.name,
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AppState>().profile;
    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const CircleAvatar(radius: 42, child: Icon(Icons.person, size: 42)),
          const SizedBox(height: 16),
          Center(
            child: Text(
              profile.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 8),
          Center(child: Text(profile.goal, textAlign: TextAlign.center)),
          const SizedBox(height: 32),
          TextField(
            decoration: const InputDecoration(labelText: 'Tên'),
            controller: nameController,
            onChanged: context.read<AppState>().updateProfileName,
          ),
          const SizedBox(height: 20),
          AppButton(
            label: 'Xong',
            icon: Icons.check,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
