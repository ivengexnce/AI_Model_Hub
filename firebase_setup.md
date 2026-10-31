# Firebase Setup Guide for BroML

This guide walks you through connecting **BroML** to a live Google Firebase backend for **Authentication**, **Cloud Storage** (architecture diagrams and weights), and **Cloud Firestore** (real-time neural model registry) with production-grade declarative security rules.

---

## 1. Current Project State & Verification

* **Project ID**: `broml-app` (Project Number: `640800735490`)
* **Storage Bucket**: `broml-app.firebasestorage.app`
* **Package Name**: `com.example.aimodelhub.ai_model_hub`
* **Local Debug SHA-1**: `2D:2C:A3:07:5F:DC:07:B4:59:57:18:E3:FC:D5:7D:2F:99:44:3A:EA` *(Verified: Matches OAuth client in [android/app/google-services.json](file:///c:/Users/Admin/AndroidStudioProjects/meet_app/android/app/google-services.json))*
* **Configuration Files**:
  * [android/app/google-services.json](file:///c:/Users/Admin/AndroidStudioProjects/meet_app/android/app/google-services.json): **Present & Valid**
  * [.firebaserc](file:///c:/Users/Admin/AndroidStudioProjects/meet_app/.firebaserc): **Present (Default: broml-app)**
  * [lib/firebase_options.dart](file:///c:/Users/Admin/AndroidStudioProjects/meet_app/lib/firebase_options.dart): **Generated & Active**
  * [firestore.rules](file:///c:/Users/Admin/AndroidStudioProjects/meet_app/firestore.rules): **Production Hardened**
  * [storage.rules](file:///c:/Users/Admin/AndroidStudioProjects/meet_app/storage.rules): **Production Hardened** (User-scoped `/models/{userId}/{fileName}`)

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
       id("com.google.gms.google-services")
   }
   ```

---

## 4. Enabling Firebase Services & Deploying Hardened Rules

### A. Firebase Authentication
1. Go to **Firebase Console** -> **Build** -> **Authentication**.
2. Click **Get Started**.
3. Under the **Sign-in method** tab, enable:
   * **Email/Password**
   * **Anonymous** (for the "Quick Demo Sign-In (Guest)" feature)
   * **Google** (Configure Web Client ID: `640800735490-vnk6dgbf23o80nlis3150cpp485omfsp.apps.googleusercontent.com`)

### B. Cloud Storage & Production Rules
1. Go to **Firebase Console** -> **Build** -> **Storage**.
2. Click **Get Started** and select your default Cloud Storage location (e.g., `us-central1`).
3. Deploy the production rules from [storage.rules](file:///c:/Users/Admin/AndroidStudioProjects/meet_app/storage.rules) enforcing strict authentication, 5 MB file size caps, and `image/*` MIME type validation:
   ```javascript
   rules_version = '2';
   service firebase.storage {
     match /b/{bucket}/o {
       match /models/{modelId}/{fileName} {
         allow read: if true;
         allow write: if request.auth != null
                      && request.resource.size < 5 * 1024 * 1024
                      && request.resource.contentType.matches('image/.*');
       }
     }
   }
   ```

### C. Cloud Firestore Security Rules
Deploy the hardened declarative rules from [firestore.rules](file:///c:/Users/Admin/AndroidStudioProjects/meet_app/firestore.rules) to protect model documents against unauthorized tampering and BOLA/IDOR attacks:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /models/{modelId} {
      allow read: if true;
      allow create: if request.auth != null
                    && request.resource.data.name is string
                    && request.resource.data.name.size() > 0;
      allow update, delete: if request.auth != null
                            && (resource.data.creatorId == request.auth.uid
                                || resource.data.creatorEmail == request.auth.token.email);
    }
  }
}
```

---

## 5. Deploying Security Rules via Firebase CLI

Deploy both security rule sets simultaneously using the Firebase CLI:

```powershell
firebase deploy --only firestore:rules,storage
```

---

## 6. Running the App with Firebase

Once configured, run the app directly from the root workspace:

```powershell
# Run in Chrome:
flutter run -d chrome

# Run on connected Android device or emulator:
flutter run
```
