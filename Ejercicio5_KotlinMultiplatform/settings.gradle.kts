rootProject.name = "CamaraMicrofonoKMP"
enableFeaturePreview("TYPESAFE_PROJECT_ACCESSORS")

pluginManagement {
    repositories {
        google {
            mavenContent {
                includeGroupAndSubgroups("androidx")
                includeGroupAndSubgroups("com.android")
                includeGroupAndSubgroups("com.google")
            }
        }
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositories {
        google {
            mavenContent {
                includeGroupAndSubgroups("androidx")
                includeGroupAndSubgroups("com.android")
                includeGroupAndSubgroups("com.google")
            }
        }
        mavenCentral()
    }
}

plugins {
    id("org.gradle.toolchains.foojay-resolver-convention") version "1.0.0"
}

// shared     -> módulo KMP: commonMain (lógica + UI Compose), androidMain e iosMain (expect/actual)
// androidApp -> aplicación Android que empaqueta el módulo compartido
// iosApp     -> proyecto de Xcode (no es módulo de Gradle) que usa el framework "Shared"
include(":shared")
include(":androidApp")
