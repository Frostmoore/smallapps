import java.util.Properties

// La firma di release sta fuori dal repository.
//
// ☠ android/key.properties e' in .gitignore e NON va committato: contiene il percorso
// del keystore e la sua password. Il keystore stesso vive in %USERPROFILE%/.android-keys,
// mai dentro il progetto. Un keystore perso significa non poter piu' aggiornare l'app su
// Play: Google non lo rigenera e l'applicationId non si riusa.
//
// Se il file non c'e', la release si firma con la chiave di debug: serve a far girare
// `flutter run --release` in locale, e produce un artefatto che Play rifiuta. E' il
// comportamento voluto, perche' fallire in fase di upload e' meglio che pubblicare
// firmato male.
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}

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
    namespace = "com.smp.filmtracker"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications (dentro micro_core, anche se Film Tracker non pianifica
        // notifiche) usa le API di data e ora di Java 8, che su Android vecchi non esistono: il
        // desugaring le rende disponibili fino a minSdk 24.
        // Senza, la build fallisce con "requires core library desugaring to be enabled".
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // Immutabile dopo il primo upload su Play: non si rinomina e non si migra.
        applicationId = "com.smp.filmtracker"
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

    signingConfigs {
        create("release") {
            val path = keystoreProperties.getProperty("storeFile")
            if (path != null) {
                storeFile = file(path)
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                // Il keystore e' un PKCS#12 (.p12), non un JKS: senza dichiararlo Gradle
                // prova a leggerlo come JKS e fallisce con un errore sul formato che non
                // nomina mai il formato.
                storeType = "PKCS12"
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystoreProperties.getProperty("storeFile") != null) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            // Il codice Dart e' gia' compilato in AOT: qui si riduce solo il Java/Kotlin,
            // che e' poco. isShrinkResources richiede isMinifyEnabled e toglie le risorse
            // non referenziate, fra cui quelle dei plugin che non usiamo.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
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
