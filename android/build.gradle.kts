allprojects {
    repositories {
        google()
        mavenCentral()
        // flutter_wake_word (DaVoice) ships its native keyword-detection AAR
        // as a local flat-dir maven repo inside the plugin itself rather
        // than publishing to a public repo; the plugin's own build.gradle
        // registers this too, but that doesn't reach :app's dependency
        // resolution — DaVoice's own setup docs say to add it here too.
        maven { url = uri("${project(":flutter_wake_word").projectDir}/libs") }
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
    // porcupine_flutter (wake-word detection) and its flutter_voice_processor
    // dependency both ship pinned to compileSdk 31, too low for their own
    // transitive androidx deps (fragment/window/etc. need 33-34+), which
    // fails Android Gradle Plugin's AAR metadata check. No newer version
    // fixes this (both are latest as of writing) — force them to compile
    // against the same SDK as :app. Bump the literal below if this app's
    // compileSdk changes.
    // Must be registered here, before evaluationDependsOn below — that call
    // triggers early evaluation of some subprojects, so an afterEvaluate
    // registered any later throws "project already evaluated".
    afterEvaluate {
        if (project.name == "flutter_voice_processor" || project.name == "porcupine_flutter") {
            extensions.findByType(com.android.build.gradle.BaseExtension::class.java)
                ?.compileSdkVersion(36)
        }
    }
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
