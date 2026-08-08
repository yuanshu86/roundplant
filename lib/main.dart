import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'theme/app_colors.dart';
import 'store/app_store.dart';
import 'screens/main_shell.dart';
import 'screens/detail_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/share_sheet.dart';
import 'screens/nearby_screen.dart';
import 'models/plant.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  runApp(const CirclePlantApp());
}

class CirclePlantApp extends StatelessWidget {
  const CirclePlantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppStore()..init(),
      child: MaterialApp(
        title: '圆形植物',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: AppColors.bg,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
            secondary: AppColors.secondary,
          ),
          textTheme: GoogleFonts.nunitoSansTextTheme().copyWith(
            titleLarge: GoogleFonts.varelaRound(
              fontSize: 17,
              color: AppColors.primary,
            ),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.bg,
            elevation: 0,
          ),
        ),
        initialRoute: '/',
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/':
              return MaterialPageRoute(builder: (_) => const MainShell());
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
      ),
    );
  }
}
