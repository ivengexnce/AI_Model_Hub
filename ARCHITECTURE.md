# BroML — System Architecture & Engineering Specification

**Product:** BroML — AI/ML Model Decision Intelligence Platform  
**Specification Version:** 1.2.0 (Blueprint 1.0 Compliant)  
**Target Environments:** Android / Mobile / Laptop / Desktop  

---

## 1. Executive Overview

**BroML** is an AI/ML Model Decision Intelligence platform that helps developers, students, and machine learning engineers select suitable machine learning models based on project requirements, real hardware limitations, latency expectations, and licensing constraints.

Rather than acting as an uncurated directory or ranking models by popularity, BroML solves the engineering question:

> *"Given my real hardware resources and deployment constraints, which models are compatible, what are their architectural trade-offs, and what evidence supports the recommendation?"*

### Core Architectural Pillars
1. **Hardware Auto-Detection & Laptop Profiling**: Dynamically discovers host memory and CPU core counts (or applies target presets like Budget 4GB Laptops) and calculates a safe ML memory budget so the user's laptop never stutters, freezes, or thermal throttles.
2. **Deterministic Recommendation & Rejection Engine**: Applies two-phase decision intelligence:
   - **Phase 1 Hard Constraint Filtering**: Incompatible candidates are eliminated with transparent, human-readable rejection reasons (RAM overflow, VRAM requirement, latency violation, license incompatibility).
   - **Phase 2 Feature Normalization & Multi-Attribute Scoring**: Eligible candidates are normalized across Benchmark Accuracy (0.35), CPU Latency (0.25), Memory Efficiency (0.20), Parameter Efficiency (0.10), and Commercial License (0.10).
3. **Side-by-Side Technical Comparison Matrix**: Compares shortlisted candidates head-to-head across latency on laptop CPUs, RAM footprint, benchmark fidelity, and key trade-offs.
4. **Verified Canonical Model Catalog**: Pre-seeded with 30 verified canonical architectures spanning all 5 ML categories (Computer Vision, NLP, Audio & Speech, Tabular ML, RL, and On-Device LLMs) with verified benchmark metrics, parameter counts, zero-lag memory footprints, and paper links.
5. **Enterprise Authentication & Threat Protection**: Multi-factor authentication (RFC 6238 TOTP), progressive rate-limiting, and Cloudflare Turnstile bot deterrence.

---

## 2. Decoupled 5-Tier System Architecture

BroML is organized around a clean, layered architecture leveraging Flutter and the **Provider** reactive state pattern (`ChangeNotifier`):

```mermaid
graph TD
    subgraph Presentation_Layer ["1. Presentation Layer (Flutter UI)"]
        A1[MainShellScreen - 3-Tab Shell]
        A1 --> B1[DecisionEngineScreen - Requirement Builder & Shortlist]
        A1 --> B2[ModelListScreen - Canonical Catalog & Feasibility HUD]
        A1 --> B3[SavedDecisionsScreen - Architectural Audit Trail]
        B1 --> B4[ModelComparisonScreen - Side-by-Side Matrix]
        B1 & B2 --> B5[ModelDetailScreen - Deep Metric Inspector]
        A1 -.-> B6[AccountMenu / Auth Screens]
    end

    subgraph State_Layer ["2. Reactive State Layer (ChangeNotifiers)"]
        D1[AuthProvider - Sessions, RBAC & TOTP MFA]
        D2[ModelProvider - Catalog Registry, Hardware Evaluation & Saved Decisions]
    end

    subgraph Domain_Layer ["3. Domain Models & Entities"]
        E1[ProjectRequirement - Hardware Limits, Task, Latency, CPU/GPU Mode]
        E2[MlModel - Parameters, RAM Footprint, Latency, Feasibility Badges]
        E3[DecisionRecord - Historical Requirement, Selected Model & Trade-offs]
        E4[DetectedHardwareProfile - Cores, RAM, Safe Budget, OOM Defense]
    end

    subgraph Service_Layer ["4. Intelligence & Infrastructure Services"]
        S1[HardwareDetectionService - Physical RAM Scanner & Laptop Presets]
        S2[RecommendationEngine - Hard Filtering & Multi-Attribute Scoring]
        S3[CanonicalCatalogService - 30 Verified Baseline Model Records]
        S4[SecurityEngine - Rate Limiter, TOTP, Anti-Brute-Force]
        S5[FirestoreService & SharedPreferences - Persistent Records]
    end

    subgraph External_Layer ["5. External Platform & OS Layer"]
        G1[Linux/Android /proc/meminfo & Platform.numberOfProcessors]
        G2[Windows WMI / PowerShell TotalVisibleMemorySize]
        G3[Hugging Face Hub API & Papers With Code Benchmarks]
        G4[Firebase Authentication & Cloud Firestore]
    end

    %% Wiring
    B1 -->|Triggers Auto-Detect| S1
    S1 --> G1 & G2
    B1 -->|Evaluates Constraints| D2
    D2 --> S2
    S2 --> S3
    B1 -->|Opens Side-by-Side Matrix| B4
    B4 -->|Locks in Final Selection| D2
    D2 --> S5
    D1 --> S4 & G4
```

---

## 3. Hardware Auto-Detection & Laptop Profiler Architecture

To guarantee that models run smoothly without lagging on standard laptops or edge devices:

```mermaid
sequenceDiagram
    autonumber
    actor User as Developer / Student
    participant UI as DecisionEngineScreen
    participant HDS as HardwareDetectionService
    participant OS as Host OS (/proc/meminfo / WMI)
    participant Engine as RecommendationEngine
    participant Catalog as CanonicalCatalogService

    User->>UI: Taps [⚡ Auto-Detect My Hardware] (or app bootstrap)
    UI->>HDS: autoDetect()
    HDS->>OS: Read total physical memory & CPU cores
    OS-->>HDS: e.g. 8.0 GB RAM, 8 CPU Cores
    HDS->>HDS: Calculate Safe ML Budget = 60% of total RAM (4.5 GB)<br/>Reserves 40% for OS & background apps
    HDS-->>UI: DetectedHardwareProfile (Zero-Lag Guaranteed)
    UI->>UI: Auto-configures RAM slider to 4.5 GB & CPU-only mode
    UI->>Engine: evaluate(candidates, requirement)
    Engine->>Catalog: Fetch canonical verified models
    Engine->>Engine: Phase 1: Hard filter out models exceeding 4.5 GB RAM or requiring GPU
    Engine->>Engine: Phase 2: Rank eligible models with normalized scoring
    Engine-->>UI: Shortlist (Rank #1 + Runner-ups + Rejection Explanations)
    UI-->>User: Displays Zero-Lag Shortlist & [Compare Candidates] button
```

### Hardware Presets Supported:
* **Budget Laptop (4 GB RAM, CPU-Only)**: Allocates safe 2.0 GB RAM budget. Designed for dual-core and quad-core budget laptops. Highlights models like `SqueezeNet-1.1`, `MobileNetV3-Small`, `TinyBERT-4L`, and `paraphrase-MiniLM-L3-v2`.
* **Standard Work Laptop (8 GB RAM, CPU-Only)**: Allocates safe 4.5 GB RAM budget. Accommodates `EfficientNet-B0`, `ResNet-18`, `DistilBERT`, `YOLOv8n`, and `all-MiniLM-L6-v2`.
* **GPU Workstation (16 GB RAM + Dedicated VRAM)**: Allocates 10.0 GB RAM and enables GPU-accelerated architectures like `RoBERTa-Base` and `YOLOv8s`.

---

## 4. Recommendation & Scoring Formulation (Blueprint Section 8)

### Phase 1: Hard Constraint Elimination
Any model $m \in M$ is immediately disqualified if:
1. $m.\text{task} \neq R.\text{task}$
2. $m.\text{minRamBytes} > R.\text{availableRamBytes}$
3. $R.\text{cpuOnly} = \text{true} \land m.\text{minVramBytes} > 0$
4. $R.\text{maxLatencyMs} \neq \text{null} \land m.\text{latencyMs} > R.\text{maxLatencyMs}$
5. $R.\text{allowedLicenses} \neq \emptyset \land m.\text{license} \notin R.\text{allowedLicenses}$

### Phase 2: Multi-Attribute Weighted Scoring
For all eligible models, features are normalized into $[0.0, 1.0]$:
* **Accuracy Score**: $S_{\text{acc}} = \frac{\text{acc} - \min(\text{acc})}{\max(\text{acc}) - \min(\text{acc}) + \epsilon}$
* **Latency Score**: $S_{\text{lat}} = \frac{\max(\text{lat}) - \text{lat}}{\max(\text{lat}) - \min(\text{lat}) + \epsilon}$
* **RAM Efficiency**: $S_{\text{ram}} = \frac{\max(\text{ram}) - \text{ram}}{\max(\text{ram}) - \min(\text{ram}) + \epsilon}$
* **Parameter Efficiency**: $S_{\text{param}} = \frac{\max(\text{params}) - \text{params}}{\max(\text{params}) - \min(\text{params}) + \epsilon}$
* **License Favorability**: Permissive (Apache 2.0 / MIT / BSD) = 1.0; Copyleft (AGPL / GPL) = 0.5.

$$\text{Total Score} = 100 \times \left( 0.35 S_{\text{acc}} + 0.25 S_{\text{lat}} + 0.20 S_{\text{ram}} + 0.10 S_{\text{param}} + 0.10 S_{\text{lic}} \right)$$

---

## 5. Side-by-Side Model Comparison Matrix (Blueprint Section 7)

When 2 or more candidate models are shortlisted, `ModelComparisonScreen` renders a head-to-head technical matrix:

| Metric Evaluated | Purpose & Diagnostic Value |
| :--- | :--- |
| **Laptop Feasibility Badge** | Identifies if model runs sub-30ms without lagging on typical laptop CPUs |
| **Inference Latency** | Actual benchmark millisecond latency on standard CPU hardware |
| **RAM Footprint** | Physical memory occupied by model weights and runtime tensor buffers |
| **Parameter Count & Disk Size** | Model compression footprint and storage overhead |
| **Benchmark Accuracy** | Standard evaluation metric (ImageNet Top-1, COCO mAP50-95, GLUE SST-2, MTEB) |
| **Commercial License** | Identifies license compatibility for enterprise and commercial distribution |
| **Key Trade-off Summary** | Human-readable explanation of why a developer would pick Model A over Model B |

---

## 6. Directory Hierarchy

```text
meet_app/
├── lib/
│   ├── main.dart                          # Application bootstrap & route configuration
│   ├── models/
│   │   ├── ml_model.dart                  # Model entity with technical specs & laptop feasibility
│   │   ├── project_requirement.dart       # Project constraints & hardware limits
│   │   └── decision_record.dart           # Persistent decision snapshot & trade-off rationale
│   ├── services/
│   │   ├── hardware_detection_service.dart # Real host hardware scanner & laptop presets
│   │   ├── recommendation_engine.dart     # Hard filtering & multi-attribute scoring
│   │   ├── canonical_catalog_service.dart # 16 verified canonical models
│   │   ├── security_engine.dart           # TOTP MFA, brute-force mitigation & audit logging
│   │   └── firestore_service.dart         # Cloud synchronization & data persistence
│   ├── screens/
│   │   ├── main_shell_screen.dart         # 3-tab modern shell
│   │   ├── decision_engine_screen.dart    # Requirement builder, auto-detect & shortlist
│   │   ├── model_comparison_screen.dart   # Side-by-side technical matrix
│   │   ├── model_list_screen.dart         # Model catalog with feasibility HUD
│   │   ├── model_detail_screen.dart       # Deep model inspector & evidence links
│   │   └── saved_decisions_screen.dart    # Decision history & audit reports
│   └── widgets/
│       ├── model_card.dart                # Model card with memory footprint & laptop badges
│       └── account_menu.dart              # Reusable profile & session menu
└── test/
    ├── hardware_detection_test.dart       # Hardware auto-detect & preset tests
    ├── recommendation_engine_test.dart    # Constraint filtering & scoring verification
    ├── widget_test.dart                   # Main shell navigation & session lifecycle
    └── security_audit_test.dart           # Authentication & rate-limit tests
```
