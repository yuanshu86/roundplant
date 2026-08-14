/// APP 全局配置
///
/// 后端代理地址：AI 识花请求只发给咱们自己的后端（持有 Pl@ntNet key），
/// APP 永远不直接接触任何第三方 key。
///
/// 默认值是一个占位域名。部署到甲骨文 VPS 后改成真实域名/IP；
/// 本地真机调试时可通过编译参数覆盖：
///   flutter build apk --dart-define=BACKEND_URL=http://192.168.x.x:3000
class AppConfig {
  static const String backendBaseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'https://plant-api.roundplant.com',
  );

  static String get identifyUrl => '$backendBaseUrl/api/identify';
}
