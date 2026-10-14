import java.io.FileInputStream
import java.util.Properties

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

val releaseStoreFile = keystoreProperties.getProperty("storeFile")?.trim().orEmpty()
val releaseStorePassword = keystoreProperties.getProperty("storePassword")
val releaseKeyAlias = keystoreProperties.getProperty("keyAlias")
val releaseKeyPassword = keystoreProperties.getProperty("keyPassword")
val releaseSigningConfigured =
    releaseStoreFile.isNotEmpty() &&
    !releaseStorePassword.isNullOrEmpty() &&
    !releaseKeyAlias.isNullOrEmpty() &&
    !releaseKeyPassword.isNullOrEmpty()

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.opensource.clearscan"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.opensource.clearscan"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    if (releaseSigningConfigured) {
        signingConfigs {
            create("release") {
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
                storeFile = rootProject.file(releaseStoreFile)
                storePassword = releaseStorePassword
            }
        }
    }

    buildTypes {
        release {
            if (releaseSigningConfigured) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

val validateReleaseSigning by tasks.registering {
    doLast {
        val requiredProperties = mapOf(
            "storeFile" to releaseStoreFile,
            "storePassword" to releaseStorePassword,
            "keyAlias" to releaseKeyAlias,
            "keyPassword" to releaseKeyPassword,
        )
        val missingProperties = requiredProperties
            .filterValues { it.isNullOrBlank() }
            .keys
        if (missingProperties.isNotEmpty()) {
            throw GradleException(
                "Release signing is not configured. Add the following values to " +
                    "${keystorePropertiesFile.path}: ${missingProperties.joinToString()}."
            )
        }

        val storeFile = rootProject.file(releaseStoreFile)
        if (!storeFile.isFile) {
            throw GradleException("Release keystore not found: ${storeFile.path}")
        }
    }
}

tasks.configureEach {
    if ((name.startsWith("package") || name.startsWith("bundle")) &&
        name.endsWith("Release")
    ) {
        dependsOn(validateReleaseSigning)
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
