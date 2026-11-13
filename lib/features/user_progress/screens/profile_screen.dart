import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../shared/services/app_state.dart';
import '../../../shared/services/auth_service.dart';

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
  late final TextEditingController ageController;
  late final TextEditingController weightController;
  late final TextEditingController heightController;
  late final TextEditingController allergiesController;
  late final TextEditingController dislikedFoodsController;
  late final TextEditingController dietaryPatternController;
  late double targetScore;
  String? errorMessage;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AppState>().profile;
    nameController = TextEditingController(text: profile.name);
    emailController = TextEditingController(
      text: AuthService().currentUser?.email ?? profile.email,
    );
    goalController = TextEditingController(text: profile.goal);
    focusController = TextEditingController(text: profile.dietaryFocus);
    final health = context.read<AppState>().healthProfile;
    ageController = TextEditingController(text: health.age?.toString() ?? '');
    weightController = TextEditingController(
      text: health.weightKg?.toString() ?? '',
    );
    heightController = TextEditingController(
      text: health.heightCm?.toString() ?? '',
    );
    allergiesController = TextEditingController(
      text: health.allergies.join(', '),
    );
    dislikedFoodsController = TextEditingController(
      text: health.dislikedFoods.join(', '),
    );
    dietaryPatternController = TextEditingController(
      text: health.dietaryPattern,
    );
    targetScore = profile.targetScore.toDouble();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    goalController.dispose();
    focusController.dispose();
    ageController.dispose();
    weightController.dispose();
    heightController.dispose();
    allergiesController.dispose();
    dislikedFoodsController.dispose();
    dietaryPatternController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final email = emailController.text.trim();
    final age = int.tryParse(ageController.text.trim());
    final weight = double.tryParse(
      weightController.text.trim().replaceAll(',', '.'),
    );
    final height = int.tryParse(heightController.text.trim());
    if (nameController.text.trim().isEmpty) {
      setState(() => errorMessage = 'Vui lòng nhập tên người dùng.');
      return;
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() => errorMessage = 'Email chưa đúng định dạng.');
      return;
    }
    if (age == null ||
        weight == null ||
        height == null ||
        age <= 0 ||
        age > 130 ||
        weight <= 0 ||
        weight > 500 ||
        height <= 0 ||
        height > 300) {
      setState(
        () =>
            errorMessage = 'Vui lòng nhập tuổi, cân nặng và chiều cao hợp lệ.',
      );
      return;
    }
    setState(() {
      errorMessage = null;
      isSaving = true;
    });
    try {
      final state = context.read<AppState>();
      state.updateProfile(
        name: nameController.text,
        email: emailController.text,
        goal: goalController.text,
        dietaryFocus: focusController.text,
        targetScore: targetScore.round(),
      );
      await state.updateHealthProfile(
        age: age,
        weightKg: weight,
        heightCm: height,
        allergies: _splitList(allergiesController.text),
        dislikedFoods: _splitList(dislikedFoodsController.text),
        dietaryPattern: dietaryPatternController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật hồ sơ sức khỏe.')),
      );
    } catch (error) {
      if (mounted) setState(() => errorMessage = 'Không thể lưu hồ sơ: $error');
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  List<String> _splitList(String value) => value
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toSet()
      .toList();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final profile = state.profile;
    final authUser = AuthService().currentUser;

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
            readOnly: authUser != null,
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
                const Text(
                  'Hồ sơ sức khỏe cá nhân',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Dùng để cá nhân hóa gợi ý món ăn. Đây không phải là chẩn đoán y khoa.',
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: ageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Tuổi',
                    suffixText: 'năm',
                    prefixIcon: Icon(Icons.cake_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: weightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Cân nặng',
                    suffixText: 'kg',
                    prefixIcon: Icon(Icons.monitor_weight_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: heightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Chiều cao',
                    suffixText: 'cm',
                    prefixIcon: Icon(Icons.height_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: allergiesController,
                  decoration: const InputDecoration(
                    labelText: 'Dị ứng thực phẩm',
                    hintText: 'Ví dụ: đậu phộng, sữa',
                    prefixIcon: Icon(Icons.warning_amber_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dislikedFoodsController,
                  decoration: const InputDecoration(
                    labelText: 'Thực phẩm không thích',
                    hintText: 'Phân cách bằng dấu phẩy',
                    prefixIcon: Icon(Icons.remove_circle_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dietaryPatternController,
                  decoration: const InputDecoration(
                    labelText: 'Chế độ ăn',
                    hintText: 'Ví dụ: ăn chay, không thịt đỏ',
                    prefixIcon: Icon(Icons.restaurant_outlined),
                  ),
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
            onPressed: isSaving ? null : _save,
          ),
          if (isSaving) ...[
            const SizedBox(height: 12),
            const Center(child: CircularProgressIndicator()),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: state.isHydrating || !state.healthProfile.isComplete
                ? null
                : () => context.push('/health-suggestions'),
            icon: const Icon(Icons.auto_awesome_outlined),
            label: const Text('AI phân tích hồ sơ và gợi ý món ăn'),
          ),
          const Text('Lưu hồ sơ trước khi yêu cầu AI phân tích.'),
          const SizedBox(height: 12),
          if (authUser == null)
            OutlinedButton.icon(
              onPressed: () => context.push('/auth'),
              icon: const Icon(Icons.login),
              label: const Text('Đăng nhập để đồng bộ dữ liệu'),
            )
          else
            OutlinedButton.icon(
              onPressed: () async {
                try {
                  await AuthService().signOut();
                } catch (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AuthService().messageFor(error))),
                    );
                  }
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('Đăng xuất'),
            ),
        ],
      ),
    );
  }
}
