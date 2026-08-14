# Flutter / 圆形植物 R8 / ProGuard 规则
#
# 启用 R8 后需要保留以下内容，否则 release 包会丢功能：

# Flutter 自身
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# 第三方插件需要保留反射 / 序列化相关
-keep class com.tekartik.sqflite.** { *; }
-keep class androidx.lifecycle.DefaultLifecycleObserver
-keepclassmembers class * {
    @androidx.annotation.Keep *;
}
-keep,allowobfuscation,allowshrinking @interface androidx.annotation.Keep
-keep @androidx.annotation.Keep class *

# Supabase Flutter / GoTrue / Realtime 用到的注解
-keep class io.supabase.** { *; }
-dontwarn io.supabase.**

# 图片/插件需要的 model 类（避免混淆后 json 解析失败）
-keep class * implements com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# flutter_local_notifications 在 Android 13+ 用到的 NotificationCompat 渠道
-keep class androidx.core.app.NotificationCompat$* { *; }

# 调试日志保留（debugPrint / debugPrintStack）
# R8 默认会移除所有 println 调用，Flutter 已自动处理