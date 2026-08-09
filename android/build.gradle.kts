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
        val androidExt = extensions.findByName("android") as? com.android.build.api.dsl.CommonExtension<*, *, *, *, *>
        androidExt?.compileSdk = 36
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
