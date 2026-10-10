// Plugin micro_ocr, lato Android: PP-OCRv5 mobile latin su ONNX Runtime 1.28.0.
// Specsheet: develop_microapps.md F12.1.2 e F12.1.9; atlante: ../codebase_reference.md.
group = "com.smp.micro_ocr"
version = "1.0.0"

buildscript {
    val kotlinVersion = "2.4.0"
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:9.1.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

plugins {
    id("com.android.library")
}

/** ☠ L'UNICA versione di ONNX Runtime ammessa: dalla 1.29 c'e' la telemetria Microsoft
 *  accesa di default (ContentProvider TelemetryInitializer + INTERNET). Cambiarla richiede
 *  una voce nuova in memory/decisioni.md (F12.0 punto 8). */
val versioneOrt = "1.28.0"

android {
    namespace = "com.smp.micro_ocr"

    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
        getByName("test") {
            java.srcDirs("src/test/kotlin")
        }
    }

    defaultConfig {
        minSdk = 24
        // ☠ JNI di ORT + R8: senza keep un crash che c'e' solo in release (§10).
        consumerProguardFiles("consumer-rules.pro")
    }

    // ☠ `androidResources { noCompress += "onnx" }` QUI NON SERVE: la compressione degli asset la
    // decide il modulo dell'APP che impacchetta (verificato il 2026-10-10: con la riga solo nel
    // plugin i .onnx uscivano «Defl:N»). La riga va nel build.gradle.kts dell'app: vedi
    // codebase_reference.md, «Come un'app aggancia micro_ocr».

    testOptions {
        unitTests {
            isIncludeAndroidResources = true
            all {
                it.useJUnitPlatform()
                it.outputs.upToDateWhen { false }
                // Il banco di parita' JVM (ParitaJvmTest) si accende solo con queste variabili.
                listOf("MICRO_OCR_PARITA_IN", "MICRO_OCR_PARITA_OUT").forEach { nome ->
                    System.getenv(nome)?.let { valore -> it.environment(nome, valore) }
                }
                // ☠ Su Windows i JDK portano un msvcp140.dll vecchio e onnxruntime.dll (desktop)
                // non si inizializza: per il banco si puo' indicare un java con i runtime di
                // System32 copiati nella sua bin/ (vedi codebase_reference.md, trappole).
                System.getenv("MICRO_OCR_JAVA")?.let { java -> it.executable = java }
                it.maxHeapSize = "2g"
                it.testLogging {
                    events("passed", "skipped", "failed", "standardError")
                }
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    implementation("com.microsoft.onnxruntime:onnxruntime-android") {
        version { strictly(versioneOrt) }          // ☠ MAI 1.29+: telemetria (F12.0 punto 8)
    }
    implementation("androidx.exifinterface:exifinterface:1.4.1")   // rotazione delle foto

    testImplementation("org.jetbrains.kotlin:kotlin-test")
    // ⚑ Sulla JVM l'AAR Android di ORT non ha le librerie native per Windows/Linux/macOS:
    // per il banco di parita' JVM si usa l'ORT "desktop" della STESSA versione (solo test,
    // non finisce mai nell'APK). Stessa API Java, stesso motore.
    testImplementation("com.microsoft.onnxruntime:onnxruntime") {
        version { strictly(versioneOrt) }
    }
}

// Nei test JVM le classi ai.onnxruntime.* devono venire SOLO dal jar desktop (che ha le .dll/.so
// per il PC): togliere l'AAR Android dal classpath di esecuzione dei test evita classi doppie.
configurations.matching { it.name.endsWith("UnitTestRuntimeClasspath") }.configureEach {
    exclude(group = "com.microsoft.onnxruntime", module = "onnxruntime-android")
}
