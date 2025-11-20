plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.paqueteria.paqueteria_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Flag to enable support for the new language APIs
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }
    
    // Enable multidex support
    buildFeatures {
        viewBinding = true
    }

    defaultConfig {
        applicationId = "com.paqueteria.paqueteria_app"
        minSdk = flutter.minSdkVersion // Android 5.0 (Lollipop)
        targetSdk = 34 // Android 14
        versionCode = 1
        versionName = "1.0.0"
        multiDexEnabled = true

        // Optimizaciones para dispositivos de 2GB RAM
        resConfigs("en", "es") // Solo idiomas necesarios
        vectorDrawables.useSupportLibrary = true

        // Limitar densidades de pantalla para reducir tamaño APK
        ndk {
            abiFilters.addAll(listOf("armeabi-v7a", "arm64-v8a"))
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")

            // Optimizaciones para dispositivos de 2GB RAM
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            // Reducir overhead en debug para testing en dispositivos low-end
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    // Optimización de pantallas para TC26
    packagingOptions {
        resources {
            excludes += setOf(
                "META-INF/DEPENDENCIES",
                "META-INF/LICENSE",
                "META-INF/LICENSE.txt",
                "META-INF/NOTICE",
                "META-INF/NOTICE.txt"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk7:1.9.22")
    // Core library desugaring
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    // Multidex support
    implementation("androidx.multidex:multidex:2.0.1")
}
