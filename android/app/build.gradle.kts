import com.android.build.gradle.internal.api.ApkVariantOutputImpl
import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties()
if (keyPropertiesFile.exists()) {
    keyProperties.load(FileInputStream(keyPropertiesFile))
}

android {
    namespace = "com.njerahouse.tafsiri"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.njerahouse.tafsiri"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Tesseract4Android ships a plain and an OpenMP flavour; the app has no
        // flavours of its own, so it has to say which one it means.
        missingDimensionStrategy("parallelization", "standard")
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    dependenciesInfo {
        includeInApk = false
        includeInBundle = false
    }

    signingConfigs {
        if (keyPropertiesFile.exists()) {
            create("release") {
                keyAlias = keyProperties["keyAlias"] as String
                keyPassword = keyProperties["keyPassword"] as String
                storeFile = file(keyProperties["storeFile"] as String)
                storePassword = keyProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // F-Droid signs every APK with its own key and wants it unsigned
            // (ADR-075). Asked for by name rather than inferred from a missing
            // key.properties, because a missing key file on a developer's
            // machine should still give an installable, debug-signed build —
            // and checked first, so it wins even where a key is present.
            signingConfig = when {
                System.getenv("TAFSIRI_UNSIGNED") == "1" -> null
                keyPropertiesFile.exists() -> signingConfigs.getByName("release")
                else -> signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

// F-Droid builds one APK per ABI and keeps the one with the highest version
// code, so the ABI has to be the lowest digit: versionCode * 10 + abi. Flutter's
// own split scheme (abi * 1000 + versionCode) puts it in front, where an old
// x86_64 build outranks a newer arm one. Only split APKs carry an ABI filter;
// the universal APK and the Play bundle keep the plain versionCode (ADR-077).
val abiCodes = mapOf("armeabi-v7a" to 1, "arm64-v8a" to 2, "x86_64" to 3)
android.applicationVariants.configureEach {
    val variant = this
    variant.outputs.forEach { output ->
        val abiVersionCode = abiCodes[output.filters.find { it.filterType == "ABI" }?.identifier]
        if (abiVersionCode != null) {
            (output as ApkVariantOutputImpl).versionCodeOverride = variant.versionCode * 10 + abiVersionCode
        }
    }
}

dependencies {
    implementation(project(":tesseract4android"))
}
