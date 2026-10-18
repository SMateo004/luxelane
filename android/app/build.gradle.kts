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

// Google Maps key for the native SDK: -PMAPS_API_KEY=..., the MAPS_API_KEY or
// GOOGLE_MAPS_API_KEY env var (CI), or `MAPS_API_KEY=...` in
// android/local.properties. Falls back to the project key (same as AppConfig
// and the iOS xcconfig) so the map never renders blank when none is set.
val localProperties = Properties().apply {
    val file = rootProject.file("local.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}
val mapsApiKey: String =
    (project.findProperty("MAPS_API_KEY") as String?)?.takeIf { it.isNotBlank() }
        ?: System.getenv("MAPS_API_KEY")?.takeIf { it.isNotBlank() }
        ?: System.getenv("GOOGLE_MAPS_API_KEY")?.takeIf { it.isNotBlank() }
        ?: localProperties.getProperty("MAPS_API_KEY")?.takeIf { it.isNotBlank() }
        ?: "AIzaSyBbDde6GtLHy9_6qys4BMmq2P2G2INRUkM"

android {
    namespace = "com.luxelane.app"
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
        manifestPlaceholders["mapsApiKey"] = mapsApiKey
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
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // AppCompat themes (res/values*/styles.xml), required by flutter_stripe.
    implementation("androidx.appcompat:appcompat:1.7.0")
}
