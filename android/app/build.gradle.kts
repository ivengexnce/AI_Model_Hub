plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.aimodelhub.ai_model_hub"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.example.aimodelhub.ai_model_hub"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

tasks.matching { it.name.startsWith("compileFlutterBuild") }.configureEach {
    doFirst {
        val flutterIntermediates = layout.buildDirectory.dir("intermediates/flutter").get().asFile
        if (flutterIntermediates.exists()) {
            flutterIntermediates.deleteRecursively()
        }
    }
}
