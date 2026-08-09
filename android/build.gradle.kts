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
    val sub = this
    // Gradle 9 禁止对已 evaluate 完成的 project 再注册 afterEvaluate，故改用 plugins.withId：
    // 在 Android 插件 apply 的同一步(配置阶段内)同步触发，覆盖已 apply 与将来 apply 的模块，
    // 且不再触碰 afterEvaluate，避免 "Cannot run afterEvaluate when already evaluated"。
    val applyCompileSdk: () -> Unit = {
        // 不依赖 AGP 内部类型(AGP9 下 CommonExtension/BaseExtension 接口常被重构)，
        // 直接反射调用 setCompileSdk/setCompileSdkVersion(int)，跨版本通用。
        val androidExt = sub.extensions.findByName("android")
        if (androidExt != null) {
            val setter = androidExt.javaClass.methods.firstOrNull { m ->
                m.parameterCount == 1 &&
                    (m.name == "setCompileSdk" || m.name == "setCompileSdkVersion")
            }
            // Method.invoke(Object, Object...) 在 Kotlin 中变参期望 Array<out Any?>，
            // 直接传 36(Int) 会被推断成 Array<Int> 导致 argument type mismatch，故显式装箱。
            setter?.invoke(androidExt, arrayOf<Any?>(36))
        }
    }
    sub.plugins.withId("com.android.application") { applyCompileSdk() }
    sub.plugins.withId("com.android.library") { applyCompileSdk() }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
