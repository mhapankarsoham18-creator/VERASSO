# VERASSO — Phase-wise Development Plan
### Full Tech Stack · Firebase Auth · Supabase Backend · bitchat BLE · Real-time Stargazing

---

## Tech Stack (Final)

| Layer | Technology | Why |
|---|---|---|
| **Framework** | Flutter (Dart) | Cross-platform, single codebase |
| **State Management** | Riverpod | Signal-driven, testable, no boilerplate |
| **Auth** | Firebase Auth | Best-in-class — email, Google OAuth, anonymous, FCM integration |
| **Push Notifications** | Firebase Cloud Messaging (FCM) | Free, reliable, deep Android/iOS integration |
| **Backend** | Supabase (PostgreSQL + Realtime + Storage) | Free tier generous, Postgres flexibility, row-level security |
| **Local Storage** | Hive (mesh queue) + SQLite (content) | Offline-first, fast, typed |
| **BLE Mesh (Primary)** | bitchat-mesh (MIT, no API key) | Replaces Bridgefy — zero cost, 7-hop relay, built-in E2E |
| **WiFi Mesh (Secondary)** | Meshrabiya | 300Mbps+, no Google Play Services |
| **P2P Fallback** | nearby_service | Third radio layer |
| **Network Detection** | connectivity_plus | Triggers mesh mode automatically |
| **Background Service** | flutter_background_service + flutter_foreground_task | Mesh alive when app closed |
| **Astronomy — Star Data** | HYG Database (100k+ stars, offline) + NASA Horizons API (planets, real-time) | Free, accurate, works offline |
| **Astronomy — ISS** | Open Notify API (`api.open-notify.org`) | Free, real-time ISS position |
| **Astronomy — AR Overlay** | ARCore + Flutter camera + CustomPainter | Point phone at sky → see stars |
| **Astronomy — Sensors** | `sensors_plus` (gyroscope + accelerometer + magnetometer) | Phone orientation → sky map sync |
| **Cryptography** | Ed25519, X25519, AES-256-GCM | ZK identity + mesh encryption |
| **RL Routing** | Multi-Armed Bandit (Thompson Sampling + UCB) | Smart mesh path selection |
| **Emergency GPS** | geolocator | SOS packets |
| **Monitoring** | Sentry | Crash tracking from Phase 1 |
| **AR (Science modules)** | ARCore | Physics/Chemistry/Biology AR |

### Firebase vs Supabase Split

```
Firebase handles:
  ├── Authentication (email, Google OAuth, anonymous)
  ├── FCM push notifications (doubt answers, mesh alerts, events)
  └── Firebase App Check (abuse prevention)

Supabase handles:
  ├── PostgreSQL — all data (posts, doubts, users, groups)
  ├── Realtime subscriptions (live feed, chat, doubt threads)
  ├── Storage — images, PDFs, AR clips, audio notes
  └── Row-level security (RLS) per role
```

---

## Phase Overview

| Phase | Name | Duration | Output |
|---|---|---|---|
| **0** | Foundation & Setup | 3 days | Project skeleton, CI, both backends wired |
| **1** | Auth, Profiles & Core UI | 1 week | Login, profile, nav shell |
| **2** | Social Feed & Doubts | 2 weeks | Posts, Q&A, trust system |
| **3** | BLE Mesh Layer | 2 weeks | Offline messaging working on 3 devices |
| **4** | Science Modules | 3 weeks | Physics, Chemistry, Biology |
| **5** | Astronomy & Stargazing | 2 weeks | Real-time sky map + AR + ISS tracker |
| **6** | AR Experiences | 1 week | Place 3D models in real world |
| **7** | Study Tools | 1 week | Flashcards, timetable, library |
| **8** | Talent Economy & ZK Identity | 2 weeks | Decentralized jobs, ZK proofs |
| **9** | Notifications & Recommendations | 1 week | FCM, RL feed ranking |
| **10** | Polish, Performance & Launch | 1 week | Sentry, optimization, release |

**Total estimated: ~16 weeks for full feature set**

---

## Phase 0 — Foundation & Setup (3 days)

### Goals
Establish the full project skeleton so every subsequent phase builds cleanly on top.

### 0.1 — Project Init

```bash
flutter create verasso --org com.verasso
cd verasso
flutter pub add \
  firebase_core firebase_auth firebase_messaging \
  supabase_flutter \
  flutter_riverpod riverpod_annotation \
  hive_flutter \
  connectivity_plus \
  flutter_background_service flutter_foreground_task \
  sentry_flutter \
  geolocator \
  sensors_plus \
  permission_handler \
  go_router
```

### 0.2 — Firebase Setup

```
1. Create project at console.firebase.google.com
2. Add Android app (package: com.verasso.app)
3. Download google-services.json → android/app/
4. Enable: Email/Password auth, Google Sign-In, Anonymous auth
5. Enable FCM
6. Set up Firebase App Check
```

### 0.3 — Supabase Setup

```sql
-- Core tables (run in Supabase SQL editor)

create table profiles (
  id uuid references auth.users primary key,
  firebase_uid text unique not null,
  username text unique,
  display_name text,
  avatar_url text,
  bio text,
  institute text,
  role text default 'student',
  subjects text[],
  trust_score float default 0,
  zk_verified boolean default false,
  mesh_relay_mode text default 'full',
  created_at timestamptz default now()
);

create table posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid references profiles(id),
  type text, -- text|image|video|pdf|poll|doubt|ar_clip
  content text,
  subject text,
  chapter text,
  exam_tags text[],
  likes int default 0,
  created_at timestamptz default now()
);

create table doubts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid references profiles(id),
  title text,
  body text,
  subject text,
  tags text[],
  solved boolean default false,
  created_at timestamptz default now()
);

-- Enable RLS on all tables
alter table profiles enable row level security;
alter table posts enable row level security;
alter table doubts enable row level security;
```

### 0.4 — Project Structure

```
lib/
├── core/
│   ├── constants.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── colors.dart
│   │   └── typography.dart
│   ├── router/
│   │   └── app_router.dart
│   └── services/
│       ├── firebase_service.dart
│       ├── supabase_service.dart
│       └── notification_service.dart
├── features/
│   ├── auth/
│   ├── feed/
│   ├── doubts/
│   ├── messaging/
│   ├── mesh/
│   ├── astronomy/       ← NEW in Phase 5
│   ├── physics/
│   ├── chemistry/
│   ├── biology/
│   ├── ar/
│   ├── study/
│   ├── profile/
│   ├── search/
│   └── admin/
└── main.dart
```

### 0.5 — Sentry Init (do this on Day 1, not Day 90)

```dart
await SentryFlutter.init(
  (options) {
    options.dsn = 'YOUR_SENTRY_DSN';
    options.tracesSampleRate = 0.2;
  },
  appRunner: () => runApp(const VerassoApp()),
);
```

### Deliverables
- [ ] Flutter project running on device
- [ ] Firebase Auth working (email sign-in)
- [ ] Supabase connected (test query succeeds)
- [ ] Sentry capturing test error
- [ ] go_router navigation shell
- [ ] All permissions declared in AndroidManifest.xml

---

## Phase 1 — Auth, Profiles & Core UI (1 week)

### Goals
Users can sign up, log in, set up their profile, and see the app shell.

### 1.1 — Firebase Auth Flows

```dart
// lib/features/auth/auth_service.dart

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Email sign up
  Future<UserCredential> signUp(String email, String password) =>
    _auth.createUserWithEmailAndPassword(email: email, password: password);

  // Google sign in
  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    final credential = GoogleAuthProvider.credential(
      accessToken: (await googleUser!.authentication).accessToken,
      idToken: (await googleUser.authentication).idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  // On auth → sync to Supabase profiles table
  Future<void> syncProfile(User firebaseUser) async {
    await supabase.from('profiles').upsert({
      'firebase_uid': firebaseUser.uid,
      'display_name': firebaseUser.displayName,
      'avatar_url': firebaseUser.photoURL,
    });
  }
}
```

### 1.2 — FCM Setup

```dart
// Request notification permission
await FirebaseMessaging.instance.requestPermission();

// Save FCM token to Supabase for targeting
final token = await FirebaseMessaging.instance.getToken();
await supabase.from('profiles').update({'fcm_token': token})
  .eq('firebase_uid', currentUser.uid);

// Handle foreground messages
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  // Show in-app notification banner
});
```

### 1.3 — Profile Setup Screen
- Display name, username, avatar (upload to Supabase Storage)
- Institute + role selection
- Subjects / interests multi-select
- Mesh relay mode preference

### 1.4 — App Shell & Navigation

```
Bottom nav: Feed | Science | Astronomy | Messages | Profile
```

Tabs:
- Feed (social)
- Science (Physics/Chemistry/Biology hub)
- Astronomy (new in Phase 5)
- Messages (chat + mesh status)
- Profile

### Deliverables
- [ ] Email + Google sign-in/sign-up working
- [ ] Profile created in Supabase on first login
- [ ] FCM token saved
- [ ] Bottom nav shell rendering
- [ ] Profile screen reading from Supabase

---

## Phase 2 — Social Feed & Doubts (2 weeks)

### Goals
Full social layer — post creation, feed, doubts, trust system.

### Week 1 — Feed

**Supabase Realtime subscription for live feed:**
```dart
supabase.from('posts')
  .stream(primaryKey: ['id'])
  .order('created_at', ascending: false)
  .listen((data) => ref.read(feedProvider.notifier).update(data));
```

**Post types supported:**
- Text (with LaTeX math rendering — `flutter_math_fork`)
- Image (Supabase Storage upload)
- PDF/Notes (Supabase Storage)
- Short video
- Poll
- Question (auto-routes to Doubts)
- AR clip (from Phase 6)

**Interactions:**
- Like (optimistic update, Supabase write)
- Comment (threaded, Supabase Realtime)
- Save to collection
- Share / repost
- Hashtags + topic tags → topic pages

**FCM notification on:**
- Someone likes your post (batched, not per-like)
- Someone answers your doubt
- You're mentioned in a post/comment

### Week 2 — Doubts & Trust

**Doubts flow:**
1. Post doubt with subject + tags + optional image
2. Supabase insert → FCM push to subject mentors
3. Answers with step-by-step + images
4. Author marks "Solved" → pins best answer
5. Trust score update via Supabase function

```sql
-- Supabase function: update trust score on solved answer
create or replace function update_trust_on_solve(answer_author_id uuid)
returns void as $$
  update profiles
  set trust_score = trust_score + 10
  where id = answer_author_id;
$$ language sql;
```

**Trust levels:**
```
0–50:   Normal User
51–200: Trusted Contributor  → can flag posts
201–500: Subject Mentor      → can curate topics, pin posts
500+:   Moderator            → full flag handling
```

**Badge triggers (Supabase edge functions):**
- "Top in Physics Doubts" → 5+ solved physics answers
- "Mesh Relay Hero" → relay active for 10+ hours
- "AR Explorer" → 10+ AR clips shared

### Deliverables
- [ ] Post creation (all types)
- [ ] Live feed via Supabase Realtime
- [ ] Doubt submission + threaded answers
- [ ] Solved marking + trust score update
- [ ] FCM notifications for doubt answers
- [ ] Badge award system

---

## Phase 3 — BLE Mesh Layer (2 weeks)

### Goals
Fully working offline messaging. Three radio layers. Emergency mode. Background service.

### Package Setup

```yaml
# pubspec.yaml additions
dependencies:
  # bitchat-mesh integrated as local module (AAR or source)
  # Meshrabiya via maven
  nearby_service: latest
  connectivity_plus: latest
  flutter_background_service: latest
  flutter_foreground_task: latest
  hive_flutter: latest
  geolocator: latest
```

```groovy
// android/app/build.gradle
repositories {
  maven { url "https://devserver3.ustadmobile.com/maven2/" }
}
dependencies {
  implementation 'com.ustadmobile.meshrabiya:lib-meshrabiya:0.1d11'
}
```

### Week 1 — Core Mesh

**NetworkMonitor** — detects internet loss → triggers MESH_ROAMING

**bitchat-mesh BLE Layer** (PRIMARY):
```dart
// lib/mesh/layers/ble_layer.dart
// Wraps bitchat-mesh library
// Handles: peer discovery, multi-hop relay (7 hops), store-and-forward
// Encryption: X25519 + AES-256-GCM (built-in)
// No API key. No internet on first launch.
```

**Meshrabiya WiFi Layer** (SECONDARY):
```dart
final myNode = AndroidVirtualNode(
  appContext: applicationContext,
  dataStore: applicationContext.dataStore,
);
myNode.setWifiHotspotEnabled(enabled: true, preferredBand: ConnectBand.BAND_5GHZ);
```

**MeshPacket:**
```dart
class MeshPacket {
  final String messageId;        // UUID dedup key
  final String receiverId;
  final Uint8List encryptedData; // E2E encrypted — relay sees nothing
  final int createdAt;
  final int expiresAt;           // 24h normal, 7 days emergency
  final bool isEmergency;
  final double? latitude;        // only set in emergency mode
  final double? longitude;
  int hopCount;
}
```

**MessageQueue (Hive):**
- Written BEFORE sending (atomic safety)
- Emergency packets sorted first
- Auto-purge expired at app dispose
- Seen-cache auto-clears at 1,000 entries

### Week 2 — Background Service + UI

**Background Service:**
```dart
// Keeps mesh alive when app closed
// Battery optimization exempt
// Foreground notification: "Verasso Mesh · Relaying for N users"
```

**FCM integration with mesh:**
- When internet restores → flush Hive queue to Supabase
- FCM notification: "3 messages delivered from mesh"

**Status Banners:**
```
CONNECTED:    [hidden]
MESH_ROAMING: 📡 Mesh Roaming Active · 4 nearby users relaying
EMERGENCY:    🆘 Emergency Mesh Active · GPS attached · Max power
```

**Delivery Ticks:**
`✓` Sent → `✓✓` Relayed → `✓✓✓` Reached internet → `✓✓✓✓` Delivered

**Emergency SOS:**
- Attach GPS (10s timeout)
- Switch to longReach BLE profile
- 7-day TTL packet
- Relay users notified

**Security fixes all applied (10 vulnerabilities — see PRD)**

### Testing Checklist
- [ ] 2 devices: A sends to B over BLE (airplane mode)
- [ ] 3 devices: A → B (relay) → C
- [x] Integrate Neumorphic & Pixel UI layout system.
- [x] Configure Firebase settings and test Email/Password workflow flawlessly natively.
- [x] Scaffold Role select and Dynamic base logic (Student, Mentor, Explorer & first badges).e still relays
- [ ] Seen-cache dedup prevents double delivery

---

## Phase 4 — Science Modules (3 weeks)

### Goals
Physics, Chemistry, Biology interactive learning modules.

### Week 1 — Physics

**Home screen tiles:** Mechanics · Waves · Optics · EM · Modern Physics

**Simulations (Flutter CustomPainter + animation):**

```dart
// Example: Projectile motion simulation
class ProjectileSimulation extends StatefulWidget {
  // Sliders: launch angle, initial velocity, mass
  // Real-time graph: height vs time, range vs angle
  // Canvas: trajectory arc rendered per frame
}
```

Simulations needed:
- Projectile motion (angle, velocity sliders)
- Simple harmonic motion (amplitude, frequency)
- Lens ray diagram (focal length, object distance)
- Ohm's Law circuit (voltage, resistance → current)
- Photoelectric effect (frequency → energy)

**Concept + Practice flow:**
1. Visual explanation (animated)
2. Simulation with sliders
3. MCQs / numericals linked to simulation

**FCM:** "New Physics simulation unlocked: Diffraction"

### Week 2 — Chemistry

**Dashboard:** progress by chapter, quick actions

**Virtual Experiments (Flutter Canvas):**
- Titration (drop acid → indicator changes colour)
- Gas laws (PV = nRT — adjust P, V, T → see live changes)
- Redox reactions (half-equations + electron flow animation)
- pH scale (add substance → colour indicator changes)
- Equilibrium (Le Chatelier's principle — adjust concentration)
- Organic: esterification, saponification

**Each experiment:**
- Balanced equation shown live
- Particle-level animation
- Safety notes
- Lab notebook (Supabase + local SQLite)

### Week 3 — Biology

**Hub topics:** Cells · Anatomy · Plant Physiology · Genetics · Microbiology

**Interactive diagrams:**
- Human heart → tap chambers → animation (blood flow)
- DNA double helix → zoom → base pairs labelled
- Mitosis stages → drag-and-drop ordering
- Photosynthesis → animated chloroplast with inputs/outputs

**Concept checks:**
- Labelling tasks
- Drag-and-drop process stages
- Case-based MCQs

### Shared science infrastructure:
```dart
// lib/features/science/simulation_engine.dart
// Handles: slider values → physics computation → canvas repaint
// All simulations extend SimulationBase
// Results saved to SQLite for progress tracking
```

---

## Phase 5 — Astronomy & Stargazing (2 weeks) ⭐ NEW

### Goals
Real-time interactive star map. Point phone at sky → see stars, constellations, planets. ISS tracker. AR overlay. Works offline with local star catalog.

### Data Sources

| Source | What it provides | Cost | Offline? |
|---|---|---|---|
| **HYG Database** | 100,000+ stars (magnitude, RA, Dec, name) | Free, open | ✅ Yes (bundle in app) |
| **NASA JPL Horizons API** | Planet positions in real-time (Mars, Jupiter, Saturn etc.) | Free | ❌ Needs internet |
| **Open Notify API** | ISS real-time position + pass predictions | Free | ❌ Needs internet |
| **NASA APOD API** | Astronomy Picture of the Day + description | Free (key required) | ❌ Needs internet |
| **Device sensors** | Gyroscope + magnetometer → phone orientation | Built-in | ✅ Yes |

### Flutter Packages for Astronomy

```yaml
dependencies:
  sensors_plus: latest          # gyroscope, accelerometer, magnetometer
  camera: latest                # camera feed for AR overlay
  geolocator: latest            # user GPS for horizon calculations
  http: latest                  # NASA/Open Notify API calls
  sqflite: latest               # local HYG star database
```

### 5.1 — HYG Star Database (Offline)

Bundle the HYG catalog as a SQLite file in assets:

```sql
-- hyg_stars.db (bundled in assets/)
CREATE TABLE stars (
  id INTEGER PRIMARY KEY,
  hip INTEGER,         -- Hipparcos catalog number
  proper_name TEXT,    -- e.g., "Sirius", "Betelgeuse"
  ra REAL,             -- Right Ascension (hours)
  dec REAL,            -- Declination (degrees)
  magnitude REAL,      -- Apparent magnitude (lower = brighter)
  distance REAL,       -- Parsecs
  spectral_type TEXT,  -- e.g., "G2V" (star colour)
  constellation TEXT
);

-- 88 constellations boundary + line data
CREATE TABLE constellation_lines (
  constellation TEXT,
  star_a_hip INTEGER,
  star_b_hip INTEGER
);
```

```dart
// lib/features/astronomy/star_catalog.dart
class StarCatalog {
  static Database? _db;

  static Future<void> init() async {
    final path = await getDatabasesPath();
    await copyIfNeeded('assets/hyg_stars.db', path);
    _db = await openDatabase('$path/hyg_stars.db');
  }

  // Get stars visible from location at current time
  static Future<List<Star>> getVisibleStars({
    required double latitude,
    required double longitude,
    required DateTime utcTime,
    double magnitudeLimit = 5.5, // naked-eye limit
  }) async {
    // Convert RA/Dec → Altitude/Azimuth using LMST calculation
    final lmst = _calculateLMST(longitude, utcTime);
    return await _db!.query('stars',
      where: 'magnitude < ?',
      whereArgs: [magnitudeLimit],
    ).then((rows) => rows
      .map((r) => Star.fromRow(r))
      .map((s) => s.withAltAz(latitude, lmst))
      .where((s) => s.altitude > 0) // above horizon
      .toList());
  }
}
```

### 5.2 — Celestial Coordinate Math

```dart
// lib/features/astronomy/celestial_math.dart

class CelestialMath {
  // Local Mean Sidereal Time
  static double calculateLMST(double longitude, DateTime utc) {
    final jd = _julianDate(utc);
    final t = (jd - 2451545.0) / 36525.0;
    final gmst = 280.46061837 + 360.98564736629 * (jd - 2451545.0)
               + 0.000387933 * t * t - t * t * t / 38710000.0;
    return (gmst + longitude) % 360.0;
  }

  // RA/Dec → Altitude/Azimuth (for given lat and LMST)
  static ({double altitude, double azimuth}) raDecToAltAz({
    required double ra,     // hours
    required double dec,    // degrees
    required double lat,    // observer latitude
    required double lmst,   // degrees
  }) {
    final ha = (lmst - ra * 15.0) * pi / 180.0; // hour angle in radians
    final decRad = dec * pi / 180.0;
    final latRad = lat * pi / 180.0;

    final sinAlt = sin(decRad) * sin(latRad) + cos(decRad) * cos(latRad) * cos(ha);
    final altitude = asin(sinAlt) * 180.0 / pi;

    final cosAz = (sin(decRad) - sinAlt * sin(latRad)) / (cos(asin(sinAlt)) * cos(latRad));
    var azimuth = acos(cosAz.clamp(-1.0, 1.0)) * 180.0 / pi;
    if (sin(ha) > 0) azimuth = 360.0 - azimuth;

    return (altitude: altitude, azimuth: azimuth);
  }

  // Phone orientation (azimuth + tilt) → sky viewport
  static Rect skyViewport({
    required double phoneAzimuth,   // from magnetometer
    required double phoneTilt,      // from accelerometer
    required double fovH,           // horizontal FOV in degrees
    required double fovV,           // vertical FOV
  }) {
    return Rect.fromCenter(
      center: Offset(phoneAzimuth, 90.0 - phoneTilt),
      width: fovH,
      height: fovV,
    );
  }
}
```

### 5.3 — Star Map Screen (Sky Canvas)

```dart
// lib/features/astronomy/star_map_screen.dart

class StarMapScreen extends ConsumerStatefulWidget {
  // Modes: Map (manual pan/zoom) | Live (gyroscope-locked to sky)
}

class _StarMapScreenState extends ConsumerState<StarMapScreen> {
  List<Star> _visibleStars = [];
  List<Planet> _planets = [];
  SkyOrientation _orientation = SkyOrientation.zero;

  @override
  void initState() {
    super.initState();
    _loadStars();
    _subscribeToSensors();
    _fetchPlanetPositions();
    _fetchISSPosition();
  }

  void _subscribeToSensors() {
    // Gyroscope + magnetometer → smooth sky orientation
    SensorsPlatform.instance.magnetometerEvents.listen((event) {
      setState(() => _orientation = _orientation.updateMagnetometer(event));
    });
    SensorsPlatform.instance.accelerometerEvents.listen((event) {
      setState(() => _orientation = _orientation.updateAccelerometer(event));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      // Base star canvas
      CustomPaint(
        painter: StarMapPainter(
          stars: _visibleStars,
          planets: _planets,
          orientation: _orientation,
          constellationLines: _constellationLines,
          showGrid: _showGrid,
          nightMode: _nightMode,
        ),
        size: Size.infinite,
      ),
      // AR camera overlay (when in AR mode)
      if (_arMode) CameraPreview(_cameraController),
      // Info panel (tap a star → show details)
      if (_selectedObject != null) CelestialObjectPanel(object: _selectedObject!),
      // Controls overlay
      StarMapControls(
        onToggleAR: _toggleAR,
        onToggleNightMode: _toggleNightMode,
        onToggleConstellations: _toggleConstellations,
        onTimeMachineOpen: _openTimeMachine,
      ),
    ]);
  }
}
```

### 5.4 — StarMapPainter (CustomPainter)

```dart
class StarMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Fill background (deep space gradient or camera feed)
    _paintBackground(canvas, size);

    // 2. Milky Way band (precomputed polygon, painted first)
    _paintMilkyWay(canvas, size);

    // 3. Constellation lines (dim, behind stars)
    for (final line in constellationLines) {
      _paintConstellationLine(canvas, size, line);
    }

    // 4. Stars (size = magnitude, colour = spectral type)
    for (final star in stars) {
      _paintStar(canvas, size, star);
    }

    // 5. Planets (larger, labelled)
    for (final planet in planets) {
      _paintPlanet(canvas, size, planet);
    }

    // 6. ISS (animated orbit dot)
    if (iss != null) _paintISS(canvas, size, iss!);

    // 7. Horizon line + compass bearing
    _paintHorizon(canvas, size);

    // 8. Selected object highlight ring
    if (selectedObject != null) _paintSelectionRing(canvas, size, selectedObject!);
  }

  // Map alt/az → screen x/y given current orientation
  Offset _celestialToScreen(double altitude, double azimuth, Size size) {
    final dAz = (azimuth - orientation.azimuth + 360) % 360;
    final dAlt = altitude - (90.0 - orientation.tilt);
    final x = size.width / 2 + dAz * pixelsPerDegree;
    final y = size.height / 2 - dAlt * pixelsPerDegree;
    return Offset(x, y);
  }

  // Star colour from spectral type: O=blue, G=yellow, M=red
  Color _spectralColor(String type) {
    return switch (type[0]) {
      'O' => const Color(0xFF9BB0FF),
      'B' => const Color(0xFFAABFFF),
      'A' => const Color(0xFFCAD7FF),
      'F' => const Color(0xFFF8F7FF),
      'G' => const Color(0xFFFFF4EA),
      'K' => const Color(0xFFFFD2A1),
      'M' => const Color(0xFFFFCC6F),
      _   => Colors.white,
    };
  }
}
```

### 5.5 — Planet Positions (NASA JPL Horizons)

```dart
// lib/features/astronomy/planet_service.dart

class PlanetService {
  static const _horizonsBase = 'https://ssd.jpl.nasa.gov/api/horizons.api';

  static final planets = {
    'Mercury': '199', 'Venus': '299', 'Mars': '499',
    'Jupiter': '599', 'Saturn': '699', 'Uranus': '799', 'Neptune': '899',
  };

  static Future<List<Planet>> fetchPlanetPositions({
    required double lat, required double lon,
  }) async {
    final results = <Planet>[];
    final now = DateTime.now().toUtc();

    for (final entry in planets.entries) {
      final response = await http.get(Uri.parse(
        '$_horizonsBase?format=json'
        '&COMMAND=${entry.value}'
        '&EPHEM_TYPE=OBSERVER'
        '&CENTER=coord@399'
        "&SITE_COORD='${lon.toStringAsFixed(4)},${lat.toStringAsFixed(4)},0'"
        '&START_TIME=${_fmt(now)}'
        '&STOP_TIME=${_fmt(now.add(const Duration(minutes: 1)))}'
        '&STEP_SIZE=1m'
        "&QUANTITIES='4,20'"  // Azimuth/Elevation
      ));

      if (response.statusCode == 200) {
        results.add(Planet.parseHorizons(entry.key, response.body));
      }
    }
    return results;
  }

  // Cache planet positions for 10 minutes (they barely move)
  static final _cache = <String, (DateTime, List<Planet>)>{};
}
```

### 5.6 — ISS Real-Time Tracker

```dart
// lib/features/astronomy/iss_service.dart

class ISSService {
  static const _url = 'http://api.open-notify.org/iss-now.json';
  static const _passUrl = 'http://api.open-notify.org/iss-pass.json';

  // Current position (update every 5 seconds — ISS moves fast)
  static Future<ISSPosition> getCurrentPosition() async {
    final response = await http.get(Uri.parse(_url));
    final data = jsonDecode(response.body);
    return ISSPosition(
      latitude: double.parse(data['iss_position']['latitude']),
      longitude: double.parse(data['iss_position']['longitude']),
      timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp'] * 1000),
    );
  }

  // Pass predictions for user's location
  static Future<List<ISSPass>> getUpcomingPasses({
    required double lat, required double lon,
  }) async {
    final response = await http.get(
      Uri.parse('$_passUrl?lat=$lat&lon=$lon&n=5')
    );
    final data = jsonDecode(response.body);
    return (data['response'] as List)
      .map((p) => ISSPass.fromJson(p))
      .toList();
  }
}
```

**FCM notification for ISS pass:**
```dart
// Supabase edge function scheduled every hour
// Check if ISS will pass over user's location in next 24h
// If yes → FCM notification with time + direction
// "🛸 ISS passes over your location tonight at 9:14 PM — look NW!"
```

### 5.7 — Night Mode & Time Machine

**Night Mode:**
- All UI goes red-tinted (preserves dark adaptation)
- Stars appear brighter (higher contrast canvas)
- Toggle with single button

**Time Machine:**
- Date/time picker → recalculate all star positions
- See what the sky looked like on your birthday
- Watch Jupiter's moons move over a week (animation)
- Historical events: "Sky on Indian Independence Day 1947"

### 5.8 — Astronomy Features List

| Feature | Data Source | Online Required? |
|---|---|---|
| Star map (100k stars) | HYG Database (local SQLite) | ❌ No |
| Constellation lines + names | HYG + local data | ❌ No |
| Live sky orientation | Gyroscope + magnetometer | ❌ No |
| AR camera overlay | Device camera | ❌ No |
| Planet positions | NASA JPL Horizons API | ✅ Yes |
| ISS real-time position | Open Notify API | ✅ Yes |
| ISS pass predictions | Open Notify API | ✅ Yes |
| ISS pass FCM alert | Firebase FCM | ✅ Yes |
| Astronomy Picture of the Day | NASA APOD API | ✅ Yes |
| Time Machine | Calculated locally | ❌ No |
| Tap star → info card | Local data + Wikipedia | ⚠️ Local + optional |
| Celestial events calendar | Local calculations | ❌ No |
| Night mode | UI-only | ❌ No |
| Stargazing index (cloud cover) | OpenWeatherMap API | ✅ Yes |

### 5.9 — Astronomy Section Layout

```
Astronomy tab
├── 🌌 Sky Map (main screen — full screen canvas)
│   ├── Live mode (gyroscope-locked)
│   ├── Manual mode (pan/zoom)
│   ├── AR mode (camera feed + star overlay)
│   └── Night mode toggle
├── 🪐 Solar System
│   ├── Planet positions tonight
│   ├── Orbital paths (2D animated view)
│   └── Planet info cards (NASA data)
├── 🛸 ISS Tracker
│   ├── Live position on world map
│   ├── Upcoming passes for your location
│   └── "Notify me before next pass" (FCM)
├── 📸 APOD (NASA Picture of the Day)
├── 📅 Events Calendar
│   ├── Meteor showers, eclipses, conjunctions
│   ├── Moon phases
│   └── Set reminders (FCM)
└── 📚 Learn Astronomy
    ├── Constellation stories (mythology + science)
    ├── How to read a star map
    └── Astrophotography basics
```

### Deliverables
- [ ] HYG database loaded and queried
- [ ] Star map renders 1,000+ stars on canvas
- [ ] Gyroscope + magnetometer → smooth sky rotation
- [ ] Constellation lines drawn correctly
- [ ] Planet positions from JPL Horizons
- [ ] ISS live position updating every 5s
- [ ] ISS pass FCM notification working
- [ ] AR camera overlay with star overlay
- [ ] Night mode (red tint)
- [ ] Time Machine (date picker → recalculate sky)
- [ ] Tap star → info panel with name, magnitude, distance
- [ ] Stargazing quality index (weather API)

---

## Phase 6 — AR Experiences (1 week)

### Goals
Place 3D science models in real world via ARCore.

**AR features (science):**
- Solar system walk (planets to scale in your room)
- Human heart (beating, labelled chambers)
- DNA double helix (rotates, base pairs tappable)
- Electric circuit (current flow animated)
- Molecular models (3D: H₂O, CH₄, NaCl)

**AR astronomy:**
- Already handled in Phase 5 (star overlay on camera)
- Additional: place planet at actual scale in sky direction

**Recording:**
- AR clips saved locally
- Upload to Supabase Storage
- Share to feed as `ar_clip` post type

**Stack:**
- `arcore_flutter_plugin` for 3D model placement
- glTF model files bundled in assets

---

## Phase 7 — Study Tools (1 week)

### Goals
Personal library, flashcards (SRS), timetable, streak tracking.

**Personal Library:**
- Saved posts, notes, PDFs → Supabase + local SQLite
- Folders by subject and exam

**Flashcards (Spaced Repetition):**
```dart
// SM-2 algorithm implementation
class SpacedRepetition {
  static FlashcardSchedule calculateNext({
    required int quality,    // 0–5 (how well recalled)
    required int repetition, // times reviewed
    required double easiness, // ease factor
    required int interval,   // days until next review
  }) { /* SM-2 formula */ }
}
```

**Timetable:**
- Study slots per subject
- Chapter goals + deadlines
- Reminders via FCM (`scheduled_notification` at slot time)
- Streak tracking (Supabase + local)

---

## Phase 8 — Talent Economy & ZK Identity (2 weeks)

### Goals
Decentralized job marketplace + zero-knowledge credential verification.

### ZK Identity

```dart
// lib/features/identity/zk_identity.dart

class ZKIdentity {
  // Generate Ed25519 keypair (stored locally, never uploaded)
  static Future<KeyPair> generateKeypair() async { ... }

  // Create ZK proof of attribute (e.g., "I am a BTech student")
  // Without revealing which college, marks, or roll number
  static Future<ZKProof> proveAttribute({
    required String attribute,
    required String credential,  // locally verified document hash
  }) async { ... }
}
```

**Talent Marketplace:**
- Skill-based profiles with ZK-verified credentials
- Job/project listings stored in Supabase
- Direct peer matching — no recruiter layer
- Offline job sync → mesh delivery when internet restores

---

## Phase 9 — Notifications & Recommendations (1 week)

### FCM Notification Types

| Trigger | Channel | Priority |
|---|---|---|
| Doubt answered | `doubts` | High |
| Best answer marked on your doubt | `doubts` | High |
| ISS passing your location | `astronomy` | Normal |
| Astronomy event reminder | `astronomy` | Normal |
| Mesh message delivered | `mesh` | Normal |
| New follower | `social` | Low (batched) |
| Study slot reminder | `study` | High |
| Mesh SOS relay received | `emergency` | Critical |

### RL Feed Ranking (Multi-Armed Bandit)

```dart
// lib/features/feed/feed_ranker.dart
// Thompson Sampling across content arms:
// Arms: [posts from followed users, doubts in your subjects,
//        science simulations, astronomy updates, trending topics]
// Reward: engagement (like, save, comment, time-spent)
// Updates weights per session, stored in Supabase
```

---

## Phase 10 — Polish, Performance & Launch (1 week)

### Performance
- Image lazy loading + Supabase CDN
- Star map: render only stars in current viewport (culling)
- Hive compact() call weekly
- Flutter DevTools profiling — target 60fps everywhere
- Heavy screens (star map, AR): `RepaintBoundary`

### Launch Checklist
- [ ] Sentry error rate < 0.1%
- [ ] 3-device mesh relay test passes (all edge cases)
- [ ] FCM delivery confirmed (all notification types)
- [ ] Supabase RLS policies audited
- [ ] DPDP Act 2023 compliance check
- [ ] App Store / Play Store listing
- [ ] Privacy policy + terms of service
- [ ] Crash-free rate > 99%

---

## Full File Structure

```
verasso/
├── android/
│   └── app/
│       ├── google-services.json
│       └── src/main/AndroidManifest.xml  ← 14 permissions
├── assets/
│   ├── hyg_stars.db           ← 100k star catalog (offline)
│   ├── constellation_data.json
│   └── models/                ← glTF 3D models for AR
├── lib/
│   ├── core/
│   │   ├── constants.dart
│   │   ├── router/app_router.dart
│   │   ├── theme/
│   │   └── services/
│   │       ├── firebase_service.dart
│   │       ├── supabase_service.dart
│   │       └── notification_service.dart
│   ├── features/
│   │   ├── auth/
│   │   ├── feed/
│   │   ├── doubts/
│   │   ├── profile/
│   │   ├── search/
│   │   ├── messaging/
│   │   ├── mesh/
│   │   │   ├── mesh_router.dart
│   │   │   ├── network_monitor.dart
│   │   │   ├── mesh_packet.dart
│   │   │   ├── message_queue.dart
│   │   │   ├── emergency_location.dart
│   │   │   ├── background_mesh_service.dart
│   │   │   ├── permission_handler.dart
│   │   │   └── layers/
│   │   │       ├── ble_layer.dart       ← bitchat-mesh
│   │   │       ├── wifi_layer.dart      ← Meshrabiya
│   │   │       └── nearby_layer.dart
│   │   ├── astronomy/           ← Phase 5
│   │   │   ├── star_map_screen.dart
│   │   │   ├── star_map_painter.dart
│   │   │   ├── star_catalog.dart
│   │   │   ├── celestial_math.dart
│   │   │   ├── planet_service.dart
│   │   │   ├── iss_service.dart
│   │   │   ├── apod_service.dart
│   │   │   ├── night_mode.dart
│   │   │   └── time_machine.dart
│   │   ├── physics/
│   │   ├── chemistry/
│   │   ├── biology/
│   │   ├── ar/
│   │   ├── study/
│   │   └── identity/
│   └── main.dart
└── pubspec.yaml
```

---

## Dependency Map (pubspec.yaml final)

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Auth + Notifications
  firebase_core: latest
  firebase_auth: latest
  firebase_messaging: latest
  google_sign_in: latest

  # Backend
  supabase_flutter: latest

  # State
  flutter_riverpod: latest
  riverpod_annotation: latest

  # Storage
  hive_flutter: latest
  sqflite: latest
  path_provider: latest

  # Mesh
  connectivity_plus: latest
  flutter_background_service: latest
  flutter_foreground_task: latest
  nearby_service: latest
  geolocator: latest

  # Astronomy
  sensors_plus: latest          # gyroscope, magnetometer
  camera: latest                # AR overlay
  http: latest                  # NASA/Open Notify APIs
  vector_math: latest           # 3D coordinate math

  # Science/AR
  arcore_flutter_plugin: latest

  # UI
  go_router: latest
  flutter_math_fork: latest     # LaTeX rendering
  cached_network_image: latest

  # Monitoring
  sentry_flutter: latest

  # Permissions
  permission_handler: latest
```

---

## Key Milestones Summary

| Week | Milestone |
|---|---|
| 1 | Firebase Auth + Supabase connected |
| 2 | Social feed live, posts working |
| 3 | Doubts + trust system working |
| 4 | BLE mesh — 2 phones talking |
| 5 | 3-phone relay + emergency mode |
| 6–7 | Physics + Chemistry modules |
| 8 | Biology module |
| 9 | ⭐ Star map + gyroscope sync |
| 10 | ⭐ ISS tracker + planet positions |
| 11 | AR experiences |
| 12 | Study tools |
| 13 | ZK identity + talent economy |
| 14 | FCM + RL recommendations |
| 15 | Performance pass |
| 16 | Launch |

---

*VERASSO · Phase-wise Development Plan · March 2026*  
*"Knowledge should be free. Identity should be private. Connectivity should be a right."*
