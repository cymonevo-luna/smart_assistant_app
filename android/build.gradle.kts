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
