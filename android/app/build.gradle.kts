import java.util.Properties
import com.android.build.gradle.internal.api.ApkVariantOutputImpl

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val ownProperties = Properties().apply {
    rootProject.file("../own.properties").inputStream().use { load(it) }
}
val keystoreProperties = Properties()
val keystorePropertiesFile = file(
    System.getenv("GYMMANE_SIGNING_PROPERTIES")
        ?: "${System.getProperty("user.home")}/.local/share/gymmane-own/signing.properties"
)
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}
fun validateOwnReleaseSigning() {
    require(keystorePropertiesFile.isFile) {
        "EnoGym release signing is missing. Run python3 scripts/setup-own-signing.py first."
    }
    for (name in listOf("keyAlias", "keyPassword", "storeFile", "storePassword")) {
        require(!keystoreProperties.getProperty(name).isNullOrBlank()) { "Missing release signing field: $name" }
    }
    require(file(keystoreProperties.getProperty("storeFile")).isFile) { "Release keystore is missing." }
}
gradle.taskGraph.whenReady {
    if (allTasks.any { it.project == project && it.name.contains("release", ignoreCase = true) }) {
        validateOwnReleaseSigning()
    }
}

android {
    namespace = "com.gymmane.app"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = ownProperties.getProperty("applicationId")
        minSdk = 24
        targetSdk = 36
        versionCode = ownProperties.getProperty("versionCode").toInt()
        versionName = ownProperties.getProperty("versionName")
        manifestPlaceholders["ownAppName"] = ownProperties.getProperty("appName")
        resValue("string", "own_app_name", ownProperties.getProperty("appName"))
    }

    dependenciesInfo {
        includeInApk = false
        includeInBundle = false
    }

    if (keystorePropertiesFile.exists()) {
        signingConfigs {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = keystoreProperties["storeFile"]?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        debug {
            applicationIdSuffix = ".debug"
            manifestPlaceholders["ownAppName"] = "${ownProperties.getProperty("appName")} Debug"
        }
        release {
            signingConfig = signingConfigs.findByName("release")
        }
    }
}

val abiCodes = mapOf("armeabi-v7a" to 1, "arm64-v8a" to 2, "x86_64" to 3)
android.applicationVariants.configureEach {
    val variant = this
    variant.outputs.forEach { output ->
        val abiVersionCode = abiCodes[output.filters.find { it.filterType == "ABI" }?.identifier]
        if (abiVersionCode != null) {
            (output as ApkVariantOutputImpl).versionCodeOverride = variant.versionCode * 10 + abiVersionCode
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

flutter {
    source = "../.."
}
