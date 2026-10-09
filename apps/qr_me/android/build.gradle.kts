allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// ☠ receive_sharing_intent 1.9.0 (tramite micro_share) dichiara `compileSdk 37` nel suo
// build.gradle: con AGP 9 diventa la piattaforma "android-37", ma l'SDK installa la 37 come
// "android-37.0" e il build fallisce con "Failed to find target with hash string 'android-37'"
// (scoperto con F17.4, 2026-10-09). Il plugin si compila con la 36 come le altre dipendenze:
// non usa nessuna API della 37. `finalizeDsl` gira DOPO il build.gradle del plugin, quindi vince.
// Da togliere quando il plugin (o l'SDK) si allinea; F16/F18/F19 che useranno micro_share
// avranno bisogno dello stesso blocco finche' non si sposta nel package.
subprojects {
    if (name == "receive_sharing_intent") {
        plugins.withId("com.android.library") {
            extensions.configure<com.android.build.api.variant.LibraryAndroidComponentsExtension>("androidComponents") {
                finalizeDsl { it.compileSdk = 36 }
            }
        }
    }
}
