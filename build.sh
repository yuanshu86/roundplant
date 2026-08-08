#!/bin/bash
# 圆形植物 - 一键构建脚本
# 用法: bash build.sh [debug|release]
set -e

MODE=${1:-debug}
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "🌱 圆形植物 - Flutter 构建 ($MODE)"
echo "================================"

cd "$PROJECT_DIR"

# 检查 Flutter
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter 未安装，请先安装 Flutter SDK"
    echo "   下载: https://docs.flutter.dev/get-started/install"
    exit 1
fi

# 首次运行: 生成平台文件
if [ ! -d "android" ]; then
    echo "📦 生成平台文件..."
    flutter create --org com.circleplant --project-name circle_plant .
fi

# 安装依赖
echo "📥 安装依赖..."
flutter pub get

# 分析代码
echo "🔍 代码分析..."
flutter analyze || true

# 构建
echo "🏗️ 构建 APK ($MODE)..."
flutter build apk --$MODE

# 输出结果
APK_PATH="build/app/outputs/flutter-apk/app-$MODE.apk"
if [ -f "$APK_PATH" ]; then
    echo ""
    echo "✅ 构建成功!"
    echo "📱 APK 路径: $PROJECT_DIR/$APK_PATH"
    echo ""
    echo "安装到设备: adb install $APK_PATH"
else
    echo "❌ 构建失败，请检查错误信息"
    exit 1
fi
