import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// 天气与问候服务（统一使用国内源「和风天气 QWeather」免费版）
///
/// 设计原则（避免补丁式拼凑）：
/// 1. 单一主数据源 = 和风天气（国内稳定、免费额度对个人 APP 足够、自带城市反查与 IP 定位）。
/// 2. Key 通过构建参数注入：`flutter build apk --release --dart-define=QWEATHER_KEY=你的key`，
///    不进源码、不进 git。
/// 3. 不使用自动定位（GPS/网络 IP 都不用），完全由用户手动选择城市，规避定位权限、
///    网络 IP 接口等不稳定因素，也更符合「不打扰用户」的底线。用户从未选择时默认显示北京。
/// 4. 仅当未配置 Key 或和风异常时，才降级到 Open-Meteo 取数据（明确标注的兜底，非默认路径）。
class WeatherService {
  static WeatherData? _cache;
  static DateTime? _cacheAt;
  static const Duration _ttl = Duration(minutes: 30);

  /// 和风天气 API Host（构建时可通过 --dart-define=QWEATHER_HOST=xxx 覆盖）。
  /// 免费版各时期/各账号的 Host 可能是 devapi.qweather.com 或 api.qweather.com，
  /// 我们在请求时自动重试这两个官方 Host，避免 Host 填错导致整站不可用。
  static const String _primaryHost = String.fromEnvironment('QWEATHER_HOST',
      defaultValue: 'devapi.qweather.com');
  static const List<String> _hosts = [_primaryHost, 'api.qweather.com'];

  // 默认兜底城市（北京）
  static const double _fallbackLat = 39.9042;
  static const double _fallbackLon = 116.4074;
  static const String _fallbackCity = '北京';

  /// 拉取当前天气（带 30 分钟缓存）。
  ///
  /// 设计：**不自动定位**（GPS/网络 IP 都不用），完全由用户手动选择城市，
  /// 规避定位权限、网络 IP 接口等不稳定因素，也更符合「不打扰用户」的底线。
  /// 用户从未选择时默认显示北京，点击城市名可随时切换。
  static Future<WeatherData?> current() async {
    if (_cache != null &&
        _cacheAt != null &&
        DateTime.now().difference(_cacheAt!) < _ttl) {
      return _cache;
    }
    try {
      final key = const String.fromEnvironment('QWEATHER_KEY');

      // 1) 用户手动选择的城市（SharedPreferences 持久化）
      final manual = await loadManualCity();
      double lat;
      double lon;
      String? city;
      String note;
      if (manual != null) {
        lat = manual.lat;
        lon = manual.lon;
        city = manual.name;
        note = '（显示你选择的城市天气）';
      } else {
        // 2) 首次未选：默认北京兜底
        lat = _fallbackLat;
        lon = _fallbackLon;
        city = _fallbackCity;
        note = '（默认显示北京，点城市名可切换）';
      }

      final data =
          await _fetchWeather(lat, lon, forcedCity: city, note: note, key: key);
      if (data != null) {
        _cache = data;
        _cacheAt = DateTime.now();
      }
      return data;
    } catch (e) {
      debugPrint('weather error: $e');
      return _cache;
    }
  }

  /// 按经纬度拉取天气。有 Key 走和风；无 Key / 和风失败则降级 Open-Meteo。
  static Future<WeatherData?> _fetchWeather(
    double lat,
    double lon, {
    String? forcedCity,
    String note = '',
    required String key,
  }) async {
    if (key.isNotEmpty) {
      final data = await _fetchQWeather(lat, lon,
          forcedCity: forcedCity, note: note, key: key);
      if (data != null) return data;
    }
    // 和风主源失败：若 key 有效，先用 GeoAPI 反查城市名，再降级 Open-Meteo
    String? city = forcedCity;
    if (city == null && key.isNotEmpty) {
      city = await _reverseCity(lon, lat, key);
    }
    return _fetchOpenMeteo(lat, lon, forcedCity: city, note: '$note（备用数据源）');
  }

  /// 和风天气：实时天气 + 城市反查（自动重试两个官方 Host）
  static Future<WeatherData?> _fetchQWeather(
    double lat,
    double lon, {
    String? forcedCity,
    String note = '',
    required String key,
  }) async {
    final loc = '$lon,$lat'; // 和风：经度,纬度（注意顺序，先经后纬）
    for (final host in _hosts) {
      try {
        final uri = Uri.parse(
            'https://$host/v7/weather/now?location=$loc&key=$key&lang=zh');
        final res = await http.get(uri).timeout(const Duration(seconds: 10));
        if (res.statusCode != 200) continue;
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json['code'] != '200') continue;
        final now = json['now'] as Map<String, dynamic>? ?? {};
        final temp = double.tryParse(now['temp']?.toString() ?? '');
        final text = (now['text'] as String?)?.trim() ?? '晴';
        final humidity = double.tryParse(now['humidity']?.toString() ?? '');

        String? city = forcedCity;
        city ??= await _reverseCity(lon, lat, key, preferredHost: host);

        return WeatherData(
          temperature: temp,
          weatherCode: _iconToCode(text),
          condition: text,
          humidity: humidity,
          city: city,
          greeting: _greetingFromText(text, temp),
          note: note,
        );
      } catch (e) {
        debugPrint('qweather now error on $host: $e');
      }
    }
    return null;
  }

  /// 和风 GeoAPI：按经纬度反查城市名（自动重试两个官方 Host）
  static Future<String?> _reverseCity(
    double lon,
    double lat,
    String key, {
    String? preferredHost,
  }) async {
    final candidates = <String>[
      if (preferredHost != null && _hosts.contains(preferredHost))
        preferredHost,
      ..._hosts.where((h) => h != preferredHost),
    ];
    for (final host in candidates) {
      try {
        final uri = Uri.parse(
            'https://$host/geo/v2/city/lookup?location=$lon,$lat&key=$key&number=1');
        final res = await http.get(uri).timeout(const Duration(seconds: 6));
        if (res.statusCode != 200) continue;
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json['code'] != '200') continue;
        final list = json['location'] as List?;
        if (list != null && list.isNotEmpty) {
          final c = list.first as Map<String, dynamic>;
          return c['name'] as String?;
        }
      } catch (_) {}
    }
    return null;
  }

  /// Open-Meteo 降级（无 Key 或和风异常时）
  static Future<WeatherData?> _fetchOpenMeteo(
    double lat,
    double lon, {
    String? forcedCity,
    String note = '',
  }) async {
    try {
      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$lat&longitude=$lon'
        '&current=temperature_2m,relative_humidity_2m,weather_code'
        '&timezone=auto',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final cur = json['current'] as Map<String, dynamic>? ?? {};
      final code = (cur['weather_code'] as num?)?.toInt() ?? 0;
      final temp = (cur['temperature_2m'] as num?)?.toDouble();
      final humidity = (cur['relative_humidity_2m'] as num?)?.toDouble();
      return WeatherData(
        temperature: temp,
        weatherCode: code,
        condition: _conditionText(code),
        humidity: humidity,
        city: forcedCity,
        greeting: _greeting(code, temp),
        note: note,
      );
    } catch (_) {
      return null;
    }
  }

  // === 手动城市（SharedPreferences 持久化） ===

  /// 读取用户手动选择的城市。无则返回 null。
  /// 公开给附近页复用，避免用户设置城市后附近页仍默认北京。
  static Future<ManualCity?> loadManualCity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString(_kManualCityName);
      final lat = prefs.getDouble(_kManualCityLat);
      final lon = prefs.getDouble(_kManualCityLon);
      if (name != null && lat != null && lon != null) {
        return ManualCity(name: name, lat: lat, lon: lon);
      }
    } catch (_) {}
    return null;
  }

  /// 保存用户手动选择的城市（覆盖缓存：下次启动直接用它）。
  static Future<void> saveManualCity(
      String name, double lat, double lon) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kManualCityName, name);
      await prefs.setDouble(_kManualCityLat, lat);
      await prefs.setDouble(_kManualCityLon, lon);
      _cache = null;
      _cacheAt = null;
    } catch (e) {
      debugPrint('saveManualCity error: $e');
    }
  }

  /// 主要城市（含经纬度），供用户在自动定位失败时手动选到本地天气。
  /// 覆盖全部省会 + 主要经济城市 + 常见养花城市，共 60 个。
  static const List<ManualCity> hotCities = [
    // 直辖市
    ManualCity(name: '北京', lat: 39.9042, lon: 116.4074),
    ManualCity(name: '上海', lat: 31.2304, lon: 121.4737),
    ManualCity(name: '天津', lat: 39.3434, lon: 117.3616),
    ManualCity(name: '重庆', lat: 29.5630, lon: 106.5516),
    // 华北 / 东北
    ManualCity(name: '石家庄', lat: 38.0428, lon: 114.5149),
    ManualCity(name: '太原', lat: 37.8706, lon: 112.5489),
    ManualCity(name: '呼和浩特', lat: 40.8414, lon: 111.7519),
    ManualCity(name: '沈阳', lat: 41.8057, lon: 123.4315),
    ManualCity(name: '大连', lat: 38.9140, lon: 121.6147),
    ManualCity(name: '长春', lat: 43.8171, lon: 125.3235),
    ManualCity(name: '哈尔滨', lat: 45.8038, lon: 126.5350),
    ManualCity(name: '济南', lat: 36.6512, lon: 117.1201),
    ManualCity(name: '青岛', lat: 36.0671, lon: 120.3826),
    ManualCity(name: '烟台', lat: 37.4638, lon: 121.4481),
    ManualCity(name: '郑州', lat: 34.7466, lon: 113.6254),
    ManualCity(name: '洛阳', lat: 34.6197, lon: 112.4540),
    // 华东
    ManualCity(name: '南京', lat: 32.0603, lon: 118.7969),
    ManualCity(name: '苏州', lat: 31.2989, lon: 120.5853),
    ManualCity(name: '无锡', lat: 31.4912, lon: 120.3119),
    ManualCity(name: '常州', lat: 31.8107, lon: 119.9736),
    ManualCity(name: '南通', lat: 31.9802, lon: 120.8943),
    ManualCity(name: '扬州', lat: 32.3942, lon: 119.4127),
    ManualCity(name: '杭州', lat: 30.2741, lon: 120.1551),
    ManualCity(name: '宁波', lat: 29.8683, lon: 121.5440),
    ManualCity(name: '温州', lat: 28.0008, lon: 120.7010),
    ManualCity(name: '嘉兴', lat: 30.7470, lon: 120.7555),
    ManualCity(name: '绍兴', lat: 30.0022, lon: 120.5788),
    ManualCity(name: '金华', lat: 29.0781, lon: 119.6477),
    ManualCity(name: '合肥', lat: 31.8206, lon: 117.2272),
    ManualCity(name: '福州', lat: 26.0745, lon: 119.2965),
    ManualCity(name: '厦门', lat: 24.4798, lon: 118.0894),
    ManualCity(name: '泉州', lat: 24.8744, lon: 118.6757),
    ManualCity(name: '南昌', lat: 28.6820, lon: 115.8579),
    // 华中 / 华南
    ManualCity(name: '武汉', lat: 30.5928, lon: 114.3055),
    ManualCity(name: '宜昌', lat: 30.6919, lon: 111.2864),
    ManualCity(name: '长沙', lat: 28.2282, lon: 112.9388),
    ManualCity(name: '株洲', lat: 27.8278, lon: 113.1338),
    ManualCity(name: '广州', lat: 23.1291, lon: 113.2644),
    ManualCity(name: '深圳', lat: 22.5431, lon: 114.0579),
    ManualCity(name: '珠海', lat: 22.2710, lon: 113.5670),
    ManualCity(name: '佛山', lat: 23.0218, lon: 113.1219),
    ManualCity(name: '东莞', lat: 23.0489, lon: 113.7447),
    ManualCity(name: '惠州', lat: 23.1115, lon: 114.4152),
    ManualCity(name: '中山', lat: 22.5176, lon: 113.3927),
    ManualCity(name: '汕头', lat: 23.3535, lon: 116.7311),
    ManualCity(name: '南宁', lat: 22.8170, lon: 108.3665),
    ManualCity(name: '桂林', lat: 25.2742, lon: 110.2998),
    ManualCity(name: '海口', lat: 20.0440, lon: 110.1999),
    ManualCity(name: '三亚', lat: 18.2528, lon: 109.5120),
    // 西南 / 西北
    ManualCity(name: '成都', lat: 30.5728, lon: 104.0668),
    ManualCity(name: '贵阳', lat: 26.6470, lon: 106.6302),
    ManualCity(name: '昆明', lat: 25.0389, lon: 102.7183),
    ManualCity(name: '拉萨', lat: 29.6500, lon: 91.1000),
    ManualCity(name: '西安', lat: 34.3416, lon: 108.9398),
    ManualCity(name: '兰州', lat: 36.0611, lon: 103.8343),
    ManualCity(name: '西宁', lat: 36.6171, lon: 101.7782),
    ManualCity(name: '银川', lat: 38.4872, lon: 106.2309),
    ManualCity(name: '乌鲁木齐', lat: 43.8256, lon: 87.6168),
    ManualCity(name: '喀什', lat: 39.4704, lon: 75.9896),
  ];

  static const String _kManualCityName = 'weather_manual_city_name';
  static const String _kManualCityLat = 'weather_manual_city_lat';
  static const String _kManualCityLon = 'weather_manual_city_lon';

  // === 天气代码 / 文案映射 ===

  /// 和风文本 → 内部图标码（仅用于选图标）
  static int _iconToCode(String text) {
    if (text.contains('雷')) return 95;
    if (text.contains('雨')) return 61;
    if (text.contains('雪')) return 71;
    if (text.contains('雾') || text.contains('霾')) return 45;
    if (text.contains('多云') || text.contains('阴')) return 3;
    return 0;
  }

  /// WMO 代码 → 中文（Open-Meteo 降级时用）
  static String _conditionText(int code) {
    if (code == 0) return '晴';
    if (code <= 2) return '多云';
    if (code == 3) return '阴';
    if (code == 45 || code == 48) return '雾';
    if (code >= 51 && code <= 57) return '毛毛雨';
    if (code >= 61 && code <= 67) return '雨';
    if (code >= 71 && code <= 77) return '雪';
    if (code >= 80 && code <= 86) return '阵雨';
    if (code >= 95) return '雷阵雨';
    return '晴';
  }

  static bool _isRain(int code) => code >= 51 && code <= 67;
  static bool _isSnow(int code) => code >= 71 && code <= 77;
  static bool _isThunder(int code) => code >= 95;
  static bool _isCloud(int code) => code >= 1 && code <= 3;

  /// WMO 版问候（Open-Meteo 降级用）
  static String _greeting(int code, double? temp) {
    if (_isRain(code)) {
      return (temp != null && temp < 15)
          ? '🌧️ 今天有雨又偏凉，注意给植物排水保暖'
          : '🌧️ 今天有雨，记得检查盆土别积水';
    }
    if (_isSnow(code)) return '❄️ 降温下雪了，怕冷的植物记得搬进屋';
    if (_isThunder(code)) return '⛈️ 雷阵雨天气，把植物收进室内更安全';
    if (_isCloud(code)) return '⛅ 多云天气，光照柔和正适合植物生长';
    if (temp != null && temp >= 32) return '☀️ 烈日当头，给植物遮遮阳、多补点水';
    if (temp != null && temp <= 5) return '☀️ 天冷光照弱，把植物挪到向阳处';
    return '☀️ 天气真好，适合带植物晒晒太阳';
  }

  /// 和风文本版问候（主用）
  static String _greetingFromText(String text, double? temp) {
    if (text.contains('雷')) return '⛈️ 雷阵雨天气，把植物收进室内更安全';
    if (text.contains('雨')) {
      return (temp != null && temp < 15)
          ? '🌧️ 今天有雨又偏凉，注意给植物排水保暖'
          : '🌧️ 今天有雨，记得检查盆土别积水';
    }
    if (text.contains('雪')) return '❄️ 降温下雪了，怕冷的植物记得搬进屋';
    if (text.contains('雾') || text.contains('霾')) {
      return '🌫️ 有雾/霾天气，光照弱，把植物挪到明亮通风处';
    }
    if (text.contains('多云') || text.contains('阴')) {
      return '⛅ 多云天气，光照柔和正适合植物生长';
    }
    if (temp != null && temp >= 32) return '☀️ 烈日当头，给植物遮遮阳、多补点水';
    if (temp != null && temp <= 5) return '☀️ 天冷光照弱，把植物挪到向阳处';
    return '☀️ 天气真好，适合带植物晒晒太阳';
  }
}

/// 当前天气数据（temperature 为 null 表示未取得真实数据）
class WeatherData {
  final double? temperature;
  final int weatherCode;
  final String condition;
  final double? humidity;
  final String? city;
  final String greeting;

  /// 兜底说明：正常为 null
  final String? note;

  const WeatherData({
    this.temperature,
    required this.weatherCode,
    required this.condition,
    this.humidity,
    this.city,
    required this.greeting,
    this.note,
  });
}

/// 手动选择的城市（含经纬度）
class ManualCity {
  final String name;
  final double lat;
  final double lon;
  const ManualCity({required this.name, required this.lat, required this.lon});
}
