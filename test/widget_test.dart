import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:circle_plant/main.dart';

void main() {
  // 桌面测试环境需要初始化 sqflite_ffi
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('App启动冒烟测试', (WidgetTester tester) async {
    await tester.pumpWidget(const CirclePlantApp());

    // 等待异步初始化（SQLite加载 + 数据seed）
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // 验证底部导航栏存在（首页/扫描/附近）
    expect(find.text('首页'), findsWidgets);
  });
}
