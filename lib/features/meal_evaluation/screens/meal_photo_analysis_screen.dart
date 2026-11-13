import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_card.dart';
import '../../../shared/services/app_state.dart';
import '../../../shared/services/meal_image_service.dart';
import '../../food_diary/models/food_item.dart';
import '../../food_diary/models/meal.dart';
import '../../food_diary/widgets/food_picker_sheet.dart';
import '../services/meal_photo_analyzer.dart';
import '../models/book_principle.dart';

class MealPhotoAnalysisScreen extends StatefulWidget {
  const MealPhotoAnalysisScreen({
    super.key,
    required this.analyzer,
    this.initialManualMode = false,
    this.initialFoods,
    this.mealType,
  });

  final MealPhotoAnalyzer analyzer;
  final bool initialManualMode;
  final List<FoodItem>? initialFoods;
  final MealType? mealType;

  @override
  State<MealPhotoAnalysisScreen> createState() =>
      _MealPhotoAnalysisScreenState();
}

class _MealPhotoAnalysisScreenState extends State<MealPhotoAnalysisScreen> {
  final _picker = ImagePicker();
  Uint8List? _imageBytes;
  String _imageMimeType = 'image/jpeg';
  bool _savePhoto = false;
  MealPhotoAnalysisResult? _result;
  bool _resultOutdated = false;
  List<FoodItem> _selectedFoods = [];
  MealType _type = _mealTypeForCurrentTime();
  String? _error;
  bool _loading = false;
  bool _manualMode = false;
  final _principles = const BookPrinciplesRepository();

  static MealType _mealTypeForCurrentTime() {
    final hour = DateTime.now().hour;
    if (hour < 10) return MealType.breakfast;
    if (hour < 15) return MealType.lunch;
    if (hour < 21) return MealType.dinner;
    return MealType.snack;
  }

  @override
  void initState() {
    super.initState();
    _manualMode = widget.initialManualMode;
    if (widget.initialFoods != null) {
      _selectedFoods = List.of(widget.initialFoods!);
    }
    if (widget.mealType != null) {
      _type = widget.mealType!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Về trang chủ',
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.home_outlined),
        ),
        title: Text(_manualMode ? 'Đánh giá bữa ăn' : 'Phân tích ảnh bữa ăn'),
      ),
      body: AbsorbPointer(
        absorbing: _loading,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(
              _manualMode
                  ? 'Chọn món ăn từ danh sách để đánh giá theo nguyên tắc dinh dưỡng.'
                  : 'Chụp ảnh hoặc chọn ảnh để nhận gợi ý món ăn.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Bạn luôn có thể điều chỉnh và xác nhận danh sách món trước khi lưu.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Đánh giá thủ công'),
              subtitle: const Text('Không cần tải ảnh'),
              value: _manualMode,
              onChanged: _loading
                  ? null
                  : (value) => setState(() {
                      _manualMode = value;
                      _imageBytes = null;
                      _result = null;
                      _error = null;
                    }),
            ),
            if (_manualMode) ...[
              OutlinedButton.icon(
                onPressed: _loading
                    ? null
                    : () async {
                        final result = await showFoodPicker(
                          context,
                          catalog: state.foods,
                          initialSelection: _selectedFoods,
                        );
                        if (result != null && mounted) {
                          setState(() {
                            _selectedFoods = result;
                            _resultOutdated = true;
                          });
                        }
                      },
                icon: const Icon(Icons.restaurant_menu_outlined),
                label: const Text('Chọn thực phẩm'),
              ),
              ..._selectedFoods.map(
                (food) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Text(food.emoji),
                  title: Text(food.name),
                  trailing: IconButton(
                    onPressed: () => setState(() {
                      _selectedFoods.remove(food);
                      _resultOutdated = true;
                    }),
                    icon: const Icon(Icons.close),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _loading || _selectedFoods.isEmpty
                    ? null
                    : () => _analyzeManual(),
                icon: _loading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome_outlined),
                label: Text(
                  _loading ? 'Đang đánh giá...' : 'Đánh giá danh sách',
                ),
              ),
            ],
            if (!_manualMode) ...[
              SwitchListTile(
                title: const Text('Lưu ảnh cùng bữa ăn'),
                subtitle: const Text('Ảnh được lưu trên Cloudinary.'),
                value: _savePhoto,
                onChanged: _loading
                    ? null
                    : (value) => setState(() => _savePhoto = value),
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
                      onPressed: _loading
                          ? null
                          : () => _pick(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Chụp ảnh'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _loading
                          ? null
                          : () => _pick(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Thư viện'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_imageBytes != null)
                FilledButton.icon(
                  onPressed: _loading
                      ? null
                      : () => _analyze(
                          state.foods,
                          mealType: _type.name,
                          profile: jsonEncode({
                            'age': state.healthProfile.age,
                            'ageGroup': state.healthProfile.ageGroup?.name,
                            'allergies': state.healthProfile.allergies,
                            'dislikedFoods': state.healthProfile.dislikedFoods,
                            'dietaryPattern':
                                state.healthProfile.dietaryPattern,
                          }),
                          principles: jsonEncode(_principles.forAi),
                          mimeType: _imageMimeType,
                        ),
                  icon: _loading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome_outlined),
                  label: Text(
                    _loading ? 'Đang phân tích...' : 'Phân tích bữa ăn',
                  ),
                ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (_result != null) ...[
              const SizedBox(height: 20),
              if (_resultOutdated)
                const Text(
                  'Danh sách hoặc loại bữa đã thay đổi. Kết quả sẽ được đánh giá lại khi lưu.',
                )
              else
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
                    setState(() {
                      _selectedFoods = result;
                      _resultOutdated = true;
                    });
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
                    onPressed: () => setState(() {
                      _selectedFoods.remove(food);
                      _resultOutdated = true;
                    }),
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
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _type = value;
                      _resultOutdated = true;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loading || _selectedFoods.isEmpty ? null : _save,
                icon: const Icon(Icons.check),
                label: Text(
                  _loading
                      ? 'Đang đánh giá và lưu...'
                      : 'Xác nhận và lưu bữa ăn',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _analyzeManual() async {
    setState(() {
      _loading = true;
      _error = null;
      _resultOutdated = true;
    });
    final profile = context.read<AppState>().healthProfile;
    try {
      final result = await widget.analyzer.analyzeFoods(
        _selectedFoods,
        mealType: _type.name,
        profile: jsonEncode({
          'age': profile.age,
          'ageGroup': profile.ageGroup?.name,
          'allergies': profile.allergies,
          'dislikedFoods': profile.dislikedFoods,
          'dietaryPattern': profile.dietaryPattern,
        }),
        principles: jsonEncode(_principles.forAi),
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _resultOutdated = false;
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
          _error = 'Không thể đánh giá món ăn lúc này. Hãy thử lại.';
        });
      }
    }
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      if (bytes.isEmpty) {
        setState(() => _error = 'Ảnh không có dữ liệu. Hãy thử ảnh khác.');
        return;
      }
      setState(() {
        _imageBytes = bytes;
        _imageMimeType = file.mimeType ?? _detectMimeType(bytes);
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

  String _detectMimeType(Uint8List bytes) {
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4e &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes.length >= 12 &&
        String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
      return 'image/webp';
    }
    return 'image/jpeg';
  }

  Future<void> _analyze(
    List<FoodItem> catalog, {
    required String mealType,
    required String profile,
    required String principles,
    required String mimeType,
  }) async {
    final bytes = _imageBytes;
    if (bytes == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.analyzer.analyze(
        bytes,
        catalog: catalog,
        mealType: mealType,
        profile: profile,
        principles: principles,
        mimeType: mimeType,
      );
      if (!mounted) return;
      final foods = <FoodItem>[];
      for (final recognized in result.foods) {
        // An AI catalog ID is accepted only when the name also matches.
        // Keep composite dish names intact instead of splitting a composite dish.
        final catalogFood = catalog.cast<FoodItem?>().firstWhere(
          (food) =>
              food != null &&
              normalizeFoodText(food.name) ==
                  normalizeFoodText(recognized.name),
          orElse: () => null,
        );
        final food =
            catalogFood ??
            FoodItem(
              id: 'ai_${normalizeFoodText(recognized.name).replaceAll(' ', '_')}',
              name: recognized.name.trim(),
              category: mealType,
              sourceType: 'ai_recognition',
              description: 'Món nhận diện từ ảnh, cần người dùng xác nhận.',
            );
        if (food.name.isNotEmpty && !foods.any((item) => item.id == food.id)) {
          foods.add(food);
        }
      }
      setState(() {
        _result = result;
        _resultOutdated = false;
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

  Future<void> _save() async {
    if (_loading || _selectedFoods.isEmpty) return;
    final state = context.read<AppState>();
    final confirmed = List<FoodItem>.of(_selectedFoods);
    final type = _type;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Evaluate exactly what the user confirmed, including edits/removals.
      final result = await widget.analyzer.analyzeFoods(
        confirmed,
        mealType: type.name,
        profile: jsonEncode({
          'age': state.healthProfile.age,
          'allergies': state.healthProfile.allergies,
          'dislikedFoods': state.healthProfile.dislikedFoods,
          'dietaryPattern': state.healthProfile.dietaryPattern,
        }),
        principles: jsonEncode(_principles.forAi),
      );
      if (!mounted) return;
      String? imageUrl;
      if (_savePhoto && !_manualMode && _imageBytes != null) {
        imageUrl = await MealImageService().upload(
          _imageBytes!,
          _imageMimeType,
        );
      }
      if (!mounted) return;
      final meal = state.addMeal(type, confirmed, imageUrl: imageUrl);
      state.saveAiMealAnalysis(
        meal.id,
        result.copyWith(
          foods: confirmed
              .map(
                (food) => RecognizedFood(
                  name: food.name,
                  catalogId: food.id,
                  needsConfirmation: false,
                  confirmedByUser: true,
                  source: 'USER_CONFIRMED',
                ),
              )
              .toList(),
        ),
      );
      context.replace('/meal-result', extra: meal);
    } on MealImageException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on MealPhotoAnalysisException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Chưa thể đánh giá và lưu. Hãy thử lại.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
                  : 'AI backend',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (result.foods.isNotEmpty) ...[
          const Text(
            'Món ăn nhận diện được:',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          ...result.foods.map(
            (food) => Text(
              '• ${food.name}${food.confidence == null ? '' : ' (${(food.confidence! * 100).round()}%)'}',
            ),
          ),
        ] else
          const Text('Chưa nhận diện được món ăn rõ ràng từ ảnh.'),
        if (result.description.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(result.description),
        ],
        _AnalysisList(
          title: 'Thành phần quan sát được',
          values: result.ingredients,
        ),
        _AnalysisList(title: 'Nhóm thực phẩm', values: result.foodGroups),
        _AnalysisList(
          title: 'Món cần kiểm tra lại',
          values: result.uncertainItems,
        ),
        if (result.foodVarietyStatus != null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Đa dạng thực phẩm'),
            subtitle: Text(
              result.foodVarietyExplanation.isNotEmpty
                  ? result.foodVarietyExplanation
                  : (result.foodVarietyStatus?.toUpperCase() == 'GOOD'
                        ? 'Đạt độ đa dạng tốt'
                        : result.foodVarietyStatus!),
            ),
          ),
        _AnalysisList(title: 'Điểm tích cực', values: result.strengths),
        _AnalysisList(title: 'Cần cải thiện', values: result.improvements),
        _AnalysisList(
          title: 'Gợi ý cá nhân hóa',
          values: result.personalizedAdvice,
        ),
        _AnalysisList(
          title: 'Chưa đủ dữ liệu',
          values: result.insufficientData,
        ),
        _AnalysisList(
          title: 'Thông tin chưa thể xác định',
          values: result.unknownInformation,
        ),
        if (result.criteriaResults.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text(
            'Đối chiếu nguyên tắc',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          ...result.criteriaResults.map(
            (item) => Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor(
                              item.status,
                              context,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.statusLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _statusColor(item.status, context),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (item.reason.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(item.reason),
                    ],
                    if (item.bookReferenceText != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        item.bookReferenceText!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 4),
                      Text(
                        item.sourceLabel,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: Colors.black54),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
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

Color _statusColor(String status, BuildContext context) {
  return switch (status.toUpperCase()) {
    'MATCH' => Colors.green.shade700,
    'PARTIAL' => Colors.orange.shade800,
    'NOT_MATCH' => Colors.red.shade700,
    _ => Theme.of(context).colorScheme.outline,
  };
}

class _AnalysisList extends StatelessWidget {
  const _AnalysisList({required this.title, required this.values});
  final String title;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          ...values.map((value) => Text('• $value')),
        ],
      ),
    );
  }
}
