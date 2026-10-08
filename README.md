# AI Model Hub & Zoo 🧠✨

A modern cross-platform **Flutter** application designed for machine learning researchers and software engineers to discover, benchmark, inspect, and deploy neural network architectures across Computer Vision, Natural Language Processing, Audio/Speech, and Multimodal domains.

---

## 🚀 Key Features

* **Connected Login & Authentication**:
  * Neural Badge header with floating 3D animations.
  * Form validation, remember-me persistence, password visibility toggles.
  * **"Quick Demo Sign-In (Guest)"** for immediate offline evaluation.
  * Profile avatar menu with user details and instant sign-out.
* **Interactive Model Zoo**:
  * Filter models by domain tag (*Vision*, *NLP*, *Audio*, *Multimodal*).
  * Real-time search across model titles, descriptions, and tags.
  * Interactive 3D flip cards revealing parameter size, inference latency (ms), and accuracy metrics.
* **Deep Architectural Inspection**:
  * Detailed parameter breakdown, framework badges (PyTorch, TensorFlow, ONNX), and release dates.
  * Benchmark visualizations and sample inference payloads.
* **Model Registry & Creation**:
  * Add custom neural models or edit existing entries.
  * Image upload with camera/gallery integration and fallback placeholder generation.

---

## 📂 Project Architecture

```
helloworld/
├── android/                  # Android Native Host (AGP 8.11.1, Kotlin 2.2.20, Gradle 9.3.1)
├── ios/                      # iOS Native Host
├── web/                      # Web Assembly & HTML5 Host
├── windows/                  # Windows Desktop Host
├── lib/
│   ├── main.dart             # Root App Entrypoint & Consumer Auth Routing
│   ├── models/
│   │   ├── ml_model.dart     # ML Model Domain Entities & JSON Serialization
│   │   └── user_model.dart   # User Profile Entity
│   ├── providers/
│   │   ├── auth_provider.dart    # User Authentication & Session State Management
│   │   └── model_provider.dart   # Model Zoo State, Filtering, and Sorting
│   ├── screens/
│   │   ├── login_screen.dart     # AI Model Hub Login & Sign-in Interface
│   │   ├── model_list_screen.dart   # Primary Model Catalog Screen
│   │   ├── model_detail_screen.dart # Deep Model Inspection & Benchmarks
│   │   └── add_edit_model_screen.dart# Model Submission & Form Editor
│   ├── services/
│   │   ├── api_service.dart      # HTTP API & REST Endpoints
│   │   └── firebase_storage_service.dart # Cloud Storage & Media Handling
│   └── widgets/
│       ├── animated_3d_card.dart # Perspective-tilted 3D Model Card
│       ├── flip_3d_card.dart     # Double-sided Interactive Spec Card
│       └── floating_3d_badge.dart# Looping Neural Badge Animation
├── test/
│   └── widget_test.dart      # Unit & Widget Verification Tests
├── pubspec.yaml              # Flutter Dependencies & Assets Configuration
└── firebase_setup.md         # Complete Firebase Backend Setup Guide
```

---

## 🛠️ Getting Started

### 1. Requirements
* **Flutter SDK**: `>= 3.47.0` (Dart `>= 3.13.0`)
* **Java Development Kit**: JDK 17 to JDK 25 (`JAVA_HOME` pointing to Android Studio JBR)
* **Android SDK**: API 31 - 37 with Build-Tools `35.0.0`

### 2. Running the App
Run directly from the workspace root:

```powershell
# Run on connected Android Emulator or Physical Device
flutter run -d emulator-5554

# Run on Chrome Web
flutter run -d chrome

# Run on Windows Desktop
flutter run -d windows
```

### 3. Running Automated Tests
```powershell
flutter test
```

---

## 🔒 Authentication & Firebase

The app is currently configured in **Safe Offline / Demo Mode** with pre-filled test credentials:
* **Email**: `developer@aimodelhub.ai`
* **Password**: `neuralnetwork2026`
* Or tap **"Quick Demo Sign-In (Guest)"** for instantaneous access.

To connect a live Google Firebase backend (Authentication, Cloud Firestore, Cloud Storage), follow the step-by-step instructions in [firebase_setup.md](file:///c:/Users/Admin/AndroidStudioProjects/helloworld/firebase_setup.md).
