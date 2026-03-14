# Versz — 100K User Architecture Blueprint

> **Purpose**: Structured rollout plan from the current ~500-user ceiling to 100K concurrent users.  
> Covers event pipeline design, denormalized projections, concrete migration steps, and monitoring checkpoints per phase.

---

## Current State Analysis (Baseline)

### Capability Ceiling: ~500 concurrent users

#### Root Causes
| # | Problem | Impact |
|---|---------|--------|
| 1 | **Client-driven counters**: `votes`, `likes`, `saves` written directly from app SDK | Race conditions at any meaningful concurrency; no atomic increment |
| 2 | **Broad realtime refresh**: every Appwrite event triggers a full collection re-fetch | O(N) Appwrite reads per event; fan-out collapses under load |
| 3 | **No caching layer**: every screen mount reads Appwrite directly | Identical queries from 1000 users = 1000 Appwrite round-trips |
| 4 | **N+1 conversation list**: `conversations` list fetches each participant's profile individually | 50-item DM list = 100+ serial requests |
| 5 | **Functions are fire-and-forget side effects**: `update-leaderboard`, `update-trending` triggered per-write with no debounce | 10K votes in 1 minute = 10K leaderboard rebuilds |
| 6 | **Leaderboard is a full collection scan**: `update-leaderboard/index.js` reads all users with score > 0 | Unbounded query; index absent → full table scan |
| 7 | **Trending is a client-sortable list**: no server-materialized view | Trending must be re-ranked per request |

---

## Architecture Phases

---

### Phase 1 — Stabilization (Target: 1K concurrent users)
**Estimated effort**: 2–3 weeks  
**Goal**: Stop the bleeding — fix race conditions and N+1 patterns without changing the overall architecture.

#### 1.1 Atomic Counter Service (replaces client-driven writes)

**Current flow**:
```
App SDK → Appwrite DB (direct document update)
```

**New flow**:
```
App SDK → Appwrite Function: atomic-counter → Appwrite DB (server-side patch)
```

**Implementation** (`functions/atomic-counter/src/index.js`):
```javascript
// Uses Appwrite's updateDocument with $inc (server-side atomic add)
// Prevents race: two users liking simultaneously no longer clobber each other
const increment = (field, delta = 1) =>
  databases.updateDocument(dbId, collectionId, docId, { [field]: Expr.add(`$${field}`, delta) });
```

> Until Appwrite exposes native atomic increment, use an optimistic-retry loop with `$version` check:
> 1. Read document + `$version`
> 2. Compute new value locally
> 3. `updateDocument` with `ifVersion: $version` (409 = retry, max 3 attempts)
> 4. Fall through to eventual inconsistency only after 3 failures (log + alert)

**Collections affected**: `votes`, `likes`, `saves` — all stat-bearing fields.

#### 1.2 Delta Realtime (replaces full-refresh on every event)

**Current pattern** (in Riverpod providers):
```dart
// Realtime fires → provider invalidates → full list re-fetch
ref.invalidate(debatesProvider);
```

**New pattern** — apply the event payload directly to local state:
```dart
// In realtime subscription handler:
final event = RealtimeMessage.fromMap(rawEvent);
final payload = DebateModel.fromMap(event.payload);

switch (event.events.first) {
  case 'databases.*.collections.*.documents.*.create':
    state = [payload, ...state]; // prepend, no network call
  case 'databases.*.collections.*.documents.*.update':
    state = state.map((d) => d.id == payload.id ? payload : d).toList();
  case 'databases.*.collections.*.documents.*.delete':
    state = state.where((d) => d.id != payload.id).toList();
}
```

**Impact**: Eliminates the most expensive re-fetch pattern. Reduces Appwrite read load by ~60–80% at 1K users.

**Collections to migrate first** (highest event frequency):
- `debates` (feed)
- `messages` (DM)
- `notifications`

#### 1.3 Conversation List Denormalization (eliminates N+1)

**Problem**: `conversations` documents store only participant `userId`s. The list screen fetches each user profile in a loop.

**Solution — denormalized snapshot in conversation document**:

New fields on `conversations` collection:
```
participantSnapshots: [
  { userId, username, displayName, avatarUrl },
  { userId, username, displayName, avatarUrl }
]
```

**Write path**: When creating/updating a conversation, the function writes the snapshot alongside the document.

**Read path**: Conversation list renders directly from `participantSnapshots` — zero additional reads.

**Staleness strategy**: `update-profile` function (new) patches all `participantSnapshots` where `userId` matches when a user changes their avatar or username. Acceptable eventual consistency — UI reflects change within seconds.

#### 1.4 Function Debounce (stop per-write leaderboard/trending rebuilds)

**Current**: `update-leaderboard` fires on every vote document write → 10K votes = 10K rebuilds.

**New**: Move to a scheduled trigger pattern:
- `update-leaderboard`: scheduled every **60 seconds** via Appwrite CRON (`*/1 * * * *`)
- `update-trending`: scheduled every **5 minutes** (`*/5 * * * *`)
- Functions read the *current* state of the DB at execution time (pull model) instead of reacting to each write

**Leaderboard rebuild**:
```javascript
// Replace current: query all users with score > 0 (unbounded)
// New: query with pagination cursor, process in chunks of 100
let cursor = null;
do {
  const page = await databases.listDocuments(DB, 'users', [
    Query.greaterThan('score', 0),
    Query.orderDesc('score'),
    Query.limit(100),
    ...(cursor ? [Query.cursorAfter(cursor)] : [])
  ]);
  // upsert into leaderboard_snapshot collection
  cursor = page.documents.length === 100 ? page.documents.at(-1).$id : null;
} while (cursor);
```

**Required index** on `users` collection: `score DESC` (add via Appwrite console or `setup_appwrite.dart`).

#### Phase 1 Monitoring Checkpoints
- [ ] P95 vote-write latency < 200ms
- [ ] Realtime reconnect rate < 1% per minute
- [ ] Conversation list load time < 500ms for 50-item list
- [ ] Zero 409 conflicts from counter updates (alert if > 0.1%)
- [ ] Leaderboard function execution time < 10s

---

### Phase 2 — Scalable Read Path (Target: 5K concurrent users)
**Estimated effort**: 3–5 weeks  
**Goal**: Introduce a caching layer and separate hot read paths from write paths.

#### 2.1 In-Memory Cache Layer (Hive + TTL)

**Add `hive` + `hive_flutter` dependencies** (or `drift` if SQL-style queries needed).

**Cache strategy per collection**:

| Collection | Cache TTL | Invalidation trigger |
|------------|-----------|----------------------|
| User profiles | 5 min | Profile update event |
| Debate metadata | 60s | Realtime delta update |
| Leaderboard top-100 | 30s | Scheduled function writes a new snapshot |
| Trending debates | 5 min | `update-trending` function completion |
| Room member list | 2 min | Room join/leave event |

**Pattern** (Riverpod AsyncNotifier with Hive):
```dart
Future<UserModel?> fetchUser(String userId) async {
  final cached = hiveBox.get(userId); // read from Hive
  if (cached != null && !cached.isStale(ttl: Duration(minutes: 5))) {
    return cached.value;
  }
  final fresh = await appwriteService.getUser(userId);
  hiveBox.put(userId, CacheEntry(value: fresh, fetchedAt: DateTime.now()));
  return fresh;
}
```

#### 2.2 Leaderboard Shadow Collection

**Problem**: Leaderboard queries `users` directly — contention with profile reads/writes.

**Solution**: Dedicated `leaderboard_snapshot` collection populated exclusively by `update-leaderboard` function.

Schema:
```
leaderboard_snapshot {
  rank: integer (indexed)
  userId: string
  username: string
  displayName: string
  avatarUrl: string
  score: integer
  updatedAt: datetime
}
```

**Read path**: App reads `leaderboard_snapshot` (pre-ranked, paginated by `rank ASC`). Zero live computation.  
**Write path**: Only the scheduled `update-leaderboard` function writes this collection. App has no write access.

> Add to `setup_appwrite.dart`: `leaderboard_snapshot` collection with `_anyRead` + server-only write (no user permissions on write).

#### 2.3 Trending Materialized View

Same pattern as leaderboard:

```
trending_snapshot {
  position: integer (indexed)
  debateId: string
  title: string
  categoryId: string
  trendScore: float
  voteCount: integer
  commentCount: integer
  updatedAt: datetime
}
```

`update-trending` function owns writes. App has read-only access. Refresh every 5 minutes.

#### 2.4 Cursor-Based Feed Pagination

**Replace offset pagination** (`Query.offset(n)`) with cursor-based:

```dart
// Provider stores last seen document ID
Future<List<DebateModel>> fetchNextPage(String? afterId) async {
  final queries = [
    Query.orderDesc('\$createdAt'),
    Query.limit(20),
    if (afterId != null) Query.cursorAfter(afterId),
  ];
  final result = await databases.listDocuments(db, 'debates', queries);
  return result.documents.map(DebateModel.fromDocument).toList();
}
```

**Why**: Offset pagination requires skipping N rows — O(N) at the DB level. Cursor is O(1) regardless of page depth. Mandatory at 5K+ users where p99 users may be on page 10+.

#### Phase 2 Monitoring Checkpoints
- [ ] Cache hit rate > 80% for profile lookups
- [ ] Leaderboard read latency < 50ms (reading from snapshot)
- [ ] `update-leaderboard` function completes within scheduled interval (no run overlap)
- [ ] Feed p95 load time < 300ms
- [ ] Hive storage size per device < 20MB

---

### Phase 3 — Event Pipeline (Target: 50K concurrent users)
**Estimated effort**: 6–10 weeks  
**Goal**: Decouple writes from read-model updates using an event-driven fanout pipeline.

#### 3.1 Event Pipeline Architecture

```
Write (App SDK or Function)
        │
        ▼
  Appwrite Database
        │
        ▼ (Appwrite Events / Webhooks)
  event-router Function
        │
   ┌────┴────────────┬──────────────────┐
   ▼                 ▼                  ▼
counter-          leaderboard-      notification-
aggregator        projector         fanout
   │                 │                  │
   ▼                 ▼                  ▼
votes_summary   leaderboard_snapshot  notifications
(per-debate)    (ranked users)        (per-user)
```

**event-router** (`functions/event-router/src/index.js`):  
Receives all DB write events via Appwrite Function trigger. Routes to downstream functions based on collection + event type.

```javascript
const ROUTES = {
  'votes.create':       ['counter-aggregator', 'leaderboard-projector'],
  'votes.delete':       ['counter-aggregator', 'leaderboard-projector'],
  'comments.create':    ['counter-aggregator', 'check-achievements'],
  'debates.create':     ['update-trending'],
  'connections.create': ['notification-fanout'],
};

export default async ({ req, res, log }) => {
  const { collection, event, document } = JSON.parse(req.body);
  const targets = ROUTES[`${collection}.${event}`] ?? [];
  await Promise.all(targets.map(fn => functions.createExecution(fn, JSON.stringify(document))));
  return res.json({ routed: targets.length });
};
```

#### 3.2 Denormalized Projections

**Principle**: The read model is always pre-computed. No query ever joins or aggregates at read time.

**Debate feed projection** (pre-computed per debate):
```
debates_feed_projection {
  debateId: string
  title: string
  categoryId: string
  authorId: string
  authorUsername: string
  authorAvatarUrl: string
  voteCount: integer     ← maintained by counter-aggregator
  commentCount: integer  ← maintained by counter-aggregator
  trendScore: float      ← maintained by update-trending
  createdAt: datetime
  userVote: null         ← client fills this in from local state
}
```

**counter-aggregator function** maintains `voteCount` and `commentCount` using the versioned atomic update pattern from Phase 1.

#### 3.3 CDN for Public Assets

Move all public bucket reads through a CDN edge:

1. Configure Appwrite Storage bucket public URL → CloudFlare CDN (or AWS CloudFront)
2. Update `AppwriteConstants` with CDN base URL:
   ```dart
   static const cdnBase = 'https://cdn.versz.app';
   static String cdnAsset(String fileId) => '$cdnBase/v1/storage/buckets/avatars/files/$fileId/view';
   ```
3. Avatar reads never hit Appwrite directly — served from nearest CDN edge node
4. Cache-Control: `public, max-age=86400, stale-while-revalidate=3600`

**Impact**: Avatar load time drops from ~200ms (Appwrite) to ~20ms (CDN edge). Appwrite bandwidth costs drop proportionally.

#### 3.4 Rate Limiting at Function Level

Add per-user rate limiting to write-intensive functions:

```javascript
// In each write function (vote, comment, message):
const RATE_LIMITS = { vote: { window: 60, max: 30 }, comment: { window: 60, max: 10 } };

async function checkRateLimit(userId, action) {
  const key = `ratelimit:${action}:${userId}`;
  const windowStart = Math.floor(Date.now() / 1000 / RATE_LIMITS[action].window);
  const countDoc = await getOrCreate(key + ':' + windowStart);
  if (countDoc.count >= RATE_LIMITS[action].max) throw new Error('RATE_LIMITED');
  await increment(countDoc, 'count');
}
```

Store rate-limit state in a lightweight `rate_limits` collection (TTL-expired via Appwrite scheduled cleanup or a separate cleanup function running hourly).

#### Phase 3 Monitoring Checkpoints
- [ ] event-router execution time < 100ms (p95)
- [ ] Counter projection lag < 2s (vote written → `voteCount` updated)
- [ ] CDN cache hit ratio > 95% for avatar reads
- [ ] `notification-fanout` delivery time < 5s for all recipients
- [ ] Zero rate-limit false positives (monitor 429 rate < 0.01%)

---

### Phase 4 — 100K Architecture (Target: 100K concurrent users)
**Estimated effort**: 10–16 weeks  
**Goal**: Fully separated read/write paths, horizontal scale for all hot components.

#### 4.1 Separate Read/Write Paths

```
                ┌─────── WRITE PATH ───────┐
                │                          │
App Write SDK → Appwrite Functions → Appwrite DB (write collections)
                                         │
                                    event-router
                                         │
                              ┌──────────┴──────────┐
                              │                     │
                       projection-              notification-
                        updater                   service
                              │
                       READ COLLECTIONS
                       (projections, snapshots)
                              │
App Read SDK  ←───────────────┘
```

**Write collections** (never queried by app UI):
- `votes`, `likes`, `saves`, `comments` (raw events)

**Read collections** (written only by server functions):
- `debates_feed_projection`
- `leaderboard_snapshot`
- `trending_snapshot`
- `conversations_projection` (pre-joined with participant snapshots)

**App rule**: All list screens read from projection collections only. Write operations go through functions only (never direct SDK document updates from client).

#### 4.2 Connection Pooling Strategy

Appwrite at 100K concurrent users requires careful connection management:

**Client-side**:
- One `AppwriteService` singleton per app instance (already done)
- Realtime: subscribe to minimum required channels per screen. Unsubscribe on `dispose`.
- Maximum concurrent realtime subscriptions per device: 3 (feed + notifications + active DM)

**Function-side**:
- All server functions share one SDK client instance (module-level singleton, not per-invocation)
- Functions that fan out to many users (e.g., `notification-fanout`) must paginate their Appwrite queries and process in batches of 100 (never unbounded `listDocuments`)

#### 4.3 Scheduled Materialized Views (replaces event-driven for slow-changing data)

For data that changes frequently but whose read value only needs near-real-time freshness:

| View | Refresh | Mechanism |
|------|---------|-----------|
| Leaderboard top-1000 | Every 60s | CRON `*/1 * * * *` |
| Trending top-50 | Every 5 min | CRON `*/5 * * * *` |
| Category stats | Every 15 min | CRON `*/15 * * * *` |
| Weekly digest | Daily | CRON `0 9 * * *` |

Advantages over event-driven at scale:
- Predictable function execution frequency — capacity can be reserved
- Natural debouncing — 1 rebuild serves all the writes that happened in the interval
- Reduces function invocation cost (Appwrite bills per execution)

#### 4.4 Horizontal Scaling Considerations

Items outside Appwrite that must be addressed at 100K:

| Component | Bottleneck | Solution |
|-----------|-----------|---------|
| Appwrite itself | Single-node deployment | Switch to Appwrite Cloud Pro or self-host with Docker Swarm/K8s with 3+ replicas |
| Firebase Cloud Messaging | Not a bottleneck (external) | Ensure FCM token refresh handled; batch send using `sendMulticast` |
| CDN origin | Appwrite Storage bandwidth | All public reads must go through CDN (Phase 3) |
| Function cold starts | Execution latency spike | Enable function keep-alive (Appwrite Cloud) or pre-warm with health-check CRON |
| Realtime subscriptions | WebSocket connection limit | Each Appwrite instance supports ~10K concurrent WebSocket connections; at 100K need load-balanced Appwrite cluster |

#### 4.5 Feature Flags for Progressive Rollout

Wrap each architectural change in a feature flag to enable gradual rollout and rollback:

```dart
// lib/core/feature_flags.dart
class FeatureFlags {
  // Phase 1
  static const bool useAtomicCounters = true;
  static const bool useDeltaRealtime = true;
  // Phase 2
  static const bool useLeaderboardSnapshot = true;
  static const bool useCursorPagination = true;
  // Phase 3
  static const bool useEventPipeline = false; // enable when pipeline deployed
  static const bool useCdnAssets = false;     // enable when CDN configured
  // Phase 4
  static const bool useProjectionReadPath = false; // enable when projections stable
}
```

Controlled via Appwrite Remote Config or a `feature_flags` collection (server-readable, client-readable, admin-writable).

#### Phase 4 Monitoring Checkpoints
- [ ] Write path p99 latency < 500ms end-to-end
- [ ] Read path p95 latency < 100ms (projection reads, cached)
- [ ] Realtime delivery lag < 3s at 100K subscribers
- [ ] Function execution success rate > 99.9%
- [ ] Zero unbounded queries reaching the DB (enforce via query analyzer script)
- [ ] CDN origin offload > 98% for static assets

---

## Migration Execution Order

```
Phase 1: No breaking changes — runs alongside current code
  ├── Add atomic-counter function
  ├── Migrate realtime handlers to delta pattern (per-provider)
  ├── Add participantSnapshots field to conversations
  └── Convert leaderboard + trending to scheduled CRON

Phase 2: Additive only — new collections, new cache layer
  ├── Add leaderboard_snapshot collection (via setup_appwrite.dart)
  ├── Add trending_snapshot collection
  ├── Add Hive dependency + cache wrapper
  └── Switch feed to cursor pagination

Phase 3: New infrastructure required before enabling
  ├── Deploy event-router function
  ├── Deploy counter-aggregator function
  ├── Configure CDN (CloudFlare or CloudFront)
  ├── Add debates_feed_projection collection
  └── Enable rate limiting on write functions

Phase 4: Requires Appwrite infrastructure upgrade
  ├── Upgrade to Appwrite Cloud Pro or clustered self-host
  ├── Enable projection read path via feature flag
  ├── Enforce write-through-function-only policy
  └── Enable CDN for all assets
```

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Projection lag causes stale UI | Medium | Medium | Show "syncing…" indicator; optimistic local update |
| event-router function cold start during spike | High | High | CRON keep-alive ping every 5 min |
| Hive cache corruption after app update | Low | Medium | Versioned Hive box; clear on schema version mismatch |
| CRON overlap (leaderboard rebuild > 60s interval) | Medium | Low | Lock document in `leaderboard_snapshot_meta`; skip execution if locked |
| CDN stale avatars after profile update | Low | Low | Include `$updatedAt` hash in CDN URL; or 5-min TTL |
| Appwrite WebSocket limit hit before cluster upgrade | High (at 50K) | High | Implement connection multiplexing at Phase 3 before reaching 50K |
| Rate limit false positives on bursty legitimate use | Low | Medium | Use sliding window (not fixed window); tune per-action limits with data |

---

## Summary Checklist

### Before deploying each phase, verify:
- [ ] `flutter test` — all tests passing
- [ ] `flutter analyze` — zero errors
- [ ] `setup_appwrite.dart` — new collections added with correct permissions
- [ ] Appwrite console — indexes created for all new query fields
- [ ] Staging env tested at 10% of target user load before prod deploy
- [ ] Rollback plan documented (feature flag disable path)
- [ ] Monitoring dashboards updated with new SLO bounds

---

*Document version: 1.0 — created during Phase 3 remediation session.*  
*Cross-reference: `scripts/load_test_plan.md` for validation scenarios per phase.*
