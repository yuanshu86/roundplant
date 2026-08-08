import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/plant.dart';
import '../store/app_store.dart';

/// Screen 3 - AI 识别 (Push Route)
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _isScanning = false;
  bool _hasResult = false;

  // 模拟识别结果库
  static const _results = [
    ('龟背竹', 'Monstera deliciosa'),
    ('绿萝', 'Epipremnum aureum'),
    ('琴叶榕', 'Ficus lyrata'),
    ('白桃星美人', 'Pachyphytum oviferum'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: AppColors.scanBg,
        child: SafeArea(
          top: true, bottom: false,
          child: Column(
            children: [
              _buildNavBar(),
              Expanded(child: _buildScanArea()),
              _buildCameraControls(),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildNavBar() {
    return Container(
      height: AppSpacing.navBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: SizedBox(
              width: 32, height: 32,
              child: Icon(Icons.close, color: Colors.white, size: 24),
            ),
          ),
          Text('AI 识别',
            style: AppTypography.pageTitle.copyWith(color: Colors.white)),
          GestureDetector(
            onTap: () {},
            child: SizedBox(
              width: 32, height: 32,
              child: Icon(Icons.flash_off, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanArea() {
    return Stack(
      children: [
        Center(
          child: Container(
            width: 260, height: 260,
            child: Stack(
              children: [
                ..._buildCorners(),
                if (!_hasResult)
                  Center(
                    child: _isScanning
                        ? const SizedBox(
                            width: 40, height: 40,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : Icon(Icons.eco, size: 80,
                            color: Colors.white.withValues(alpha: 0.2)),
                  ),
              ],
            ),
          ),
        ),
        if (_hasResult) _buildResultPanel(),
        if (!_hasResult)
          Positioned(
            bottom: 40, left: 0, right: 0,
            child: Center(
              child: Text(
                _isScanning ? '识别中...' : '将植物放入框内识别',
                style: TextStyle(
                  fontFamily: 'NunitoSans', fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildCorners() {
    const s = 28.0;
    const w = 3.0;
    const c = Colors.white;
    return [
      Positioned(top: 0, left: 0,
        child: Container(width: s, height: s,
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(width: w, color: c), left: BorderSide(width: w, color: c)),
            borderRadius: BorderRadius.only(topLeft: Radius.circular(8)),
          ))),
      Positioned(top: 0, right: 0,
        child: Container(width: s, height: s,
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(width: w, color: c), right: BorderSide(width: w, color: c)),
            borderRadius: BorderRadius.only(topRight: Radius.circular(8)),
          ))),
      Positioned(bottom: 0, left: 0,
        child: Container(width: s, height: s,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(width: w, color: c), left: BorderSide(width: w, color: c)),
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(8)),
          ))),
      Positioned(bottom: 0, right: 0,
        child: Container(width: s, height: s,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(width: w, color: c), right: BorderSide(width: w, color: c)),
            borderRadius: BorderRadius.only(bottomRight: Radius.circular(8)),
          ))),
    ];
  }

  Widget _buildResultPanel() {
    final result = _results[0]; // v1 固定返回龟背竹
    return Positioned(
      bottom: 40, left: 20, right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text('识别成功 · 置信度 98%',
                  style: AppTypography.bodySemiBold.copyWith(color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.softCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.eco, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(result.$1, style: AppTypography.bodySemiBold.copyWith(fontSize: 16)),
                        Text(result.$2,
                          style: AppTypography.caption.copyWith(fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      final now = DateTime.now();
                      final newPlant = Plant(
                        id: const Uuid().v4(),
                        name: result.$1,
                        scientificName: result.$2,
                        healthStatus: '健康',
                        wateringFrequency: 7,
                        lastWatered: now,
                        nextWatering: now.add(const Duration(days: 7)),
                        fertilizingFrequency: 14,
                        lastFertilized: now,
                        nextFertilizing: now.add(const Duration(days: 14)),
                        pruningFrequency: 30,
                        lastPruned: now,
                        nextPruning: now.add(const Duration(days: 30)),
                        lightRequirement: '明亮散射光',
                        temperatureRange: '18-28°C',
                        humidityRange: '60-80%',
                      );
                      context.read<AppStore>().addPlant(newPlant);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${result.$1} 已添加到我的植物'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('添加', style: TextStyle(
                        color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraControls() {
    return Container(
      height: 120,
      padding: const EdgeInsets.only(bottom: 34),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.photo_library, color: Colors.white, size: 24),
            ),
          ),
          GestureDetector(
            onTap: _startScan,
            child: Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.flip_camera_ios, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  void _startScan() {
    setState(() => _isScanning = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _hasResult = true;
        });
      }
    });
  }
}
