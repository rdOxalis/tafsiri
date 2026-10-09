pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.9.1" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

include(":app")

// Tesseract built from source as a module, not fetched as an AAR (ADR-075).
// The published AAR comes from JitPack, which F-Droid does not accept; the
// source is Apache-2.0 and compiles Tesseract, Leptonica, libjpeg and libpng
// itself, which is exactly what F-Droid's build server can do too.
include(":tesseract4android")
project(":tesseract4android").projectDir =
    file("third_party/Tesseract4Android/tesseract4android")
