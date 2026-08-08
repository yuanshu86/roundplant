@echo off
setlocal
REM ====================================================
REM  圆形植物 App - Release APK 构建脚本
REM  用法：双击本文件，或在项目根目录执行 build_apk.bat
REM ====================================================

set "FLUTTER_ROOT=C:\flutter"
set "PUB_CACHE=C:\Users\My\.pub-cache"
set "FLUTTER_SUPPRESS_ANALYTICS=true"
set "PATH=C:\flutter\bin;%PATH%"

REM 删除可能残留的 flutter 锁文件（Windows Defender 偶发抢锁会导致启动失败）
if exist "C:\flutter\bin\cache\lockfile" del /f /q "C:\flutter\bin\cache\lockfile" >nul 2>&1

echo [1/2] 尝试 flutter.bat 标准构建...
C:\flutter\bin\flutter.bat build apk --release
if not errorlevel 1 (
  echo [完成] APK 已生成，见 build\app\outputs\flutter-apk\app-release.apk
  goto :done
)

echo [重试] flutter.bat 失败，改用 dart 快照直跑（绕过 .bat 子进程输出问题）...
if exist "C:\flutter\bin\cache\lockfile" del /f /q "C:\flutter\bin\cache\lockfile" >nul 2>&1
C:\flutter\bin\cache\dart-sdk\bin\dart.exe C:\flutter\bin\cache\flutter_tools.snapshot build apk --release
if not errorlevel 1 (
  echo [完成] APK 已生成，见 build\app\outputs\flutter-apk\app-release.apk
  goto :done
)

echo [失败] 构建未成功，请查看上方报错信息。
pause
exit /b 1

:done
echo.
echo 构建结束。APK 路径：
echo   C:\circle_plant\build\app\outputs\flutter-apk\app-release.apk
pause
