@echo off
rem ============================================
rem  CirclePlant (Circle Plant) Release Build
rem  One-click build with all dart-defines baked in
rem  (QWEATHER key + Supabase URL + Supabase anon key)
rem ============================================
cd /d C:\circle_plant
echo [1/2] flutter pub get ...
call C:\flutter\bin\flutter.bat pub get
echo [2/2] flutter build apk --release ...
call C:\flutter\bin\flutter.bat build apk --release --dart-define=QWEATHER_KEY=c7e21da99d424157b2a616da963ab57a --dart-define=SUPABASE_URL=https://jzbbbemmpjcisldrxtoi.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp6YmJiZW1tcGpjaXNsZHJ4dG9pIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODYzNTkyNzIsImV4cCI6MjEwMTkzNTI3Mn0.6nmab2b7jOWGlsssOuhLu2bkT3alntV3lL-iUFSCZ1o
echo.
echo Build finished!
echo APK: C:\circle_plant\build\app\outputs\flutter-apk\app-release.apk
pause
