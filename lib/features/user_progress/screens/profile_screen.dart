import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../shared/services/app_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController nameController;
  late final TextEditingController emailController;
  late final TextEditingController goalController;
  late final TextEditingController focusController;
  late double targetScore;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AppState>().profile;
    nameController = TextEditingController(text: profile.name);
    emailController = TextEditingController(text: profile.email);
    goalController = TextEditingController(text: profile.goal);
    focusController = TextEditingController(text: profile.dietaryFocus);
    targetScore = profile.targetScore.toDouble();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    goalController.dispose();
    focusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final profile = state.profile;

    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          AppCard(
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 42,
                  child: Icon(Icons.person, size: 42),
                ),
                const SizedBox(height: 14),
                Text(
                  profile.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  profile.email,
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 10),
                Text(profile.goal, textAlign: TextAlign.center),
              ],
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Tên người dùng',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
            controller: nameController,
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            keyboardType: TextInputType.emailAddress,
            controller: emailController,
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Mục tiêu cá nhân',
              prefixIcon: Icon(Icons.flag_outlined),
            ),
            controller: goalController,
            minLines: 1,
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Trọng tâm ăn uống',
              prefixIcon: Icon(Icons.eco_outlined),
            ),
            controller: focusController,
          ),
          const SizedBox(height: 18),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mục tiêu điểm: ${targetScore.round()}/100',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Slider(
                  min: 50,
                  max: 100,
                  divisions: 10,
                  value: targetScore,
                  label: '${targetScore.round()}',
                  onChanged: (value) => setState(() => targetScore = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (errorMessage != null) ...[
            Text(
              errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 12),
          ],
          AppButton(
            label: 'Lưu hồ sơ',
            icon: Icons.check,
            onPressed: () {
              final email = emailController.text.trim();
              if (nameController.text.trim().isEmpty) {
                setState(() => errorMessage = 'Vui lòng nhập tên người dùng.');
                return;
              }
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                setState(() => errorMessage = 'Email chưa đúng định dạng.');
                return;
              }
              setState(() => errorMessage = null);
              context.read<AppState>().updateProfile(
                name: nameController.text,
                email: emailController.text,
                goal: goalController.text,
                dietaryFocus: focusController.text,
                targetScore: targetScore.round(),
              );
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
