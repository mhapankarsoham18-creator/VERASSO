# 🌌 VERASSO

### THE DECENTRALIZED COGNITIVE ECOSYSTEM

**Verasso** is not just an app; it is a digital nervous system designed to thrive where the internet dies. It fuses **Neural Mesh Networking**, **Zero-Knowledge Identity**, and **3D Immersive Learning** into a single, cohesive platform for growth, work, and discovery.

---

## 🧬 CORE ARCHITECTURE

### 🧠 NEURAL MESH (P2P)

Gone are the days of server reliance. Verasso utilizes a custom-engineered **Reinforcement Learning (Multi-Armed Bandit)** routing algorithm to navigate peer-to-peer data.

- **Offline Autonomy**: Trade jobs, send E2E encrypted messages, and sync learning progress via Bluetooth & WiFi Direct.
- **Expertise-Aware TTL**: Data propagates smarter, not harder, by prioritizing nodes with relevant domain knowledge.

### 🛡️ COGNITIVE SOVEREIGNTY (ZK-PRIVACY)

Your identity is your own. Using **Zero-Knowledge Proofs (ZK)**, Verasso allows you to verify your skills and credentials across the network without ever exposing your private profile or global IDs.

- **Blinded Identifiers**: Session-based anonymity for every mesh interaction.
- **Proof of skill**: Cryptographic commitments to your mastery.

### 🧪 IMMERSIVE LEARNING (3D/AR)

Experience knowledge as a physical reality. With 65+ specialized simulations spanning Physics, Chemistry, Biology, and Astronomy, learning is an active pursuit.

- **Cognitive Dashboard**: Explore your knowledge profile in a reactive, 3D node-graph visualization.
- **Liquid Glass 2.0**: A UI that breaths with the network—frosted glass aesthetics that react dynamically to mesh congestion.

---

## 💼 THE TALENT ECONOMY

A decentralized marketplace for the global workforce.

- **The Ledger**: A cryptographic record of work and reputation, ensuring transaction integrity even when the cloud is out of reach.
- **Mentor Discovery**: Find guides in the mesh or the cloud, supported by high-fidelity portfolio tracking.

---

## 🛠️ TECH STACK

- **Engine**: Flutter (Dart)
- **State**: Riverpod (Signal-driven architecture)
- **Mesh**: Nearby Connections + Custom RL Routing
- **Security**: Ed25519 (Signing), X25519 (E2E Key Exchange), AES-256 (Encryption)
- **Storage**: Hybrid Supabase (Cloud) + Hive (Encrypted Local) + SQLite (Offline Queue)

---

## 🚀 GETTING STARTED

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (≥3.3.0)
- Dart SDK (included with Flutter)
- Android Studio / Xcode (for device emulators)
- A [Supabase](https://supabase.com/) project (free tier works)

### Setup

```bash
# 1. Clone the repository
git clone <repo-url> && cd VERASSO

# 2. Install dependencies
flutter pub get

# 3. Configure environment
cp .env.example .env
# Edit .env with your Supabase URL, anon key, and Sentry DSN

# 4. Generate code (Riverpod, JSON serialization, mocks)
dart run build_runner build --delete-conflicting-outputs

# 5. Run the app
flutter run --dart-define-from-file=.env

# 6. Run tests
flutter test
```

### Firebase Setup

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Add Android app → download `google-services.json` to `android/app/`
3. Add iOS app → download `GoogleService-Info.plist` to `ios/Runner/`

---

## 🛤️ PHILOSOPHY

Verasso is built on the belief that **Knowledge should be free, Identity should be private, and Connectivity should be a right, not a subscription.**

Join the mesh. Own your mind.
