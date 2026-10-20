import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Builds that need the release key and a Maps key. Debug builds
// (`flutter run`, `flutter build apk --debug`) need neither.
fun Gradle.buildsRelease(): Boolean =
    startParameter.taskNames.any { it.contains("Release", ignoreCase = true) }

// Google Maps key for the native SDK. CI passes it as the GOOGLE_MAPS_API_KEY
// env var; locally, add `MAPS_API_KEY=...` to android/local.properties.
// There is no built-in key: without one a debug build still starts (maps show
// a notice) and a release build stops below.
val localProperties = Properties().apply {
    val file = rootProject.file("local.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}
val mapsApiKey: String =
    System.getenv("GOOGLE_MAPS_API_KEY")?.takeIf { it.isNotBlank() }
        ?: localProperties.getProperty("MAPS_API_KEY")?.takeIf { it.isNotBlank() }
        ?: ""

// --dart-define values Flutter hands to Gradle (base64 KEY=VALUE, comma
// separated). Only the names are checked; values are never printed.
val dartDefines: Map<String, String> =
    (project.findProperty("dart-defines") as String?)
        ?.split(",")
        ?.mapNotNull { encoded ->
            runCatching { String(java.util.Base64.getDecoder().decode(encoded)) }.getOrNull()
        }
        ?.mapNotNull { pair -> pair.split("=", limit = 2).takeIf { it.size == 2 }?.let { it[0] to it[1] } }
        ?.toMap()
        ?: emptyMap()

// Upload key for Play. android/key.properties (never committed, see
// key.properties.example) points to the keystore; CI writes it from secrets.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) keystorePropertiesFile.inputStream().use { load(it) }
}

if (gradle.buildsRelease()) {
    if (!keystorePropertiesFile.exists()) {
        throw GradleException(
            "Release build without android/key.properties. Create it from " +
                "android/key.properties.example with your upload keystore (see DEPLOY.md, " +
                "\"Firma de Android\"). Debug builds do not need it."
        )
    }
    val missing = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
        .filter { keystoreProperties.getProperty(it).isNullOrBlank() }
    if (missing.isNotEmpty()) {
        throw GradleException("android/key.properties is missing: ${missing.joinToString()}")
    }
    if (mapsApiKey.isEmpty()) {
        throw GradleException(
            "Release build without a Google Maps key. Set the GOOGLE_MAPS_API_KEY env var " +
                "or MAPS_API_KEY in android/local.properties (see DEPLOY.md, \"Claves de Google Maps\")."
        )
    }
    // Firebase app of this build: no default key in the code (B8).
    val missingFirebase = listOf("FIREBASE_ANDROID_APP_ID", "FIREBASE_ANDROID_API_KEY")
        .filter { dartDefines[it].isNullOrBlank() }
    if (missingFirebase.isNotEmpty()) {
        throw GradleException(
            "Release build without Firebase Android config: pass " +
                missingFirebase.joinToString { "--dart-define=$it=..." } +
                " (see DEPLOY.md, \"Claves de Firebase de las apps nativas\")."
        )
    }
}

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
        applicationId = "com.luxelane.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["mapsApiKey"] = mapsApiKey
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                storeFile = rootProject.file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}
