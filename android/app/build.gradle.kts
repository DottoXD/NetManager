import org.jetbrains.kotlin.gradle.dsl.JvmTarget
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

val flutterRootDir: File? = rootProject.projectDir.parentFile
val pubspecFile = File(flutterRootDir, "pubspec.yaml")
val pubspecText = if (pubspecFile.exists()) pubspecFile.readText() else ""
val buildNumberMatch = Regex("""version:\s*[\d\.]+\+(\d+)""").find(pubspecText)
val rawVersionCode = buildNumberMatch?.groupValues?.get(1)?.toIntOrNull() ?: 15

val isReleaseBuild = gradle.startParameter.taskNames.any {
    it.contains("Release", ignoreCase = true)
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
        versionCode = rawVersionCode
        versionName = flutter.versionName
    }

    splits {
        abi {
            isEnable = isReleaseBuild
            reset()
            include("armeabi-v7a", "arm64-v8a")
            isUniversalApk = true
        }
    }

    packaging {
        jniLibs {
            if (isReleaseBuild) {
                excludes += listOf(
                    "lib/x86/**",
                    "lib/x86_64/**"
                )
            }
        }
    }

    dependenciesInfo {
        includeInApk = false
        includeInBundle = false
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

            externalNativeBuild {
                cmake {
                    cppFlags(
                        "-ffile-prefix-map=${project.rootDir}=/build",
                        "-ffile-prefix-map=/home/runner/work/NetManager/NetManager=."
                    )
                    arguments.add("-DCMAKE_SHARED_LINKER_FLAGS=-Wl,--build-id=none")
                }
            }
        }

        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    buildFeatures {
        aidl = true
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

val abiCodes = mapOf("armeabi-v7a" to 1, "arm64-v8a" to 2, "x86_64" to 3)

androidComponents {
    onVariants { variant ->
        variant.outputs.forEach { output ->
            val abiFilter = output.filters.find { it.filterType.name == "ABI" }?.identifier
            val abiVersionCode = abiCodes[abiFilter] ?: 0

            output.versionCode.set((rawVersionCode * 10) + 5000 + abiVersionCode)
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("com.google.code.gson:gson:2.14.0")
    implementation("com.squareup.okhttp3:okhttp:5.5.0")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")

    implementation("dev.rikka.shizuku:api:13.1.5")
    implementation("dev.rikka.shizuku:provider:13.1.5")

    "playImplementation"("com.google.android.gms:play-services-wearable:20.0.1")
}
