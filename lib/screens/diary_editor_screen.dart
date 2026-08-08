import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../store/app_store.dart';
import '../widgets/plant_image.dart';

/// 写日记 / 记心得页面
class DiaryEditorScreen extends StatefulWidget {
  final String? initialPlantId;

  const DiaryEditorScreen({super.key, this.initialPlantId});

  @override
  State<DiaryEditorScreen> createState() => _DiaryEditorScreenState();
}

class _DiaryEditorScreenState extends State<DiaryEditorScreen> {
  final _noteController = TextEditingController();
  String? _selectedPlantId;
  final List<String> _imagePaths = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialPlantId != null) {
      _selectedPlantId = widget.initialPlantId;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final picker = ImagePicker();
      final xFiles = await picker.pickMultiImage(
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (xFiles.isEmpty) return;

      final docsDir = await getApplicationDocumentsDirectory();
      final imageDir = Directory(p.join(docsDir.path, 'diary_images'));
      if (!await imageDir.exists()) {
        await imageDir.create(recursive: true);
      }

      final savedPaths = <String>[];
      for (final xFile in xFiles) {
        final fileName = '${const Uuid().v4()}.jpg';
        final savedPath = p.join(imageDir.path, fileName);
        await File(xFile.path).copy(savedPath);
        savedPaths.add(savedPath);
      }

      setState(() => _imagePaths.addAll(savedPaths));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择图片失败: $e'),
            backgroundColor: AppColors.danger),
        );
      }
    }
  }

  void _save() {
    final store = context.read<AppStore>();
    if (_selectedPlantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择一株植物'),
          backgroundColor: AppColors.danger),
      );
      return;
    }

    setState(() => _isSaving = true);

    store.addDiary(
      plantId: _selectedPlantId!,
      imagePath: _imagePaths.isNotEmpty ? _imagePaths.first : '',
      extraImagePaths: _imagePaths.length > 1 ? _imagePaths.sublist(1) : null,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('日记已保存'),
        backgroundColor: AppColors.success),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStore>(
      builder: (context, store, _) {
        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            backgroundColor: AppColors.bg,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.close, color: AppColors.textPrimary),
            ),
            title: Text('写日记', style: AppTypography.pageTitle),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: _isSaving ? null : _save,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text('保存',
                      style: AppTypography.buttonText.copyWith(fontSize: 13)),
                  ),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPlantSelector(store),
                const SizedBox(height: 20),
                _buildImageSection(),
                const SizedBox(height: 20),
                _buildNoteField(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlantSelector(AppStore store) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('关联植物', style: AppTypography.label),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: store.plants.map((plant) {
            final isSelected = _selectedPlantId == plant.id;
            return GestureDetector(
              onTap: () => setState(() => _selectedPlantId = plant.id),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                  boxShadow: isSelected ? AppColors.buttonShadow : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PlantImage(
                      plantName: plant.name,
                      imagePath: plant.imagePath,
                      width: 28,
                      height: 28,
                    ),
                    const SizedBox(width: 8),
                    Text(plant.name,
                      style: TextStyle(
                        fontFamily: 'NunitoSans', fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.textPrimary)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('照片', style: AppTypography.label),
        const SizedBox(height: 8),
        if (_imagePaths.isEmpty)
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.softCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: _buildPlaceholder(),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: _imagePaths.length + (_imagePaths.length < 9 ? 1 : 0),
            itemBuilder: (context, index) {
              if (index < _imagePaths.length) {
                return _buildImageThumbnail(index);
              }
              return _buildAddImageButton();
            },
          ),
      ],
    );
  }

  Widget _buildImageThumbnail(int index) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            File(_imagePaths[index]),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildMiniPlaceholder(),
          ),
          Positioned(
            top: 4, right: 4,
            child: GestureDetector(
              onTap: () => setState(() => _imagePaths.removeAt(index)),
              child: Container(
                width: 24, height: 24,
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.softCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Icon(Icons.add, color: AppColors.primary, size: 32),
      ),
    );
  }

  Widget _buildMiniPlaceholder() {
    return Container(
      color: AppColors.softCard,
      child: Icon(Icons.eco, color: AppColors.primary.withValues(alpha: 0.5)),
    );
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.camera_alt_outlined,
          size: 40, color: AppColors.textHint),
        const SizedBox(height: 8),
        Text('点击选择照片',
          style: AppTypography.caption),
      ],
    );
  }

  Widget _buildNoteField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('心得', style: AppTypography.label),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller: _noteController,
            maxLines: 5,
            maxLength: 500,
            style: AppTypography.body.copyWith(height: 1.6),
            decoration: InputDecoration(
              hintText: '记录一下今天的养护心得...',
              hintStyle: AppTypography.caption.copyWith(
                color: AppColors.textHint),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              counterStyle: AppTypography.caption,
            ),
          ),
        ),
      ],
    );
  }
}
