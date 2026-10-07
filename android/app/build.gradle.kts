import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing: create android/key.properties (never commit it):
//   storeFile=/absolute/path/to/upload-keystore.jks
//   storePassword=...
//   keyAlias=upload
//   keyPassword=...
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}

android {
    namespace = "com.example.luxelane"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Android Maps SDK key: pass -PMAPS_API_KEY=... or set the env var.
        manifestPlaceholders["MAPS_API_KEY"] =
            (project.findProperty("MAPS_API_KEY") as String?) ?: System.getenv("MAPS_API_KEY") ?: ""
    }

    // Two apps from one codebase:
    //   flutter build appbundle --flavor rider  -t lib/main.dart
    //   flutter build appbundle --flavor driver -t lib/main_driver.dart
    // ⚠ Application IDs are permanent once published on Google Play.
    flavorDimensions += "app"
    productFlavors {
        create("rider") {
            dimension = "app"
            applicationId = "com.luxelane.rider"
            resValue("string", "app_name", "Luxelane")
        }
        create("driver") {
            dimension = "app"
            applicationId = "com.luxelane.driver"
            resValue("string", "app_name", "Luxelane Chófer")
        }
    }

    signingConfigs {
        create("release") {
            if (keystoreProperties.isNotEmpty()) {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Falls back to debug keys only when key.properties is missing
            // (local testing); Play Console rejects debug-signed bundles.
            signingConfig = if (keystoreProperties.isNotEmpty()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
