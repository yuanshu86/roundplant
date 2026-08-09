import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';

/// 「更新通知」页：展示版本更新内容，支持留言反馈
class ChangelogScreen extends StatefulWidget {
  const ChangelogScreen({super.key});

  @override
  State<ChangelogScreen> createState() => _ChangelogScreenState();
}

class _ChangelogScreenState extends State<ChangelogScreen> {
  List<Map<String, dynamic>> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    try {
      final raw = await rootBundle.loadString('assets/changelog.json');
      final list = jsonDecode(raw) as List<dynamic>;
      setState(() {
        _logs = list.cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _logs = [
          {
            'version': '1.0.0',
            'date': '2026-08-09',
            'title': 'AI 识花正式上线',
            'items': ['数据加载失败，请检查 assets/changelog.json']
          }
        ];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.isDark ? AppColors.frostedTintDark : AppColors.frostedTint,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text('更新通知', style: AppTypography.cardTitle),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              itemCount: _logs.length,
              itemBuilder: (context, index) => _buildVersionCard(_logs[index]),
            ),
    );
  }

  Widget _buildVersionCard(Map<String, dynamic> log) {
    final items = (log['items'] as List<dynamic>?)?.cast<String>() ?? [];
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.itemGap),
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('v${log['version']}', style: AppTypography.bodySemiBold.copyWith(
                  color: AppColors.primary, fontSize: 13,
                )),
              ),
              const SizedBox(width: 8),
              Text('${log['date']}', style: AppTypography.badge),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text('${log['title']}', style: AppTypography.bodySemiBold),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(item, style: AppTypography.body)),
              ],
            ),
          )),
          const SizedBox(height: 12),
          _buildFeedbackButton(),
        ],
      ),
    );
  }

  Widget _buildFeedbackButton() {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('留言功能开发中，后续版本将支持直接反馈到官网')),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.feedback_outlined, size: 18, color: AppColors.textHint),
            const SizedBox(width: 6),
            Text('对这次更新有意见？留言告诉我们', style: AppTypography.caption.copyWith(
              color: AppColors.textHint,
            )),
          ],
        ),
      ),
    );
  }
}
