@echo off
chcp 65001 >nul
title 圆形植物 APK 一键构建

echo ================================================
echo         圆形植物 v1.0 · APK 构建
echo ================================================
echo.

REM 配置国内镜像（保证 Gradle 依赖能下载）
set PUB_HOSTED_URL=https://pub.flutter-io.cn
set FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

REM 安装 Gradle 国内镜像配置
if not exist "%USERPROFILE%\.gradle" mkdir "%USERPROFILE%\.gradle"
copy /Y "%~dp0gradle国内镜像配置.gradle" "%USERPROFILE%\.gradle\init.gradle" >nul 2>&1
echo [镜像] Gradle 国内镜像已配置
echo.

REM 检查 Flutter 是否可用
where flutter >nul 2>&1
if %errorlevel% neq 0 (
    echo [错误] 找不到 flutter 命令！
    echo 请先安装 Flutter SDK：https://docs.flutter.dev/get-started/install/windows
    echo 解压到 C:\flutter\，然后把 C:\flutter\bin 加到 PATH
    pause
    exit /b 1
)

echo [1/4] Flutter 版本检查...
flutter --version

echo.
echo [2/4] 初始化项目配置...
flutter create --org com.circleplant --project-name circle_plant .

echo.
echo [3/4] 安装依赖...
flutter pub get

echo.
echo [4/4] 编译 APK (大约需要 3-5 分钟)...
flutter build apk --release

if %errorlevel% equ 0 (
    echo.
    echo ================================================
    echo    ✅ 编译成功！
    echo    APK 文件位置:
    echo    build\app\outputs\flutter-apk\app-release.apk
    echo ================================================
    echo.
    echo 把这个文件传到手机安装即可。
    explorer build\app\outputs\flutter-apk\
) else (
    echo.
    echo [失败] 编译出错，请检查上面的报错信息。
    echo 常见原因：
    echo 1. Android SDK 未安装 → 请安装 Android Studio
    echo 2. 未接受 Android 许可 → 运行 flutter doctor --android-licenses
    echo 3. 路径中有中文或空格 → 把项目放在 C:\circle_plant\
)

pause
