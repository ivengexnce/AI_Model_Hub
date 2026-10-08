# Multi-Platform Android & Flutter Workspace (`helloworld`)

A unified mobile engineering workspace containing both a **Native Android Application** built with Kotlin, MVVM, and Jetpack Navigation, and an **AI Model Hub & Zoo Cross-Platform Application** built with Flutter, Provider, and custom 3D UI components.

---

## 📱 Project Modules Overview

```
helloworld/
├── app/                          # Native Android Application (Kotlin, Jetpack, MVVM)
│   ├── src/main/
│   │   ├── java/com/example/helloworld/
│   │   │   ├── MainActivity.kt   # Primary host with Drawer & BottomNavigation
│   │   │   └── ui/
│   │   │       ├── login/        # LoginActivity & LoginViewModel (Auth flow)
│   │   │       ├── transform/    # Responsive TransformFragment (RecyclerView & Grid/Linear)
│   │   │       ├── reflow/       # Dynamic text reflow demonstration
│   │   │       ├── slideshow/    # Slideshow view
│   │   │       └── settings/     # App settings
│   │   └── res/                  # Layouts, adaptive navigation, menus, drawables, strings
│   └── src/test/                 # JVM Unit Tests (LoginViewModelTest)
│
├── ai_model_hub/                 # Cross-Platform Flutter Application (Dart)
│   ├── lib/
│   │   ├── models/               # MlModel data entity & JSON serialization
│   │   ├── providers/            # ModelProvider (ChangeNotifier state management)
│   │   ├── screens/              # ModelListScreen, ModelDetailScreen, AddEditModelScreen
│   │   ├── services/             # ApiService (REST CRUD) & FirebaseStorageService
│   │   └── widgets/              # Animated3dCard, Flip3dCard, Floating3dBadge
│   └── test/                     # Flutter Widget Tests
│
├── gradle/                       # Gradle wrapper and version catalog (libs.versions.toml)
├── build.gradle.kts              # Root Gradle configuration
├── settings.gradle.kts           # Module inclusion settings
└── README.md                     # Comprehensive project documentation
```

---

## 🛠️ Tech Stack & Architecture

### 1. Native Android App (`app`)
- **Language**: Kotlin 2.x
- **Min SDK**: API 24 (Android 7.0) | **Target & Compile SDK**: API 37 (Android 17)
- **Architecture Pattern**: MVVM (Model - View - ViewModel)
- **UI & Components**:
  - **Jetpack Navigation**: `NavHostFragment`, `AppBarConfiguration`, `setupActionBarWithNavController`, `setupWithNavController`.
  - **Adaptive Layouts**: Responsive navigation that dynamically switches between **Navigation Drawer** (tablet / landscape `w600dp` - `w1240dp`) and **Bottom Navigation View** (compact portrait mobile).
  - **ViewBinding**: Type-safe view interactions across all layouts and RecyclerView view holders.
  - **Lifecycle & Coroutines**: `LiveData`, `ViewModelProvider`, `viewModelScope`.
  - **Material 3 / DayNight Theme**: Seamless light/dark mode adaptation with MaterialComponents styling.

### 2. Flutter App (`ai_model_hub`)
- **Framework**: Flutter (Dart SDK ^3.13.5)
- **State Management**: `provider` (Provider / ChangeNotifier)
- **Networking & Cloud**:
  - HTTP REST client (`http`) with simulated JSON endpoints for full CRUD operations.
  - `firebase_core` & `firebase_storage` for cloud artifact/image hosting.
  - `image_picker` for local camera & gallery selection.
- **Custom 3D Animations & Graphics**:
  - `Animated3dCard`: Real-time touch/pointer gesture tracking with perspective matrix projection (`Matrix4.setEntry(3, 2, 0.0015)`), dynamic 3D tilt physics, and specular highlight reflection.
  - `Flip3dCard`: 3D card-flip rotation over the Y-axis revealing the deep technical specs matrix.
  - `Floating3dBadge`: Continuous 3D oscillating orbital rotation.

---

## 🔧 Bugs & Errors Resolved

During project analysis and verification, the following issues were diagnosed and resolved:

| File | Issue | Solution |
|---|---|---|
| `app/.../TransformFragment.kt` | `ItemTransformBinding.inflate` was called without passing `(parent, false)`, causing RecyclerView items to discard parent layout constraints and fail `match_parent` cell expansion. | Updated to `ItemTransformBinding.inflate(LayoutInflater.from(parent.context), parent, false)`. |
| `app/.../TransformFragment.kt` | `drawables[position]` risked `IndexOutOfBoundsException` if items exceeded the 16 bundled avatar drawables. | Applied bounds safety: `drawables[position % drawables.size]`. |
| `app/.../TransformViewModel.kt` | `mapIndexed { _, i -> "This is item # $i" }` produced 0-based strings (`# 0` to `# 15`) despite `(1..16)` range. | Updated to `(1..16).map { i -> "This is item # $i" }` for correct 1-based display. |
| `app/.../LoginViewModel.kt` | `Patterns.EMAIL_ADDRESS` relied solely on Android framework runtime, causing null references during pure JVM JUnit tests without Robolectric. | Added regex fallback (`EMAIL_REGEX`) to ensure reliable email validation in both Android runtime and unit test suites. |
| `app/.../LoginViewModelTest.kt` | Test suite was missing `LoginViewModel` import and tested raw string methods instead of actual ViewModel methods. | Added `import com.example.helloworld.ui.login.LoginViewModel` and comprehensive tests for valid emails, malformed emails, empty inputs, and password length checks. |
| `app/.../res/values/strings.xml` | `lorem_ipsum_title` and `lorem_ipsum` contained extraneous trailing quotes (`"`) resulting in malformed string resources. | Cleaned up string definitions and quotation formatting. |
| `ai_model_hub/pubspec.yaml` | `cupertino_icons` triggered asset copy issues on Windows, and concurrent daemons caused `sqflite_android` directory file locks. | Removed unused `cupertino_icons` dependency, terminated lingering daemons, and ran clean rebuild. |
| `ai_model_hub/.../gradle-wrapper.properties` | AGP 9.1.0 required Gradle 9.3.1+, but wrapper was configured for Gradle 9.1.0 (`Minimum supported Gradle version is 9.3.1`). | Upgraded `distributionUrl` to `gradle-9.3.1-all.zip`. |
| `ai_model_hub/.../app/build.gradle.kts` | Incremental Flutter builds failed on Windows with `PathExistsException (errno = 183)` when copying `NativeAssetsManifest.json`. | Added `compileFlutterBuild` Gradle pre-compile hook to automatically clear stale `intermediates/flutter` before compilation. |
| `ai_model_hub/.dart_tool` | Missing `.dart_tool/package_config.json` after clean. | Restored package configuration by executing `flutter pub get`. |

---

## 🚀 Getting Started & Build Guide

### Prerequisites
- **JDK**: Java 17+ / JBR (e.g. bundled in Android Studio: `C:\Program Files\Android\Android Studio\jbr`)
- **Android SDK**: Build tools & Platform API 34+
- **Flutter SDK**: 3.13+ (optional if only running the native Android app)

### 1. Build and Run Native Android App

#### Set Environment (PowerShell)
```powershell
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
$env:Path = "$env:JAVA_HOME\bin;C:\Users\Admin\AppData\Local\Android\Sdk\platform-tools;" + $env:Path
```

#### Run Unit Tests
```powershell
.\gradlew.bat test
```
*Result: All tests in `:app:testDebugUnitTest` pass.*

#### Build Debug APK
```powershell
.\gradlew.bat assembleDebug
```
Output APK generated at:
`app/build/outputs/apk/debug/app-debug.apk`

#### Install and Launch on Emulator / Connected Device
```powershell
adb -s emulator-5554 install -r app/build/outputs/apk/debug/app-debug.apk
adb -s emulator-5554 shell am start -n com.example.helloworld/.ui.login.LoginActivity
```

---

### 2. Build and Run Flutter App (`ai_model_hub`)

#### Navigate to Flutter Directory
```powershell
cd ai_model_hub
```

#### Run Static Analysis
```powershell
flutter analyze
```

#### Run Flutter Tests
```powershell
flutter test
```

#### Run App on Connected Device
```powershell
# Run on Android Emulator
flutter run -d emulator-5554

# Or run on Windows Desktop
flutter run -d windows

# Or run in Chrome browser
flutter run -d chrome
```

---

## 🧪 Verification & Testing Status

- ✅ **Kotlin Compilation**: `gradlew compileDebugSources` passed without errors.
- ✅ **Android Unit Tests**: `gradlew test` passed 100% of test cases.
- ✅ **Android APK Build**: `gradlew assembleDebug` generated `app-debug.apk` successfully.
- ✅ **Live Emulator Deployment**: Installed and verified on active Android 17 emulator (`emulator-5554`).
- ✅ **Screen Navigation & Rendering**:
  - `LoginActivity`: Input fields, password visibility toggle, IME actions, form validation, and login delay validated.
  - `MainActivity`: Toolbar, bottom navigation bar, and `TransformFragment` avatar list verified with live screenshots.
- ✅ **Flutter Static Analysis**: `flutter analyze` completed with 0 errors and 0 warnings.
- ✅ **Flutter Widget Test**: `flutter test` passed app smoke test.
