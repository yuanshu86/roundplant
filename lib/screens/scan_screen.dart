import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../models/plant.dart';
import '../store/app_store.dart';
import '../config/app_config.dart';

/// 单条识别候选
class PlantMatch {
  final String name;
  final String scientificName;
  final double score;
  final String family;

  PlantMatch({
    required this.name,
    required this.scientificName,
    required this.score,
    this.family = '',
  });

  factory PlantMatch.fromJson(Map<String, dynamic> j) => PlantMatch(
        name: (j['name'] as String?) ?? '未知植物',
        scientificName: (j['scientificName'] as String?) ?? '',
        score: (j['score'] is num ? (j['score'] as num).toDouble() : 0.0),
        family: (j['family'] as String?) ?? '',
      );
}

/// Screen 3 - AI 识别 (Push Route)
/// 真实流程：拍照/选图 → 上传到咱们自己的后端代理 → 代理调 Pl@ntNet → 返回候选 → 一键加植物
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _isScanning = false;
  bool _hasResult = false;
  String? _error;
  List<PlantMatch> _matches = [];

  final ImagePicker _picker = ImagePicker();

  Future<void> _capture(ImageSource source) async {
    if (_isScanning) return;
    final granted = await _ensurePermission(source);
    if (!granted) return;
    final XFile? file = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1024,
    );
    if (file == null) return;
    await _identify(file);
  }

  /// 打开相机/相册前先请求权限；被永久拒绝则引导去系统设置开启
  Future<bool> _ensurePermission(ImageSource source) async {
    final perm =
        source == ImageSource.camera ? Permission.camera : Permission.photos;
    PermissionStatus status = await perm.status;
    if (status.isGranted) return true;

    status = await perm.request();
    if (status.isGranted) return true;

    if (status.isPermanentlyDenied || status.isRestricted) {
      _showOpenSettingsDialog(perm);
      return false;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('需要${_permLabel(perm)}权限才能'
              '${source == ImageSource.camera ? "拍照" : "选择图片"}'),
        ),
      );
    }
    return false;
  }

  String _permLabel(Permission p) => p == Permission.camera ? '相机' : '相册';

  void _showOpenSettingsDialog(Permission perm) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('需要${_permLabel(perm)}权限'),
        content: Text('${_permLabel(perm)}权限已被永久拒绝，'
            '请到系统设置中手动开启后重试。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('去设置'),
          ),
        ],
      ),
    );
  }

  Future<void> _identify(XFile file) async {
    setState(() {
      _isScanning = true;
      _hasResult = false;
      _error = null;
      _matches = [];
    });
    try {
      final bytes = await file.readAsBytes();
      final ext = file.path.split('.').last.toLowerCase();
      final subtype = (ext == 'png') ? 'png' : 'jpeg';

      final req = http.MultipartRequest('POST', Uri.parse(AppConfig.identifyUrl));
      req.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: 'plant.$ext',
          contentType: MediaType('image', subtype),
        ),
      );

      final streamed = await req.send().timeout(const Duration(seconds: 25));
      final resp = await http.Response.fromStream(streamed);

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final list = (data['results'] as List? ?? [])
              .map((e) => PlantMatch.fromJson(e as Map<String, dynamic>))
              .toList();
          setState(() {
            _matches = list;
            _hasResult = list.isNotEmpty;
            if (list.isEmpty) _error = '没能认出这株植物，换个角度或光线再试一次～';
          });
        } else {
          setState(() => _error = data['error']?.toString() ?? '识别失败');
        }
      } else {
        setState(() => _error = '服务异常 (${resp.statusCode})');
      }
    } on TimeoutException catch (_) {
      setState(() => _error = '识别超时，请检查网络或稍后再试');
    } on SocketException catch (_) {
      setState(() => _error = '网络连接失败，请检查网络权限或稍后重试');
    } catch (e) {
      debugPrint('AI 识别异常: $e');
      setState(() => _error = '网络错误 (${e.runtimeType})');
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  void _addPlant(PlantMatch m) {
    final now = DateTime.now();
    final newPlant = Plant(
      id: const Uuid().v4(),
      name: m.name,
      scientificName: m.scientificName,
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
        content: Text('${m.name} 已添加到我的植物'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: AppColors.scanBg,
        child: SafeArea(
          top: true,
          bottom: false,
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
            child: const SizedBox(
              width: 32,
              height: 32,
              child: Icon(Icons.close, color: Colors.white, size: 24),
            ),
          ),
          Text('AI 识别',
              style: AppTypography.pageTitle.copyWith(color: Colors.white)),
          GestureDetector(
            onTap: () {},
            child: const SizedBox(
              width: 32,
              height: 32,
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
            width: 260,
            height: 260,
            child: Stack(
              children: [
                ..._buildCorners(),
                if (!_hasResult && _error == null)
                  Center(
                    child: _isScanning
                        ? const SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : Icon(Icons.eco,
                            size: 80,
                            color: Colors.white.withValues(alpha: 0.2)),
                  ),
              ],
            ),
          ),
        ),
        if (_hasResult) _buildResultPanel(),
        if (_error != null && !_isScanning) _buildErrorPanel(),
        if (!_hasResult && _error == null)
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                _isScanning ? '识别中...' : '拍照或从相册选一张植物照片',
                style: TextStyle(
                  fontFamily: 'NunitoSans',
                  fontSize: 14,
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
      Positioned(
        top: 0,
        left: 0,
        child: Container(
          width: s,
          height: s,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(width: w, color: c),
              left: BorderSide(width: w, color: c),
            ),
            borderRadius: BorderRadius.only(topLeft: Radius.circular(8)),
          ),
        ),
      ),
      Positioned(
        top: 0,
        right: 0,
        child: Container(
          width: s,
          height: s,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(width: w, color: c),
              right: BorderSide(width: w, color: c),
            ),
            borderRadius: BorderRadius.only(topRight: Radius.circular(8)),
          ),
        ),
      ),
      Positioned(
        bottom: 0,
        left: 0,
        child: Container(
          width: s,
          height: s,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(width: w, color: c),
              left: BorderSide(width: w, color: c),
            ),
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(8)),
          ),
        ),
      ),
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          width: s,
          height: s,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(width: w, color: c),
              right: BorderSide(width: w, color: c),
            ),
            borderRadius: BorderRadius.only(bottomRight: Radius.circular(8)),
          ),
        ),
      ),
    ];
  }

  Widget _buildResultPanel() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.55),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text('识别成功 · 选一株添加',
                    style: AppTypography.bodySemiBold
                        .copyWith(color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _matches.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final m = _matches[i];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.softCard,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
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
                              Text(m.name,
                                  style: AppTypography.bodySemiBold
                                      .copyWith(fontSize: 16)),
                              if (m.scientificName.isNotEmpty)
                                Text(m.scientificName,
                                    style: AppTypography.caption
                                        .copyWith(fontStyle: FontStyle.italic)),
                              const SizedBox(height: 2),
                              Text('匹配度 ${(m.score * 100).toInt()}%',
                                  style: AppTypography.caption
                                      .copyWith(color: AppColors.primary)),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _addPlant(m),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('添加',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorPanel() {
    return Positioned(
      bottom: 40,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        ),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: Colors.orange, size: 28),
            const SizedBox(height: 8),
            Text(_error ?? '出错了',
                style: AppTypography.caption
                    .copyWith(color: Colors.black87, fontSize: 14),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _capture(ImageSource.camera),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('重新拍照',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
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
            onTap: () => _capture(ImageSource.gallery),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.photo_library, color: Colors.white, size: 24),
            ),
          ),
          GestureDetector(
            onTap: () => _capture(ImageSource.camera),
            child: Container(
              width: 72,
              height: 72,
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
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  Icon(Icons.flip_camera_ios, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}
