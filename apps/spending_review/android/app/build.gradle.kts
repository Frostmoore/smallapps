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
    // exist" perche' MainActivity non esiste come classe (vedi QR Me).
    id("org.jetbrains.kotlin.android")
    // Il plugin Flutter va applicato DOPO quelli Android e Kotlin.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // ⚑ Senza trattino basso, come l'applicationId (F12.0 punto 1): `flutter create` aveva messo
    // com.smp.spending_review.
    namespace = "com.smp.spendingreview"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    // ⚑ I modelli PP-OCRv5 (12,7 MB, negli asset di micro_ocr) non compressi nell'APK: i pesi in
    // virgola mobile si comprimono poco e decomprimerli a ogni avvio a freddo costa tempo
    // (F12.1.2). ☠ Nel build.gradle del plugin non ha effetto: la compressione la decide il
    // modulo app (micro_ocr/codebase_reference.md §8).
    androidResources { noCompress += "onnx" }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications (dentro micro_core, anche se Spending Review non pianifica
        // notifiche) usa le API di data e ora di Java 8: il desugaring le rende disponibili fino
        // a minSdk 24. Senza, la build fallisce con "requires core library desugaring".
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // Immutabile dopo il primo upload su Play: non si rinomina e non si migra.
        applicationId = "com.smp.spendingreview"
        // 24 come le altre app e come micro_ocr (ONNX Runtime 1.28 su Android 7+).
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
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
                // Il keystore e' un PKCS#12 (.p12), non un JKS: senza dichiararlo Gradle prova a
                // leggerlo come JKS e fallisce con un errore che non nomina mai il formato.
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
            // Il codice Dart e' gia' compilato in AOT: qui si riduce solo il Java/Kotlin.
            // ☠ ONNX Runtime passa da JNI: le sue classi le tiene il consumer-rules.pro di
            // micro_ocr (F12.1.9); un crash «solo in release» e' il rischio di §10.
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

// ─────────────────────────────────────────────────────────────────────────────────────────────
// Guardia di privacy della release (develop_microapps.md F12.1.2, punti 1 e 2): lo script
// CONDIVISO di micro_ocr, una riga (packages/micro_ocr/codebase_reference.md §8).
//
// ☠ Perche' esiste: ONNX Runtime dalla 1.29 contiene telemetria Microsoft accesa di default
// (ContentProvider `ai.onnxruntime.TelemetryInitializer`, permesso INTERNET, invio a
// mobile.events.data.microsoft.com). micro_ocr la blocca a 1.28.0 con `strictly`, ma un plugin
// nuovo, un aggiornamento o un Dependabot possono portare altro: il task `verificaPrivacyOcr` fa
// FALLIRE la build di release invece di pubblicare un'app che telefona.
// ⚑ INTERNET nel manifest c'e' comunque (Play Billing, gruppo `com.google.android.datatransport`,
// eccezione del 2026-10-09): il controllo guarda CHI lo porta, leggendo il report di fusione.
// ACCESS_NETWORK_STATE e' ammesso anche da `androidx.media3` (lo porta la fotocamera CameraX).
// ⚑ Fino al 2026-10-11 qui c'era una copia in Kotlin script del controllo, scritta in F12.2c
// perche' lo script condiviso ammetteva solo `transport-backend-cct`: allineato lo script
// (F12.4), la copia e' stata tolta. Una regola sola, in un posto solo.
// ☠ Groovy e non .kts: un .gradle.kts applicato con apply(from) fa cadere
// lintVitalAnalyzeRelease su AGP 9.1 (micro_ocr, 2026-10-10).
// Prova in negativo (F12.4): un <uses-permission INTERNET> aggiunto per prova in src/main fa
// fallire `flutter build apk --release`; tolto, la build passa.
// ─────────────────────────────────────────────────────────────────────────────────────────────
apply(from = "../../../../packages/micro_ocr/android/privacy_ocr.gradle")
