import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// 天气与问候服务
/// - 通过后端代理请求 Open-Meteo，APP 不直接访问第三方天气 API
/// - 仅启动时获取一次位置（不后台持续定位）
/// - 失败或用户拒绝位置权限时，返回默认阳光问候
class WeatherService {
  static String? _cached;
  static DateTime? _cachedAt;

  static Future<String> greeting() async {
    if (_cached != null &&
        _cachedAt != null &&
        DateTime.now().difference(_cachedAt!) < const Duration(minutes: 30)) {
      return _cached!;
    }

    try {
      String? lat;
      String? lon;
      try {
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          final request = await Geolocator.requestPermission();
          if (request == LocationPermission.denied ||
              request == LocationPermission.deniedForever) {
            throw Exception('位置权限被拒绝');
          }
        }
        if (permission != LocationPermission.deniedForever) {
          final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.low,
              timeLimit: Duration(seconds: 5),
            ),
          );
          lat = position.latitude.toStringAsFixed(4);
          lon = position.longitude.toStringAsFixed(4);
        }
      } catch (e) {
        debugPrint('location error: $e');
      }

      final uri = lat != null && lon != null
          ? Uri.parse('${AppConfig.weatherUrl}?lat=$lat&lon=$lon')
          : Uri.parse(AppConfig.weatherUrl);

      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _cached = (data['suggestion'] as String?) ?? _defaultGreeting();
      } else {
        _cached = _defaultGreeting();
      }
    } catch (e) {
      debugPrint('weather error: $e');
      _cached = _defaultGreeting();
    }

    _cachedAt = DateTime.now();
    return _cached!;
  }

  static String _defaultGreeting() => '☀️ 今天阳光充足，适合浇水';
}
