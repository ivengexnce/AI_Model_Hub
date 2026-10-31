# BroML 🧠⚡
### AI/ML Model Decision Intelligence Platform & Neural Architecture Hub

<p align="center">
  <img src="assets/logo.png" alt="BroML Logo" width="150" height="150" style="border-radius: 28px; box-shadow: 0 12px 32px rgba(0, 229, 255, 0.25);" />
</p>

<p align="center">
  <b>Evidence-Backed Model Selection, Hardware Auto-Detection & Head-to-Head Architectural Comparison</b>
</p>

<p align="center">
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.24+-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" /></a>
  <a href="https://dart.dev"><img src="https://img.shields.io/badge/Dart-3.13.5+-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" /></a>
  <img src="https://img.shields.io/badge/Hardware_Profiling-Auto--Detect_RAM-00E5FF?style=for-the-badge&logo=intel&logoColor=white" alt="Hardware Profiling" />
  <img src="https://img.shields.io/badge/Decision_Engine-Blueprint_1.0-10B981?style=for-the-badge&logo=fastapi&logoColor=white" alt="Decision Engine" />
  <img src="https://img.shields.io/badge/Tests-60%20Passed%20(100%25)-success?style=for-the-badge&logo=checkmarx&logoColor=white" alt="Tests" />
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-38BDF8?style=for-the-badge" alt="License" /></a>
</p>

---

## 📑 Table of Contents
- [🚀 Product Overview](#-product-overview)
- [⚡ Hardware Auto-Detection & Laptop Profiler](#-hardware-auto-detection--laptop-profiler)
- [🧠 Decision & Recommendation Engine](#-decision--recommendation-engine)
- [⚖️ Side-by-Side Model Comparison Matrix](#️-side-by-side-model-comparison-matrix)
- [📚 Verified Canonical Model Catalog](#-verified-canonical-model-catalog)
- [📱 Clean 3-Tab Main Navigation Shell](#-clean-3-tab-main-navigation-shell)
- [🛡️ Enterprise Security & Threat Protection](#️-enterprise-security--threat-protection)
- [🏛️ System Architecture](#️-system-architecture)
- [🧪 Automated Testing & Verification](#-automated-testing--verification)
- [🛠️ Getting Started & Local Setup](#️-getting-started--local-setup)

---

## 🚀 Product Overview

**BroML** (*AI/ML Model Decision Intelligence*) is an engineering tool designed to answer one critical question for AI/ML developers, students, and engineers:

> *"Given my real hardware resources (laptop RAM, CPU/GPU) and deployment constraints, which models are compatible, what are their technical trade-offs, and what evidence supports the recommendation?"*

Unlike uncurated lists that rank repos by popularity or display fabricated benchmark numbers, BroML enforces **verified metadata**, **hardware compatibility before popularity**, and **transparent rejection explanations**.

---

## ⚡ Hardware Auto-Detection & Laptop Profiler

Many developers work on laptops with 4 GB or 8 GB RAM and no dedicated GPU. Loading heavy neural networks can freeze or thermal throttle the machine. 

BroML includes an automated hardware discovery and profiling engine:
* **Real System Memory Scanner**: Auto-detects total physical memory (via `/proc/meminfo` on Linux/Android and WMI on Windows) and CPU cores (`Platform.numberOfProcessors`).
* **Zero-Lag Safe Memory Budgeting**: Calculates a safe ML allocation (60% of total RAM, reserving 40% for the operating system and background applications) so the host laptop **never stutters or crashes**.
* **1-Click Hardware Target Presets**:
  * 💻 **Budget Laptop (4 GB RAM, CPU-Only)**: Allocates safe 2.0 GB budget. Identifies ultra-light models (`SqueezeNet-1.1`, `MobileNetV3-Small`, `TinyBERT-4L`, `paraphrase-MiniLM-L3-v2`).
  * 💻 **Standard Work Laptop (8 GB RAM, CPU-Only)**: Allocates safe 4.5 GB budget. Supports balanced models (`ResNet-18`, `EfficientNet-B0`, `DistilBERT`, `YOLOv8n`, `all-MiniLM-L6-v2`).
  * 🚀 **GPU Workstation (16 GB RAM + Dedicated VRAM)**: Allocates 10.0 GB budget for high-accuracy deep models.
* **Laptop Feasibility Badges**: Every model card displays a real-time status indicator:
  * 🟢 `Laptop Ready (Zero Lag)`: Inference $<30\text{ ms}$ on standard laptop CPUs, $<1\text{ GB RAM}$.
  * 🟡 `Standard Laptop`: Inference $30{-}80\text{ ms}$ on laptop CPUs.
  * 🔴 `Heavy on Laptop CPU / Requires GPU`: Disclosed clearly to prevent hardware freeze.

---

## 🧠 Decision & Recommendation Engine

BroML applies a two-phase deterministic decision pipeline (Technical Implementation Blueprint 1.0, Section 8):

### Phase 1: Hard Constraint Filtering
Models are immediately rejected if they exceed available RAM, require dedicated GPU VRAM during CPU-only execution, violate maximum latency ceilings, or breach license restrictions. Every rejected candidate displays its exact reason:
> *"Requires 1.5 GB RAM, exceeds 0.5 GB budget"*  
> *"Requires dedicated GPU VRAM (1.0 GB) while CPU-only execution is enforced"*

### Phase 2: Multi-Attribute Weighted Ranking
Eligible candidates are normalized into $[0.0, 1.0]$ and scored across 5 dimensions:
$$\text{Score} = 100 \times \left( 0.35 S_{\text{acc}} + 0.25 S_{\text{lat}} + 0.20 S_{\text{ram}} + 0.10 S_{\text{param}} + 0.10 S_{\text{lic}} \right)$$

---

## ⚖️ Side-by-Side Model Comparison Matrix

When candidates are shortlisted, users can open the **Side-by-Side Technical Comparison Matrix** to compare models head-to-head before locking in a decision:

| Evaluation Metric | Model A (e.g. all-MiniLM-L6-v2) | Model B (e.g. BGE-Small-EN-v1.5) |
| :--- | :--- | :--- |
| **Architecture Rank** | 🏆 **Rank #1** (65 pts) | 🥈 **Rank #2** (58 pts) |
| **Laptop Feasibility** | 🟢 **Laptop Ready (Zero Lag)** | 🟡 **Standard Laptop** |
| **Laptop CPU Latency** | 🟢 **7 ms** (Fastest) | 🟡 **14 ms** |
| **RAM Footprint** | 🟢 **512 MB** | 🟡 **1.0 GB** |
| **Benchmark Accuracy** | 56.3% (MTEB Retrieval) | **62.1%** (+5.8% Quality) |
| **Parameter Count** | 22.7M parameters | 33.5M parameters |
| **Commercial License** | Apache-2.0 | MIT |
| **Action** | `[Select #1 Best]` | `[Select Rank #2]` |

---

## 📚 Verified Canonical Model Catalog

BroML replaces generic third-party scraped tutorials with 30 verified canonical foundation models covering all 5 core ML disciplines:

### 1. Computer Vision
* **Image Classification**: `SqueezeNet-1.1` (1.2M), `MobileNetV3-Small` (2.5M), `ResNet-18` (11.7M), `EfficientNet-B0` (5.3M), `ResNet-50` (25.6M).
* **Object Detection**: `YOLOv5n` (1.9M), `SSD-MobileNetV2` (4.3M), `YOLOv8n` (3.2M), `YOLOv8s` (11.2M).
* **Generative Diffusion**: `FLUX.1-schnell` (12B).

### 2. Natural Language Processing & Large Language Models
* **Text Classification**: `TinyBERT-4L` (14.5M), `DistilBERT-Base` (66.4M), `RoBERTa-Base` (124.6M).
* **Sentiment Analysis**: `TinyBERT-SST2` (14.5M), `DistilBERT-SST2` (66.4M), `RoBERTa-Sentiment` (124.6M).
* **Text Embedding**: `paraphrase-MiniLM-L3-v2` (17.5M), `all-MiniLM-L6-v2` (22.7M), `BGE-Small-EN-v1.5` (33.5M), `Nomic Embed Text v1.5` (137M).
* **On-Device LLMs**: `Meta LLaMA 3.2 1B Instruct` (1.23B), `DeepSeek-R1 Distill Qwen 1.5B` (1.5B).

### 3. Audio & Speech Processing
* **Speech Recognition (ASR)**: `Whisper-Tiny` (39M), `Whisper-Base` (74M).
* **Voice Activity Detection**: `Silero VAD` (250k).

### 4. Tabular ML & Classical Machine Learning
* **Gradient Boosted Trees (GBDT)**: `DMLC XGBoost`, `Microsoft LightGBM`, `Yandex CatBoost`.

### 5. Reinforcement Learning
* **Policy & Value Optimization**: `Stable-Baselines3 PPO`, `CleanRL Deep Q-Network (DQN)`.

---

## 📱 Clean 3-Tab Main Navigation Shell

1. **Decision Engine (`/decision_engine`)**: Requirement builder, hardware auto-detection, interactive latency sliders, ranked shortlist, and rejection explanations.
2. **Model Catalog (`/models`)**: Searchable canonical model registry with laptop feasibility HUD, memory footprint tags, and architecture cards.
3. **Saved Decisions (`/saved_decisions`)**: Historical archive of selected architectures, requirements, trade-off summaries, and decision timestamps.

---

## 🛡️ Enterprise Security & Threat Protection

BroML features application-level defense protecting user accounts and data:
* **RFC 6238 TOTP Multi-Factor Authentication** with replay protection.
* **Progressive Rate Limiting & Distributed Brute-Force Throttling**.
* **Password Breach Dictionary Defense** and cryptographic hashing.
* **Tamper-Evident Security Audit Ledger**.

---

## 🏛️ System Architecture

Detailed engineering specifications, flowcharts, sequence diagrams, and mathematical formulations are documented in:
* **[`ARCHITECTURE.md`](file:///c:/Users/Admin/AndroidStudioProjects/meet_app/ARCHITECTURE.md)** — Complete 5-tier architecture & data schemas.
* **[`SECURITY_ASSESSMENT_REPORT.md`](file:///c:/Users/Admin/AndroidStudioProjects/meet_app/SECURITY_ASSESSMENT_REPORT.md)** — Red-team audit and verification proofs.

---

## 🧪 Automated Testing & Verification

BroML maintains a 100% green test suite across 60 automated unit, widget, and red-team tests:
```powershell
flutter analyze
# Analyzing meet_app...
# No issues found! (ran in 5.1s)

flutter test
# 00:03 +60: All tests passed!
```

---

## 🛠️ Getting Started & Local Setup

### Prerequisites
* Flutter SDK (3.24.0 or newer)
* Dart SDK (3.13.5 or newer)
* Android Studio / VS Code

### Run Locally
```powershell
# 1. Clone repository
git clone https://github.com/your-username/meet_app.git
cd meet_app

# 2. Install dependencies
flutter pub get

# 3. Run automated test suite
flutter test

# 4. Launch application
flutter run
```
