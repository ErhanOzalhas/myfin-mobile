pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    // Sürüm 1.0.0'a yükseltildi (Gradle 9 ve Java 17+ uyumlu, IBM_SEMERU hatasını çözer)
    id("org.gradle.toolchains.foojay-resolver-convention") version "1.0.0"

    // Flutter eklentisi
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"

    // Uyarıları çözmek ve Flutter standardına uymak için sürümler yükseltildi:
    id("com.android.application") version "8.11.1" apply false
    id("com.google.gms.google-services") version "4.3.15" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}

include(":app")
