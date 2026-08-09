import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_colors.dart';
import 'store/app_store.dart';
import 'screens/main_shell.dart';
import 'screens/detail_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/share_sheet.dart';
import 'screens/nearby_screen.dart';
import 'screens/onboarding_screen.dart';
import 'models/plant.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
            theme: _buildTheme(),
            darkTheme: _buildTheme(),
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

/// 构建主题数据：颜色全部来自 [AppColors]，随深浅主题自动切换
ThemeData _buildTheme() {
  final dark = AppColors.isDark;
  return ThemeData(
    brightness: dark ? Brightness.dark : Brightness.light,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      brightness: dark ? Brightness.dark : Brightness.light,
    ),
    textTheme: GoogleFonts.nunitoSansTextTheme().copyWith(
      titleLarge: GoogleFonts.varelaRound(
        fontSize: 17,
        color: AppColors.primary,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.bg,
      elevation: 0,
    ),
  );
}
