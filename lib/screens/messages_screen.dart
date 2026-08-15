import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../services/supabase_service.dart';
import '../widgets/avatar_image.dart';
import '../models/plant.dart';
import 'chat_screen.dart';
import 'nearby_screen.dart';

/// 消息 Tab 页 —— 列出所有聊过天的植友（按最近一条消息排序）
/// 右上角"附近"按钮跳附近地图页
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List<_ConvSummary> _convs = [];
  bool _loading = false;
  String? _myId;
  StreamSubscription<Map<String, dynamic>>? _msgSub;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    if (SupabaseService.isInitialized) {
      _myId = SupabaseService.client.auth.currentUser?.id;
      _load();
      // 任意一条新消息来都刷新列表（避免错过无人提醒）
      _msgSub = SupabaseService.onNewMessage().listen((_) {
        if (mounted) _load();
      });
      // 轮询兜底：每 5 秒拉一次（WebSocket 不可靠时的双保险）
      _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (mounted) _load();
      });
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _msgSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (!SupabaseService.isInitialized) return;
    setState(() => _loading = true);
    final myId = _myId;
    if (myId == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      // 拉 7 天内与自己相关的所有消息
      final cutoff = DateTime.now().toUtc()
          .subtract(const Duration(days: 7))
          .toIso8601String();
      final msgs = await SupabaseService.client
          .from('messages')
          .select('sender_id, receiver_id, content, created_at')
          .or('sender_id.eq.$myId,receiver_id.eq.$myId')
          .gt('created_at', cutoff)
          .order('created_at', ascending: false);

      // 按 peer_id 分组，每组只保留最新一条
      final grouped = <String, Map<String, dynamic>>{};
      for (final raw in (msgs as List).cast<Map<String, dynamic>>()) {
        final peer = raw['sender_id'] == myId ? raw['receiver_id'] : raw['sender_id'];
        if (peer == null) continue;
        grouped.putIfAbsent(peer, () => raw);
      }

      // 拉对方 profiles
      final peerIds = grouped.keys.toList();
      if (peerIds.isEmpty) {
        setState(() {
          _convs = [];
          _loading = false;
        });
        return;
      }
      final profiles = await SupabaseService.client
          .from('profiles')
          .select('id, nickname, avatar_color, plant_icon, tag')
          .inFilter('id', peerIds);
      final pMap = {
        for (final p in (profiles as List).cast<Map<String, dynamic>>())
          p['id']: p,
      };

      // 组装结果
      final list = <_ConvSummary>[];
      for (final e in grouped.entries) {
        final p = pMap[e.key];
        list.add(_ConvSummary(
          peerId: e.key,
          peerName: (p?['nickname'] as String?)?.isNotEmpty == true
              ? p!['nickname'] as String
              : '植友',
          avatarColor:
              NearbyUserFactory.parseColor(p?['avatar_color'] as String?),
          avatarUrl: (p?['avatar_url'] as String?)?.isNotEmpty == true
              ? p!['avatar_url'] as String
              : null,
          plantIcon: (p?['plant_icon'] as String?) ?? 'leaf',
          tag: (p?['tag'] as String?) ?? '养花爱好者',
          lastContent: e.value['content'] as String? ?? '',
          lastAt: DateTime.parse(e.value['created_at'] as String).toLocal(),
        ));
      }
      // 按时间倒序（grouped 已按 desc 排，遍历顺序天然有序）
      if (mounted) {
        setState(() {
          _convs = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('消息', style: AppTypography.cardTitle),
        actions: [
          // 右上角"附近"按钮 → 进附近地图页
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NearbyScreen(showBack: true)),
            ),
            behavior: HitTestBehavior.opaque,
            child: Container(
              margin: const EdgeInsets.only(right: 14),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.explore_outlined,
                      size: 14, color: AppColors.primaryText),
                  const SizedBox(width: 4),
                  Text('附近',
                      style: TextStyle(
                          fontFamily: 'NunitoSans',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryText)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: !SupabaseService.isInitialized
            ? _buildOffline()
            : _loading && _convs.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _convs.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: _load,
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: _convs.length,
                          separatorBuilder: (_, __) =>
                              Divider(height: 1, color: AppColors.border, indent: 76),
                          itemBuilder: (ctx, i) => _buildConvItem(_convs[i]),
                        ),
                      ),
      ),
    );
  }

  Widget _buildOffline() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_outlined, size: 40, color: AppColors.textHint),
          const SizedBox(height: 10),
          Text('未接入云端', style: AppTypography.bodySemiBold.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text('附近植友功能需要 Supabase 凭证', style: AppTypography.caption),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.forum_outlined, size: 56, color: AppColors.textHint),
              const SizedBox(height: 14),
              Text('还没有对话',
                  style: AppTypography.bodySemiBold.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text('点右上角"附近"看看同城植友，向心仪的植友打个招呼开始聊天～',
                    textAlign: TextAlign.center,
                    style: AppTypography.caption),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const NearbyScreen(showBack: true)),
                ),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: AppColors.buttonShadow,
                  ),
                  child: const Text(
                    '去附近找植友',
                    style: TextStyle(
                      fontFamily: 'NunitoSans',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConvItem(_ConvSummary c) {
    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              peer: NearbyUser(
                id: c.peerId,
                serverId: c.peerId,
                name: c.peerName,
                avatarColor: c.avatarColor,
                plantIcon: c.plantIcon,
                distance: 0,
                tag: c.tag,
              ),
            ),
          ),
        );
        // 从对话返回时刷新一次列表（消息预览可能变化）
        _load();
      },
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            AvatarImage(
              url: c.avatarUrl,
              plantIcon: c.plantIcon,
              color: Color(c.avatarColor),
              size: 44,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(c.peerName,
                            style: AppTypography.bodySemiBold, overflow: TextOverflow.ellipsis),
                      ),
                      Text(_fmtTime(c.lastAt),
                          style: AppTypography.caption
                              .copyWith(fontSize: 11, color: AppColors.textHint)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(c.lastContent,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String name) {
    switch (name) {
      case 'flower':
        return Icons.local_florist;
      case 'sprout':
        return Icons.grain;
      case 'seedling':
        return Icons.eco;
      case 'rose':
        return Icons.local_florist;
      default:
        return Icons.eco;
    }
  }

  String _fmtTime(DateTime t) {
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
    if (diff.inDays < 1) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${t.month}/${t.day} ${pad(t.hour)}:${pad(t.minute)}';
  }
}

/// 单条对话摘要
class _ConvSummary {
  final String peerId;
  final String peerName;
  final int avatarColor;
  final String? avatarUrl;
  final String plantIcon;
  final String tag;
  final String lastContent;
  final DateTime lastAt;

  _ConvSummary({
    required this.peerId,
    required this.peerName,
    required this.avatarColor,
    this.avatarUrl,
    required this.plantIcon,
    required this.tag,
    required this.lastContent,
    required this.lastAt,
  });
}

/// 解析十六进制颜色（从 plant.dart 拆出来，避免循环 import）
class NearbyUserFactory {
  static int parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return 0xFF059669;
    final v = int.tryParse(hex.replaceFirst('#', ''), radix: 16);
    return v == null ? 0xFF059669 : (v | 0xFF000000);
  }
}