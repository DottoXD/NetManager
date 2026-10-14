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

data class RustTarget(
    val rustTriple: String,
    val clangPrefix: String,
    val abi: String
)

val rustAbiTargets = listOf(
    RustTarget("aarch64-linux-android", "aarch64-linux-android", "arm64-v8a"),
    RustTarget("armv7-linux-androideabi", "armv7a-linux-androideabi", "armeabi-v7a"),
)

val netManagerDiagDir: File? = rootProject.file("../NetManagerDiag")
val netManagerDiagAvailable = netManagerDiagDir?.let { it.exists() && it.resolve("Cargo.toml").exists() } ?: false
val netManagerDiagJniLibsDir =
    layout.buildDirectory.dir("netManagerDiag/jniLibs")
val netManagerDiagCargoTargetDir =
    layout.buildDirectory.dir("netManagerDiag/cargo-target")

if (netManagerDiagAvailable) {
    android.sourceSets
        .getByName("main")
        .jniLibs
        .srcDir(netManagerDiagJniLibsDir.get().asFile)
}

val buildNetManagerDiag = tasks.register("buildNetManagerDiag") {
    onlyIf { netManagerDiagAvailable }

    val diagDir = requireNotNull(netManagerDiagDir)

    inputs.files(fileTree(diagDir) {
        exclude("target/**", ".git/**")
    })

    val outDir = netManagerDiagJniLibsDir.get().asFile
    val cargoTargetDir = netManagerDiagCargoTargetDir.get().asFile

    outputs.dir(outDir)

    doLast {
        val os = org.gradle.internal.os.OperatingSystem.current()

        val hostTag = when {
            os.isMacOsX -> "darwin-x86_64"
            os.isWindows -> "windows-x86_64"
            else -> "linux-x86_64"
        }

        val exeSuffix = if (os.isWindows) ".cmd" else ""
        val arName = if (os.isWindows) "llvm-ar.exe" else "llvm-ar"

        val toolchainBin =
            android.ndkDirectory.resolve("toolchains/llvm/prebuilt/$hostTag/bin")
        val minSdkForNdk =
            android.defaultConfig.minSdk ?: 24
        val llvmAr =
            toolchainBin.resolve(arName)

        logger.lifecycle("NetManagerDiag: source dir is $diagDir")
        logger.lifecycle("NetManagerDiag: cargo target dir is $cargoTargetDir")
        logger.lifecycle("NetManagerDiag: using NDK at ${android.ndkDirectory}")
        logger.lifecycle("NetManagerDiag: using toolchain bin $toolchainBin")

        val rustupResult = providers.exec {
            workingDir(diagDir)

            commandLine(
                listOf("rustup", "target", "add") +
                        rustAbiTargets.map { it.rustTriple }
            )

            isIgnoreExitValue = true
        }.result.get()

        if (rustupResult.exitValue != 0) {
            logger.warn(
                "NetManagerDiag: rustup target add exited with ${rustupResult.exitValue}! Continuing anyway..."
            )
        }

        rustAbiTargets.forEach { target ->
            val clang =
                toolchainBin.resolve(
                    "${target.clangPrefix}${minSdkForNdk}-clang$exeSuffix"
                )

            val envKey =
                target.rustTriple
                    .uppercase()
                    .replace("-", "_")

            logger.lifecycle(
                "NetManagerDiag: building ${target.rustTriple} for ${target.abi}"
            )

            val cargoResult = providers.exec {
                workingDir(diagDir)

                commandLine(
                    "cargo",
                    "build",
                    "--release",
                    "--target",
                    target.rustTriple,
                    "--target-dir",
                    cargoTargetDir.absolutePath,
                    "-p",
                    "netmanager-diag",
                    "--bin",
                    "NetManagerDiag"
                )

                environment(
                    "CC_${target.rustTriple.replace("-", "_")}",
                    clang.absolutePath
                )

                environment(
                    "AR_${target.rustTriple.replace("-", "_")}",
                    llvmAr.absolutePath
                )

                environment(
                    "CARGO_TARGET_${envKey}_LINKER",
                    clang.absolutePath
                )
            }.result.get()

            if (cargoResult.exitValue != 0) {
                throw GradleException(
                    "Cargo build failed for ${target.rustTriple} " + "(exit code ${cargoResult.exitValue}). "
                )
            }

            val builtBinary = cargoTargetDir.resolve(
                "${target.rustTriple}/release/NetManagerDiag"
            )

            logger.lifecycle(
                "NetManagerDiag: expecting binary at $builtBinary!"
            )

            val destDir =
                outDir.resolve(target.abi)

            destDir.mkdirs()

            val destination =
                destDir.resolve("libNetManagerDiag.so")

            builtBinary.copyTo(
                destination,
                overwrite = true
            )

            logger.lifecycle(
                "NetManagerDiag: copied $builtBinary to $destination"
            )
        }
    }
}

tasks.named("preBuild") {
    dependsOn(buildNetManagerDiag)
}
