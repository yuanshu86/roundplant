allprojects {
    repositories {
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
        maven { url = uri("https://storage.flutter-io.cn") }
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// 强制所有 Android 模块（含 Flutter 插件，如 :share_plus/:image_picker_android）使用 compileSdk=36。
// 本机 Flutter 版本较旧，插件模块默认继承 flutter.compileSdkVersion=33，
// 无法满足 image_picker/geolocator/sqflite/share_plus 等插件及其 androidx 依赖(要求>=34/36)。
subprojects {
    afterEvaluate {
        val androidExt = extensions.findByName("android") ?: return@afterEvaluate
        // 不依赖 AGP 内部类型(AGP9 下 CommonExtension/BaseExtension 接口常被重构)，
        // 直接反射调用 setCompileSdk/setCompileSdkVersion(int)，跨版本通用。
        val setter = androidExt.javaClass.methods.firstOrNull { m ->
            m.parameterCount == 1 &&
                (m.name == "setCompileSdk" || m.name == "setCompileSdkVersion")
        }
        setter?.invoke(androidExt, 36)
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
