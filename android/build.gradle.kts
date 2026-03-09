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

// Fix namespace for older plugins that don't set it in their build.gradle
subprojects {
    project.plugins.whenPluginAdded {
        if (this is com.android.build.gradle.LibraryPlugin) {
            val android = project.extensions.getByType(com.android.build.gradle.LibraryExtension::class.java)
            if (android.namespace.isNullOrEmpty()) {
                val manifest = file("${project.projectDir}/src/main/AndroidManifest.xml")
                if (manifest.exists()) {
                    val pkg = Regex("""package\s*=\s*"([^"]+)"""")
                        .find(manifest.readText())
                        ?.groupValues?.get(1)
                    if (!pkg.isNullOrEmpty()) {
                        android.namespace = pkg
                    }
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
