plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.marwadi_parking"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Required for flutter_local_notifications
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }


    defaultConfig {
       applicationId = "com.example.marwadi_parking"

       minSdk = flutter.minSdkVersion
       targetSdk = flutter.targetSdkVersion

       versionCode = flutter.versionCode
       versionName = flutter.versionName
       
       multiDexEnabled = true
    }




    buildTypes {
        release {
            // Signing with debug keys for project submission
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // This library allows modern Java features on older phones
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

flutter {
    source = "../.."
}
