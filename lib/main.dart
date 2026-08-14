import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_colors.dart';
import 'store/app_store.dart';
import 'screens/main_shell.dart';
import 'screens/detail_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/share_sheet.dart';
import 'screens/nearby_screen.dart';
import 'screens/achievement_screen.dart';
import 'screens/annual_report_screen.dart';
import 'screens/onboarding_screen.dart';
import 'models/plant.dart';
import 'services/notification_service.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 全局渲染异常兜底：release 模式下任何未捕获的 build/layout/paint 异常
  // 都显示成带文字的卡片，而不是静默空白（便于真机定位白屏等疑难问题）。
  // 刻意不用 Scaffold / Material：渲染异常可能发生在 MaterialApp 之外，
  // 那里没有 Material 与 Directionality 祖先，用 Scaffold 会二次抛错并陷入
  // 无限递归。这里只用最底层、无依赖的组件，保证任何情况下都能画出来。
  ErrorWidget.builder = (details) {
    final isDark = AppColors.isDark;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: isDark ? AppColors.bg : Colors.white,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.eco_outlined, color: AppColors.danger, size: 40),
                const SizedBox(height: 12),
                Text(
                  '这个页面开小差了',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'NunitoSans',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimary : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  details.exceptionAsString(),
                  textAlign: TextAlign.center,
                  maxLines: 8,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'NunitoSans',
                    fontSize: 12,
                    color: AppColors.danger,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  };

  // P3 后端初始化：未注入 SUPABASE_URL/ANON_KEY 时静默降级为本地模式
  await SupabaseService.init();
  await NotificationService.init();
  final prefs = await SharedPreferences.getInstance();
  final seen = prefs.getBool('onboarded') ?? false;
  runApp(CirclePlantApp(initialRoute: seen ? '/' : '/onboarding'));
}

class CirclePlantApp extends StatelessWidget {
  final String initialRoute;
  const CirclePlantApp({super.key, this.initialRoute = '/'});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppStore()..init(),
      child: Consumer<AppStore>(
        builder: (context, store, _) {
          // 状态栏图标随主题切换明暗（深色用浅色图标，浅色用深色图标）
          SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness:
                AppColors.isDark ? Brightness.light : Brightness.dark,
            statusBarBrightness:
                AppColors.isDark ? Brightness.dark : Brightness.light,
          ));
          return MaterialApp(
            title: '圆形植物',
            debugShowCheckedModeBanner: false,
            themeMode: store.themeMode,
            theme: _buildTheme(false),
            darkTheme: _buildTheme(true),
            initialRoute: initialRoute,
            onGenerateRoute: (settings) {
              switch (settings.name) {
                case '/':
                  return MaterialPageRoute(builder: (_) => const MainShell());
                case '/onboarding':
                  return MaterialPageRoute(
                      builder: (_) => const OnboardingScreen());
                case '/detail':
                  final plant = settings.arguments as Plant;
                  return MaterialPageRoute(
                    builder: (_) => DetailScreen(plant: plant),
                  );
                case '/scan':
                  return MaterialPageRoute(builder: (_) => const ScanScreen());
                case '/share':
                  final plant = settings.arguments as Plant?;
                  return MaterialPageRoute(
                    builder: (_) => ShareSheet(plant: plant),
                  );
                case '/nearby':
                  return MaterialPageRoute(
                    builder: (_) => const NearbyScreen(showBack: true),
                  );
                case '/achievement':
                  return MaterialPageRoute(
                      builder: (_) => const AchievementScreen());
                case '/report':
                  return MaterialPageRoute(
                      builder: (_) => const AnnualReportScreen());
                default:
                  return MaterialPageRoute(builder: (_) => const MainShell());
              }
            },
          );
        },
      ),
    );
  }
}

/// 构建主题数据。
///
/// 必须显式传入 [dark] 而不是读 `AppColors.isDark`：MaterialApp 会同时持有
/// theme 与 darkTheme 两份，若两份都按「当前」明暗构建，则系统级组件
/// （Dialog / SnackBar / 文本选择手柄 / 滚动条）在切换主题时不会跟随。
ThemeData _buildTheme(bool dark) {
  final brightness = dark ? Brightness.dark : Brightness.light;
  final bg = AppColors.bgFor(dark);
  final card = AppColors.cardFor(dark);
  final textMain = AppColors.textPrimaryFor(dark);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: bg,
    canvasColor: bg,
    dividerColor: AppColors.borderFor(dark),
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primaryTextFor(dark),
      secondary: AppColors.secondary,
      surface: card,
      brightness: brightness,
    ),
    textTheme: TextTheme(
      // 标题用本地打包的站酷快乐体（圆润可爱），不再依赖 Google Fonts 联网下载
      titleLarge: TextStyle(
        fontFamily: 'ZCOOLKuaiLe',
        fontFamilyFallback: const [
          'PingFang SC',
          'Microsoft YaHei',
          'Noto Sans SC',
          'Source Han Sans SC',
          'sans-serif',
        ],
        fontSize: 17,
        color: AppColors.primaryTextFor(dark),
      ),
      bodyLarge: TextStyle(
        fontFamily: 'NunitoSans',
        fontFamilyFallback: const [
          'PingFang SC',
          'Microsoft YaHei',
          'Noto Sans SC',
          'Source Han Sans SC',
          'sans-serif',
        ],
        fontSize: 14,
        color: textMain,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      foregroundColor: textMain,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: card,
      surfaceTintColor: Colors.transparent,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: card,
      surfaceTintColor: Colors.transparent,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.primary,
      contentTextStyle: const TextStyle(
        fontFamily: 'NunitoSans',
        fontSize: 14,
        color: Colors.white,
      ),
    ),
    // 全局统一水波纹：轻量、不刺眼
    splashFactory: InkRipple.splashFactory,
    highlightColor: AppColors.primary.withValues(alpha: 0.06),
  );
}
