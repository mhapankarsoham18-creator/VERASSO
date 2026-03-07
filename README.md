# 🌌 VERASSO

## THE DECENTRALIZED COGNITIVE ECOSYSTEM

**Verasso** is a "digital nervous system" designed to thrive where the internet dies. It fuses **Neural Mesh Networking**, **Zero-Knowledge Identity**, and **3D Immersive Learning** into a single, cohesive platform for growth, work, and discovery.

---

## 🧬 CORE ARCHITECTURE

### 🧠 NEURAL MESH (P2P)

VERASSO utilizes a sophisticated hybrid P2P architecture to ensure connectivity even in dead zones.

- **Discovery**: Uses `nearby_connections` (P2P_CLUSTER) for reliable local peer-to-peer discovery.
- **RL-Routing**: A custom **Multi-Armed Bandit** algorithm navigates data through the mesh based on node reliability and expertise.
- **Proactive Relay**: `MeshSyncManager` supports multi-hop relaying for critical packets (chat, doubts, science data) with expertise-aware TTL.
- **Cloud Bridge**: `SyncBridgeService` uplinks packets to Supabase automatically when a gateway node finds internet.

### 🛡️ COGNITIVE SOVEREIGNTY (ZK-PRIVACY)

Your identity and achievements are cryptographically secured.

- **Zero-Knowledge Proofs**: Verify skills and credentials without exposing your global identity.
- **Proof of Mastery**: Cryptographic signatures of learning progress (`MasterySignatureService`) ensure untamperable academic records.
- **Blinded Identifiers**: Session-based anonymity for all mesh interactions.

---

## 🧪 THE LEARNING HUB

### 🎮 CODEMASTER ODYSSEY (Integrated RPG)

A flagship retro-RPG learning experience built directly into the ecosystem.

- **Python Combat**: Defeat enemies like the `Variable Viper` and `Syntax Error` by solving real-time coding challenges.
- **Region Management**: Explore 5+ distinct regions, each focusing on different programming paradigms.

### 🔬 SCIENCE SIMULATIONS (3D/AR)

Immersive 3D environments for specialized domains:

- **Biology**: 3+ Interactive simulations (Cell Structure, Synaptic Transmission).
- **Chemistry**: 4+ Interactive simulations (Molecular Builder, Titration Lab, Periodic Table, Gas Law Lab).
- **Physics**: 12+ Interactive simulations across 6 specialized lab categories.
- **Astronomy**: Interactive stellar maps and planetary simulations.
- **Pharmacy (AR)**: Augmented Reality drug viewer and chemical interaction lab.
- **Finance**: Dynamic ROI calculators and economic modeling simulations.
- **History**: AR Archaeological reconstructions and timeline explorer.

### 🏫 CLASSROOM 2.0

Collaborative learning that works offline:

- **Mesh-Labs**: Conduct experiments in collaborative mesh groups even without Wi-Fi.
- **Relay-Game**: Gamified collaborative problem-solving across the network.

---

## 💼 THE TALENT ECONOMY

A decentralized marketplace for the global workforce.

- **The Job Ledger**: A cryptographic record of work, reputation, and payouts.
- **Job Repository**: Proactively match skills with local or cloud-based opportunities.
- **MFA Security**: Multi-factor authentication (Biometrics + OTP) for all sensitive financial operations.

---

## 🛠️ TECH STACK

- **Framework**: Flutter 3.41.0 (Stable)
- **State Management**: Riverpod (Signal-driven architecture)
- **Mesh Layer**: Nearby Connections + Custom Multi-hop Routing
- **Intelligence**: Integrated Gemini & OpenRouter AI support
- **Backend**: Hybrid Supabase (Cloud) + Encrypted SQLite/Hive (Local)
- **CI/CD**: Consolidated GitHub Actions with **Auto-Formatting** and automated security scanning.

---

## 🚀 GETTING STARTED

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.41.0)
- [Supabase CLI](https://supabase.com/docs/guides/cli)
- Android Studio / Xcode

### Setup

```bash
# 1. Clone & Install
git clone <repo-url> && cd VERASSO
flutter pub get

# 2. Configure Environment
cp .env.example .env
# Fill in your SUPABASE_URL and SUPABASE_ANON_KEY

# 3. Code Generation
dart run build_runner build --delete-conflicting-outputs

# 4. Launch
flutter run --dart-define-from-file=.env
```

---

## 🛤️ PHILOSOPHY

Verasso is built on the belief that **Knowledge should be free, Identity should be private, and Connectivity should be a right, not a subscription.**

Join the mesh. Own your mind.
