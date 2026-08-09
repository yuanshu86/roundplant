import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/plant.dart';
import '../store/app_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'frosted.dart';

/// 长按植物卡片后弹出的标签编辑器
class TagEditorSheet extends StatefulWidget {
  final Plant plant;

  const TagEditorSheet({super.key, required this.plant});

  @override
  State<TagEditorSheet> createState() => _TagEditorSheetState();

  static void show(BuildContext context, Plant plant) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => TagEditorSheet(plant: plant),
    );
  }
}

class _TagEditorSheetState extends State<TagEditorSheet> {
  late List<PlantTag> _tags;
  final _controller = TextEditingController();
  int _selectedColor = 0xFFD97706;

  static const List<int> _presetColors = [
    0xFFD97706, // 琥珀
    0xFFEF4444, // 红
    0xFF3B82F6, // 蓝
    0xFF22C55E, // 绿
    0xFFA855F7, // 紫
    0xFF06B6D4, // 青
  ];

  @override
  void initState() {
    super.initState();
    _tags = List.of(widget.plant.tags);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addTag() {
    final text = _controller.text.trim();
    if (text.isEmpty || _tags.length >= 3) return;
    setState(() {
      _tags.add(PlantTag(text: text, color: _selectedColor));
      _controller.clear();
    });
  }

  void _save() {
    context.read<AppStore>().updatePlantTags(widget.plant.id, _tags);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return FrostedGlass(
      tint: AppColors.frostedTint,
      radius: const BorderRadius.vertical(top: Radius.circular(32)),
      height: MediaQuery.of(context).size.height * 0.58,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('给 ${widget.plant.name} 打标签',
              style: AppTypography.cardTitle.copyWith(fontSize: 18)),
          const SizedBox(height: 4),
          Text('最多 3 个标签，会斜着挂在植物图片上',
              style: AppTypography.caption),
          const SizedBox(height: 20),
          // 当前标签
          if (_tags.isNotEmpty) ...[
            Wrap(
              spacing: 10,
              children: _tags
                  .asMap()
                  .entries
                  .map((e) => _buildTagChip(e.value, e.key))
                  .toList(),
            ),
            const SizedBox(height: 20),
          ],
          // 新增输入
          if (_tags.length < 3) ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    maxLength: 6,
                    decoration: InputDecoration(
                      hintText: '例如：开心、新手、缺水',
                      hintStyle: TextStyle(
                          fontFamily: 'NunitoSans', color: AppColors.textHint),
                      filled: true,
                      fillColor: AppColors.softCard,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: AppTypography.body,
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _addTag,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // 颜色选择
            Text('标签颜色', style: AppTypography.label),
            const SizedBox(height: 10),
            Row(
              children: _presetColors.map((c) => _buildColorDot(c)).toList(),
            ),
          ],
          const Spacer(),
          GestureDetector(
            onTap: _save,
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: const Text('保存标签',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'NunitoSans',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip(PlantTag tag, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Color(tag.color).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(tag.color).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(tag.text,
              style: TextStyle(
                  fontFamily: 'NunitoSans',
                  fontWeight: FontWeight.w600,
                  color: Color(tag.color))),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => setState(() => _tags.removeAt(index)),
            child: Icon(Icons.close, size: 14, color: Color(tag.color)),
          ),
        ],
      ),
    );
  }

  Widget _buildColorDot(int color) {
    final selected = _selectedColor == color;
    return GestureDetector(
      onTap: () => setState(() => _selectedColor = color),
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: Color(color),
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppColors.textPrimary : Colors.transparent,
            width: 2,
          ),
          boxShadow: selected
              ? [BoxShadow(color: Color(color).withValues(alpha: 0.4), blurRadius: 8)]
              : null,
        ),
      ),
    );
  }
}
