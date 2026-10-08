# BroML 🧠⚡

<p align="center">
  <img src="assets/logo.png" alt="BroML Logo" width="160" height="160" style="border-radius: 24px;" />
</p>

<p align="center">
  <b>The Neural Architecture Hub & Model Zoo for Machine Learning Engineers & Researchers</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Material_3-Supported-7B1FA2" alt="Material 3" />
  <img src="https://img.shields.io/badge/Firebase-Integrated-FFCA28?logo=firebase&logoColor=black" alt="Firebase" />
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License" />
</p>

---

## 🚀 Overview

**BroML** is a cutting-edge cross-platform application built with Flutter, designed to help machine learning practitioners, researchers, and developers explore, benchmark, inspect, and publish deep learning models across **Computer Vision**, **Natural Language Processing (NLP)**, **Audio / Speech**, and **Multimodal** domains.

---

## ✨ Key Features

### 🎮 Interactive 3D Model Zoo
* **3D Tilt & Flip Cards**: Double-tap any model card to flip into a futuristic 3D tensor spec sheet displaying dataset details, inference latency, and framework backends.
* **Domain Categorization**: Filter by **Vision**, **NLP**, **Audio**, and **Multimodal** with responsive filter chips.
* **Instant Search**: Search models in real time by name, framework (*PyTorch, TensorFlow, ONNX, JAX*), or dataset.

### 🔐 Authentication & Session Persistence
* **Modern Auth Interface**: Fluid dark-mode login & registration screens with animated 3D neural badges.
* **Quick Demo Sign-In (Guest)**: One-tap instant access for evaluation without registration.
* **Remember-Me & Session Cache**: Backed by `shared_preferences` and live `FirebaseAuth`.
* **Account Menu**: Quick profile avatar popup with user email and one-tap sign-out.

### 📊 Benchmark Metrics & Architectural Inspection
* **Live Stats Header**: Real-time aggregation of registered models, average accuracy (%), and active frameworks.
* **Model Detail Screen**: Deep inspection view displaying:
  * Accuracy benchmarks (% Top-1 / F1 score)
  * Hardware latency (ms / sample)
  * Parameter counts & model weights
  * Supported input/output tensor shapes
  * Paper citations and direct repository links

### 🛠️ Model Publisher & Editor
* Add new neural network models to the catalog or edit existing configurations.
* Image asset picking with camera/gallery support and high-performance network image caching.

---

## 📂 Project Structure

```
meet_app/
├── assets/
│   ├── logo.png                  # Primary 512x512 BroML App Icon
│   └── logo_small.png            # 128x128 Compact BroML Icon
├── android/                      # Android Native Configuration (AGP 8.11+, Gradle 9.3+)
├── ios/                          # iOS Native Project Configuration
├── web/                          # Web Assembly & HTML5 Shell
│   ├── icons/                    # PWA App Icons (192x192, 512x512 maskable)
│   ├── index.html                # BroML Web Entrypoint
│   └── manifest.json             # Web App Manifest
├── windows/                      # Windows Desktop Native Host
├── lib/
│   ├── main.dart                 # Root App Entrypoint & Provider Hierarchy
│   ├── models/
│   │   ├── ml_model.dart         # ML Model Entity, Metrics & JSON Parsing
│   │   └── user_model.dart       # User Profile Entity
│   ├── providers/
│   │   ├── auth_provider.dart    # Authentication & Session State Management
│   │   └── model_provider.dart   # Model Zoo Filtering, Sorting & Mutators
│   ├── screens/
│   │   ├── login_screen.dart     # BroML Login Screen
│   │   ├── register_screen.dart  # BroML User Registration Screen
│   │   ├── model_list_screen.dart# Primary Model Catalog & Stats Header
│   │   ├── model_detail_screen.dart # Deep Architectural & Benchmark View
│   │   └── add_edit_model_screen.dart # Model Publication & Editing Form
│   ├── services/
│   │   ├── api_service.dart      # HTTP API & REST Integration
│   │   └── firebase_storage_service.dart # Cloud Storage Service
│   └── widgets/
│       ├── animated_3d_card.dart # Perspective-tilted 3D Model Card
│       ├── flip_3d_card.dart     # Double-sided Interactive Spec Card
│       └── floating_3d_badge.dart# Animated Neural Badge
├── test/
│   └── widget_test.dart          # Automated Widget Verification Tests
├── pubspec.yaml                  # Flutter Dependencies & Assets Configuration
├── firebase_setup.md             # Complete Live Firebase Configuration Guide
└── README.md                     # Project Documentation
```

---

## 🛠️ Getting Started

### Prerequisites
* **Flutter SDK**: `>= 3.13.0`
* **Dart SDK**: `>= 3.13.5`
* **JDK**: Version 17 to 21 recommended
* **Android Studio / VS Code** with Flutter & Dart extensions

### Running the App

```powershell
# 1. Clone repository & install dependencies
flutter pub get

# 2. Run on connected Android device or emulator
flutter run

# 3. Run on Chrome Web
flutter run -d chrome

# 4. Run on Windows Desktop
flutter run -d windows
```

---

## 🔒 Authentication & Demo Credentials

BroML includes a built-in **Safe Offline Fallback Mode** so you can immediately test the entire application without configuring a remote database:

* **Demo Account**: `developer@aimodelhub.ai`
* **Demo Password**: `neuralnetwork2026`
* **Guest Access**: Tap **"Quick Demo Sign-In (Guest)"** on the login screen.

To connect your own live **Google Firebase backend** (Authentication, Firestore, Cloud Storage), follow the step-by-step instructions in [firebase_setup.md](file:///c:/Users/Admin/AndroidStudioProjects/meet_app/firebase_setup.md).

---

## 🧪 Testing

Execute automated unit and widget tests:

```powershell
flutter test
```

---

## 📄 License

This project is open-source and available under the [MIT License](LICENSE).
