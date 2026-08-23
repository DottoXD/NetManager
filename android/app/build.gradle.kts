import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val keystorePropertiesFileExists = keystorePropertiesFile.exists()
if (keystorePropertiesFileExists) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "pw.dotto.netmanager"
    ndkVersion = "28.2.13676358" //flutter.ndkVersion

    compileSdk {
        version = release(37)
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "pw.dotto.netmanager"
        minSdk = 24 //flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    dependenciesInfo {
        includeInApk = false
    }

    signingConfigs {
        create("release") {
            if(keystorePropertiesFileExists) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = keystoreProperties["storeFile"]?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String
            } else {
                initWith(getByName("debug"))
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            vcsInfo.include = false
            isCrunchPngs = false

            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                file("proguard-rules.pro")
            )

            ndk {
                abiFilters.addAll(listOf("armeabi-v7a", "arm64-v8a"))
            }

            externalNativeBuild {
                cmake {
                    cppFlags(
                        "-ffile-prefix-map=${project.rootDir}=/build",
                        "-ffile-prefix-map=/home/runner/work/NetManager/NetManager=."
                    )
                }
            }
        }

        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    flavorDimensions += "distribution"

    productFlavors {
        create("foss") {
            dimension = "distribution"
            applicationIdSuffix = ".foss"
            versionNameSuffix = "-foss"
        }
        create("play") {
            dimension = "distribution"
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
    implementation("com.google.code.gson:gson:2.14.0")
    implementation("com.squareup.okhttp3:okhttp:5.5.0")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")

    "playImplementation"("com.google.android.gms:play-services-wearable:20.0.1")
}
