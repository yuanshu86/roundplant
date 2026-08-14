import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.circleplant.circle_plant"
    // 显式锁定 compileSdk=36：本机 Flutter SDK 默认 compileSdk 为 33，
    // 但 image_picker/geolocator/sqflite/shared_preferences 等插件及其 androidx 依赖
    // (activity:1.12.4/core:1.18.0 等)已要求 >=36，取最大值一次到位避免反复
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.circleplant.circle_plant"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        // 显式锁定 targetSdk=35：Google Play 自 2025 年起要求上架应用 targetSdk >= 35，
        // 取 Flutter 默认（34）会被新版本 Flutter 升到 34 而不够；显式锁定免得自动升降。
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // 正式签名配置：读取 android/key.properties（含密钥路径与密码，已被 .gitignore 排除）
    // 无 key.properties 时回退到 debug 签名，避免 CI / 未配置密钥时 release 构建失败
    val keystorePropsFile = rootProject.file("key.properties")
    val useReleaseKey = keystorePropsFile.exists()

    if (useReleaseKey) {
        val keystoreProps = Properties().apply {
            load(FileInputStream(keystorePropsFile))
        }
        signingConfigs {
            create("release") {
                keyAlias = keystoreProps["keyAlias"] as String
                keyPassword = keystoreProps["keyPassword"] as String
                storeFile = file(keystoreProps["storeFile"] as String)
                storePassword = keystoreProps["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // 正式签名（有 key.properties 时用 release 密钥，否则 fallback debug）
            signingConfig = if (useReleaseKey) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            // 启用 R8：代码混淆 + 死代码移除 + 资源压缩
            // Google Play 推荐，能显著减小 APK 体积并保护代码不裸露
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    // 本地通知插件 flutter_local_notifications 要求开启核心库脱糖
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

flutter {
    source = "../.."
}
