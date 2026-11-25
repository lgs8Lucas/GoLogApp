import java.io.FileInputStream
import java.util.Base64
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// O Flutter repassa os valores de --dart-define para o Gradle como a project
// property "dart-defines": pares KEY=VALUE em base64, separados por vírgula.
// Extraímos GOOGLE_MAPS_API_KEY daqui pra injetar no AndroidManifest.xml sem
// precisar duplicar a chave em outro arquivo.
val dartDefines: Map<String, String> =
    (project.findProperty("dart-defines") as String?)
        ?.split(",")
        ?.filter { it.isNotEmpty() }
        ?.associate {
            val decoded = String(Base64.getDecoder().decode(it))
            val separatorIndex = decoded.indexOf("=")
            decoded.substring(0, separatorIndex) to decoded.substring(separatorIndex + 1)
        }
        ?: emptyMap()

// Assinatura de release: lida de android/key.properties (fora do git).
// Formato:
//   storeFile=/caminho/para/golog-release.jks
//   storePassword=...
//   keyAlias=golog
//   keyPassword=...
// Sem o arquivo, o release cai na chave de debug (só serve para testes,
// não pode ser publicado).
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) FileInputStream(file).use { load(it) }
}
val hasReleaseKeystore = keystoreProperties.getProperty("storeFile") != null

android {
    namespace = "br.com.golog.app"
    // google_navigation_flutter (Navigation SDK 8.x) exige compileSdk 36.
    compileSdk = maxOf(flutter.compileSdkVersion, 36)
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Navigation SDK exige core library desugaring.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlin {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "br.com.golog.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // Navigation SDK exige minSdk 24.
        minSdk = maxOf(flutter.minSdkVersion, 24)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        manifestPlaceholders["GOOGLE_MAPS_API_KEY"] =
            dartDefines["GOOGLE_MAPS_API_KEY"] ?: ""
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                logger.warn("android/key.properties ausente: release assinado com a chave de DEBUG.")
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Android Auto (Car App Library) e Navigation SDK: as versões acompanham
    // as do google_navigation_flutter 0.12.1, que já as usa internamente;
    // aqui são declaradas porque o código em br.com.golog.app.auto as importa.
    implementation("androidx.car.app:app:1.7.0")
    implementation("androidx.car.app:app-projected:1.7.0")
    implementation("com.google.android.libraries.navigation:navigation:8.1.0")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs_nio:2.1.5")
}
