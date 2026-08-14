import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../widgets/frosted.dart';
import '../models/plant.dart';
import '../store/app_store.dart';
import '../widgets/plant_card.dart';
import 'package:provider/provider.dart';

/// 添加/编辑植物表单
/// plant == null → 添加模式；plant != null → 编辑模式
class AddEditPlantScreen extends StatefulWidget {
  final Plant? plant;

  const AddEditPlantScreen({super.key, this.plant});

  @override
  State<AddEditPlantScreen> createState() => _AddEditPlantScreenState();
}

class _AddEditPlantScreenState extends State<AddEditPlantScreen> {
  final _nameController = TextEditingController();
  final _scientificController = TextEditingController();
  final _frequencyController = TextEditingController();
  final _lightController = TextEditingController();
  final _tempController = TextEditingController();
  final _humidityController = TextEditingController();
  final _fertilizingController = TextEditingController();
  final _pruningController = TextEditingController();

  String _healthStatus = '健康';
  String? _imagePath;
  bool _isSaving = false;

  bool get _isEditMode => widget.plant != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final plant = widget.plant!;
      _nameController.text = plant.name;
      _scientificController.text = plant.scientificName;
      _frequencyController.text = plant.wateringFrequency.toString();
      _fertilizingController.text = plant.fertilizingFrequency.toString();
      _pruningController.text = plant.pruningFrequency.toString();
      _lightController.text = plant.lightRequirement;
      _tempController.text = plant.temperatureRange;
      _humidityController.text = plant.humidityRange;
      _healthStatus = plant.healthStatus;
      _imagePath = plant.imagePath;
    } else {
      _frequencyController.text = '7';
      _fertilizingController.text = '14';
      _pruningController.text = '30';
      _lightController.text = '明亮散射光';
      _tempController.text = '18-28°C';
      _humidityController.text = '50-70%';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _scientificController.dispose();
    _frequencyController.dispose();
    _lightController.dispose();
    _tempController.dispose();
    _humidityController.dispose();
    _fertilizingController.dispose();
    _pruningController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final xFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (xFile == null) return;

      // 复制到 app 文档目录，确保重启后仍可访问
      final docsDir = await getApplicationDocumentsDirectory();
      final imageDir = Directory(p.join(docsDir.path, 'plant_images'));
      if (!await imageDir.exists()) {
        await imageDir.create(recursive: true);
      }
      final fileName = '${const Uuid().v4()}.jpg';
      final savedPath = p.join(imageDir.path, fileName);
      await File(xFile.path).copy(savedPath);

      setState(() => _imagePath = savedPath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('选择图片失败: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('请输入植物名称'), backgroundColor: AppColors.accent),
      );
      return;
    }

    final freq = int.tryParse(_frequencyController.text.trim()) ?? 7;
    final freqF = int.tryParse(_fertilizingController.text.trim()) ?? 14;
    final freqP = int.tryParse(_pruningController.text.trim()) ?? 30;
    final now = DateTime.now();

    setState(() => _isSaving = true);

    final store = context.read<AppStore>();

    if (_isEditMode) {
      // 编辑模式：保留养护时间，更新信息
      final updated = widget.plant!.copyWith(
        name: name,
        scientificName: _scientificController.text.trim(),
        imagePath: _imagePath,
        healthStatus: _healthStatus,
        wateringFrequency: freq,
        fertilizingFrequency: freqF,
        pruningFrequency: freqP,
        lightRequirement: _lightController.text.trim(),
        temperatureRange: _tempController.text.trim(),
        humidityRange: _humidityController.text.trim(),
      );
      store.updatePlant(updated);
    } else {
      // 添加模式
      final newPlant = Plant(
        id: const Uuid().v4(),
        name: name,
        scientificName: _scientificController.text.trim(),
        imagePath: _imagePath,
        healthStatus: _healthStatus,
        wateringFrequency: freq,
        lastWatered: now,
        nextWatering: now.add(Duration(days: freq)),
        fertilizingFrequency: freqF,
        lastFertilized: now,
        nextFertilizing: now.add(Duration(days: freqF)),
        pruningFrequency: freqP,
        lastPruned: now,
        nextPruning: now.add(Duration(days: freqP)),
        lightRequirement: _lightController.text.trim(),
        temperatureRange: _tempController.text.trim(),
        humidityRange: _humidityController.text.trim(),
        careDays: 1,
        points: 0,
      );
      store.addPlant(newPlant);
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isEditMode ? '植物信息已更新' : '$name 已添加到我的植物'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: AppColors.bg,
        child: SafeArea(
          top: true,
          bottom: false,
          child: Column(
            children: [
              _buildNavBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildImagePicker(),
                      const SizedBox(height: 20),
                      _buildFormSection(),
                    ],
                  ),
                ),
              ),
              _buildSaveBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavBar() {
    return FrostedTopBar(
      title: _isEditMode ? '编辑植物' : '添加植物',
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        behavior: HitTestBehavior.opaque,
        child: const SizedBox(
          width: 32,
          height: 32,
          child: Icon(Icons.chevron_left, color: AppColors.primary, size: 28),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: GestureDetector(
        onTap: _pickImage,
        child: Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.softCard,
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            border: Border.all(
              color: _imagePath != null ? Colors.transparent : AppColors.border,
              width: 1,
            ),
          ),
          child: _imagePath != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                  child: Image.file(File(_imagePath!), fit: BoxFit.cover),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo, size: 40, color: AppColors.primary),
                    const SizedBox(height: 8),
                    Text('添加植物照片', style: AppTypography.label),
                    const SizedBox(height: 4),
                    Text('点击从相册选择（可选）', style: AppTypography.badge),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildFormSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildField('植物名称', _nameController, '如：龟背竹', required: true),
          const SizedBox(height: 16),
          _buildField('学名（可选）', _scientificController, '如：Monstera deliciosa'),
          const SizedBox(height: 16),
          _buildFrequencyField(
            label: '浇水频率',
            controller: _frequencyController,
            hint: '7',
            suffix: '每X天浇水一次',
          ),
          const SizedBox(height: 16),
          _buildFrequencyField(
            label: '施肥频率',
            controller: _fertilizingController,
            hint: '14',
            suffix: '每X天施肥一次',
          ),
          const SizedBox(height: 16),
          _buildFrequencyField(
            label: '修剪频率',
            controller: _pruningController,
            hint: '30',
            suffix: '每X天修剪一次',
          ),
          const SizedBox(height: 16),
          _buildHealthSelector(),
          const SizedBox(height: 16),
          _buildField('光照需求', _lightController, '如：明亮散射光'),
          const SizedBox(height: 16),
          _buildField('适宜温度', _tempController, '如：18-28°C'),
          const SizedBox(height: 16),
          _buildField('适宜湿度', _humidityController, '如：50-70%'),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    String hint, {
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(text: label, style: AppTypography.label),
              if (required)
                TextSpan(
                    text: ' *',
                    style:
                        AppTypography.label.copyWith(color: AppColors.danger)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.softCard,
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          ),
          child: TextField(
            controller: controller,
            style: AppTypography.body,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle:
                  AppTypography.caption.copyWith(color: AppColors.textHint),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFrequencyField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required String suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.label),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.softCard,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                ),
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  style: AppTypography.body,
                  decoration: InputDecoration(
                    hintText: hint,
                    suffixText: '天',
                    suffixStyle: AppTypography.caption,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.softCard,
                borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
              ),
              child: Text(suffix, style: AppTypography.caption),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHealthSelector() {
    final statuses = ['健康', '需关注', '生病'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('健康状态', style: AppTypography.label),
        const SizedBox(height: 8),
        Row(
          children: statuses.map((status) {
            final selected = _healthStatus == status;
            final color = status == '健康'
                ? AppColors.primary
                : (status == '需关注' ? AppColors.accent : AppColors.danger);
            return Expanded(
              child: Padding(
                padding:
                    EdgeInsets.only(right: status != statuses.last ? 8 : 0),
                child: GestureDetector(
                  onTap: () => setState(() => _healthStatus = status),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selected ? color : AppColors.softCard,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusCard),
                    ),
                    child: Text(
                      status,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'NunitoSans',
                        fontSize: 13,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                        color:
                            selected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSaveBar() {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        boxShadow: [
          BoxShadow(
            color: AppColors.scanBg.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: GradientButton(
        label: _isSaving ? '保存中...' : (_isEditMode ? '保存修改' : '添加植物'),
        icon: Icons.check,
        onTap: _isSaving ? null : _save,
      ),
    );
  }
}
