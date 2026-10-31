# BroML — Comprehensive Technology Stack & Architecture Rationale

This document outlines the complete technology stack powering **BroML** (*Neural Architecture Hub, Model Registry & Advanced Threat Protection Platform*), detailing the technical rationale, implementation layer, and operational behavior for each engineering component.

---

## 1. Technology Stack Summary Matrix

| Category | Technology | Version | Location / Module | Architectural Purpose & Rationale | Operational Behavior in BroML |
| :--- | :--- | :---: | :--- | :--- | :--- |
| **Framework** | **Flutter** | `3.47.6` | Whole App (`lib/`, `android/`, `web/`) | Single codebase delivering 60 FPS across mobile, desktop, and web with reactive UI and native performance. | Ahead-of-Time (AOT) compiled to native ARM machine code on Android and CanvasKit/WebAssembly on Web. |
| **Language** | **Dart** | `>=3.13.5` | Application codebase | Type-safe, null-safe language with sound static analysis, async/await primitives, and zero runtime NPEs. | Powers application logic, asynchronous cloud synchronization, and cryptographic calculations. |
| **State Management** | **Provider** | `^6.1.0` | `lib/providers/` | Official Flutter recommended state management pattern; low boilerplate, predictable unidirectional data flow. | `ChangeNotifier` triggers granular, scoped widget rebuilds on auth changes, search queries, and model mutations. |
| **Security Engine** | **BroML Security Suite** | Native | `lib/services/security_engine.dart` | Self-contained, zero-dependency threat intelligence, rate-limiting, and TOTP authentication engine. | Evaluates client velocity, manages progressive throttling, verifies RFC 6238 TOTP codes, and maintains audit logs. |
| **Cryptography** | **Crypto** | `^3.0.3` | `lib/services/security_engine.dart` | Pure Dart cryptographic hashing and HMAC implementations. | Computes HMAC-SHA1 for RFC 6238 TOTP code generation, SHA-256 for password entropy verification, and token digests. |
| **Authentication** | **Firebase Auth** | `^5.4.0` | `lib/providers/auth_provider.dart` | Battle-tested, enterprise-grade identity platform handling email/password, tokens, and OAuth credential flows. | Authenticates users, validates session tokens, and maps Firebase auth states to the reactive `AuthUser` entity. |
| **Social OAuth** | **Google Sign-In** | `^6.2.1` | `lib/providers/auth_provider.dart` | Native Google OAuth 2.0 flow via Google Play Services. | Requests OpenID connect tokens and seamlessly exchanges them for authenticated Firebase credentials. |
| **NoSQL Database** | **Cloud Firestore** | `^5.1.0` | `lib/services/firestore_service.dart` | Highly scalable, real-time NoSQL document database with built-in offline synchronization. | Stores the global `'models'` collection with atomic document mutations and real-time streams. |
| **Cloud Storage** | **Firebase Storage** | `^12.1.0` | `lib/services/firebase_storage_service.dart` | Scalable object storage for binary assets (high-resolution neural architecture diagrams). | Uploads architecture diagrams to bucket `broml-app.firebasestorage.app` with strict 5 MB and MIME validation. |
| **External REST API** | **GitHub REST API v3** | v3 | `lib/services/github_service.dart` | Industry standard repository metadata API for discovering open-source AI/ML models. | Performs filtered searches with query caching and maps repositories to structured `MlModel` domain objects. |
| **Networking** | **HTTP** | `^1.2.0` | `lib/services/api_service.dart`, `github_service.dart` | Composable, multi-platform HTTP client for Dart. | Dispatches asynchronous HTTP GET/POST requests with timeouts and custom headers to external endpoints. |
| **Image Caching** | **CachedNetworkImage** | `^3.3.0` | `lib/widgets/model_image.dart` | Memory and disk-level caching for remote network images. | Prevents duplicate image downloads, displays smooth placeholders, and caches neural diagrams locally. |
| **Local Persistence** | **SharedPreferences** | `^2.3.0` | `lib/providers/` | Asynchronous, persistent key-value store for lightweight local data. | Persists user session identifiers, TOTP secrets, recovery codes, and local model bookmarks (`'Saved'`). |
| **Image Acquisition** | **ImagePicker** | `^1.1.0` | `lib/services/firebase_storage_service.dart` | Native photo library and camera selector. | Allows ML engineers to select architecture diagrams directly from gallery or camera before cloud upload. |
| **Typography** | **GoogleFonts** | `^6.2.1` | `lib/theme/app_theme.dart` | Dynamic font rendering from Google Fonts repository. | Delivers modern dark-mode typography (JetBrains Mono for metrics and Inter for UI labels). |
| **Bot Defense** | **Cloudflare Turnstile** | Edge | `cloudflare/worker.js`, `lib/services/security_engine.dart` | Privacy-preserving, user-friendly CAPTCHA alternative protecting login endpoints. | Validates challenge tokens server-side to reject headless automated scrapers and credential-stuffing bots. |
| **Automated Testing** | **Flutter Test** | SDK | `test/` (7 comprehensive test suites) | Built-in test runner for unit, component, widget, and integration verification. | Executes 46 automated tests verifying UI rendering, BOLA authorization, rate limiting, and adversary red-team attacks. |
| **Build Host (Android)** | **Kotlin & Gradle** | Gradle 9.3, AGP 8.11 | `android/` | Android native build system and Google Services configuration. | Compiles Flutter engine into production-ready Android APK binaries (`BroML-release.apk`). |
| **Build Host (Web)** | **HTML5 & WebAssembly** | CanvasKit | `web/` | Web rendering engine. | Renders Flutter graphics canvas directly in Chrome, Edge, and mobile browsers. |

---

## 2. Architectural Design Rationale

### Why Provider for State Management?
* **Low Complexity & Boilerplate**: Unlike heavy patterns like BLoC or Redux which require events, states, reducers, and duplicate classes, Provider utilizes Dart's native `ChangeNotifier` with intuitive `.watch<T>()` and `.read<T>()` bindings.
* **Granular Rebuilding**: Allows targeted subtree updates (e.g. only updating the search results list when `ModelProvider.setSearchQuery()` is invoked, without re-rendering the app bar or brand mark).
* **Decoupled Business Logic**: Screens remain purely visual consumers while all API interactions, data validation, and session management reside inside `AuthProvider` and `ModelProvider`.

### Why Custom In-Memory Security Engine?
* **Zero External Runtime Dependencies**: Eliminates third-party native plugin dependencies for rate-limiting, risk assessment, and TOTP generation, ensuring high cross-platform portability across Android, Web, and Desktop.
* **RFC 6238 Compliance**: Native HMAC-SHA1 TOTP calculation guarantees seamless compatibility with standard authenticator applications (Google Authenticator, Microsoft Authenticator, Authy, 1Password).
* **Distributed Attack Defense**: Centralizing IP and Account failure tracking in `RateLimitEngine` allows BroML to detect and neutralize distributed brute-force attacks where malicious actors rotate client IP addresses.

### Why GitHub REST API v3 Integration?
* **Universal Source of Truth**: GitHub hosts the vast majority of open-source artificial intelligence foundation models.
* **Direct Repository Linking**: BroML acts as an interactive mobile HUD for GitHub repositories, allowing researchers to explore stars, forks, licenses, and architecture diagrams directly on mobile devices.
* **In-Memory Query Caching**: Mitigates GitHub API rate limits by caching search results for identical queries.

### Why Cloud Firestore + Cloud Storage Architecture?
* **Relational + Blob Decoupling**: Metadata, accuracy percentages, latency numbers, and GitHub links reside in Cloud Firestore documents (low latency, fast indexing, structured querying), while heavy visual diagrams reside in Cloud Storage buckets (optimized for binary blob throughput).
* **Offline First Resilience**: Cloud Firestore automatically caches recent documents on disk, enabling seamless offline browsing when network connections are degraded or unavailable.

---

## 3. Security & Quality Verification Summary

* **Static Analysis**: `flutter analyze` executed with **0 issues found** across the entire workspace.
* **Effective Dart Conformance**: Strict curly brace block enclosing, null-safety enforcement, and clean import pruning.
* **Test Automation Coverage**:
  1. `test/auth_provider_test.dart` — Multi-provider authentication and session management.
  2. `test/model_provider_test.dart` — Model CRUD, category filtering, and BOLA authorization.
  3. `test/github_service_test.dart` — Curated model catalog verification and domain categorization.
  4. `test/add_edit_model_screen_test.dart` — Form validation, URL sanitization, and required field guards.
  5. `test/security_audit_test.dart` — Unit testing of RateLimitEngine, TurnstileService, and MfaService.
  6. `test/red_team_security_test.dart` — Adversary red-team simulations (credential stuffing, distributed brute-force, TOTP replay).
  7. `test/widget_test.dart` — Full application navigation and smoke testing.
* **Overall Automated Test Result**: **46 / 46 Tests Passed (100% Pass Rate)**.
