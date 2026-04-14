# VERASSO — Feed Algorithm Implementation Plan
### pgvector + MAB + Gorse | Solo Build | March 2026

---

## Overview

Three algorithms. Three weeks. Build order matters — each one works standalone
and feeds into the next.

```
Week 1: pgvector    → Similar posts (Supabase, already available)
Week 2: MAB         → Personalised feed ranking (Thompson Sampling)
Week 3+: Gorse      → Full collaborative filtering (deploy on Render)
```

---

## Week 1 — pgvector (Similar Posts)

### What It Does
Finds posts similar to what a user has engaged with.
User liked a Physics post → show more Physics posts like it.

### Setup (30 minutes)

```sql
-- Step 1: Enable pgvector in Supabase SQL editor
create extension if not exists vector;

-- Step 2: Add embedding column to posts table
alter table posts
  add column embedding vector(384);

-- Step 3: Create index for fast similarity search
create index on posts
  using ivfflat (embedding vector_cosine_ops)
  with (lists = 100);
```

### Generate Embeddings

Install sentence-transformers in a Python script
(run once to backfill, then on every new post):

```python
# scripts/generate_embeddings.py
from sentence_transformers import SentenceTransformer
from supabase import create_client
import os

model = SentenceTransformer('all-MiniLM-L6-v2')  # Apache 2.0, free
supabase = create_client(os.environ['SUPABASE_URL'], os.environ['SUPABASE_KEY'])

def generate_embedding(post):
    # Combine subject + content for richer embedding
    text = f"{post['subject']} {post['chapter']} {post['content']}"
    return model.encode(text).tolist()

def backfill_embeddings():
    posts = supabase.table('posts').select('id, subject, chapter, content').execute()
    for post in posts.data:
        embedding = generate_embedding(post)
        supabase.table('posts').update({
            'embedding': embedding
        }).eq('id', post['id']).execute()
        print(f"Embedded post {post['id']}")

# Run on new post creation via Supabase edge function
def embed_new_post(post_id):
    post = supabase.table('posts').select('*').eq('id', post_id).single().execute()
    embedding = generate_embedding(post.data)
    supabase.table('posts').update({
        'embedding': embedding
    }).eq('id', post_id).execute()

if __name__ == '__main__':
    backfill_embeddings()
```

### Query Similar Posts (Flutter → Supabase RPC)

```sql
-- Supabase SQL: create this as a function
create or replace function get_similar_posts(
  query_embedding vector(384),
  match_threshold float default 0.7,
  match_count int default 20
)
returns table (
  id uuid,
  content text,
  subject text,
  author_id uuid,
  created_at timestamptz,
  similarity float
)
language sql stable
as $$
  select
    posts.id,
    posts.content,
    posts.subject,
    posts.author_id,
    posts.created_at,
    1 - (posts.embedding <=> query_embedding) as similarity
  from posts
  where 1 - (posts.embedding <=> query_embedding) > match_threshold
  order by similarity desc
  limit match_count;
$$;
```

```dart
// Flutter: call from feed service
// lib/features/feed/feed_service.dart

class FeedService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Post>> getSimilarPosts({
    required List<double> userEmbedding, // average of posts user engaged with
    int limit = 20,
  }) async {
    final response = await _supabase.rpc('get_similar_posts', params: {
      'query_embedding': userEmbedding,
      'match_threshold': 0.7,
      'match_count': limit,
    });
    return (response as List).map((p) => Post.fromJson(p)).toList();
  }

  // Get user's interest embedding = average of their last 10 engaged posts
  Future<List<double>> getUserInterestEmbedding(String userId) async {
    final engagements = await _supabase
      .from('engagements')
      .select('posts(embedding)')
      .eq('user_id', userId)
      .order('created_at', ascending: false)
      .limit(10);

    if (engagements.isEmpty) return [];

    // Average the embeddings
    final embeddings = engagements
      .map((e) => List<double>.from(e['posts']['embedding']))
      .toList();

    final averaged = List<double>.filled(384, 0.0);
    for (final emb in embeddings) {
      for (int i = 0; i < 384; i++) {
        averaged[i] += emb[i] / embeddings.length;
      }
    }
    return averaged;
  }
}
```

### Track Engagements

```sql
-- Track what users engage with
create table engagements (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id),
  post_id uuid references posts(id),
  action text, -- 'volt', 'connect', 'relay', 'view', 'save'
  weight float generated always as (
    case action
      when 'relay'   then 8.0   -- highest signal (mesh share)
      when 'save'    then 5.0
      when 'connect' then 4.0   -- comment
      when 'volt'    then 3.0   -- like
      when 'view'    then 1.0   -- lowest signal
    end
  ) stored,
  created_at timestamptz default now()
);

-- Index for fast user lookups
create index on engagements (user_id, created_at desc);
```

**Week 1 Deliverable:** Feed shows semantically similar posts to what
user has engaged with. Works offline — embeddings cached locally in Hive.

---

## Week 2 — Multi-Armed Bandit (Feed Ranking)

### What It Does
Decides which content TYPE to show each user.
Learns over time: this user engages more with doubts than posts,
more with astronomy than physics, etc.

### The Five Content Arms

```dart
// lib/features/feed/content_arms.dart

enum ContentArm {
  socialPost,    // regular feed posts
  doubt,         // Q&A doubts
  scienceModule, // physics/chemistry/biology
  astronomy,     // stargazing content
  meshUpdate,    // mesh activity, relay stats
}
```

### Thompson Sampling Implementation

```dart
// lib/features/feed/thompson_sampler.dart
import 'dart:math';

class ThompsonSampler {
  final Map<String, int> _alpha = {}; // successes per arm
  final Map<String, int> _beta = {};  // failures per arm
  final Random _random = Random();

  ThompsonSampler(List<String> arms) {
    for (final arm in arms) {
      _alpha[arm] = 1; // start with 1 to avoid division by zero
      _beta[arm] = 1;
    }
  }

  // Sample from Beta distribution using approximation
  double _betaSample(int alpha, int beta) {
    // Box-Muller approximation for Beta distribution
    final a = alpha.toDouble();
    final b = beta.toDouble();
    final x = _gammaVariate(a);
    final y = _gammaVariate(b);
    return x / (x + y);
  }

  double _gammaVariate(double alpha) {
    if (alpha < 1) {
      return _gammaVariate(1 + alpha) * pow(_random.nextDouble(), 1 / alpha);
    }
    final d = alpha - 1 / 3;
    final c = 1 / sqrt(9 * d);
    while (true) {
      double x, v;
      do {
        x = _random.nextGaussian();
        v = 1 + c * x;
      } while (v <= 0);
      v = v * v * v;
      final u = _random.nextDouble();
      if (u < 1 - 0.0331 * (x * x) * (x * x)) return d * v;
      if (log(u) < 0.5 * x * x + d * (1 - v + log(v))) return d * v;
    }
  }

  // Select next content arm
  String selectArm() {
    String bestArm = _alpha.keys.first;
    double bestSample = 0;

    for (final arm in _alpha.keys) {
      final sample = _betaSample(_alpha[arm]!, _beta[arm]!);
      if (sample > bestSample) {
        bestSample = sample;
        bestArm = arm;
      }
    }
    return bestArm;
  }

  // Update based on user engagement
  void update(String arm, bool engaged) {
    if (engaged) {
      _alpha[arm] = (_alpha[arm] ?? 1) + 1;
    } else {
      _beta[arm] = (_beta[arm] ?? 1) + 1;
    }
    _persist(); // save to Hive
  }

  // Persist state to Hive (survives app restart)
  Future<void> _persist() async {
    final box = Hive.box('mab_state');
    await box.put('alpha', _alpha);
    await box.put('beta', _beta);
  }

  // Load from Hive on app start
  static ThompsonSampler fromHive(List<String> arms) {
    final box = Hive.box('mab_state');
    final sampler = ThompsonSampler(arms);
    final savedAlpha = box.get('alpha') as Map<String, int>?;
    final savedBeta = box.get('beta') as Map<String, int>?;
    if (savedAlpha != null) sampler._alpha.addAll(savedAlpha);
    if (savedBeta != null) sampler._beta.addAll(savedBeta);
    return sampler;
  }
}

// Extension for Gaussian random
extension on Random {
  double nextGaussian() {
    double u, v, s;
    do {
      u = nextDouble() * 2 - 1;
      v = nextDouble() * 2 - 1;
      s = u * u + v * v;
    } while (s >= 1 || s == 0);
    return u * sqrt(-2 * log(s) / s);
  }
}
```

### Feed Ranking Score

```dart
// lib/features/feed/feed_ranker.dart

class FeedRanker {
  static double scorePost(Post post, Map<String, double> userInterests) {
    final hoursSincePost = DateTime.now()
      .difference(post.createdAt).inHours.toDouble();

    return (
      (post.volts * 3.0) +
      (post.connectCount * 5.0) +       // comments
      (post.relayCount * 8.0) +          // mesh relay = highest signal
      (post.saveCount * 4.0) +
      (userInterests[post.subject] ?? 0.1) * 10.0 +  // subject interest
      (-hoursSincePost * 0.5)            // time decay
    );
  }

  static List<Post> rankFeed(
    List<Post> candidates,
    Map<String, double> userInterests,
  ) {
    final scored = candidates.map((p) => (
      post: p,
      score: scorePost(p, userInterests),
    )).toList();

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.map((s) => s.post).toList();
  }
}
```

### Wiring It Together in the Feed

```dart
// lib/features/feed/feed_provider.dart

final feedProvider = AsyncNotifierProvider<FeedNotifier, List<Post>>(
  FeedNotifier.new,
);

class FeedNotifier extends AsyncNotifier<List<Post>> {
  late ThompsonSampler _sampler;
  late FeedService _feedService;

  @override
  Future<List<Post>> build() async {
    _sampler = ThompsonSampler.fromHive([
      'socialPost', 'doubt', 'scienceModule', 'astronomy', 'meshUpdate'
    ]);
    _feedService = ref.read(feedServiceProvider);
    return _loadFeed();
  }

  Future<List<Post>> _loadFeed() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;

    // 1. Get user interest embedding
    final embedding = await _feedService.getUserInterestEmbedding(userId);

    // 2. Get similar posts via pgvector
    final similarPosts = embedding.isNotEmpty
      ? await _feedService.getSimilarPosts(userEmbedding: embedding)
      : await _feedService.getRecentPosts();

    // 3. Select content arm via MAB
    final selectedArm = _sampler.selectArm();

    // 4. Boost posts matching selected arm
    final boosted = similarPosts.map((p) {
      if (p.type == selectedArm) {
        return p.copyWith(boostScore: 2.0);
      }
      return p;
    }).toList();

    // 5. Rank by score
    final userInterests = await _feedService.getUserInterests(userId);
    return FeedRanker.rankFeed(boosted, userInterests);
  }

  // Called when user engages with a post
  void onEngagement(Post post, String action) {
    _sampler.update(post.type, true);
    _feedService.trackEngagement(
      postId: post.id,
      action: action,
    );
  }

  // Called when user skips a post
  void onSkip(Post post) {
    _sampler.update(post.type, false);
  }
}
```

**Week 2 Deliverable:** Feed learns each user's content preferences.
Relay action weighted 8x — your unique signal. Works fully offline
via Hive persistence.

---

## Week 3+ — Gorse (Collaborative Filtering)

### What It Does
"Users similar to you also liked X."
Needs ~10,000 interactions to be meaningful.
Build this when you hit 5,000+ users.

### Deploy on Render (Free Tier)

```yaml
# render.yaml — add to your repo
services:
  - type: web
    name: verasso-gorse
    env: docker
    dockerfilePath: ./gorse/Dockerfile
    envVars:
      - key: GORSE_DATABASE_DRIVER
        value: postgres
      - key: GORSE_DATABASE_DSN
        fromService:
          type: pserv
          name: verasso-db
          envVarKey: DATABASE_URL
    plan: free
```

```toml
# gorse/config.toml
[database]
driver = "postgres"
data_store = "${GORSE_DATABASE_DSN}"
cache_store = "${GORSE_DATABASE_DSN}"

[master]
http_host = "0.0.0.0"
http_port = 8088

[recommend]
popular_window = "4320h"    # 6 months
fit_period = "60m"          # retrain every hour
search_period = "3h"
neighborhood_size = 100
collaborative_filtering_type = "als"  # Alternating Least Squares

[online_predict]
num_feedback_fallback_item_based = 10
```

### Flutter Integration

```dart
// lib/features/feed/gorse_service.dart

class GorseService {
  static const _base = 'https://verasso-gorse.onrender.com';

  // Insert feedback when user engages
  static Future<void> insertFeedback({
    required String userId,
    required String postId,
    required String feedbackType, // 'volt', 'relay', 'save', 'connect'
  }) async {
    await http.post(
      Uri.parse('$_base/api/feedback'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode([{
        'FeedbackType': feedbackType,
        'UserId': userId,
        'ItemId': postId,
        'Timestamp': DateTime.now().toIso8601String(),
      }]),
    );
  }

  // Get recommendations for user
  static Future<List<String>> getRecommendations(String userId) async {
    final response = await http.get(
      Uri.parse('$_base/api/recommend/$userId?n=20'),
    );
    final data = jsonDecode(response.body) as List;
    return data.map((item) => item['Id'] as String).toList();
  }

  // Insert item (post) when created
  static Future<void> insertItem(Post post) async {
    await http.post(
      Uri.parse('$_base/api/item'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'ItemId': post.id,
        'Labels': [post.subject, post.type, ...post.examTags],
        'Timestamp': post.createdAt.toIso8601String(),
      }),
    );
  }
}
```

**Week 3+ Deliverable:** Full "users like you also liked" recommendations.
Automatically retrains every hour. Free on Render.

---

## The Full Feed Pipeline

```
User opens feed
       │
       ▼
Get user embedding (pgvector) ──→ Find similar posts (Week 1)
       │
       ▼
Select content arm (MAB) ──────→ Boost matching content type (Week 2)
       │
       ▼
Get collaborative recs (Gorse) → Merge with similar posts (Week 3)
       │
       ▼
Score + rank all candidates ───→ FeedRanker.rankFeed()
       │
       ▼
Return top 20 posts to user
       │
       ▼
Track engagement ──────────────→ Update MAB + Gorse + pgvector
```

---

## Verasso-Specific Signals

These are signals Instagram doesn't have. Use them:

| Signal | Weight | Why |
|---|---|---|
| Relay (mesh share) | 8.0 | Highest trust — user broadcast via Bluetooth |
| Save to library | 5.0 | User wants to keep this |
| Connect (comment) | 4.0 | Active engagement |
| Volt (like) | 3.0 | Passive engagement |
| View >30 seconds | 2.0 | Read, not just scrolled past |
| View <3 seconds | -0.5 | Negative signal — didn't want this |

The **Relay signal** is unique to Verasso. Nobody else has it.
Weight it highest.

---

## pubspec.yaml Additions

```yaml
dependencies:
  hive_flutter: latest    # MAB state persistence
  http: latest            # Gorse API calls
  supabase_flutter: latest # pgvector queries (already present)

dev_dependencies:
  # Run embedding generation separately in Python
  # Not a Flutter dependency
```

```txt
# requirements.txt (for embedding script)
sentence-transformers==2.2.2
supabase==1.0.3
python-dotenv==1.0.0
```

---

## Environment Variables

```env
# .env (never commit this)
SUPABASE_URL=your_supabase_url
SUPABASE_SERVICE_KEY=your_service_key  # use service key for scripts
GORSE_API_KEY=your_gorse_key           # set in Render dashboard
```

---

*VERASSO · Algorithm Implementation Plan · March 2026*
