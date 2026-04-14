# VERASSO — Product Requirements Document
### Version 1.0 | March 2026 | India Innovates 2026 — iDEA 2.0

---

## Table of Contents

1. [Overview](#1-overview)
2. [Problem Statement](#2-problem-statement)
3. [Vision & Mission](#3-vision--mission)
4. [Target Users](#4-target-users)
5. [Core Pillars](#5-core-pillars)
6. [App Architecture](#6-app-architecture)
7. [Tech Stack](#7-tech-stack)
8. [Mesh Network Architecture](#8-mesh-network-architecture)
9. [Network States](#9-network-states)
10. [Security & Identity](#10-security--identity)
11. [Feature Specifications](#11-feature-specifications)
    - [11.1 Authentication & Profiles](#111-authentication--profiles)
    - [11.2 Social Feed & Content](#112-social-feed--content)
    - [11.3 Doubts, Q&A & Discussions](#113-doubts-qa--discussions)
    - [11.4 Trust, Reputation & Roles](#114-trust-reputation--roles)
    - [11.5 Study Tools & Notes](#115-study-tools--notes)
    - [11.6 Physics Immersive Module](#116-physics-immersive-module)
    - [11.7 Chemistry Virtual Lab](#117-chemistry-virtual-lab)
    - [11.8 Biology Immersive Learning](#118-biology-immersive-learning)
    - [11.9 AR & 3D Experiences](#119-ar--3d-experiences)
    - [11.10 Messaging, Groups & Collaboration](#1110-messaging-groups--collaboration)
    - [11.11 Offline Mesh Communication](#1111-offline-mesh-communication)
    - [11.12 Talent Economy & Decentralized Jobs](#1112-talent-economy--decentralized-jobs)
    - [11.13 Search, Discovery & Recommendations](#1113-search-discovery--recommendations)
    - [11.14 Safety, Moderation & Admin](#1114-safety-moderation--admin)
12. [Mesh Implementation Plan](#12-mesh-implementation-plan)
13. [Packet Model & Routing](#13-packet-model--routing)
14. [Emergency Mode](#14-emergency-mode)
15. [Background Service](#15-background-service)
16. [UI/UX Specifications](#16-uiux-specifications)
17. [Data Models](#17-data-models)
18. [Backend & Infrastructure](#18-backend--infrastructure)
19. [Security Engineering](#19-security-engineering)
20. [Permissions](#20-permissions)
21. [Testing Checklist](#21-testing-checklist)
22. [Monetization](#22-monetization)
23. [Roadmap](#23-roadmap)
24. [Team](#24-team)
25. [Deployment Notes](#25-deployment-notes)

---

## 1. Overview

**Verasso** is a decentralized, offline-first learning and talent ecosystem for students and professionals. It combines:

- A social-learning platform (feed, doubts, immersive science modules, AR)
- A privacy-first BLE + WiFi mesh communication layer that works without any internet
- A decentralized identity and talent marketplace

The core insight: **every existing educational and communication tool breaks exactly when it is needed most** — during disasters, connectivity outages, and in infrastructure-poor regions. Verasso does not.

Verasso has **1,237 real users** as of March 2026 and was submitted to India Innovates 2026 (iDEA 2.0, Union Bank of India / IBA — PS9, Open Innovation / EdTech track).

**Team:** Soham Mhapankar (Lead), Aditya Mhatre, Deven Dhule

---

## 2. Problem Statement

> **Over 700 million people lose internet access daily due to disasters, censorship, or infrastructure failure — yet every emergency communication tool requires the very infrastructure that fails first.**

Existing messaging and learning apps collapse exactly when they are needed most. There is no production-ready, privacy-first platform that enables secure peer-to-peer communication, offline learning, and decentralized identity — without depending on servers, SIM cards, or internet connectivity.

Specifically:

- Students in rural India, disaster zones, and internet-censored regions cannot communicate, learn, or prove their identity when connectivity drops
- 1.4 billion people in low-connectivity regions have smartphones but cannot reliably use them for education, employment verification, or emergency communication
- No platform works for them without infrastructure they do not have
- Current solutions either require internet (WhatsApp, Signal), depend on paid vendor lock-in (Bridgefy), or exist only as isolated apps rather than embeddable platforms (Briar, bitchat)

**Verasso is the missing layer.**

---

## 3. Vision & Mission

**Vision:** Knowledge should be free. Identity should be private. Connectivity should be a right.

**Mission:** Build the first platform combining BLE mesh networking with zero-knowledge identity for offline-capable education — requiring no server infrastructure for core functionality.

**Tagline:** *"No internet? The mesh takes over."*

---

## 4. Target Users

| Segment | Description |
|---|---|
| School students (Class 9–12) | JEE, NEET, board exam prep; use science modules and doubts |
| College students | Peer learning, resource sharing, group study |
| Teachers / Mentors | Share notes, answer doubts, create study groups |
| Students in low-connectivity areas | Primary beneficiaries of mesh offline layer |
| Emergency responders | Use emergency mesh mode for SOS and coordination |
| Competitive exam aspirants | JEE, NEET, UPSC — use flashcards, timetable, topic pages |

---

## 5. Core Pillars

```
VERASSO
├── LEARN         — Immersive science modules (Physics, Chemistry, Biology, AR)
├── CONNECT       — Social feed, doubts, Q&A, messaging
├── MESH          — Offline-first BLE + WiFi mesh communication
├── IDENTITY      — Zero-knowledge private identity (Ed25519 / X25519)
└── TALENT        — Decentralized job marketplace, no intermediaries
```

---

## 6. App Architecture

```
┌─────────────────────────────────────────────────────┐
│                   Flutter UI Layer                   │
│   Riverpod state management · Signal-driven arch     │
├──────────────┬──────────────┬───────────────────────┤
│  Learn       │  Connect     │  Mesh                 │
│  (Modules)   │  (Social)    │  (Offline P2P)        │
├──────────────┴──────────────┴───────────────────────┤
│              Identity & Encryption Layer             │
│   Ed25519 · X25519 · AES-256-GCM · ZK Proofs        │
├─────────────────────────────────────────────────────┤
│              Data Layer                             │
│   Supabase (online) · Hive (offline) · SQLite       │
├─────────────────────────────────────────────────────┤
│              Mesh Transport Layer                   │
│   bitchat-mesh (BLE) · Meshrabiya (WiFi) · Nearby   │
└─────────────────────────────────────────────────────┘
```

**System Flow:**
```
USER → MESH → ZK VERIFY → LEDGER → LEARNING SYNC
```

---

## 7. Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (Dart) |
| State Management | Riverpod (signal-driven) |
| Backend | Supabase (PostgreSQL, Auth, Storage) |
| Local Storage | Hive (offline queue) + SQLite |
| BLE Mesh (Primary) | bitchat-mesh library (MIT, no API key) |
| WiFi Mesh (Secondary) | Meshrabiya — 300Mbps+, no Google Play Services |
| P2P Fallback | nearby_service |
| Network Detection | connectivity_plus |
| Background Service | flutter_background_service + flutter_foreground_task |
| Cryptography | Ed25519, X25519, AES-256-GCM |
| Routing Algorithm | RL Multi-Armed Bandit (Thompson Sampling / UCB) |
| Emergency GPS | geolocator |
| Rendering | Flutter canvas + custom shaders |
| AR | ARCore (Android) |
| Monitoring | Sentry (early config) |

**Free through MVP — zero proprietary dependencies.**

---

## 8. Mesh Network Architecture

```
Internet available?
    └── Normal send via existing backend (CONNECTED mode)

No internet detected? → MESH ROAMING MODE
    ├── bitchat-mesh (BLE)          ← PRIMARY  ~100m
    ├── Meshrabiya (WiFi Direct)    ← SECONDARY ~300m+
    └── nearby_service              ← FALLBACK
         └── All three fire simultaneously
         └── Hive stores undelivered messages (store-and-forward)
         └── Foreground service keeps everything alive
         └── Internet restored? → flush Hive queue instantly

Emergency triggered? → EMERGENCY MESH MODE
    ├── BLE switches to longReach profile (max range)
    ├── All radios at max power simultaneously
    ├── GPS coords attached unencrypted to packets
    ├── Never expires (7-day TTL)
    └── Relay users notified they are re-broadcasting
```

**Radio Stack Summary:**

| Layer | Library | Range | Role |
|---|---|---|---|
| PRIMARY | bitchat-mesh | ~100m BLE | Replaces Bridgefy — free, MIT, no API key |
| SECONDARY | Meshrabiya | ~300m+ WiFi | Replaces flutter_p2p_connection |
| FALLBACK | nearby_service | varies | Backup radio, auto-discover |

**Why bitchat-mesh over Bridgefy:**
- No API key required
- No internet on first launch for license validation
- MIT licensed — zero cost forever
- Multi-hop relay (7 hops), store-and-forward built-in
- X25519 + AES-256-GCM encryption included
- Active development (3.4k GitHub stars)

---

## 9. Network States

```dart
enum VerassoNetworkState {
  CONNECTED,              // Internet available — normal send
  MESH_ROAMING,           // No internet — mesh takes over, medium power
  MESH_ROAMING_EMERGENCY  // SOS — all radios max power, GPS attached
}
```

| State | Trigger | Behavior | UI |
|---|---|---|---|
| CONNECTED | Internet present | Normal backend send | No banner |
| MESH_ROAMING | Internet lost | All three radios activate, Hive queues messages | Amber banner: "Mesh Roaming Active · N nearby users" |
| MESH_EMERGENCY | SOS triggered by user | All radios max power, GPS attached, 7-day TTL | Red banner: "Emergency Mesh Active · GPS broadcasting" |

---

## 10. Security & Identity

### Cryptography Standards

| Purpose | Algorithm |
|---|---|
| Key exchange | X25519 (Curve25519 ECDH) |
| Message signing | Ed25519 (EdDSA) |
| Message encryption | AES-256-GCM |
| Identity proofs | zk-SNARKs / zk-STARKs |
| Transport (mesh) | Noise Protocol (forward secrecy) |

### ZK Identity
- Users prove attributes (age, institution, qualification) without revealing underlying data
- No central authority stores identity — verification is peer-validated
- Privacy-first: no phone numbers, no real name required
- Random ephemeral peer IDs generated per session

### Mesh Packet Security
- All packets are E2E encrypted using user's existing encryption keys
- Relay nodes see packet header only — never content
- Emergency GPS coords are the only unencrypted field (intentional for rescue)

---

## 11. Feature Specifications

### 11.1 Authentication & Profiles

**Login / Sign-up:**
- Email + password or OAuth (Google)
- Supabase Auth with JWT session management
- First launch: one-time internet required for mesh license init

**User Profile:**
- Name, avatar, bio, institute, role (student / teacher / admin / moderator)
- Subjects and interests
- Followers / following count
- Trust score (visible)
- Badges and milestones
- ZK identity verification status

**Settings:**
- Theme: light / dark / glassmorphism
- Privacy: who can DM, comment, see posts
- Notification control (per category)
- Language selection
- Mesh relay mode: Full Relay / Receive Only / Off
- Auto Emergency Mode toggle

---

### 11.2 Social Feed & Content

**Feed:**
- Instagram-style scrollable feed
- Post types: text, images, short videos, PDFs/notes, polls, question posts
- Tagged by: subject, chapter, level, exam (JEE / NEET / university)
- Actions: like, comment, share, save to collection, repost
- Hashtags, mentions, clickable topic tags → topic pages

**Post Creation:**
- Rich editor: diagrams, LaTeX math, code blocks
- Attach external links or drive files
- AR clip attachment (from AR mode)
- Subject + chapter + difficulty tagging

**Topic Pages:**
- Aggregate best posts, FAQs, formula sheets, practice sets per chapter/concept
- Curated by mentors and moderators

---

### 11.3 Doubts, Q&A & Discussions

**Doubts Section:**
- Post questions with: subject, topic, tags, images (diagrams, handwritten)
- Answer format: step-by-step, images, short videos
- Mark best answer as "Solved" → pins on thread
- Threaded comments for follow-up

**Voting & Trust Integration:**
- Upvotes / downvotes on answers
- Reports feed into trust system
- Wrong answers flagged by subject mentors

---

### 11.4 Trust, Reputation & Roles

**Trust Score Inputs:**
- Helpful answers marked solved
- Reports cleared
- Verified identity (ZK proof)
- Consistent positive activity
- Community upvotes

**Role Ladder:**
```
Normal User → Trusted Contributor → Subject Mentor → Moderator
```

Each level unlocks: flag handling, topic curation, featured posts.

**Badge System:**
- "Top in Physics Doubts"
- "Chem Lab Helper"
- "AR Explorer"
- "Mesh Relay Hero" (for users who relay emergency messages)
- Displayed on profile and certain posts

---

### 11.5 Study Tools & Notes

**Personal Library:**
- Save posts, notes, PDFs, question sets, playlists
- Organize into folders by subject and exam

**Flashcard Revision:**
- Spaced repetition (SRS) for definitions, formulas, reactions, diagrams
- Convert any note or post into flashcards
- Track recall accuracy per card

**Timetable & Task Planner:**
- Set study slots, chapter goals, deadlines
- Reminders and notifications
- Streak tracking
- Progress by subject and chapter

---

### 11.6 Physics Immersive Module

**Home Screen:**
- Tiles: Mechanics, Waves, Optics, EM, Modern Physics
- Each opens: mini-lessons → simulations → problem sets

**Simulations:**
- Topics: motion, forces, energy, electricity, optics
- Adjustable sliders: mass, angle, voltage, refractive index
- Real-time graphs synchronized to slider changes
- Guided tasks with hints

**Concept + Practice Flow:**
1. Interactive visual explanation
2. Simulation exploration
3. MCQs / numericals linked to the simulation

---

### 11.7 Chemistry Virtual Lab

**Dashboard:**
- Greeting + progress tracker by chapter
- Quick actions: Launch Simulation, Start Quiz, Ask a Doubt, Upload Experiment

**Virtual Experiments:**
- States of matter, gas laws, titrations, pH, redox, equilibrium
- Organic reactions, periodic trends
- Realistic glassware rendering, colour-changing indicators, physical controls

**Each Simulation Includes:**
- Balanced equations displayed live
- Particle-level animations
- Real-time graphs (pressure, temperature, concentration)
- Safety notes
- Lab notebook: observation tables, inference recording

---

### 11.8 Biology Immersive Learning

**Hub Topics:**
- Cells, Human Anatomy, Plant Physiology, Genetics, Microbiology

**Interactive Diagrams:**
- 3D-style zoomable models of organs, tissues, systems
- Highlight-on-tap → info cards
- Animations: blood circulation, nerve impulse, photosynthesis, mitosis

**Concept Checks:**
- Labelling tasks
- Drag-and-drop processes (stages of mitosis, steps of digestion)
- Case-based MCQs

---

### 11.9 AR & 3D Experiences

**AR Mode:**
- Place 3D models in real environment: solar system, human heart, circuits, molecules
- Rotation, zoom, labelled hotspots
- Powered by ARCore (Android)

**AR Practice:**
- Align lenses → see ray diagrams overlay
- Place charges → view electric field lines in room
- Arrange virtual lab apparatus over physical desk

**Sharing:**
- AR scenes recorded as short clips or screenshots
- Share directly to feed or as doubt explanation

---

### 11.10 Messaging, Groups & Collaboration

**One-to-One Chat:**
- Text, images, voice notes
- Quick-share: Verasso posts, doubts, simulations
- Optional E2E encryption for private chats

**Group Chats / Study Groups:**
- Based on: class, coaching batch, subject, exam
- Pinned resources, polls, shared task lists
- Group study session coordination

**Offline Mesh Messaging:**
- All messaging routes through mesh when internet unavailable
- Delivery status ticks: Sent → Relayed → Reached Internet → Delivered
- Messages never lost — Hive queue persists across app restarts

---

### 11.11 Offline Mesh Communication

This is Verasso's core differentiator. Full technical spec in sections 12–15.

**Key User-Facing Features:**
- Automatic mesh activation when internet drops (no user action needed)
- Status banner shows how many nearby users are relaying
- Delivery ticks that accurately reflect mesh hop status
- Emergency SOS button activates max-power broadcast with GPS

**Mesh Settings Screen:**
- Full Relay: help relay others' messages (~1% battery/day)
- Receive Only: only your messages (~0.3% battery/day)
- Off: no mesh, normal app only

---

### 11.12 Talent Economy & Decentralized Jobs

**Concept:**
- Decentralized job marketplace powered by peer nodes — no central servers
- Skill verification via ZK proofs — prove qualification without revealing institution
- Direct talent-to-opportunity connections without intermediaries

**Features:**
- Skill-based profile sections
- ZK-verified credentials (degree, marks, certifications)
- Direct peer-to-peer job/project matching
- Works offline — job listings sync when connectivity restores

---

### 11.13 Search, Discovery & Recommendations

**Global Search:**
- Across: users, posts, doubts, topics, simulations, groups
- Filters: subject, exam, difficulty, type (note / doubt / lab / AR)

**Recommendation Engine:**
- RL Multi-Armed Bandit (Thompson Sampling + UCB)
- Surfaces: relevant doubts, notes, simulations
- Based on: user profile, followed subjects, previous activity

**Topic Pages:**
- Best posts, FAQs, formula sheets, practice sets per chapter/concept
- Curated by subject mentors

---

### 11.14 Safety, Moderation & Admin

**Reporting:**
- Categories: spam, abusive, wrong information, plagiarism
- Reports feed into moderator dashboard queue

**Auto-Filters:**
- Slurs, hate speech, obvious spam links
- Soft warnings before posting sensitive or misleading academic content

**Admin Panel:**
- Manage featured content
- Global announcements (exam dates, app updates)
- Ban or shadow-limit harmful accounts
- Moderator assignment and escalation

---

## 12. Mesh Implementation Plan

**Goal:** Full multi-radio mesh network. 10–12 hours build time. Minimum 3 Android devices for testing.

### Package List

```yaml
dependencies:
  # BLE Mesh — PRIMARY (replaces Bridgefy)
  # bitchat-mesh: integrated as AAR/source module
  
  # WiFi Mesh — SECONDARY
  meshrabiya: via maven { url "https://devserver3.ustadmobile.com/maven2/" }
  
  # P2P Fallback
  nearby_service: latest
  
  # Network detection
  connectivity_plus: latest
  
  # Background service
  flutter_background_service: latest
  flutter_foreground_task: latest
  
  # Offline queue
  hive_flutter: latest
  
  # Emergency GPS
  geolocator: latest
```

### Phase-by-Phase Schedule

| Hour | Phase | Deliverable |
|---|---|---|
| 0–1 | Phase 0 | Permissions, Hive init, constants |
| 1–2 | Phase 1–2 | NetworkMonitor + MeshPacket model |
| 2–3 | Phase 3 | MessageQueue store-and-forward |
| 3–5 | Phase 4 | BLE layer working, 2 phones talking |
| 5–6 | Phase 5–6 | WiFi Direct + Nearby fallback |
| 6–7 | Phase 7 | Emergency GPS attached to packets |
| 7–8 | Phase 8 | MeshRouter — all layers wired |
| 8–9 | Phase 9 | Background service, relay app-closed |
| 9–10 | Phase 10 | UI banners, delivery ticks, settings |
| 10–11 | Phase 11–12 | Wired into main app, onboarding |
| 11–12 | Testing | 3-device relay, edge cases |

**Total: ~600 lines · 10 files · no API keys · everything else: already built**

---

## 13. Packet Model & Routing

### MeshPacket

```dart
class MeshPacket {
  final String messageId;        // UUID — deduplication key
  final String receiverId;       // target user UUID
  final Uint8List encryptedData; // existing E2E encrypted bytes
  final int createdAt;           // unix timestamp ms
  final int expiresAt;           // unix timestamp ms (24h normal, 7d emergency)
  final bool isEmergency;
  final double? latitude;        // unencrypted in emergency only
  final double? longitude;
  int hopCount;                  // relay hop counter (loop guard)
}
```

### MessageQueue (Hive store-and-forward)

| Method | Purpose |
|---|---|
| `enqueue()` | Add to pending — written BEFORE send (atomic safety) |
| `getPending()` | Emergency first → oldest first |
| `markDelivered()` | Remove from queue after confirmed |
| `hasSeenBefore()` | Deduplication — kills relay loops |
| `flushForInternet()` | Called when connectivity restores |
| `purgeExpired()` | Cleans stale packets on dispose |

### MeshRouter Receive Flow

```
1. Packet arrives from any radio layer
2. Expired? → discard
3. Seen before? → discard (dedup)
4. Mark as seen in shared cache
5. For me? → deliver to UI + mark done
6. Not for me? → enqueue + relay all radios
7. Internet restored? → flush Hive queue to backend
```

### RL Routing

- Multi-Armed Bandit (Thompson Sampling + UCB)
- Tracks delivery success rate per radio per peer
- Dynamically weights which radio fires first
- Degrades gracefully — if one radio fails repeatedly, deprioritized

---

## 14. Emergency Mode

**Trigger:** `meshRouter.triggerEmergency()` — user presses SOS button

**What activates:**
- BLE switches to `longReach` profile (maximum range)
- All three radios fire simultaneously at max power
- GPS coordinates fetched (10s timeout, null fallback → 0,0)
- GPS attached unencrypted to packet (rescue services can read)
- Packet TTL: 7 days (never expires mid-delivery)
- Nearby relay users receive notification: "You are relaying an SOS"

**Cancel:** `meshRouter.cancelEmergency()` — returns to CONNECTED or MESH_ROAMING

**Packet format (emergency):**
```dart
MeshPacket.emergency(
  receiverId: receiverId,
  encryptedData: encryptedPayload,  // message still encrypted
  latitude: position.latitude,       // GPS unencrypted
  longitude: position.longitude,
)
```

---

## 15. Background Service

**Purpose:** Keep mesh alive when app is closed. Without this, relay dies when screen turns off.

**Implementation:**
- `flutter_foreground_task` — battery optimization exemption
- `flutter_background_service` — foreground notification keeps process alive
- Hive initialized in background isolate (separate from UI)
- Notification text updates based on mesh state:
  - CONNECTED: hidden
  - MESH_ROAMING: "Verasso Mesh · Relaying for N users"
  - EMERGENCY: "Verasso Mesh · SOS Active"

**Android-specific:**
- `FOREGROUND_SERVICE_CONNECTED_DEVICE` permission
- `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` permission
- Survives battery saver mode

---

## 16. UI/UX Specifications

### Design System
- Theme: light / dark / glassmorphism
- Primary font: system sans-serif with LaTeX math rendering
- Accent colors by mode: cyan (normal), amber (mesh roaming), red (emergency)

### Status Banners (Mesh)

```
CONNECTED:      [hidden — no banner]
MESH_ROAMING:   📡 Mesh Roaming Active
                Sending through N nearby users · Battery drains faster
EMERGENCY:      🆘 Emergency Mesh Active
                All radios broadcasting · GPS attached · Never stops
```

### Delivery Tick States

| Ticks | Status |
|---|---|
| ✓ | Sent from device |
| ✓✓ | Picked up by relay |
| ✓✓✓ | Reached internet |
| ✓✓✓✓ | Delivered to recipient |

### Key Screens

- Home feed
- Doubts / Q&A
- Physics module
- Chemistry lab
- Biology hub
- AR explorer
- Messages / Groups
- Mesh settings
- Profile
- Search / Discover
- Admin panel
- Study library
- Timetable / Planner

### Onboarding (First Launch)
- One-time internet required for mesh activation
- Explains mesh roaming in simple terms
- Requests all permissions upfront with explanations
- Sets relay mode preference

---

## 17. Data Models

### User

```
id: UUID
name: string
email: string
avatar_url: string
bio: string
institute: string
role: enum (student | teacher | mentor | moderator | admin)
subjects: string[]
trust_score: float
zk_verified: boolean
created_at: timestamp
```

### Post

```
id: UUID
author_id: UUID
type: enum (text | image | video | pdf | poll | doubt | ar_clip)
content: string (rich text / markdown)
subject: string
chapter: string
difficulty: enum (easy | medium | hard)
exam_tags: string[]
likes: int
saves: int
created_at: timestamp
```

### MeshPacket (local Hive)

```
messageId: string (UUID)
receiverId: string
encryptedData: Uint8List
createdAt: int (ms)
expiresAt: int (ms)
isEmergency: boolean
latitude: double?
longitude: double?
hopCount: int
```

### StudyGroup

```
id: UUID
name: string
subject: string
exam: string
members: UUID[]
pinned_resources: resource[]
created_at: timestamp
```

---

## 18. Backend & Infrastructure

**Supabase (online):**
- PostgreSQL for all relational data
- Supabase Auth (JWT, sessions)
- Supabase Storage (images, PDFs, AR clips)
- Realtime subscriptions for feed and chat
- Row-level security (RLS) per user role

**Local (offline):**
- Hive: mesh message queue, seen-cache, settings
- SQLite: downloaded notes, flashcards, simulation progress

**Sync Strategy:**
- Optimistic local writes
- Background sync when internet restores
- Hive flush → Supabase upload on CONNECTED state

**Free through MVP — Supabase free tier handles core functionality.**

---

## 19. Security Engineering

### Vulnerabilities Fixed in Mesh Layer

| # | Attack Vector | Fix |
|---|---|---|
| 1 | Message replay loops | UUID deduplication in `hasSeenBefore()` |
| 2 | Expired messages relayed | `packet.isExpired` check before relay |
| 3 | App killed by Android OS | `flutter_foreground_task` + battery opt exempt |
| 4 | BLE radio needs internet first | Onboarding screen — one-time setup |
| 5 | Permissions silently fail | All 14 declared + runtime request Phase 0 |
| 6 | Message lost mid-send | Hive queue written BEFORE sending |
| 7 | Same packet via 3 radios | Single seen-cache shared across all layers |
| 8 | Emergency GPS fails silently | 10s timeout + graceful null → 0,0 fallback |
| 9 | Seen-cache grows forever | Auto-purge at 1,000 entries |
| 10 | Large messages exceed BLE MTU | bitchat-mesh handles chunking internally |

### Platform Security
- Certificate pinning (planned post-MVP)
- DPDP Act 2023 compliance
- No raw personal data stored on relay nodes
- Emergency GPS: only field intentionally unencrypted

---

## 20. Permissions

### AndroidManifest.xml — All Required

```xml
<!-- Bluetooth -->
<uses-permission android:name="android.permission.BLUETOOTH"/>
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN"/>
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"
    android:usesPermissionFlags="neverForLocation"/>
<uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE"/>
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>

<!-- WiFi Direct -->
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE"/>
<uses-permission android:name="android.permission.CHANGE_WIFI_STATE"/>
<uses-permission android:name="android.permission.NEARBY_WIFI_DEVICES"
    android:usesPermissionFlags="neverForLocation"/>

<!-- Location (required for BLE scan on Android < 12) -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>

<!-- Background / Foreground Service -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_CONNECTED_DEVICE"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS"/>

<!-- Emergency GPS -->
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>
```

---

## 21. Testing Checklist

### Phase 1 — 2 Devices
- [ ] Device A sends to Device B over BLE (no internet)
- [ ] Device B receives and decrypts correctly
- [ ] Delivery ticks update correctly

### Phase 2 — 3 Devices (Relay)
- [ ] Device A → Device B (relay) → Device C
- [ ] Device B never sees message content (encrypted)
- [ ] Same message not delivered twice (dedup working)

### Phase 3 — Flight Simulation
- [ ] Airplane mode on all 3 devices
- [ ] Confirm mesh still works
- [ ] Internet on one device → queued messages flush

### Phase 4 — Emergency Mode
- [ ] Trigger SOS on Device A
- [ ] GPS coords attached in packet
- [ ] Relay notification fires on Device B
- [ ] Red banner visible on all mesh peers

### Phase 5 — Edge Cases
- [ ] App closed on relay device → service still relays
- [ ] Battery saver enabled → service survives
- [ ] Expired packet → correctly discarded
- [ ] 1,000+ seen-cache entries → auto-purge fires
- [ ] Large message (>500 bytes) → chunking works

### Phase 6 — Social Features
- [ ] Post creation with all types
- [ ] Doubt submission and answer
- [ ] Trust score updates after helpful answer
- [ ] AR clip records and shares to feed
- [ ] Search returns correct results
- [ ] Flashcard SRS scheduling correct

---

## 22. Monetization

**Free tier:** Core features — social feed, doubts, study tools, basic mesh

**Optional premium (future ₹99/month):**
- Advanced AR experiences
- Offline module downloads (full physics/chem/bio labs)
- AI-powered doubt solver
- Priority talent marketplace listing

**Guiding principle:** mesh communication, emergency mode, and basic learning are always free. No one should pay to send an SOS.

---

## 23. Roadmap

### Phase 1 — MVP (current)
- [x] Flutter UI scaffolding
- [x] Supabase backend + auth
- [x] Social feed + doubts
- [x] Basic BLE mesh (bitchat-mesh)
- [x] 1,237 real users
- [ ] Chemistry virtual lab (complete)
- [ ] Emergency mode (complete)

### Phase 2 — Stabilization
- [ ] Full 3-device relay testing
- [ ] Physics + Biology modules complete
- [ ] WiFi mesh (Meshrabiya) integrated
- [ ] Background service stable across OEMs
- [ ] ZK identity MVP

### Phase 3 — Scale
- [ ] AR module (ARCore)
- [ ] RL routing algorithm
- [ ] Talent economy MVP
- [ ] iOS port
- [ ] DPDP Act compliance audit

### Phase 4 — Growth
- [ ] Offline content packs downloadable
- [ ] Regional language support
- [ ] School / coaching institute partnerships
- [ ] Premium tier launch

---

## 24. Team

| Name | Role |
|---|---|
| Soham Mhapankar | Lead — Architecture, Flutter, Mesh, Backend |
| Aditya Mhatre | Co-founder — Security, Identity, Backend |
| Deven Dhule | Co-founder — UI/UX, Science Modules |

**Submitted to:** India Innovates 2026 (iDEA 2.0) — Union Bank of India / IBA  
**Track:** Open Innovation / EdTech — PS9  
**Status:** Phase 1 passed → Phase 2 offline 24-hour round at KJ Somaiya

---

## 25. Deployment Notes

### Final File Structure

```
VERASSO/
├── lib/
│   ├── core/
│   │   ├── constants.dart
│   │   └── theme.dart
│   ├── features/
│   │   ├── feed/
│   │   ├── doubts/
│   │   ├── physics/
│   │   ├── chemistry/
│   │   ├── biology/
│   │   ├── ar/
│   │   ├── messaging/
│   │   ├── profile/
│   │   ├── search/
│   │   └── admin/
│   ├── mesh/
│   │   ├── mesh_router.dart          ← brain, ties everything
│   │   ├── network_monitor.dart      ← detects internet loss
│   │   ├── mesh_packet.dart          ← packet model
│   │   ├── message_queue.dart        ← store-and-forward
│   │   ├── emergency_location.dart   ← GPS for SOS
│   │   ├── background_mesh_service.dart
│   │   ├── permission_handler.dart
│   │   └── layers/
│   │       ├── ble_layer.dart        ← bitchat-mesh (PRIMARY)
│   │       ├── wifi_layer.dart       ← Meshrabiya (SECONDARY)
│   │       └── nearby_layer.dart     ← nearby_service (FALLBACK)
│   ├── identity/
│   │   ├── zk_identity.dart
│   │   └── crypto_service.dart
│   └── main.dart
├── pubspec.yaml
└── android/
    └── app/src/main/AndroidManifest.xml
```

### Key Numbers
- ~600 lines of new mesh code across 10 files
- 8 Flutter packages for mesh layer
- 14 Android permissions
- 3 radio layers
- 10 security vulnerabilities fixed
- 1,237 real users at launch

---

*VERASSO · Product Requirements Document · March 2026*  
*"Knowledge should be free. Identity should be private. Connectivity should be a right."*
