import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_card.dart';
import '../../../shared/services/app_state.dart';
import '../../food_diary/models/food_item.dart';
import '../../food_diary/models/meal.dart';
import '../../food_diary/widgets/food_picker_sheet.dart';
import '../services/meal_photo_analyzer.dart';

class MealPhotoAnalysisScreen extends StatefulWidget {
  const MealPhotoAnalysisScreen({
    super.key,
    this.analyzer = const DemoMealPhotoAnalyzer(),
  });

  final MealPhotoAnalyzer analyzer;

  @override
  State<MealPhotoAnalysisScreen> createState() =>
      _MealPhotoAnalysisScreenState();
}

class _MealPhotoAnalysisScreenState extends State<MealPhotoAnalysisScreen> {
  final _picker = ImagePicker();
  Uint8List? _imageBytes;
  MealPhotoAnalysisResult? _result;
  List<FoodItem> _selectedFoods = [];
  MealType _type = MealType.lunch;
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Phân tích ảnh bữa ăn')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'Chụp ảnh hoặc chọn ảnh để nhận gợi ý món ăn.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Bạn luôn cần xác nhận danh sách món trước khi lưu.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          if (_imageBytes == null)
            const _PhotoPlaceholder()
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.memory(
                _imageBytes!,
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const _PhotoPlaceholder(),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : () => _pick(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Chụp ảnh'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : () => _pick(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Thư viện'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_imageBytes != null)
            FilledButton.icon(
              onPressed: _loading ? null : () => _analyze(state.foods),
              icon: _loading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome_outlined),
              label: Text(_loading ? 'Đang phân tích...' : 'Phân tích bữa ăn'),
            ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          if (_result != null) ...[
            const SizedBox(height: 20),
            _ResultCard(result: _result!),
            const SizedBox(height: 16),
            const Text(
              'Xác nhận món ăn',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                final result = await showFoodPicker(
                  context,
                  catalog: state.foods,
                  initialSelection: _selectedFoods,
                );
                if (result != null && mounted) {
                  setState(() => _selectedFoods = result);
                }
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Chỉnh sửa danh sách món'),
            ),
            const SizedBox(height: 8),
            ..._selectedFoods.map(
              (food) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Text(food.emoji),
                title: Text(food.name),
                trailing: IconButton(
                  tooltip: 'Xóa món',
                  onPressed: () => setState(() => _selectedFoods.remove(food)),
                  icon: const Icon(Icons.close),
                ),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<MealType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Loại bữa ăn'),
              items: MealType.values
                  .map(
                    (type) =>
                        DropdownMenuItem(value: type, child: Text(type.label)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _type = value);
              },
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _selectedFoods.isEmpty ? null : _save,
              icon: const Icon(Icons.check),
              label: const Text('Xác nhận và lưu bữa ăn'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final file = await _picker.pickImage(source: source, imageQuality: 85);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) {
        return;
      }
      if (bytes.isEmpty) {
        setState(() => _error = 'Ảnh không có dữ liệu. Hãy thử ảnh khác.');
        return;
      }
      setState(() {
        _imageBytes = bytes;
        _result = null;
        _selectedFoods = [];
        _error = null;
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Không thể mở ảnh. Hãy kiểm tra quyền truy cập hoặc thử lại.',
        );
      }
    }
  }

  Future<void> _analyze(List<FoodItem> catalog) async {
    final bytes = _imageBytes;
    if (bytes == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.analyzer.analyze(bytes, catalog: catalog);
      if (!mounted) return;
      final foods = result.foods
          .map(
            (recognized) => catalog.cast<FoodItem?>().firstWhere(
              (food) => food?.id == recognized.catalogId,
              orElse: () => null,
            ),
          )
          .whereType<FoodItem>()
          .toSet()
          .toList();
      setState(() {
        _result = result;
        _selectedFoods = foods;
        _loading = false;
      });
    } on MealPhotoAnalysisException catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Không thể phân tích ảnh lúc này. Hãy thử lại.';
        });
      }
    }
  }

  void _save() {
    final meal = context.read<AppState>().addMeal(_type, _selectedFoods);
    if (mounted) context.go('/meal/${meal.id}');
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) => Container(
    height: 220,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Center(child: Icon(Icons.image_search_outlined, size: 56)),
  );
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final MealPhotoAnalysisResult result;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome_outlined),
            const SizedBox(width: 8),
            Text(
              result.mode == MealPhotoAnalysisMode.demo
                  ? 'Chế độ Demo'
                  : 'Real AI',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(result.description),
        if (result.warning != null) ...[
          const SizedBox(height: 8),
          Text(
            result.warning!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    ),
  );
}
