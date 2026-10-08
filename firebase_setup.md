# Firebase Setup Guide for BroML

This guide walks you through connecting **BroML** to a live Google Firebase backend for **Authentication**, **Cloud Storage** (model weights & preview images), and **Cloud Firestore** (real-time neural model registry).

---

## 1. Current Project State

Currently, the application runs in **Safe Offline / Mock Mode**:
* **Authentication**: Managed via [lib/providers/auth_provider.dart](file:///c:/Users/Admin/AndroidStudioProjects/meet_app/lib/providers/auth_provider.dart) with local state validation and one-tap guest login.
* **Storage**: In [lib/services/firebase_storage_service.dart](file:///c:/Users/Admin/AndroidStudioProjects/meet_app/lib/services/firebase_storage_service.dart), if Firebase is uninitialized or offline, it falls back to placeholder architecture previews.
* **Initialization**: [lib/main.dart](file:///c:/Users/Admin/AndroidStudioProjects/meet_app/lib/main.dart) uses guarded fallback `FirebaseOptions` inside a `try-catch` block so the app builds and runs without crashing when offline.

---

## 2. Prerequisites

1. A Google Account with access to the [Firebase Console](https://console.firebase.google.com/).
2. Firebase CLI and FlutterFire CLI installed:
   ```bash
   npm install -g firebase-tools
   dart pub global activate flutterfire_cli
   ```

---

## 3. Step-by-Step Setup

### Step 1: Create a Project in Firebase Console
1. Navigate to [https://console.firebase.google.com/](https://console.firebase.google.com/).
2. Click **Add project** (or **Create a project**).
3. Name your project (e.g., `broml-app`).
4. (Optional) Enable Google Analytics and click **Create project**.

---

### Step 2: Register the Android Application
* **Package Name**: `com.example.aimodelhub.ai_model_hub`
  *(Defined in [android/app/build.gradle.kts](file:///c:/Users/Admin/AndroidStudioProjects/meet_app/android/app/build.gradle.kts))*
* **App Nickname**: BroML Android

#### Get SHA-1 Fingerprint (Required for Google Sign-In):
Run this in the project root:
```powershell
cd android
./gradlew signingReport
```
Copy the `SHA1` fingerprint under `debugAndroidTest` or `debug` and paste it into the Firebase Console Android App configuration.

---

### Step 3: Configure Firebase in Flutter

#### Option A: Automatic Configuration via FlutterFire CLI (Recommended)
Log in to Firebase and run the configurator from the project root:
```bash
firebase login
flutterfire configure
```
1. Select your newly created Firebase project from the list.
2. Select target platforms (Android, iOS, Web, Windows).
3. FlutterFire will automatically generate `lib/firebase_options.dart` and download `google-services.json` to [android/app/google-services.json](file:///c:/Users/Admin/AndroidStudioProjects/meet_app/android/app/google-services.json).

#### Option B: Manual Configuration
1. In Firebase Console, download the generated **`google-services.json`**.
2. Place the file directly in:
   ```
   android/app/google-services.json
   ```
3. Ensure the Google Services plugin is applied in [android/app/build.gradle.kts](file:///c:/Users/Admin/AndroidStudioProjects/meet_app/android/app/build.gradle.kts):
   ```kotlin
   plugins {
       id("com.android.application")
       id("dev.flutter.flutter-gradle-plugin")
       id("com.google.gms.google-services") // Add if using manual setup
   }
   ```

---

## 4. Enabling Firebase Services

### A. Firebase Authentication
1. Go to **Firebase Console** -> **Build** -> **Authentication**.
2. Click **Get Started**.
3. Under the **Sign-in method** tab, enable:
   * **Email/Password**
   * **Anonymous** (for the "Quick Demo Sign-In (Guest)" feature)
   * *(Optional)* **Google**
4. Verify dependencies in [pubspec.yaml](file:///c:/Users/Admin/AndroidStudioProjects/meet_app/pubspec.yaml):
   ```yaml
   dependencies:
     firebase_core: ^3.1.0
     firebase_auth: ^5.4.0
     firebase_storage: ^12.1.0
   ```
   Then run `flutter pub get`.

### B. Firebase Cloud Storage
1. Go to **Firebase Console** -> **Build** -> **Storage**.
2. Click **Get Started** and select **Start in test mode** for development:
   ```javascript
   rules_version = '2';
   service firebase.storage {
     match /b/{bucket}/o {
       match /{allPaths=**} {
         allow read, write: if true; // Secure this before production!
       }
     }
   }
   ```
3. Choose your default Cloud Storage location (e.g., `us-central1`).

---

## 5. Connecting AuthProvider to Live Firebase

In [lib/providers/auth_provider.dart](file:///c:/Users/Admin/AndroidStudioProjects/meet_app/lib/providers/auth_provider.dart), live `FirebaseAuth` calls are already integrated with safe offline fallback. Once `firebase_options.dart` or `google-services.json` is provided, live authentication connects automatically.

---

## 6. Running the App with Firebase

Once configured, run the app directly from the root workspace:

```powershell
flutter run -d emulator-5554
```
