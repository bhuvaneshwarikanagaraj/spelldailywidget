plugins {
  id("com.android.application")
  id("kotlin-android")

  // Google services Gradle plugin to read google-services.json
  id("com.google.gms.google-services")

  // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
  id("dev.flutter.flutter-gradle-plugin")
}

android {
  // This must match the `package_name` in `google-services.json`.
  namespace = "com.company.spelldaily"
  compileSdk = flutter.compileSdkVersion
  ndkVersion = flutter.ndkVersion

  compileOptions {
    sourceCompatibility = JavaVersion.VERSION_11
    targetCompatibility = JavaVersion.VERSION_11
  }

  kotlinOptions {
    jvmTarget = JavaVersion.VERSION_11.toString()
  }

  defaultConfig {
    // The Application ID must also match the `package_name` in `google-services.json`.
    applicationId = "com.company.spelldaily"
    // You can update the following values to match your application needs.
    // For more information, see: https://flutter.dev/to/review-gradle-config.
    minSdk = flutter.minSdkVersion
    targetSdk = flutter.targetSdkVersion
    versionCode = flutter.versionCode
    versionName = flutter.versionName
  }

  buildTypes {
    release {
      // TODO: Add your own signing config for the release build.
      // Signing with the debug keys for now, so `flutter run --release` works.
      signingConfig = signingConfigs.getByName("debug")
    }
  }
}

flutter {
  source = "../.."
}

dependencies {
  // WorkManager for background jobs (used by widget update service)
  implementation("androidx.work:work-runtime-ktx:2.9.0")

  // Firebase BoM to keep Firebase Android libraries in sync
  implementation(platform("com.google.firebase:firebase-bom:34.5.0"))

  // Example Firebase SDKs (actual usage via Flutter plugins like cloud_firestore)
  implementation("com.google.firebase:firebase-analytics")
  implementation("com.google.firebase:firebase-firestore")
}