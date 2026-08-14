import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../widgets/frosted.dart';
import '../widgets/radar_sweep.dart';
import '../widgets/avatar_image.dart';
import '../models/plant.dart';
import '../store/app_store.dart';
import '../services/supabase_service.dart';
import '../services/weather_service.dart';
import 'chat_screen.dart';

enum _LocationSource { gps, lastKnown, ip, manualWeather, beijing, denied }

/// Screen 6 - 附近植友
/// showBack: true 时显示返回按钮 (push 路由), false 时作为 Tab 内容
class NearbyScreen extends StatefulWidget {
  final bool showBack;

  const NearbyScreen({super.key, this.showBack = false});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  // 未接入 Supabase 时保留原有示例数据，保证本地体验不受影响
  final List<NearbyUser> _users =
      SupabaseService.isInitialized ? [] : NearbyUser.sampleUsers;
  NearbyUser? _selectedUser;
  int _range = 5; // 搜索半径（km）：默认 5km，覆盖 IP 定位 3km 级误差
  bool _loading = false;
  String? _error;
  String? _locationHint; // 定位提示文案（null 表示无需提示）

  // 定位来源：用于决定提示文案与兜底策略
  _LocationSource _locationSource = _LocationSource.beijing;

  @override
  void initState() {
    super.initState();
    if (SupabaseService.isInitialized) _loadNearby();
    // 昵称引导已搬到 onboarding_screen 最后一屏，此处不再弹窗
  }

  /// 引导完善昵称：未设置（默认"植友"）时弹窗输入，保存后即可被同城植友看到。
  Future<void> _maybeAskNickname() async {
    if (!SupabaseService.isInitialized) return;
    final n = await SupabaseService.fetchMyNickname();
    if (n != null || !mounted) return;
    final controller = TextEditingController();
    final name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FrostedGlass(
        tint: AppColors.frostedTint,
        radius: const BorderRadius.vertical(top: Radius.circular(28)),
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, 24 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 14),
            Text('给植友起个称呼',
                style: AppTypography.cardTitle.copyWith(fontSize: 16)),
            const SizedBox(height: 4),
            Text('起个昵称才能出现在附近页，让同城植友找到你',
                style: AppTypography.caption),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLength: 12,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '如：爱养花的阿绿',
                hintStyle: AppTypography.caption,
                isDense: true,
                filled: true,
                fillColor: AppColors.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => Navigator.pop(ctx, controller.text.trim()),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text('保存昵称',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: 'NunitoSans',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
    if (name != null && name.isNotEmpty && mounted) {
      final ok = await SupabaseService.updateMyNickname(name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok
                ? '昵称已保存，现在能被同城植友看到啦'
                : '昵称保存失败，请稍后再试'),
            backgroundColor: ok ? AppColors.primary : AppColors.danger,
          ),
        );
        _loadNearby();
      }
    }
  }

  /// 拉取真实附近植友：先定位 → 上报位置 → 调 nearby_users RPC
  Future<void> _loadNearby() async {
    if (!SupabaseService.isInitialized) return;
    setState(() {
      _loading = true;
      _error = null;
      _locationHint = null;
    });
    try {
      final result = await _locate();
      _locationSource = result.source;
      final queryPos = (result.lat, result.lon);

      // 方案 B：所有定位来源都上报（IP 兜底也写坐标），但非 GPS 来源给用户轻量警示
      if (_locationSource == _LocationSource.denied) {
        _locationHint = '需要定位权限才能发现附近植友，请在系统设置中允许定位权限。';
      } else if (_locationSource == _LocationSource.gps ||
                 _locationSource == _LocationSource.lastKnown) {
        _locationHint = null; // GPS 精准，不打扰用户
      } else {
        _locationHint = '位置信号弱，距离仅供参考。去阳台/窗边定位更准。';
      }

      final me = SupabaseService.client.auth.currentUser;
      // B 方案：所有定位来源都上报（IP/手动城市/北京兜底也写入，室内用户也能被看到）
      if (me != null) {
        try {
          await SupabaseService.client.rpc('report_location',
              params: {'my_lat': queryPos.$1, 'my_lng': queryPos.$2});
          // 植物墙：把自己的植物名（仅名称）同步到云端，公开给植友看
          final names = context
              .read<AppStore>()
              .plants
              .map((p) => p.name)
              .toList();
          await SupabaseService.syncMyPlantWall(names);
        } catch (_) {}
      }
      final res = await SupabaseService.client.rpc('nearby_users', params: {
        'my_lat': queryPos.$1,
        'my_lng': queryPos.$2,
        'radius_m': _range * 1000,
      });
      final list = (res as List)
          .map((e) => NearbyUser.fromNearby(e as Map<String, dynamic>))
          .where((u) => u.name != '植友') // 过滤未起昵称的测试残留/幽灵账号
          .toList();
      setState(() {
        _users
          ..clear()
          ..addAll(list);
        _error = null;
      });
    } catch (e) {
      setState(() => _error = '附近植友加载失败：$e');
    } finally {
      setState(() => _loading = false);
    }
  }

  /// 定位链路（按优先级）：
  /// 1. 上次缓存位置（getLastKnownPosition，无权限要求、最快）
  /// 2. GPS 当前位置（已授权的前提下）
  /// 3. 网络 IP 定位（ipapi.co，国内访问可能受限）
  /// 4. 用户在首页手动选择的城市（与天气共享）
  /// 5. 北京兜底
  Future<({double lat, double lon, _LocationSource source, String? city})>
      _locate() async {
    // 1. 权限检查
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) {
      return (
        lat: 39.9042,
        lon: 116.4074,
        source: _LocationSource.denied,
        city: '北京',
      );
    }

    // 2. 上次已知位置（最快，室内 GPS 拿不到时也能用）
    if (perm != LocationPermission.denied) {
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) {
          return (
            lat: last.latitude,
            lon: last.longitude,
            source: _LocationSource.lastKnown,
            city: null,
          );
        }
      } catch (_) {}

      // 3. 当前 GPS
      try {
        final p = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 20),
          ),
        );
        return (
          lat: p.latitude,
          lon: p.longitude,
          source: _LocationSource.gps,
          city: null,
        );
      } catch (_) {}
    }

    // 4. 网络 IP 兜底（免费服务，可能在国内受限，多源重试）
    final ipSources = [
      (
        url: Uri.parse('https://ipapi.co/json/'),
        parser: (Map<String, dynamic> j) => (
              (j['latitude'] as num?)?.toDouble(),
              (j['longitude'] as num?)?.toDouble(),
            ),
      ),
      (
        url: Uri.parse('https://ipinfo.io/json'),
        parser: (Map<String, dynamic> j) {
          final loc = (j['loc'] as String?)?.split(',');
          if (loc != null && loc.length == 2) {
            return (double.tryParse(loc[0]), double.tryParse(loc[1]));
          }
          return (null, null);
        },
      ),
    ];
    for (final s in ipSources) {
      try {
        final r = await http.get(s.url).timeout(const Duration(seconds: 6));
        if (r.statusCode == 200) {
          final j = jsonDecode(r.body) as Map<String, dynamic>;
          final (lat, lon) = s.parser(j);
          if (lat != null && lon != null) {
            return (
              lat: lat,
              lon: lon,
              source: _LocationSource.ip,
              city: null,
            );
          }
        }
      } catch (_) {}
    }

    // 5. 用户在天气页选择的城市
    try {
      final manual = await WeatherService.loadManualCity();
      if (manual != null) {
        return (
          lat: manual.lat,
          lon: manual.lon,
          source: _LocationSource.manualWeather,
          city: manual.name,
        );
      }
    } catch (_) {}

    // 6. 最终兜底
    return (
      lat: 39.9042,
      lon: 116.4074,
      source: _LocationSource.beijing,
      city: '北京',
    );
  }

  @override
  Widget build(BuildContext context) {
    // push 模式下没有底部 Tab 栏，卡片应贴底；Tab 模式下需避让悬浮 Tab 栏
    final cardBottom = widget.showBack ? 0.0 : AppSpacing.tabBarHeight;
    return Column(
      children: [
        _buildNavBar(),
        Expanded(
          child: Stack(
            children: [
              _buildMapArea(),
              Positioned(
                left: 0,
                right: 0,
                bottom: cardBottom,
                child: _selectedUser != null
                    ? _buildUserCard(_selectedUser!)
                    : _buildSummaryCard(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavBar() {
    return FrostedTopBar(
      title: '附近植友',
      leading: widget.showBack
          ? GestureDetector(
              onTap: () => Navigator.pop(context),
              behavior: HitTestBehavior.opaque,
              child: const SizedBox(
                width: 32,
                height: 32,
                child: Icon(Icons.chevron_left,
                    color: AppColors.primary, size: 28),
              ),
            )
          : null,
      trailing: GestureDetector(
        onTap: _loadNearby,
        behavior: HitTestBehavior.opaque,
        child: const SizedBox(
          width: 32,
          height: 32,
          child: Icon(Icons.refresh, color: AppColors.primary, size: 22),
        ),
      ),
    );
  }

  Widget _buildMapArea() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.bg,
      child: Stack(
        children: [
          CustomPaint(size: Size.infinite, painter: MapTerrainPainter()),
          LayoutBuilder(
            builder: (context, constraints) {
              final cx = constraints.maxWidth / 2;
              final cy = constraints.maxHeight / 2;
              return Stack(
                children: [
                  CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: DistanceRingPainter(cx, cy),
                  ),
                  // 中心用户
                  Positioned(
                    left: cx - 50,
                    top: cy + 10,
                    child: Column(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 12,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Text('你在这里',
                              style: TextStyle(
                                  fontFamily: 'NunitoSans',
                                  fontSize: 9,
                                  color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                  ..._buildUserMarkers(cx, cy),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _buildUserMarkers(double cx, double cy) {
    final positions = [
      Offset(cx - 95, cy - 100),
      Offset(cx + 58, cy + 40),
      Offset(cx - 139, cy + 105),
      Offset(cx + 100, cy - 120),
      Offset(cx - 60, cy + 160),
    ];
    return List.generate(_users.length, (i) {
      final user = _users[i];
      final pos = positions[i % positions.length];
      final isSelected = _selectedUser?.id == user.id;
      return Positioned(
        left: pos.dx - 22,
        top: pos.dy - 22,
        child: GestureDetector(
          onTap: () => setState(() => _selectedUser = user),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Color(user.avatarColor),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: isSelected ? 3 : 2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                              color: Color(user.avatarColor)
                                  .withValues(alpha: 0.4),
                              blurRadius: 12)
                        ]
                      : null,
                ),
                child: _buildPlantIcon(user.plantIcon),
              ),
              const SizedBox(height: 4),
              Text('${user.distance.round()}m', style: AppTypography.badge),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildPlantIcon(String icon) {
    IconData data = Icons.eco;
    if (icon == 'flower') data = Icons.local_florist;
    if (icon == 'sprout') data = Icons.grain;
    return Icon(data, color: Colors.white, size: 20);
  }

  /// 底部名片卡：雷达扫描 + 距离切换 + 横向错落瀑布卡
  Widget _buildSummaryCard() {
    final visible = _users.where((u) => u.distance <= _range * 1000).toList();
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusSheet)),
        boxShadow: AppColors.sheetShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              RadarSweep(size: 42),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('正在扫描附近植友',
                        style: AppTypography.cardTitle
                            .copyWith(color: AppColors.primary)),
                    const SizedBox(height: 2),
                    Text('点亮一盏灯，也许就遇见植友', style: AppTypography.caption),
                  ],
                ),
              ),
              _rangeToggle(),
            ],
          ),
          if (_locationHint != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _locationSource == _LocationSource.denied
                    ? AppColors.danger.withValues(alpha: 0.08)
                    : AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _locationSource == _LocationSource.denied
                        ? Icons.location_off
                        : Icons.info_outline,
                    size: 14,
                    color: _locationSource == _LocationSource.denied
                        ? AppColors.danger
                        : AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _locationHint!,
                      style: AppTypography.caption.copyWith(
                        fontSize: 12,
                        color: _locationSource == _LocationSource.denied
                            ? AppColors.danger
                            : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_error != null)
            _buildErrorHint()
          else if (visible.isEmpty)
            _buildNoNeighborHint()
          else
            SizedBox(
              // 与 _buildFriendCard 的固定高度保持一致，避免底部出现空白条
              height: _friendCardHeight,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                padding: const EdgeInsets.symmetric(vertical: 2),
                itemCount: visible.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (ctx, i) => _buildFriendCard(visible[i], i),
              ),
            ),
        ],
      ),
    );
  }

  /// 加载失败时的错误态（带重试）
  Widget _buildErrorHint() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.softCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off, size: 28, color: AppColors.danger),
          const SizedBox(height: 8),
          Text('出了点小问题', style: AppTypography.bodySemiBold),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(_error ?? '',
                style: AppTypography.caption, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _loadNearby,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text('重试',
                  style: TextStyle(
                      fontFamily: 'NunitoSans',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  /// 半径内暂时没人时的紧凑空态（不要留下整块空白）
  Widget _buildNoNeighborHint() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.softCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.travel_explore, size: 28, color: AppColors.textHint),
          const SizedBox(height: 8),
          Text('${_range}km 内还没有植友',
              style: AppTypography.bodySemiBold
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text('把范围调大一点，或者过会儿再来看看', style: AppTypography.caption),
        ],
      ),
    );
  }

  Widget _rangeToggle() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
          color: AppColors.softCard, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          _rangeChip('1km', 1),
          _rangeChip('2km', 2),
          _rangeChip('5km', 5),
          _rangeChip('10km', 10),
          _rangeChip('20km', 20),
        ],
      ),
    );
  }

  Widget _rangeChip(String label, int km) {
    final active = _range == km;
    return GestureDetector(
      onTap: () {
        setState(() => _range = km);
        if (SupabaseService.isInitialized) _loadNearby();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(label,
            style: TextStyle(
                fontFamily: 'NunitoSans',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : AppColors.textSecondary)),
      ),
    );
  }

  /// 植友卡固定高度。
  /// 原来按奇偶做 190/158 的「错落瀑布」，但在横向列表里 child 是顶对齐的，
  /// 矮卡片下方会露出参差的空档，看起来像布局出错。统一高度更干净。
  static const double _friendCardHeight = 176.0;

  /// 横向植友卡：距离 / 头像 / 名字 / 彩色药丸标签 / 迷你盆栽数
  Widget _buildFriendCard(NearbyUser u, int i) {
    const h = _friendCardHeight;
    final color = Color(u.avatarColor);
    return GestureDetector(
      onTap: () => setState(() => _selectedUser = u),
      child: Container(
        width: 150,
        height: h,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: AppColors.cardShadow,
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: AppColors.softCard,
                    borderRadius: BorderRadius.circular(10)),
                child: Text('${u.distance.round()}m',
                    style: const TextStyle(
                        fontFamily: 'NunitoSans',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
              ),
            ),
            Align(
              alignment: const Alignment(0, -0.12),
              child: AvatarImage(
                url: u.avatarUrl,
                plantIcon: u.plantIcon,
                color: color,
                size: 48,
              ),
            ),
            Positioned(
              top: 70,
              left: 0,
              right: 0,
              child: Text(u.name,
                  style: AppTypography.bodySemiBold,
                  textAlign: TextAlign.center),
            ),
            Positioned(
              top: 96,
              left: 0,
              right: 0,
              child: Center(child: _tagPill(u.tag)),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              child: GestureDetector(
                onTap: () => _sayHi(u),
                child: Text('打招呼',
                    style: TextStyle(
                        fontFamily: 'NunitoSans',
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600)),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Row(
                children: [
                  Icon(Icons.eco, size: 14, color: AppColors.secondary),
                  const SizedBox(width: 2),
                  Text('${u.plants.length}', style: AppTypography.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 专属标签 → 彩色小药丸（按关键词匹配主题色）
  static const Map<String, List<Color>> _tagColors = {
    '多肉': [Color(0xFFE9D5F5), Color(0xFF7E22CE)],
    '蕨': [Color(0xFFD1FAE5), Color(0xFF065F46)],
    '苔藓': [Color(0xFFCCFBF1), Color(0xFF0F766E)],
    '香草': [Color(0xFFFEF3C7), Color(0xFF92400E)],
    '阳台': [Color(0xFFFCE7F3), Color(0xFF9D174D)],
    '花园': [Color(0xFFFCE7F3), Color(0xFF9D174D)],
  };

  Widget _tagPill(String tag) {
    Color bg = const Color(0xFFDBEAFE);
    Color fg = const Color(0xFF1E40AF);
    for (final e in _tagColors.entries) {
      if (tag.contains(e.key)) {
        bg = e.value[0];
        fg = e.value[1];
        break;
      }
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(tag,
          style: TextStyle(
              fontFamily: 'NunitoSans',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg)),
    );
  }

  Widget _buildUserCard(NearbyUser user) {
    final color = Color(user.avatarColor);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusSheet)),
        boxShadow: AppColors.sheetShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          // 植友信息行
          Row(
            children: [
              AvatarImage(
                url: user.avatarUrl,
                plantIcon: user.plantIcon,
                color: color,
                size: 52,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(user.name,
                            style: AppTypography.bodySemiBold
                                .copyWith(fontSize: 17)),
                        const SizedBox(width: 8),
                        Text('${user.distance.round()}m',
                            style: AppTypography.caption
                                .copyWith(color: AppColors.secondary)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _tagPill(user.tag),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _sayHi(user),
                child: Container(
                  width: 64,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.waving_hand, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text('打招呼',
                          style: TextStyle(
                              fontFamily: 'NunitoSans',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 植友的植物墙：本地示例数据直接用 plants；真数据为空时拉云端公开植物墙
          if (user.plants.isNotEmpty) ...[
            Container(height: 1, color: AppColors.divider),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.eco, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text('${user.name}养护的 ${user.plants.length} 株植物',
                    style: AppTypography.label.copyWith(
                        fontWeight: FontWeight.w600, color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 130,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: user.plants.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) =>
                    _buildFriendPlantCard(user.plants[index], color),
              ),
            ),
          ] else
            FutureBuilder<List<String>>(
              future: SupabaseService.fetchUserPlantWall(user.serverId),
              builder: (context, snap) {
                final plants = snap.data ?? const <String>[];
                if (plants.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(Icons.eco, size: 14, color: AppColors.textHint),
                        const SizedBox(width: 6),
                        Text('TA 还没公开植物墙',
                            style: AppTypography.caption),
                      ],
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.eco, size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text('${user.name}养护的 ${plants.length} 株植物',
                            style: AppTypography.label.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final name in plants)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.softCard,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.eco,
                                    size: 12, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(name,
                                    style: AppTypography.caption.copyWith(
                                        fontSize: 12,
                                        color: AppColors.textPrimary)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.shield, size: 14, color: AppColors.textHint),
              const SizedBox(width: 6),
              Text('线下见面请选择公共场所，注意安全',
                  style: AppTypography.caption
                      .copyWith(fontSize: 11, color: AppColors.textHint)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFriendPlantCard(FriendPlant plant, Color accentColor) {
    final (statusIcon, statusColor) = switch (plant.healthStatus) {
      '健康' => (Icons.eco, AppColors.success),
      '需关注' => (Icons.warning_amber, AppColors.accent),
      _ => (Icons.help_outline, AppColors.textHint),
    };
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.softCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.eco, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(plant.name,
                    style: AppTypography.bodySemiBold.copyWith(fontSize: 13),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(plant.scientificName,
              style: AppTypography.caption
                  .copyWith(fontSize: 10, fontStyle: FontStyle.italic),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const Spacer(),
          Row(
            children: [
              Icon(statusIcon, size: 12, color: statusColor),
              const SizedBox(width: 3),
              Text(plant.healthStatus,
                  style: TextStyle(
                      fontFamily: 'NunitoSans',
                      fontSize: 10,
                      color: statusColor,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('${plant.careDays}天',
                  style: AppTypography.caption
                      .copyWith(fontSize: 10, color: AppColors.textHint)),
            ],
          ),
        ],
      ),
    );
  }

  /// 进入与某植友的对话页（统一入口：本地示例数据 / 真数据都跳到 ChatScreen）
  void _sayHi(NearbyUser user) {
    // 本地示例数据没有 serverId，没法发消息——给一个友好提示。
    if (!SupabaseService.isInitialized || user.serverId.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('向 ${user.name} 打招呼', style: AppTypography.cardTitle),
          content: Text(
              '${user.name}（${user.tag}）暂时还没在附近，刷新看看或退到窗边试试。\n\n接入真实后端后即可与他对话。',
              style: AppTypography.body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('好的', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatScreen(peer: user)),
    );
  }
}

/// 地形纹理画笔 (装饰性)
class MapTerrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(size.width * 0.13, size.height * 0.23),
          width: 120,
          height: 90),
      paint..color = AppColors.mapTerrain.withValues(alpha: 0.5),
    );
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(size.width * 0.85, size.height * 0.16),
          width: 100,
          height: 80),
      paint..color = AppColors.mapTerrain.withValues(alpha: 0.4),
    );
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(size.width * 0.08, size.height * 0.86),
          width: 110,
          height: 80),
      paint..color = const Color(0xFFD1FAE5).withValues(alpha: 0.4),
    );

    final roadPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFBBF7D0).withValues(alpha: 0.5);

    final path1 = Path();
    path1.moveTo(-10, size.height / 2);
    path1.quadraticBezierTo(
        size.width * 0.2, size.height * 0.43, size.width / 2, size.height / 2);
    path1.quadraticBezierTo(
        size.width * 0.8, size.height * 0.57, size.width + 10, size.height / 2);
    canvas.drawPath(path1, roadPaint);

    final path2 = Path();
    path2.moveTo(size.width / 2, -10);
    path2.quadraticBezierTo(
        size.width * 0.42, size.height * 0.23, size.width / 2, size.height / 2);
    path2.quadraticBezierTo(size.width * 0.58, size.height * 0.74,
        size.width / 2, size.height + 10);
    canvas.drawPath(path2, roadPaint..strokeWidth = 6);
  }

  @override
  bool shouldRepaint(covariant CustomPainter? oldDelegate) => false;
}

/// 距离环画笔
class DistanceRingPainter extends CustomPainter {
  final double cx;
  final double cy;
  DistanceRingPainter(this.cx, this.cy);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.mapRing.withValues(alpha: 0.5);

    canvas.drawCircle(Offset(cx, cy), 55, paint);
    canvas.drawCircle(Offset(cx, cy), 110,
        paint..color = AppColors.mapRing.withValues(alpha: 0.4));
    canvas.drawCircle(Offset(cx, cy), 170,
        paint..color = AppColors.mapRing.withValues(alpha: 0.3));

    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (final (label, r) in [('100m', 55), ('500m', 110), ('1km', 170)]) {
      tp.text = TextSpan(
          text: label,
          style: TextStyle(
              fontFamily: 'sans-serif', fontSize: 9, color: AppColors.mapRing));
      tp.layout();
      tp.paint(canvas, Offset(cx + r - 15, cy - r - 5));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter? oldDelegate) => false;
}
