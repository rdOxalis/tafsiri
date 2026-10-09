// Tesseract4Android's own build file reads this from its root project when it
// configures Maven publishing. Built as a module of ours, our project is its
// root, so the value has to live here — set rather than patched in, so the
// submodule stays exactly as upstream tagged it (ADR-075).
extra["tesseract4AndroidVersion"] = "4.9.0"

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
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
