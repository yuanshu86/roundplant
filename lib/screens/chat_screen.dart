import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../services/supabase_service.dart';
import '../services/sensitive_words.dart';
import '../widgets/avatar_image.dart';
import '../models/plant.dart';

/// 与某植友的对话详情页
///
/// - 入口：附近页 → 打招呼按钮 → ChatScreen(peer)
/// - 7 天清理：只显示 7 天内的消息，超过自动从 UI 隐藏
/// - Realtime：监听 messages 表 INSERT，对方发来消息实时显示
/// - 加微信：对方填了 wechat 字段则显示，复制到剪贴板
class ChatScreen extends StatefulWidget {
  /// 对方用户信息（serverId 用于消息 receiver_id / sender_id）
  final NearbyUser peer;

  const ChatScreen({super.key, required this.peer});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<_Msg> _msgs = [];
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  StreamSubscription<Map<String, dynamic>>? _msgSub;
  Timer? _pollTimer;
  bool _loading = false;
  bool _sending = false;
  String? _peerWechat; // 对方的微信号，未填则为 null
  String? _myId; // 当前用户 uuid

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _msgSub?.cancel(); // Stream 订阅随页面销毁释放
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    if (!SupabaseService.isInitialized) return;
    _myId = SupabaseService.client.auth.currentUser?.id;
    setState(() => _loading = true);
    await _loadHistory();
    // 打开对话即标记已读（清掉对方发来的未读红点）
    unawaited(SupabaseService.markPeerRead(widget.peer.serverId));
    // 拉对方微信号（不阻塞 UI；找不到或失败就保持 null）
    unawaited(_loadPeerWechat());
    setState(() => _loading = false);
    // 订阅 Realtime stream（chat_screen 销毁时自动 cancel）
    _msgSub?.cancel();
    _msgSub = SupabaseService.onNewMessage().listen(_onNewMessage);
    // 轮询兜底：每 3 秒拉一次最新消息（WebSocket 不可靠时的双保险）
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _poll());
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _poll() {
    if (!mounted) return;
    SupabaseService.fetchMessagesWith(widget.peer.serverId).then((list) {
      if (!mounted) return;
      final existing = _msgs.map((m) => m.id).toSet();
      bool added = false;
      for (final r in list) {
        final m = _Msg.fromRow(r);
        if (existing.add(m.id)) {
          _msgs.add(m);
          added = true;
        }
      }
      if (added) setState(() {});
    });
  }

  Future<void> _loadHistory() async {
    final list = await SupabaseService.fetchMessagesWith(widget.peer.serverId);
    _msgs
      ..clear()
      ..addAll(list.map(_Msg.fromRow));
    if (mounted) setState(() {});
  }

  Future<void> _loadPeerWechat() async {
    final w = await SupabaseService.fetchUserWechat(widget.peer.serverId);
    if (!mounted) return;
    setState(() => _peerWechat = w);
  }

  void _onNewMessage(Map<String, dynamic> row) {
    // 只关心和当前 peer 之间的消息
    final s = row['sender_id'] as String?;
    final r = row['receiver_id'] as String?;
    if (s == null || r == null) return;
    final peer = widget.peer.serverId;
    final my = _myId;
    if (my == null) return;
    final isBetween = (s == peer && r == my) || (s == my && r == peer);
    if (!isBetween) return;
    final msg = _Msg.fromRow(row);
    if (_msgs.any((m) => m.id == msg.id)) return; // 防重
    setState(() => _msgs.add(msg));
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _send() async {
    if (_sending) return;
    final txt = _input.text.trim();
    if (txt.isEmpty) return;
    // 敏感词过滤（公安安全评估「内容审核机制」的实据）
    final bad = SensitiveWords.firstHit(txt);
    if (bad != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('内容包含敏感词，请文明交流'),
          backgroundColor: AppColors.accent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() => _sending = true);
    final ok = await SupabaseService.sendMessage(
      receiverId: widget.peer.serverId,
      content: txt,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (ok) {
      _input.clear();
      // Realtime 会自己回灌，UI 也会刷新；保险起见手动滚到底
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } else {
      // 发送失败：输入内容保留，浮层提供「重试」按钮
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('发送失败，网络开小差了'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: '重试',
            textColor: Colors.white,
            onPressed: _send,
          ),
        ),
      );
    }
  }

  void _scrollToBottom() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent + 80,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  Future<void> _copyWechat() async {
    final w = _peerWechat;
    if (w == null) return;
    await Clipboard.setData(ClipboardData(text: w));
    if (!mounted) return;
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已复制微信号：$w'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final peer = widget.peer;
    final avatar = Color(peer.avatarColor);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          behavior: HitTestBehavior.opaque,
          child: const Icon(Icons.chevron_left, color: AppColors.primary, size: 28),
        ),
        title: Row(
          children: [
            AvatarImage(
              url: widget.peer.avatarUrl,
              plantIcon: widget.peer.plantIcon,
              color: avatar,
              size: 32,
            ),
            const SizedBox(width: 8),
            Text(peer.name, style: AppTypography.cardTitle),
          ],
        ),
        actions: [
          if (_peerWechat != null)
            GestureDetector(
              onTap: _copyWechat,
              behavior: HitTestBehavior.opaque,
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chat_bubble_outline,
                        size: 14, color: AppColors.primaryText),
                    const SizedBox(width: 4),
                    Text('加微信',
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
        child: Column(
          children: [
            // 7 天提示条（始终可见，告知用户聊天记录会被清理）
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: AppColors.primary.withValues(alpha: 0.06),
              child: Row(
                children: [
                  Icon(Icons.timer_outlined,
                      size: 14, color: AppColors.primaryText),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '匿名对话，仅文字，聊天记录 7 天后自动清理',
                      style: AppTypography.caption.copyWith(
                        fontSize: 11,
                        color: AppColors.primaryText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : _msgs.isEmpty
                      ? _buildEmpty()
                      : ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          itemCount: _msgs.length,
                          itemBuilder: (ctx, i) {
                            final m = _msgs[i];
                            final mine = m.senderId == _myId;
                            return _buildBubble(m, mine, avatar);
                          },
                        ),
            ),
            _buildQuickGreetings(),
            _buildInput(),
          ],
        ),
      ),
    );
  }

  /// 一键破冰快捷语：点击填入输入框（可编辑后再发），降低新用户开口门槛
  static const List<String> _greetings = [
    '你好呀，同城植友',
    '你养的是什么植物呀？',
    '周末一起去逛花市吗？',
    '我家薄荷又该浇水了',
  ];

  Widget _buildQuickGreetings() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        itemCount: _greetings.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final g = _greetings[i];
          return GestureDetector(
            onTap: () {
              _input.text = g;
              _input.selection = TextSelection.collapsed(offset: g.length);
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.softCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                g,
                style: AppTypography.caption.copyWith(
                  fontSize: 12,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.forum_outlined, size: 40, color: AppColors.textHint),
          const SizedBox(height: 10),
          Text('还没有对话', style: AppTypography.bodySemiBold.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text('发条招呼开始聊天吧', style: AppTypography.caption),
        ],
      ),
    );
  }

  Widget _buildBubble(_Msg m, bool mine, Color peerColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!mine)
            AvatarImage(
              url: widget.peer.avatarUrl,
              plantIcon: widget.peer.plantIcon,
              color: peerColor,
              size: 28,
            ),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.66,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: mine ? AppColors.primary : AppColors.cardWhite,
                borderRadius: BorderRadius.circular(14),
                border: mine
                    ? null
                    : Border.all(color: AppColors.border),
              ),
              child: Text(
                m.content,
                style: TextStyle(
                  fontFamily: 'NunitoSans',
                  fontSize: 14,
                  color: mine ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ),
          if (mine)
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(left: 8),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.eco, color: Colors.white, size: 14),
            ),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        8 + MediaQuery.of(context).viewPadding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _input,
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: '发条消息…',
                hintStyle: AppTypography.caption,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                filled: true,
                fillColor: AppColors.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sending ? null : _send,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: _sending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white)),
                    )
                  : const Text('发送',
                      style: TextStyle(
                          fontFamily: 'NunitoSans',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

/// 单条消息（UI 内部用，避免引入新 model 类）
class _Msg {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime createdAt;

  _Msg({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.createdAt,
  });

  factory _Msg.fromRow(Map<String, dynamic> r) {
    DateTime ts;
    try {
      ts = DateTime.parse(r['created_at'] as String).toLocal();
    } catch (_) {
      ts = DateTime.now();
    }
    return _Msg(
      id: (r['id'] ?? '') as String,
      senderId: (r['sender_id'] ?? '') as String,
      receiverId: (r['receiver_id'] ?? '') as String,
      content: (r['content'] ?? '') as String,
      createdAt: ts,
    );
  }
}

void unawaited(Future<void> _) {}