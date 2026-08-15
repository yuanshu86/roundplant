import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

/// P3 后端接入封装：初始化 Supabase 客户端 + 匿名一键登录 + Realtime 消息订阅。
///
/// - URL 与 anon key 通过 `--dart-define` 在构建时注入，不写进源码、不进 git。
/// - 匿名登录：打开 App 自动登录，不填表、不打扰用户；之后可在「我的」补昵称。
/// - 未注入 key（或登录失败）时静默降级为纯本地模式，附近植友走空态，不影响其它功能。
class SupabaseService {
  /// 全局 Supabase 客户端；未初始化时访问会抛异常，调用方需先判断 [isInitialized]。
  static SupabaseClient get client => Supabase.instance.client;

  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  /// Realtime 订阅 messages 表 INSERT：返回 broadcast stream，所有订阅者都能收到新消息。
  /// - channel 只挂一次（首次调用时挂），channel 回调 add 到 broadcast controller。
  /// - 调用方用 .listen() 订阅 stream；自己负责在 dispose 时 cancel。
  static StreamController<Map<String, dynamic>>? _msgController;
  static RealtimeChannel? _msgChannel;
  static Stream<Map<String, dynamic>> onNewMessage() {
    final c = _msgController;
    if (c != null) return c.stream;
    final controller = StreamController<Map<String, dynamic>>.broadcast();
    _msgController = controller;
    final ch = client
        .channel('public:messages')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            final row = payload.newRecord;
            if (row.isNotEmpty && !controller.isClosed) {
              controller.add(row);
            }
          },
        )
        .subscribe();
    _msgChannel = ch;
    return controller.stream;
  }

  static Future<void> disposeMessageChannel() async {
    final ch = _msgChannel;
    if (ch == null) return;
    await client.removeChannel(ch);
    _msgChannel = null;
  }

  static Future<void> init() async {
    const url = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
    const anonKey =
        String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
    if (url.isEmpty || anonKey.isEmpty) {
      // 没注入凭证：保持纯本地模式，不阻断启动。
      return;
    }
    await Supabase.initialize(url: url, publishableKey: anonKey);
    _initialized = true;
    // 已登录则复用会话；否则匿名一键登录。
    final current = Supabase.instance.client.auth.currentSession;
    if (current == null) {
      try {
        await Supabase.instance.client.auth.signInAnonymously();
      } catch (_) {
        // 匿名登录失败（如网络问题）不致命，附近植友降级为空态。
      }
    }
  }

  /// 拉取与某用户的对话历史（最近 7 天内的消息，按时间正序）。
  static Future<List<Map<String, dynamic>>> fetchMessagesWith(String peerId) async {
    final me = client.auth.currentUser;
    if (me == null) return const [];
    try {
      final res = await client
          .from('messages')
          .select('id, sender_id, receiver_id, content, created_at')
          .or('and(sender_id.eq.${me.id},receiver_id.eq.$peerId),and(sender_id.eq.$peerId,receiver_id.eq.${me.id})')
          .gt('created_at', DateTime.now().toUtc().subtract(const Duration(days: 7)).toIso8601String())
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(res as List);
    } catch (_) {
      return const [];
    }
  }

  /// 发送一条文字消息给对方。
  static Future<bool> sendMessage({
    required String receiverId,
    required String content,
  }) async {
    final me = client.auth.currentUser;
    if (me == null) return false;
    final trimmed = content.trim();
    if (trimmed.isEmpty) return false;
    try {
      await client.from('messages').insert({
        'sender_id': me.id,
        'receiver_id': receiverId,
        'content': trimmed,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 未读消息数（7 天内、发给我的、还没读的）。
  /// 依赖 messages.read_at 列（见 supabase/schema.sql 的 alter 语句）。
  static Future<int> fetchUnreadCount() async {
    if (!isInitialized) return 0;
    final me = client.auth.currentUser;
    if (me == null) return 0;
    try {
      final res = await client
          .from('messages')
          .select('id')
          .eq('receiver_id', me.id)
          .isFilter('read_at', null)
          .gt(
            'created_at',
            DateTime.now()
                .toUtc()
                .subtract(const Duration(days: 7))
                .toIso8601String(),
          );
      return (res as List).length;
    } catch (_) {
      return 0;
    }
  }

  /// 标记"与某植友的对话"已读（对方发给我的未读消息全部置 read_at）。
  static Future<void> markPeerRead(String peerId) async {
    if (!isInitialized) return;
    final me = client.auth.currentUser;
    if (me == null) return;
    try {
      await client
          .from('messages')
          .update({'read_at': DateTime.now().toUtc().toIso8601String()})
          .eq('sender_id', peerId)
          .eq('receiver_id', me.id)
          .isFilter('read_at', null);
    } catch (_) {
      // 标记已读失败不致命（下次进对话再试）
    }
  }

  /// 取自己的微信号（未填返回 null）。
  static Future<String?> fetchMyWechat() async {
    final me = client.auth.currentUser;
    if (me == null) return null;
    try {
      final res = await client
          .from('profiles')
          .select('wechat')
          .eq('id', me.id)
          .maybeSingle();
      if (res == null) return null;
      final w = res['wechat'] as String?;
      return (w == null || w.isEmpty) ? null : w;
    } catch (_) {
      return null;
    }
  }

  /// 更新自己的微信号（传 null/空字符串表示清空）。
  static Future<bool> updateMyWechat(String? wechat) async {
    if (!isInitialized) return false;
    try {
      await client.rpc('set_my_wechat', params: {'my_wechat': wechat ?? ''});
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 取对方的微信号（对方未填返回 null）。
  static Future<String?> fetchUserWechat(String userId) async {
    if (!isInitialized) return null;
    try {
      final w = await client.rpc('get_user_wechat', params: {'target_id': userId});
      final s = (w as String?)?.trim();
      return (s == null || s.isEmpty) ? null : s;
    } catch (_) {
      return null;
    }
  }

  /// 同步自己的植物墙（仅植物名 JSON 数组，不暴露任何位置信息）。
  static Future<void> syncMyPlantWall(List<String> names) async {
    if (!isInitialized) return;
    final me = client.auth.currentUser;
    if (me == null) return;
    try {
      await client
          .from('profiles')
          .update({'plant_wall': jsonEncode(names)})
          .eq('id', me.id);
    } catch (_) {
      // 同步失败不致命，下次进附近页再试
    }
  }

  /// 取某植友公开的植物墙（植物名列表；未公开返回空表）。
  static Future<List<String>> fetchUserPlantWall(String userId) async {
    if (!isInitialized) return const [];
    try {
      final res = await client
          .from('profiles')
          .select('plant_wall')
          .eq('id', userId)
          .maybeSingle();
      if (res == null) return const [];
      final raw = res['plant_wall'] as String?;
      if (raw == null || raw.isEmpty) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }

  /// 取自己的昵称；未设置（默认"植友"）返回 null。
  static Future<String?> fetchMyNickname() async {
    if (!isInitialized) return null;
    final me = client.auth.currentUser;
    if (me == null) return null;
    try {
      final res = await client
          .from('profiles')
          .select('nickname')
          .eq('id', me.id)
          .maybeSingle();
      if (res == null) return null;
      final n = res['nickname'] as String?;
      return (n == null || n.isEmpty || n == '植友') ? null : n;
    } catch (_) {
      return null;
    }
  }

  /// 设置自己的昵称（附近页公开名，未起昵称不出现在附近）。
  static Future<bool> updateMyNickname(String nickname) async {
    if (!isInitialized) return false;
    final me = client.auth.currentUser;
    if (me == null) return false;
    final n = nickname.trim();
    if (n.isEmpty || n.length > 12) return false;
    try {
      await client
          .from('profiles')
          .update({
            'nickname': n,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', me.id);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 7 天内有对话的植友 profiles（用于"识花分享给植友"等场景，不依赖定位）。
  static Future<List<Map<String, dynamic>>> fetchRecentPeers() async {
    if (!isInitialized) return const [];
    final me = client.auth.currentUser;
    if (me == null) return const [];
    try {
      final msgs = await client
          .from('messages')
          .select('sender_id, receiver_id, created_at')
          .or('sender_id.eq.${me.id},receiver_id.eq.${me.id}')
          .gt(
            'created_at',
            DateTime.now()
                .toUtc()
                .subtract(const Duration(days: 7))
                .toIso8601String(),
          )
          .order('created_at', ascending: false);
      final peerIds = <String>{};
      for (final raw in (msgs as List).cast<Map<String, dynamic>>()) {
        final s = raw['sender_id'] as String?;
        final r = raw['receiver_id'] as String?;
        if (s == me.id) {
          if (r != null) peerIds.add(r);
        } else if (r == me.id) {
          if (s != null) peerIds.add(s);
        }
      }
      if (peerIds.isEmpty) return const [];
      final profiles = await client
          .from('profiles')
          .select('id, nickname, avatar_color, plant_icon, tag, avatar_url')
          .inFilter('id', peerIds.toList());
      return List<Map<String, dynamic>>.from(profiles as List);
    } catch (_) {
      return const [];
    }
  }

  /// 上传头像到 avatars 桶并回写 profiles.avatar_url，返回公开 URL（失败返回 null）。
  static Future<String?> uploadAvatar(File file) async {
    if (!isInitialized) return null;
    final me = client.auth.currentUser;
    if (me == null) return null;
    try {
      final path =
          '${me.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await client.storage.from('avatars').upload(path, file);
      final url = client.storage.from('avatars').getPublicUrl(path);
      await client.from('profiles').update({
        'avatar_url': url,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', me.id);
      return url;
    } catch (_) {
      return null;
    }
  }

  /// 取某用户的头像 URL（未设置返回 null）。
  static Future<String?> fetchUserAvatar(String userId) async {
    if (!isInitialized) return null;
    try {
      final res = await client
          .from('profiles')
          .select('avatar_url')
          .eq('id', userId)
          .maybeSingle();
      if (res == null) return null;
      final u = res['avatar_url'] as String?;
      return (u == null || u.isEmpty) ? null : u;
    } catch (_) {
      return null;
    }
  }
}