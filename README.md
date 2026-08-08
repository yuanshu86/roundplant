# 圆形植物 — Flutter App v1

> 治愈温柔的居家植物养护 App · Flutter 高保真实现

## 快速开始

### 1. 环境要求
- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0
- Android Studio 或 VS Code (含 Flutter 插件)

### 2. 初始化项目
```bash
# 进入项目目录
cd 02-Flutter代码

# 生成平台文件 (Android/iOS/Web)
flutter create --org com.circleplant --project-name circle_plant .

# 安装依赖
flutter pub get
```

### 3. 运行
```bash
# 连接手机或启动模拟器后
flutter run

# 或指定设备
flutter run -d <device_id>
```

### 4. 构建 APK
```bash
# Debug APK (快速测试)
flutter build apk --debug

# Release APK (正式安装包)
flutter build apk --release

# APK 输出路径
# build/app/outputs/flutter-apk/app-release.apk
```

## 项目结构

```
lib/
├── main.dart                      # 入口 · Provider · 路由 · 主题
├── store/
│   └── app_store.dart             # 全局状态 (ChangeNotifier)
├── theme/
│   ├── app_colors.dart            # 色彩系统
│   ├── app_typography.dart        # 字体层级
│   └── app_spacing.dart           # 间距/圆角/尺寸常量
├── models/
│   └── plant.dart                 # Plant / CareTask / NearbyUser 数据模型
├── widgets/
│   ├── plant_image.dart           # 植物视觉占位 (渐变+图标，v2替换为真实图片)
│   ├── plant_card.dart            # PlantCard / GradientButton / HealthBadge / CareParamCard
│   └── custom_tab_bar.dart        # CustomStatusBar / CustomNavBar / CustomTabBar
└── screens/
    ├── main_shell.dart            # 底部 Tab 导航壳 (IndexedStack)
    ├── home_screen.dart           # ① 首页 — Hero / 浇水卡 / 地图按钮 / 植物网格
    ├── detail_screen.dart         # ② 详情 — 插画 / 养护参数 / 浇水 / 分享栏
    ├── scan_screen.dart           # ③ AI识别 — 扫描框 / 模拟识别 / 结果面板
    ├── tasks_screen.dart          # ④ 养护任务 — 进度环 / 任务清单 / 成就卡
    ├── share_sheet.dart           # ⑤ 分享面板 — 系统Share Sheet
    ├── nearby_screen.dart         # ⑥ 附近花友 — 风格化地图 / 花友标记
    └── profile_screen.dart        # ⑦ 个人中心 — 统计 / 设置
```

## v1 已实现功能

| 功能 | 状态 | 说明 |
|------|------|------|
| 首页植物网格 | ✅ | 4株示例植物，点击进入详情 |
| 浇水操作 | ✅ | 点浇水→更新浇水时间→+5积分→Snack反馈 |
| 养护任务 | ✅ | 进度环+任务勾选（勾选=浇水） |
| AI识别 | ✅ 模拟 | 点快门→2秒识别→结果面板→可添加 |
| 分享 | ✅ | 调系统 Share Sheet（微信/小红书/更多） |
| 附近花友 | ✅ 模拟 | 风格化地图+3位花友+打招呼对话框 |
| 个人中心 | ✅ | 统计数据+菜单+关于弹窗 |
| 底部导航 | ✅ | 4 Tab + FAB凸起按钮 |
| 状态管理 | ✅ | Provider + ChangeNotifier |
| 数据持久化 | ⏳ v2 | v1 使用内存数据，v2 接 SharedPreferences |

## 设计规范

### 色彩
| 变量 | 色值 | 用途 |
|------|------|------|
| primary | #15803D | 森林绿·主色 |
| secondary | #059669 | 翡翠绿·辅色 |
| accent | #D97706 | 琥珀橙·强调 |
| bg | #F0FDF4 | 页面背景 |
| softCard | #F0F7F3 | 次级卡片 |
| textSecondary | #64748B | 次文字 |
| border | #E2EFE7 | 边框 |

### 圆角
- 卡片: 16 · 容器: 32 · 药丸: 48

### 字体
- 标题: Varela Round (通过 google_fonts 加载)
- 正文: Nunito Sans (通过 google_fonts 加载)
- 状态栏: SF Pro (系统字体)

## v2 待完成

- [ ] SharedPreferences 数据持久化
- [ ] 植物增删改编辑页
- [ ] AI 识别接入百度 AI 接口
- [ ] 腾讯地图 SDK 接入（真实定位+地图）
- [ ] BLE 广播发现附近花友
- [ ] 推送通知（浇水提醒）
- [ ] 暗色模式
- [ ] 引导页/空状态
- [ ] 植物图片替换为真实照片

## 技术栈

- **框架**: Flutter 3.x
- **状态管理**: Provider + ChangeNotifier
- **字体**: google_fonts (Varela Round + Nunito Sans)
- **分享**: share_plus
- **图标**: Material Icons
- **绘图**: CustomPaint (进度环/地图地形/距离环)

## 构建注意事项

1. **字体**: v1 通过 `google_fonts` 包在运行时下载字体，首次启动需联网。离线环境下回退到系统字体。
2. **图片**: v1 不依赖外部图片资源，所有视觉用 Flutter Widget + Canvas 绘制。v2 可替换为真实图片。
3. **地图**: v1 使用装饰性风格化地图（CustomPaint），不含真实地理数据。v2 需接入腾讯地图 SDK。
4. **定位**: v1 使用模拟数据。v2 需接入 geolocator 或腾讯定位服务。
5. **Android 权限**: v2 需在 AndroidManifest.xml 添加定位、相机、存储权限。
