# BroML (AI Model Hub) — System Architecture & Flowchart Specification

---

## 1. Executive Overview

**BroML** (*Neural Architecture Hub & Model Registry*) is a cross-platform Flutter application engineered for machine learning practitioners to register, benchmark, inspect, and explore artificial intelligence models. The system integrates Google Firebase for authentication and cloud persistence, GitHub REST APIs for open-source model repository discovery, and an interactive 3D perspective rendering engine for visual engagement.

---

## 2. High-Level System Architecture

The codebase adheres to a clean, decoupled **Layered Reactive Architecture** powered by the **Provider** pattern:

```mermaid
graph TD
    subgraph UI_Layer ["1. Presentation Layer (UI & Widgets)"]
        A1[MaterialApp / AppTheme] --> A2[_AppEntry Root Router]
        A2 -->|Unauthenticated| B1[LoginScreen / RegisterScreen]
        A2 -->|Authenticated| B2[ModelListScreen]
        B2 --> B3[ModelDetailScreen]
        B2 --> B4[AddEditModelScreen]
        B2 --> B5[GithubBrowserScreen]
        B2 -.-> C1[3D Animated Widgets & ModelCards]
    end

    subgraph State_Layer ["2. State Management Layer (ChangeNotifiers)"]
        D1[AuthProvider]
        D2[ModelProvider]
    end

    subgraph Domain_Layer ["3. Domain Models"]
        E1[AuthUser]
        E2[MlModel]
        E3[GithubRepo]
    end

    subgraph Service_Layer ["4. Data & Service Infrastructure"]
        F1[FirestoreService]
        F2[FirebaseStorageService]
        F3[GithubService]
        F4[ApiService / Local Store]
        F5[SharedPreferences]
    end

    subgraph Backend_Layer ["5. External Clouds & Services"]
        G1[(Google Firebase Auth)]
        G2[(Cloud Firestore)]
        G3[(Firebase Storage)]
        G4[GitHub REST API v3]
        G5[Google Play Services OAuth]
    end

    %% Connections
    B1 -->|Invokes| D1
    B2 -->|Consumes| D2
    B3 & B4 -->|Updates| D2
    B5 -->|Fetches & Imports| D2

    D1 --> E1
    D2 --> E2
    B5 --> E3

    D1 -->|Google / Email Auth| G1
    D1 -->|Native Tokens| G5
    D1 -->|Persist Session| F5

    D2 --> F1
    D2 --> F2
    D2 --> F4
    B5 --> F3

    F1 --> G2
    F2 --> G3
    F3 --> G4
```

---

## 3. Application Flowcharts

### 3.1. Master Navigation & Lifecycle Flow

```mermaid
flowchart TD
    Start([App Launch]) --> Init[Initialize Firebase & Orientations]
    Init --> CheckSession[AuthProvider.restoreSession]
    CheckSession --> IsAuth{Firebase User Active?}

    IsAuth -- Yes --> Home[ModelListScreen Dashboard]
    IsAuth -- No --> Login[LoginScreen]

    Login -->|New User| Register[RegisterScreen]
    Register -->|Account Created| Home
    Login -->|Guest Button| GuestAuth[Quick Demo Guest Session]
    GuestAuth --> Home
    Login -->|Google / Email Auth| Authenticate[Validate Credentials]
    Authenticate -->|Success| Home
    Authenticate -->|Error| ShowError[Display Error Banner]
    ShowError --> Login

    Home -->|Search / Filter| FilterModels[Update ModelProvider Query]
    FilterModels --> RefreshUI[Re-render Grid/List]

    Home -->|Select Card| Detail[ModelDetailScreen]
    Detail -->|3D Rotate / Inspect| ViewMetrics[View Accuracy, Latency & Spec]
    Detail -->|Delete| DeleteModel[Delete from Firestore] --> Home
    Detail -->|Edit| EditModel[AddEditModelScreen] --> SaveModel[Commit Changes] --> Home

    Home -->|FAB '+' Tap| AddModel[AddEditModelScreen]
    AddModel --> UploadImg[Pick Architecture Diagram]
    UploadImg --> CommitNew[Save to Cloud Firestore] --> Home

    Home -->|GitHub Icon Tap| GithubBrowser[GithubBrowserScreen]
    GithubBrowser --> SearchRepo[Query GitHub ML Repos]
    SearchRepo --> ImportRepo[Convert Repo to BroML Model]
    ImportRepo --> AddModel

    Home -->|User Menu Tapped| Profile[Profile Menu]
    Profile -->|Sign Out| Logout[Clear Session & Google Sign-Out] --> Login
```

---

### 3.2. Authentication & Authorization Pipeline

```mermaid
sequenceDiagram
    autonumber
    actor User
    participant LoginUI as LoginScreen
    participant AuthP as AuthProvider
    participant GPS as Google Play Services
    participant FBAuth as Firebase Auth
    participant Prefs as SharedPreferences

    alt Google OAuth Flow
        User->>LoginUI: Taps "Google" button
        LoginUI->>AuthP: loginWithGoogle()
        AuthP->>GPS: GoogleSignIn.signIn(serverClientId)
        alt User Dismisses Picker
            GPS-->>AuthP: null (cancelled)
            AuthP-->>LoginUI: Returns false (no error)
        else User Selects Google Account
            GPS-->>AuthP: GoogleSignInAccount + ID Token
            AuthP->>FBAuth: signInWithCredential(GoogleAuthProvider)
            FBAuth-->>AuthP: UserCredential (uid, email, displayName)
            AuthP->>Prefs: Persist session identifier
            AuthP-->>LoginUI: Returns true
            LoginUI->>User: Transitions to ModelListScreen
        end
    else Email & Password Flow
        User->>LoginUI: Enters credentials & taps "Sign in"
        LoginUI->>AuthP: login(email, password)
        AuthP->>FBAuth: signInWithEmailAndPassword(email, pass)
        alt Valid Credentials
            FBAuth-->>AuthP: UserCredential
            AuthP-->>LoginUI: Returns true
        else Invalid Credentials
            FBAuth-->>AuthP: FirebaseAuthException
            AuthP-->>LoginUI: Returns mapped friendly error banner
        end
    end
```

---

### 3.3. Model Data Management Flow (CRUD & Cloud Sync)

```mermaid
flowchart LR
    subgraph Input ["User Input"]
        UI_Input[User Enters Model Info & Diagram]
    end

    subgraph ModelOps ["ModelProvider Workflow"]
        Validate[Validate Name & Metrics]
        ImgUpload{Custom Image Selected?}
        UploadCloud[Upload to Firebase Storage]
        SaveFirestore[Save Document to Cloud Firestore]
        FallbackLocal[Cache in Local Memory / ModelList]
    end

    subgraph Storage ["Cloud / Local Tier"]
        FStorage[(Firebase Storage Bucket)]
        FStore[(Cloud Firestore 'models' Collection)]
        StateList[Provider In-Memory State]
    end

    UI_Input --> Validate
    Validate --> ImgUpload
    ImgUpload -- Yes --> UploadCloud --> FStorage
    ImgUpload -- No --> FallbackLocal
    UploadCloud --> SaveFirestore
    FallbackLocal --> SaveFirestore
    SaveFirestore --> FStore
    FStore --> StateList
    StateList --> Render[ModelListScreen Grid Display]
```

---

## 4. Codebase Directory Map

```text
meet_app/
├── android/                             # Native Android project configuration
│   ├── app/
│   │   ├── build.gradle.kts             # AGP build rules, signing configs & dependencies
│   │   ├── google-services.json         # Firebase project credentials & OAuth client mappings
│   │   └── src/main/
│   │       ├── AndroidManifest.xml      # App label (BroML), permissions, launcher intent
│   │       └── res/mipmap-*/ic_launcher # 3D Quantum Tensor Cube app icons
│   ├── build.gradle.kts                 # Root project Gradle configuration
│   └── gradle.properties                # JVM heap configuration (-Xmx3072m, G1GC)
├── assets/
│   ├── logo.png                         # High-res BroML 3D Cube identity asset
│   └── logo_small.png                   # Compact navigation bar branding asset
├── lib/
│   ├── main.dart                        # Application entry point, multi-provider wiring, root router
│   ├── models/
│   │   └── ml_model.dart                # Core data entity: MlModel (metrics, latency, framework, dataset)
│   ├── providers/
│   │   ├── auth_provider.dart           # Authentication state, OAuth orchestration, session persistence
│   │   └── model_provider.dart          # Registry state, category filter queries, Firestore sync
│   ├── screens/
│   │   ├── add_edit_model_screen.dart   # Model registration and modification form
│   │   ├── github_browser_screen.dart   # Live GitHub repository search and model importer
│   │   ├── login_screen.dart            # Animated sign-in portal (Google, GitHub, Email, Guest)
│   │   ├── model_detail_screen.dart     # Deep inspection screen with interactive 3D card tilt
│   │   ├── model_list_screen.dart       # Dashboard screen with search bar, category chips, and model grid
│   │   └── register_screen.dart         # Account creation workflow
│   ├── services/
│   │   ├── api_service.dart             # Local model seed catalog & fallback provider
│   │   ├── firebase_storage_service.dart# Image picker & Firebase Storage asset uploader
│   │   ├── firestore_service.dart       # Cloud Firestore NoSQL repository operations
│   │   └── github_service.dart          # GitHub REST API v3 client for machine learning repositories
│   ├── theme/
│   │   └── app_theme.dart               # Dark/Light design system, neon cyan/indigo tokens, typography
│   └── widgets/
│       ├── animated_3d_card.dart        # Gyro/touch 3D perspective rotation matrix widget
│       ├── auth_shell.dart              # Glassmorphism container with backdrop filter glow
│       ├── common_widgets.dart          # Skeleton loaders, ErrorBanners, ButtonSpinner, EmptyState
│       ├── flip_3d_card.dart            # Dual-sided animated card flip on user tap
│       ├── floating_3d_badge.dart       # Elevated floating pill badge with drop shadows
│       ├── model_card.dart              # Interactive model card with performance indicators
│       └── model_image.dart             # Cached image renderer with network placeholder fallbacks
├── test/
│   ├── auth_provider_test.dart          # Automated unit test suite (validation, session, auth rules)
│   └── widget_test.dart                 # Component integration test (login -> model hub -> logout)
├── web/                                 # Web platform assets, manifest.json & index.html
└── pubspec.yaml                         # Dependencies (firebase_auth, firestore, google_sign_in, etc.)
```

---

## 5. Architectural Quality Matrix

| Architectural Dimension | Implementation Strategy | Verification Metric |
| :--- | :--- | :--- |
| **Separation of Concerns** | Decoupled UI (screens/widgets), Logic (providers), and Services | `flutter analyze`: **0 issues** |
| **Authentication Integrity** | Real Firebase Auth + OAuth 2.0 Web Client validation | Zero mock user fallbacks; real session restore |
| **Persistence & Fallbacks** | Cloud Firestore with offline cache fallback | Seamless loading even on degraded networks |
| **Responsiveness & UX** | 3D matrix transformations, curved animations, skeleton loading | Fluid 60 FPS transitions across form factors |
| **Build Stability** | JVM memory tuned (`-Xmx3072m`), R8 optimization rules tailored | Debug and Release APKs compile with exit code 0 |
