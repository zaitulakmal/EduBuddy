import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.github.triplet.play")
}

val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties()
if (keyPropertiesFile.exists()) {
    keyProperties.load(FileInputStream(keyPropertiesFile))
}

// Play publishing credentials are optional. The plugin is always applied so
// its tasks exist, but it only gets credentials when the key is actually
// present, so a normal `flutter build` still works on a machine that has never
// seen them.
val playCredentials = rootProject.file("play-service-account.json")
val playPublishingEnabled = playCredentials.exists()

android {
    namespace = "com.edubuddy.edubuddy"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // Play Store identity — permanent, do not change after first upload.
        // (namespace above stays com.edubuddy.edubuddy; only the published ID changes)
        applicationId = "com.zaitulakmal.edubuddy"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keyProperties["keyAlias"] as String
            keyPassword = keyProperties["keyPassword"] as String
            storeFile = file(keyProperties["storeFile"] as String)
            storePassword = keyProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

// ── Play publishing ──────────────────────────────────────────────────────────
// Configured only when android/play-service-account.json is present.
//
//   flutter build appbundle --release
//   cd android && ./gradlew publishReleaseBundle          # -> internal track
//   cd android && ./gradlew publishReleaseBundle -Ptrack=production
//
// The first production release must still be created by hand in Play Console;
// the API cannot bootstrap a track that has never been live. See
// docs/play-api-setup.md.
play {
    if (playPublishingEnabled) {
        serviceAccountCredentials.set(playCredentials)
    }
    // Default to the internal track: publishing straight to production by
    // accident is not a mistake you can take back.
    track.set(providers.gradleProperty("track").getOrElse("internal"))
    // Uploads land as drafts until you explicitly roll them out in Console.
    releaseStatus.set(com.github.triplet.gradle.androidpublisher.ReleaseStatus.DRAFT)
    defaultToAppBundles.set(true)
}
