# 「圆形植物」APK 构建指南

> 预计总时间：**40 分钟**（大部分是下载等待）

---

## 你需要安装的软件（2个）

| # | 软件 | 大小 | 下载链接 |
|---|------|------|----------|
| 1 | **Android Studio** | ~1.2 GB | https://developer.android.com/studio （选 Windows 版本下载） |
| 2 | **Flutter SDK** | ~1.5 GB | https://docs.flutter.dev/get-started/install/windows （下载 flutter_windows 压缩包） |

> **为什么选 Android Studio？** 它一键安装就能同时给你 JDK + Android SDK + 编译工具，比自己分别装省事太多。

---

## 第一步：安装 Android Studio

1. 双击下载的安装包，一路 **Next**
2. 安装路径建议保持默认（`C:\Program Files\Android\Android Studio`）
3. 安装完成后启动 Android Studio，会弹出 SDK 设置向导：
   - 选择 **Standard** 安装
   - 勾选 **Android Virtual Device**（模拟器，可选）
   - 点 **Next** → 等待下载完成（约 10 分钟）

---

## 第二步：安装 Flutter SDK

1. 把下载的 `flutter_windows_*.zip` 解压到 **C 盘根目录**：
   ```
   C:\flutter\
   ```
   > ⚠️ 不要放在 Program Files 里！权限问题会导致编译失败。

2. 双击 `C:\flutter\flutter_console.bat`，会打开一个命令行窗口

3. 在窗口里输入以下命令，逐一执行：
   ```
   flutter doctor
   ```
   会看到类似这样的输出，红色叉号是正常的（还没配置完）：
   ```
   [✓] Flutter
   [✓] Android toolchain
   [!] Android Studio
   ```

4. 接受 Android 许可协议：
   ```
   flutter doctor --android-licenses
   ```
   一路按 `y` 确认

5. 再次运行验证：
   ```
   flutter doctor
   ```
   所有项都应该是绿色的 `[✓]`

---

## 第三步：编译 APK

1. 把「**02-Flutter代码**」整个文件夹，复制到 `C:\circle_plant\`

2. 打开命令行（Win+R → 输入 `cmd`），执行：
   ```
   cd C:\circle_plant
   flutter create --org com.circleplant --project-name circle_plant .
   flutter pub get
   flutter build apk --release
   ```

3. 编译成功后，APK 文件在：
   ```
   C:\circle_plant\build\app\outputs\flutter-apk\app-release.apk
   ```

4. 把这个 APK 传到手机安装即可！

---

## 常见问题

| 问题 | 解决 |
|------|------|
| `flutter: command not found` | 把 `C:\flutter\bin` 加到系统环境变量 PATH 里 |
| `Android SDK not found` | 打开 Android Studio → More Actions → SDK Manager → 确认安装了 Android 14 (API 34) |
| `cmdline-tools missing` | 在 Android Studio 的 SDK Manager 里勾选 "Android SDK Command-line Tools" |
| 编译报错 `android:exported` | 这是 Android 12+ 的安全要求，运行 `flutter create .` 就能自动修复 |

---

## 如果你搞不定

把报错截图发给我，我帮你一步步排查。这些坑我都见过，大多数时候敲一行命令就解决了。
