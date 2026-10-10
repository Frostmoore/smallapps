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
// Guardia di privacy della release (develop_microapps.md F12.1.2, punti 1 e 2).
//
// ☠ Perche' esiste: ONNX Runtime dalla 1.29 contiene telemetria Microsoft accesa di default
// (ContentProvider `ai.onnxruntime.TelemetryInitializer`, permesso INTERNET, invio a
// mobile.events.data.microsoft.com). micro_ocr la blocca a 1.28.0 con `strictly`, ma un plugin
// nuovo, un aggiornamento o un Dependabot possono portare altro: questo task fa FALLIRE la build
// di release invece di pubblicare un'app che telefona.
//
// ⚑ INTERNET nel manifest c'e' comunque: lo porta Play Billing (`com.google.android.datatransport`,
// eccezione del 2026-10-09). Il controllo quindi non guarda SE c'e', ma CHI lo porta, e per saperlo
// legge il REPORT di fusione (il manifest unito deduplica i permessi e perde le fonti).
// ⚑ `transport-runtime` oltre a `transport-backend-cct`: nel report di QR Me ACCESS_NETWORK_STATE
// arriva da entrambi, tutti e due da Play Billing. Si ammette il GRUPPO datatransport.
// ⚑ Si aggancia a processReleaseMainManifest (che scrive il report) e non al debug: il debug ha
// INTERNET da src/debug per hot reload e DevTools, e lo deve avere.
// Prova in negativo (F12.2c): un <uses-permission INTERNET> aggiunto per prova in src/main fa
// fallire `flutter build apk --release`; tolto, la build passa.
// ─────────────────────────────────────────────────────────────────────────────────────────────

/** Una riga «ADDED/MERGED/IMPLIED from ...» del report e' ammessa solo se viene da qui. */
fun fonteAmmessa(riga: String): Boolean =
    riga.contains("[com.google.android.datatransport:") ||
        riga.contains("\\src\\debug\\") || riga.contains("/src/debug/")

/**
 * Solo per ACCESS_NETWORK_STATE: anche `androidx.media3` (la porta la fotocamera:
 * camera_android_camerax → androidx.camera:camera-video → media3-container → media3-common).
 * ⚑ Trovato alla prima prova della guardia (F12.2c): e' un permesso «normale» che media3 dichiara
 * per sapere il tipo di rete durante lo streaming video, che qui non c'e'; senza INTERNET da fonti
 * non ammesse (controllo che resta stretto) non puo' mandare niente. Toglierlo con
 * tools:node="remove" toglierebbe il permesso anche a Play Billing (datatransport lo usa), con il
 * rischio di un SecurityException nel Pro. Stessa situazione, mai notata, in QR Me.
 */
fun fonteAmmessaStatoRete(riga: String): Boolean = fonteAmmessa(riga) || riga.contains("[androidx.media3:")

/** Le righe-fonte del blocco di un elemento del report (es. `uses-permission#...INTERNET`). */
fun fontiDi(report: List<String>, elemento: String): List<String> {
    val inizio = report.indexOfFirst { it.trim() == elemento }
    if (inizio < 0) return emptyList()
    return report.drop(inizio + 1)
        .takeWhile { r -> listOf("ADDED from", "MERGED from", "IMPLIED from", "INJECTED from").any { r.startsWith(it) } }
}

val verificaPrivacyOcr by tasks.registering {
    group = "verification"
    description = "Fa fallire la release se ONNX Runtime non e' 1.28.0, se c'e' telemetria o se INTERNET arriva da fonti non ammesse (F12.1.2)."
    val reportFile = layout.buildDirectory.file("outputs/logs/manifest-merger-release-report.txt")
    val manifestiUniti = layout.buildDirectory.dir("intermediates/merged_manifest/release")
    val classpath = configurations.named("releaseRuntimeClasspath")
    doLast {
        val errori = mutableListOf<String>()

        // 1. Il report di fusione: chi porta INTERNET e ACCESS_NETWORK_STATE, e niente provider di ORT.
        val report = reportFile.get().asFile
        if (!report.exists()) throw GradleException("verificaPrivacyOcr: manca ${report.path}")
        val righe = report.readLines()
        fontiDi(righe, "uses-permission#android.permission.INTERNET")
            .filterNot { fonteAmmessa(it) }
            .forEach { errori += "INTERNET portato da una fonte non ammessa: $it" }
        fontiDi(righe, "uses-permission#android.permission.ACCESS_NETWORK_STATE")
            .filterNot { fonteAmmessaStatoRete(it) }
            .forEach { errori += "ACCESS_NETWORK_STATE portato da una fonte non ammessa: $it" }
        righe.filter { it.startsWith("provider#") && it.contains("ai.onnxruntime") }
            .forEach { errori += "provider di ONNX Runtime nel manifest: $it" }

        // 2. Il manifest unito, per scrupolo (la stessa stringa puo' arrivare da un meta-data).
        manifestiUniti.get().asFile.walkTopDown()
            .filter { it.name == "AndroidManifest.xml" }
            .filter { it.readText().contains("ai.onnxruntime.TelemetryInitializer") }
            .forEach { errori += "TelemetryInitializer in ${it.path}" }

        // 3. Le dipendenze risolte della release.
        classpath.get().incoming.resolutionResult.allComponents.forEach { c ->
            val m = c.moduleVersion ?: return@forEach
            val id = "${m.group}:${m.name}:${m.version}"
            when {
                m.group == "com.microsoft.onnxruntime" && m.version != "1.28.0" ->
                    errori += "ONNX Runtime diversa da 1.28.0 (telemetria dalla 1.29): $id"
                m.group.startsWith("com.google.mlkit") -> errori += "ML Kit (manda metriche a Google): $id"
                m.group == "com.google.firebase" && m.name.startsWith("firebase-analytics") ->
                    errori += "Firebase Analytics: $id"
                m.group == "com.google.android.gms" && m.name.startsWith("play-services-tflite") ->
                    errori += "LiteRT di Play Services: $id"
                m.group == "com.google.ai.edge.litert" -> errori += "LiteRT 2.x (porta play-services): $id"
            }
        }

        if (errori.isNotEmpty()) {
            throw GradleException(
                "verificaPrivacyOcr: la release NON rispetta la regola «dati solo sul telefono» " +
                    "(develop_microapps.md F12.1.2):\n - " + errori.joinToString("\n - "),
            )
        }
        logger.lifecycle("verificaPrivacyOcr: OK (INTERNET solo da Play Billing, niente telemetria di ORT)")
    }
}

tasks.matching { it.name == "processReleaseMainManifest" }.configureEach {
    finalizedBy(verificaPrivacyOcr)
}
