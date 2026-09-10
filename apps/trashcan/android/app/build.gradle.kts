plugins {
    id("com.android.application")
    // ☠ Senza questo il Kotlin del modulo app non viene compilato: l'APK si costruisce
    // senza errori, si installa, e poi il sistema risponde "Activity class does not
    // exist" perche' MainActivity non esiste come classe. Il template di flutter create
    // lo aveva omesso, contando su android.builtInKotlin che era a false.
    id("org.jetbrains.kotlin.android")
    // Il plugin Flutter va applicato DOPO quelli Android e Kotlin.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.smp.trashcan"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications usa le API di data e ora di Java 8, che su Android
        // vecchi non esistono: il desugaring le rende disponibili fino a minSdk 24.
        // Senza, la build fallisce con "requires core library desugaring to be enabled".
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // Immutabile dopo il primo upload su Play: non si rinomina e non si migra.
        applicationId = "com.smp.trashcan"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
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

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}
