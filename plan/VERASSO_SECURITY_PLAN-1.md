# VERASSO — Security Plan
### Full Stack | Firebase + Supabase + BLE Mesh | March 2026

---

## Threat Model

Who might attack Verasso and why:

| Threat Actor | Motivation | Target |
|---|---|---|
| Random attacker | Data theft | User PII, messages |
| Mesh eavesdropper | Intercept communications | BLE packets in transit |
| Malicious relay node | Inject fake messages | Mesh routing |
| Spam bots | Pollute feed | Post creation API |
| Scraper | Harvest student data | User profiles, posts |
| Insider (compromised account) | Elevate privileges | Admin/moderator actions |
| Government shutdown | Surveillance | Communication content |

---

## Layer 1 — Authentication Security

### Firebase Auth

```dart
// lib/core/services/auth_service.dart

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Force email verification before profile creation
  Future<void> signUp(String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    // Send verification email immediately
    await credential.user?.sendEmailVerification();
    // Do not create Supabase profile until verified
  }

  // Check verification on every sensitive action
  bool get isVerified => _auth.currentUser?.emailVerified ?? false;

  // Re-authenticate before sensitive operations
  Future<void> reauthenticate(String password) async {
    final user = _auth.currentUser!;
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: password,
    );
    await user.reauthenticateWithCredential(credential);
  }
}
```

### Session Security

```dart
// Force token refresh every 55 minutes
// Firebase tokens expire at 60 minutes
Timer.periodic(const Duration(minutes: 55), (_) async {
  await FirebaseAuth.instance.currentUser?.getIdToken(true);
});

// Detect token revocation
FirebaseAuth.instance.idTokenChanges().listen((user) {
  if (user == null) {
    // Token revoked — force logout
    ref.read(authProvider.notifier).signOut();
  }
});
```

### Brute Force Protection

```sql
-- Supabase: track failed login attempts
create table login_attempts (
  id uuid primary key default gen_random_uuid(),
  email text not null,
  ip_address text,
  attempted_at timestamptz default now(),
  success boolean default false
);

-- Block after 5 failed attempts in 15 minutes
create or replace function check_login_allowed(p_email text)
returns boolean
language sql stable
as $$
  select count(*) < 5
  from login_attempts
  where email = p_email
    and success = false
    and attempted_at > now() - interval '15 minutes';
$$;
```

---

## Layer 2 — Supabase Row Level Security (RLS)

**Every table must have RLS enabled. No exceptions.**

### Profiles Table

```sql
alter table profiles enable row level security;

-- Users can only read public profile fields
create policy "profiles_public_read" on profiles
  for select using (true);

-- Users can only update their own profile
create policy "profiles_own_update" on profiles
  for update using (auth.uid()::text = firebase_uid);

-- Users cannot change their own role or trust_score
-- (these are system-managed fields)
create policy "profiles_restricted_fields" on profiles
  for update
  using (auth.uid()::text = firebase_uid)
  with check (
    role = (select role from profiles where firebase_uid = auth.uid()::text)
    and
    trust_score = (select trust_score from profiles where firebase_uid = auth.uid()::text)
  );
```

### Posts Table

```sql
alter table posts enable row level security;

-- Anyone can read posts
create policy "posts_public_read" on posts
  for select using (true);

-- Only authenticated users can create posts
create policy "posts_authenticated_insert" on posts
  for insert with check (
    auth.uid() is not null
    and
    -- Rate limit: max 20 posts per hour per user
    (
      select count(*) from posts
      where author_id = auth.uid()
        and created_at > now() - interval '1 hour'
    ) < 20
  );

-- Users can only delete their own posts
create policy "posts_own_delete" on posts
  for delete using (author_id = auth.uid());

-- Users cannot update others' posts
create policy "posts_own_update" on posts
  for update using (author_id = auth.uid());
```

### Messages Table

```sql
alter table messages enable row level security;

-- Users can only read messages in their conversations
create policy "messages_conversation_read" on messages
  for select using (
    sender_id = auth.uid()
    or
    receiver_id = auth.uid()
    or
    exists (
      select 1 from group_members
      where group_id = messages.group_id
        and user_id = auth.uid()
    )
  );

-- Users can only send as themselves
create policy "messages_own_insert" on messages
  for insert with check (sender_id = auth.uid());
```

### Admin Actions — Strict Role Check

```sql
-- Only moderators can perform moderation actions
create policy "moderation_moderator_only" on reports
  for update using (
    exists (
      select 1 from profiles
      where firebase_uid = auth.uid()::text
        and role in ('moderator', 'admin')
    )
  );
```

---

## Layer 3 — Mesh Network Security

### Packet Encryption

```dart
// lib/mesh/crypto_service.dart
// All mesh packets are E2E encrypted
// Relay nodes see: [messageId, receiverId, encryptedBlob]
// Relay nodes CANNOT see: message content, sender identity

import 'package:cryptography/cryptography.dart';

class MeshCryptoService {
  // X25519 key exchange
  static Future<KeyPair> generateKeyPair() async {
    final algorithm = X25519();
    return algorithm.newKeyPair();
  }

  // AES-256-GCM encryption
  static Future<List<int>> encrypt({
    required String plaintext,
    required SimplePublicKey recipientPublicKey,
    required KeyPair senderKeyPair,
  }) async {
    // 1. ECDH key exchange
    final x25519 = X25519();
    final sharedSecret = await x25519.sharedSecretKey(
      keyPair: senderKeyPair,
      remotePublicKey: recipientPublicKey,
    );

    // 2. Derive AES key from shared secret
    final hkdf = Hkdf(
      hmac: Hmac.sha256(),
      outputLength: 32,
    );
    final aesKey = await hkdf.deriveKey(
      secretKey: sharedSecret,
      nonce: List<int>.filled(0, 0),
      info: utf8.encode('verasso-mesh-v1'),
    );

    // 3. Encrypt with AES-256-GCM
    final aesGcm = AesGcm.with256bits();
    final nonce = aesGcm.newNonce();
    final secretBox = await aesGcm.encrypt(
      utf8.encode(plaintext),
      secretKey: aesKey,
      nonce: nonce,
    );

    return [...nonce, ...secretBox.cipherText, ...secretBox.mac.bytes];
  }

  static Future<String> decrypt({
    required List<int> ciphertext,
    required SimplePublicKey senderPublicKey,
    required KeyPair recipientKeyPair,
  }) async {
    // Reverse of encrypt
    final x25519 = X25519();
    final sharedSecret = await x25519.sharedSecretKey(
      keyPair: recipientKeyPair,
      remotePublicKey: senderPublicKey,
    );

    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
    final aesKey = await hkdf.deriveKey(
      secretKey: sharedSecret,
      nonce: List<int>.filled(0, 0),
      info: utf8.encode('verasso-mesh-v1'),
    );

    final aesGcm = AesGcm.with256bits();
    final nonceLength = aesGcm.nonceLength;
    final macLength = 16;

    final nonce = ciphertext.sublist(0, nonceLength);
    final mac = Mac(ciphertext.sublist(ciphertext.length - macLength));
    final encrypted = ciphertext.sublist(
      nonceLength,
      ciphertext.length - macLength,
    );

    final plaintext = await aesGcm.decrypt(
      SecretBox(encrypted, nonce: nonce, mac: mac),
      secretKey: aesKey,
    );
    return utf8.decode(plaintext);
  }
}
```

### Mesh Attack Mitigations

```dart
// lib/mesh/mesh_security.dart

class MeshSecurity {
  // 1. REPLAY ATTACK PREVENTION
  // Store seen message IDs for 48 hours
  static final Set<String> _seenIds = {};
  static bool isReplay(String messageId) => _seenIds.contains(messageId);
  static void markSeen(String messageId) {
    _seenIds.add(messageId);
    if (_seenIds.length > 10000) _seenIds.clear(); // prevent memory growth
  }

  // 2. TTL ENFORCEMENT
  // Refuse to relay expired packets
  static bool isExpired(MeshPacket packet) {
    return DateTime.now().millisecondsSinceEpoch > packet.expiresAt;
  }

  // 3. HOP COUNT LIMIT
  // Max 7 hops — prevent infinite relay loops
  static const maxHops = 7;
  static bool exceedsHopLimit(MeshPacket packet) {
    return packet.hopCount >= maxHops;
  }

  // 4. PACKET SIZE LIMIT
  // Prevent oversized packets that could cause DoS
  static const maxPacketSize = 512; // bytes
  static bool isOversized(Uint8List data) => data.length > maxPacketSize;

  // 5. RATE LIMITING PER PEER
  static final Map<String, List<DateTime>> _peerSendRates = {};
  static bool isPeerSpamming(String peerId) {
    final now = DateTime.now();
    _peerSendRates[peerId] ??= [];
    _peerSendRates[peerId]!.removeWhere(
      (t) => now.difference(t).inSeconds > 60,
    );
    _peerSendRates[peerId]!.add(now);
    // Max 30 packets per minute per peer
    return (_peerSendRates[peerId]?.length ?? 0) > 30;
  }

  // Combined validation
  static bool isPacketValid(MeshPacket packet, Uint8List rawData) {
    if (isReplay(packet.messageId)) return false;
    if (isExpired(packet)) return false;
    if (exceedsHopLimit(packet)) return false;
    if (isOversized(rawData)) return false;
    return true;
  }
}
```

### Emergency Mode Security Exception

```dart
// Emergency GPS is intentionally unencrypted for rescue services
// All other fields remain encrypted even in emergency mode

class EmergencyPacket {
  // ENCRYPTED fields
  final Uint8List encryptedMessage;
  final String messageId;
  final String receiverId;

  // UNENCRYPTED fields (intentional — rescue services must read these)
  final double latitude;
  final double longitude;
  final int timestamp;

  // Clearly document why these are unencrypted
  // in code comments and security documentation
}
```

---

## Layer 4 — API Security

### Supabase Edge Function Rate Limiting

```typescript
// supabase/functions/create-post/index.ts
import { createClient } from '@supabase/supabase-js'

const rateLimits: Map<string, number[]> = new Map()

export default async function handler(req: Request) {
  const userId = req.headers.get('x-user-id')!

  // Rate limit: 20 posts per hour
  const now = Date.now()
  const userTimestamps = rateLimits.get(userId) ?? []
  const recentTimestamps = userTimestamps.filter(
    t => now - t < 3600000 // 1 hour
  )

  if (recentTimestamps.length >= 20) {
    return new Response('Rate limit exceeded', { status: 429 })
  }

  rateLimits.set(userId, [...recentTimestamps, now])

  // Process request...
}
```

### Input Validation

```dart
// lib/core/validators/input_validator.dart

class InputValidator {
  // Sanitize all user input before sending to Supabase
  static String sanitize(String input) {
    return input
      .trim()
      .replaceAll(RegExp(r'<[^>]*>'), '')    // strip HTML
      .replaceAll(RegExp(r'javascript:'), '') // strip JS injection
      .substring(0, min(input.length, 5000)); // max length
  }

  // Validate post content
  static String? validatePost(String content) {
    if (content.trim().isEmpty) return 'Post cannot be empty';
    if (content.length > 5000) return 'Post too long (max 5000 chars)';
    // Check for obvious spam patterns
    if (RegExp(r'(.)\1{50,}').hasMatch(content)) return 'Invalid content';
    return null; // valid
  }

  // Validate username
  static String? validateUsername(String username) {
    if (username.length < 3) return 'Username too short';
    if (username.length > 30) return 'Username too long';
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      return 'Username can only contain letters, numbers, underscore';
    }
    return null;
  }
}
```

---

## Layer 5 — Data Privacy

### What Verasso Stores vs What It Doesn't

| Data | Stored? | Where | Retention |
|---|---|---|---|
| Email | Yes | Firebase Auth | Until account deletion |
| Display name | Yes | Supabase | Until account deletion |
| Posts | Yes | Supabase | Until user deletes |
| Messages (online) | Yes | Supabase | 90 days then purged |
| Mesh packets | NO | Never reaches server | Hive, 24h TTL |
| GPS (emergency only) | Packet only | Never server-side | 7-day TTL |
| Encryption keys | NO | Local device only | Never uploaded |
| Browsing behaviour | No | Not collected | N/A |
| Device identifiers | No | Not collected | N/A |

### DPDP Act 2023 Compliance (India)

```dart
// lib/features/privacy/privacy_service.dart

class PrivacyService {
  // Right to erasure — delete all user data
  static Future<void> deleteAccount(String userId) async {
    // 1. Delete from Supabase (all tables cascade)
    await supabase.rpc('delete_user_data', params: {'p_user_id': userId});

    // 2. Delete from Firebase Auth
    await FirebaseAuth.instance.currentUser?.delete();

    // 3. Clear local Hive data
    await Hive.deleteFromDisk();

    // 4. Revoke FCM token
    await FirebaseMessaging.instance.deleteToken();
  }

  // Data export — user can download their data
  static Future<Map<String, dynamic>> exportUserData(String userId) async {
    final posts = await supabase
      .from('posts')
      .select()
      .eq('author_id', userId);

    final profile = await supabase
      .from('profiles')
      .select()
      .eq('id', userId)
      .single();

    return {
      'profile': profile.data,
      'posts': posts.data,
      'exported_at': DateTime.now().toIso8601String(),
    };
  }

  // Consent management
  static Future<void> recordConsent({
    required String userId,
    required String consentType, // 'terms', 'privacy', 'mesh_relay'
    required bool granted,
  }) async {
    await supabase.from('consent_records').insert({
      'user_id': userId,
      'consent_type': consentType,
      'granted': granted,
      'recorded_at': DateTime.now().toIso8601String(),
      'app_version': packageInfo.version,
    });
  }
}
```

### Minimal Data Collection Principle

```dart
// NEVER collect this — even if convenient for analytics:
// - Location (except emergency GPS, never stored server-side)
// - Device fingerprint
// - Contact list
// - Call logs
// - Precise usage timing patterns

// ONLY collect what's necessary:
// - Email (auth)
// - Username (identity)
// - Posts/doubts (core feature)
// - Engagement actions (feed algorithm only, anonymised after 90 days)
```

---

## Layer 6 — Infrastructure Security

### Supabase Configuration

```sql
-- Disable public schema access
revoke usage on schema public from anon;
revoke all on all tables in schema public from anon;

-- Only allow authenticated access
grant usage on schema public to authenticated;
grant select, insert, update, delete on all tables in schema public to authenticated;

-- Service role only for admin operations
-- Never expose service role key to client
```

### Firebase Security Rules

```json
{
  "rules": {
    "users": {
      "$uid": {
        ".read": "$uid === auth.uid",
        ".write": "$uid === auth.uid"
      }
    },
    "fcm_tokens": {
      "$uid": {
        ".read": false,
        ".write": "$uid === auth.uid"
      }
    }
  }
}
```

### Environment Variables — Never in Code

```dart
// WRONG — never do this
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';

// RIGHT — use --dart-define or .env
// Run: flutter run --dart-define=SUPABASE_KEY=xxx
const supabaseKey = String.fromEnvironment('SUPABASE_KEY');
```

```bash
# .gitignore — always include these
.env
.env.local
.env.production
google-services.json
GoogleService-Info.plist
```

### Dependency Security

```bash
# Run before every release
flutter pub audit          # check for vulnerable packages
dart pub outdated          # check for outdated packages

# For Python scripts
pip-audit -r requirements.txt
```

---

## Layer 7 — Content Security

### Spam Detection

```sql
-- Supabase: flag suspicious posts automatically
create or replace function flag_suspicious_post()
returns trigger language plpgsql as $$
begin
  -- Flag if user posts more than 5 times in 10 minutes
  if (
    select count(*) from posts
    where author_id = new.author_id
      and created_at > now() - interval '10 minutes'
  ) > 5 then
    new.flagged = true;
    new.flag_reason = 'rate_limit_exceeded';
  end if;

  -- Flag if content contains known spam patterns
  if new.content ~* '(bit\.ly|tinyurl|free.*money|click.*here.*earn)' then
    new.flagged = true;
    new.flag_reason = 'spam_pattern';
  end if;

  return new;
end;
$$;

create trigger flag_post_on_insert
  before insert on posts
  for each row execute function flag_suspicious_post();
```

### Content Moderation Queue

```sql
create table moderation_queue (
  id uuid primary key default gen_random_uuid(),
  content_type text,  -- 'post', 'comment', 'user'
  content_id uuid,
  report_reason text,
  reporter_id uuid references profiles(id),
  status text default 'pending', -- 'pending', 'reviewed', 'actioned', 'dismissed'
  reviewed_by uuid references profiles(id),
  created_at timestamptz default now()
);

-- Auto-escalate to moderator if 3+ reports
create or replace function auto_escalate_reports()
returns trigger language plpgsql as $$
begin
  if (
    select count(*) from moderation_queue
    where content_id = new.content_id
      and status = 'pending'
  ) >= 3 then
    -- Notify moderators via FCM
    perform notify_moderators(new.content_id, new.content_type);
  end if;
  return new;
end;
$$;
```

---

## Security Checklist — Before Every Release

### Code Review
- [ ] No hardcoded secrets in codebase
- [ ] `flutter pub audit` passes clean
- [ ] All user inputs validated and sanitised
- [ ] RLS enabled on all new Supabase tables
- [ ] New API endpoints have rate limiting

### Mesh Security
- [ ] All packets validated (replay, TTL, hop count, size)
- [ ] Encryption keys never leave device
- [ ] Emergency GPS clearly documented as intentionally unencrypted

### Auth Security
- [ ] Firebase tokens refreshed properly
- [ ] Session invalidation works on password change
- [ ] Reauthentication required for account deletion

### Privacy
- [ ] No new PII collected without consent flow
- [ ] Data retention policies enforced
- [ ] Account deletion removes all data

### Infrastructure
- [ ] No `.env` files in git history
- [ ] Supabase service key not in client code
- [ ] Firebase rules reviewed

---

## Incident Response

If a security issue is discovered:

**Step 1 — Contain (within 1 hour)**
- Revoke affected API keys in Supabase dashboard
- Force-invalidate all Firebase sessions if auth is compromised
- Take affected feature offline if needed

**Step 2 — Assess (within 4 hours)**
- Identify what data was accessed
- Identify how many users affected
- Check Supabase logs: `select * from auth.audit_log_entries order by created_at desc`

**Step 3 — Notify (within 24 hours)**
- DPDP Act 2023 requires notification to CERT-In within 6 hours of significant breach
- Notify affected users via FCM push notification
- Post disclosure on Verasso's social accounts

**Step 4 — Fix and Verify**
- Patch the vulnerability
- Deploy fix
- Verify fix works
- Document in post-mortem

---

## Security Contacts

| Resource | Link |
|---|---|
| CERT-In (India) | https://www.cert-in.org.in |
| Supabase Security | security@supabase.io |
| Firebase Security | https://firebase.google.com/support/troubleshooter/contact |
| DPDP Act 2023 | https://www.meity.gov.in/data-protection-framework |

---

*VERASSO · Security Plan · March 2026*
*"Security is not a feature. It is a foundation."*
