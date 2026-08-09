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
// 强制所有 Android 模块（含 Flutter 插件，如 :share_plus/:image_picker_android）使用 compileSdk=36。
// 本机 Flutter 版本较旧，插件模块默认继承 flutter.compileSdkVersion=33，
// 不满足 image_picker/geolocator/sqflite/share_plus 等插件及其 androidx 依赖(要求>=34/36)。
// 必须在各模块 build.gradle 执行完(其 compileSdk 已设为 33)之后再覆盖，故走 per-project afterEvaluate；
// 且 afterEvaluate 的注册必须早于 evaluationDependsOn(':app')——后者会触发部分模块提前 evaluate，
// 若之后再注册 afterEvaluate 会抛 "Cannot run afterEvaluate when already evaluated" (Gradle 9)。
subprojects {
    afterEvaluate {
        val androidExt = extensions.findByName("android") ?: return@afterEvaluate
        // 反射 setCompileSdk(int)：AGP9 new DSL 下 CommonExtension/BaseExtension 类型不稳定，
        // 直接反射跨版本通用；仅匹配 int/Integer 参数的 setter，排除 setCompileSdkVersion(String) 误选。
        val clazz = androidExt::class.java
        val setter = clazz.methods.firstOrNull { m ->
            m.parameterCount == 1 &&
                (m.name == "setCompileSdk" || m.name == "setCompileSdkVersion") &&
                m.parameterTypes[0].let { t ->
                    t == Int::class.javaPrimitiveType || t == Integer::class.java
                }
        }
        setter?.invoke(androidExt, *arrayOf<Any?>(36))
    }
    // evaluationDependsOn 放在 afterEvaluate 注册之后，避免对已 evaluate 的模块调用 afterEvaluate。
    evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
