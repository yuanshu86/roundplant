import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// 本地养护提醒服务
/// 设计原则：非侵入式 —— 每天仅一条温和的系统通知，绝不弹窗、不骚扰。
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// 在 main() 中调用一次，完成插件初始化与权限申请
  static Future<void> init() async {
    const android = AndroidInitializationSettings('mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: darwin);
    await _plugin.initialize(settings);
    _initialized = true;
    await requestPermission();
  }

  /// 申请通知权限（可在首启引导中主动调用，也可由系统权限弹窗触发）
  static Future<void> requestPermission() async {
    if (!_initialized) return;
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// 注册每日养护提醒（按待办数量生成温和文案）
  static Future<void> scheduleDailyReminder(int dueCount) async {
    if (!_initialized) return;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'care_reminder',
        '养护提醒',
        channelDescription: '圆形植物的每日养护提醒',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(),
    );
    final body =
        dueCount > 0 ? '今天有 $dueCount 株植物在等你照顾~' : '你的植物们都很好，有空去看看它们吧~';
    await _plugin.periodicallyShow(
      0,
      '圆形植物 · 每日养护',
      body,
      RepeatInterval.daily,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
