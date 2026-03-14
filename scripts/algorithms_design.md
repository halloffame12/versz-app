# VERSZ — Production Algorithm Design
## All 14 Phases · Engineer-Grade Reference

> **Status**: Implemented in Appwrite Functions.  
> All formulas are live in `functions/`. Cross-reference each phase with the corresponding function file.

---

## PHASE 1 — TRENDING ALGORITHM

**File**: `functions/update-trending/src/index.js`  
**Trigger**: CRON `*/5 * * * *` (every 5 minutes)

### Formula

```
engagement  = (comments × 5) + (votes × 2) + (likes × 1) + (views × 0.05)
controversy = 1.2  if  |agreeRatio − 0.5| < 0.2  else  1.0
spamGuard   = 0.1  if  engagement > prevScore × 5  AND  prevScore > 10  else  1.0
rawScore    = engagement × controversy × spamGuard
trendingScore = rawScore / (hoursOld + 2) ^ 1.8
```

### Design rationale

**Why gravity decay?**  
The old formula `votes*2 + comments*3 - hoursOld*0.8` is **linear**. A 48-hour-old debate with 1000 votes still outscores a 1-hour-old debate with 50 votes, permanently. Gravity decay makes older content lose score exponentially — the feed stays fresh automatically.

**Why these weights?**  
`comments(5) > votes(2) > likes(1) > views(0.05)` reflects intent signal strength:
- Commenting requires typing a response — highest intent
- Voting is one tap but deliberate
- Liking is passive positive signal
- Viewing can be accidental (scroll-past)

**Why gravity = 1.8?**  
- `1.0` = mild decay (large platforms, broad content)
- `1.5` = moderate (Reddit default)
- `1.8` = aggressive (keeps debate feed very fresh, ideal for time-sensitive debate content)
- `2.0+` = too aggressive for debates that unfold over hours

**Controversy multiplier**  
Debates where both sides are roughly even (within 20% of 50/50 split) get a 20% boost. They are more interesting and drive more engagement. This mirrors Reddit's "controversial" sort signal.

**Spam guard**  
If a debate's engagement is 5× its last recorded score (and the score was meaningful, >10), suppress it to 10% for one cycle. This catches vote-farming bots. Legitimate viral content catches up in the next 5-minute window.

### Scoring example

| Debate | Comments | Votes | Likes | Views | Age (h) | Score |
|--------|----------|-------|-------|-------|---------|-------|
| Fresh hot | 20 | 40 | 10 | 200 | 1 | (100+80+10+10) / (3)^1.8 = 200/7.2 = **27.8** |
| Old popular | 100 | 500 | 200 | 5000 | 36 | (500+1000+200+250) / (38)^1.8 = 1950/780 = **2.5** |

Fresh debate wins. Old debate is still present but further down the list.

### Storage

- `debates.trendingScore` — written back per-debate (only if change > 0.01)
- `debates.isTrending` — boolean: `trendingScore > 1.0`
- `trending` collection — top 50 snapshot rebuilt every 5 minutes

---

## PHASE 2 — LEADERBOARD ALGORITHM

**File**: `functions/update-leaderboard/src/index.js`  
**Trigger**: CRON `* * * * *` (every 60 seconds)

### Rank Calculation

```
All-time rank:
  primary   = xp DESC
  tiebreak1 = winRate DESC
  tiebreak2 = currentStreak DESC
  tiebreak3 = accountCreatedAt ASC  (earlier account = more loyal = wins tie)

Weekly rank:
  primary   = weeklyXp DESC
  tiebreak  = winRate DESC
```

### Weekly Reset Logic

On Monday, within the first hour of midnight UTC:
1. Read all users (fully paginated)
2. For each user with `weeklyXp > 0`: write `weeklyXp: 0`
3. Continue to rebuild leaderboard with reset values

**Idempotent**: The function checks `dayOfWeek === 1 && hoursIntoDay < 1`. Running it twice within the first hour of Monday is safe — the second run finds all users already at `weeklyXp: 0`.

### Bug fixed: 100-user cap

The previous implementation called `listDocuments` with `limit: 100` once, then sorted and inserted. On a platform with 200+ users, ranks 101-200 were silently dropped from the leaderboard. The new implementation uses a cursor-based pagination loop supporting up to 10,000 users.

### When leaderboard updates

| Event | Trigger |
|-------|---------|
| Vote cast | Not triggered directly — picked up in next 60s CRON cycle |
| Comment posted | Not triggered directly — next CRON cycle |
| Debate created | Not triggered directly — next CRON cycle |
| XP awarded (update-xp) | Can optionally trigger leaderboard directly for immediate reflection |
| Monday midnight | Weekly reset + full rebuild triggered by CRON |

**Design decision**: Not triggering the leaderboard rebuild per-write prevents O(writes) function calls. 60-second eventual consistency is acceptable for a leaderboard display.

---

## PHASE 3 — XP ECONOMY ALGORITHM

**File**: `functions/update-xp/src/index.js`  
**Trigger**: Called by client after user actions (via `functions.createExecution`)

### XP Table

| Action | Base XP | Daily Cap | Cap Collection |
|--------|---------|-----------|----------------|
| `debate_created` | +50 | 3 debates | `debates` |
| `comment_posted` | +10 | 20 comments | `comments` |
| `vote_cast` | +2 | 15 votes | `votes` |
| `debate_won` | +50 | No cap (one per debate) | — |
| `daily_checkin` | +5 | 1 per day | `lastVoteDate` field |
| `receive_vote` | +3 | No cap (passive) | — |

### Streak Bonuses (on `daily_checkin`)

| Streak milestone | Bonus XP |
|-----------------|----------|
| Day 3 | +10 |
| Day 7 | +25 |
| Day 30 | +100 |

Milestones are **exact** (not cumulative). Hitting day 7 does not also give day 3 bonus — the loop breaks on first match.

### Abuse Prevention

1. **Daily caps**: Counted via `listDocuments` query on the action's source collection, filtered `createdAt > startOfToday`. No extra tables needed.
2. **Checkin deduplication**: `lastVoteDate` field repurposed as last-activity-date (YYYY-MM-DD). If it equals today — reject. This is the cheapest possible dedup (one field read).
3. **debate_won deduplication**: Verifies `winningSide` is a confirmed winner before awarding. Prevents XP from being awarded before `calculate-winner` runs.
4. **All validation is server-side**: Client passes `userId + action` — never XP value. Server computes and writes XP. Client cannot forge inflation.

### Reputation Score

Computed every time XP is awarded:

```
reputation = log₁₀(max(xp, 1)) × 100
           + winRate × 300
           + min(currentStreak, 30) × 5
           + min(debatesCreated, 100) × 3
```

**Why log scale for XP?** Prevents pure grinding from dominating reputation. A user with 100,000 XP only has 5× the log-reputation of a user with 10 XP, but 10,000× the raw XP. Reputation reflects engagement quality, not just volume.

**Uses of reputation**:
- Badge unlock thresholds (e.g., "Verified Debater" requires reputation ≥ 500)
- Content weight in feed recommendation (higher reputation = slight boost)
- Verification gating (reputation ≥ 800 unlocks verification request)

---

## PHASE 4 — DEBATE WINNER ALGORITHM

**File**: `functions/calculate-winner/src/index.js`  
**Trigger**: Called when debate closes, or daily CRON on debates aged > 24h

### Wilson Score Lower Bound

The naive winner (whoever has more votes) is statistically unreliable for small samples. The Wilson Score Lower Bound answers:

> "What is the minimum plausible true win rate, at 95% confidence?"

```javascript
p = positive / n
z = 1.96  // 95% confidence

lower = (p + z²/2n − z√(p(1−p)/n + z²/4n²)) / (1 + z²/n)
```

Both sides (agree and disagree) get a confidence score. The side with the higher lower bound wins.

### Decision Logic

```
total < 10            → winningSide = 'inconclusive'
|agreeConf − disagreeConf| < 0.05  → winningSide = 'tie'
agreeConf > disagreeConf           → winningSide = 'agree'
else                               → winningSide = 'disagree'
```

5% tie threshold: if the two confidence scores are within 5% of each other, the result is statistically equivalent — it's a tie.

### Worked Example

| Agree | Disagree | Total | agreeConf | disagreeConf | Winner |
|-------|----------|-------|-----------|--------------|--------|
| 2 | 1 | 3 | 0.15 | 0.03 | inconclusive (total < 10) |
| 8 | 2 | 10 | 0.51 | 0.04 | agree (0.51 − 0.04 > 0.05) |
| 5 | 5 | 10 | 0.21 | 0.21 | tie |
| 600 | 400 | 1000 | 0.571 | 0.371 | agree |
| 550 | 450 | 1000 | 0.520 | 0.421 | agree (subtle but statistically confirmed) |

---

## PHASE 5 — ANTI-SPAM ALGORITHM

**File**: `functions/anti-spam-check/src/index.js`  
**Trigger**: Called from client before any rate-limited write

### Rate Limits

| Action | Window | Limit | Penalty |
|--------|--------|-------|---------|
| `vote_cast` | 1 hour | 30 | 15-min block |
| `comment_posted` | 1 hour | 15 | 30-min block |
| `debate_created` | 24 hours | 5 | 24-hour block |
| `message_sent` | 1 hour | 100 | 1-hour block |

### Velocity Detection

10 identical actions in 60 seconds → **velocity limit exceeded** → 5-minute cooldown.

This catches:
- Automated scripts fire-flooding votes
- Rage-clicking the vote button
- Message spam bots

### Where Each Check Lives

| Check type | Layer | Reason |
|------------|-------|--------|
| Rate limiting | Appwrite Function | Time-window queries impossible in DB rules |
| Velocity detection | Appwrite Function | Same reason |
| Auth validation | Database permissions | First-line defence — no function needed |
| Own-document-only writes | Database document security | `docSecurity: true` on messages/chats |
| Input sanitization | Client | Validate before sending (defense in depth) |

### Fail-Open Design

If the anti-spam function errors (network blip, timeout), the response is:
```json
{ "allowed": true, "reason": "check_error_fail_open" }
```

**Tradeoff**: Some spam may slip through during outages. Alternative (fail-closed) would block all legitimate users during any function downtime. For a social platform, service availability > perfect spam prevention. Monitor for spam spikes in Appwrite logs when function errors occur.

---

## PHASE 6 — RECOMMENDATION ALGORITHM

**Implementation**: Client-side feed ranking (no dedicated function required at current scale)

### Feed Score Formula

```
feedScore =
  trendingComponent × 0.35
  + categoryComponent × 0.25
  + socialComponent   × 0.20
  + qualityComponent  × 0.10
  + freshnessComponent × 0.10
```

### Component Definitions

```dart
// trendingComponent: normalized debate trending score [0–1]
final trendingComponent = debate.trendingScore / maxTrendingScore;

// categoryComponent: user's affinity for this debate's category
// Measured by counting user's past votes/comments in this category
final categoryComponent = userCategoryAffinity[debate.category] ?? 0.0;

// socialComponent: is debate author in user's connections/following?
// 1.0 = direct connection, 0.5 = followed, 0.0 = no relation
final socialComponent = socialProximity(debate.creatorId, currentUserId);

// qualityComponent: vote density (well-voted content = higher quality signal)
final qualityComponent = min(totalVotes, 200) / 200.0;

// freshnessComponent: exponential decay over 24h baseline
final hoursOld = DateTime.now().difference(debate.createdAt).inHours;
final freshnessComponent = exp(-hoursOld / 24.0);
```

### When to Compute

At current scale: compute in the Flutter provider after fetching the base feed from Appwrite. Sort locally. This is O(n) on the fetched page — cheap enough client-side.

At 50K+ users: move to a server-side `compute-feed` function that personalizes the feed per user and returns a pre-ranked list. Cache per user with 60s TTL.

---

## PHASE 7 — REPUTATION ALGORITHM

### Formula

```
reputation = log₁₀(max(xp, 1)) × 100      // XP contribution (log-scaled)
           + winRate × 300                  // Win rate (0–300)
           + min(currentStreak, 30) × 5    // Active streak (0–150, capped at 30 days)
           + min(debatesCreated, 100) × 3  // Debate creation (0–300, capped at 100)
```

**Range**: ~0 (new user with 0 xp) to ~1200+ (elite user)

### Reputation Score Scale

| Score | Tier | Meaning |
|-------|------|---------|
| 0–50 | New | Just started |
| 51–200 | Active | Regular participation |
| 201–500 | Engaged | Consistent debater |
| 501–800 | Veteran | High win rate + streak |
| 801+ | Elite | Top platform contributor |

### Uses

| Feature | Threshold |
|---------|-----------|
| Badge unlock: "Rising Debater" | reputation ≥ 150 |
| Badge unlock: "Verified Debater" | reputation ≥ 500 |
| Content weight in feed | `feedScore += reputation / 2000 * 0.1` |
| Verification request | reputation ≥ 800 |
| Trust for report moderation | reputation ≥ 300 |

---

## PHASE 8 — NOTIFICATION PRIORITY ALGORITHM

**Collection**: `notifications`

### Priority Queue

| Type | Priority Score | Reason |
|------|---------------|--------|
| `direct_message` | 100 | Highest intent — someone sent you a message |
| `reply` | 80 | Someone replied to your comment directly |
| `mention` | 75 | Someone mentioned you by username |
| `debate_vote` | 60 | Someone voted on your debate |
| `comment_vote` | 50 | Someone liked your comment |
| `follow` | 40 | Someone followed you |
| `like` | 30 | Passive positive signal on your content |
| `badge_earned` | 25 | System milestone notification |
| `streak_reminder` | 20 | Automated retention nudge |

### Deduplication Rules

- `debate_vote`: batch into one notification per debate per 1-hour window ("5 people voted on your debate") — instead of 5 individual notifications
- `like`: batch per post per 24-hour window
- `follow`: individual (identity matters)
- `reply`/`message`: always individual (no batching — user expects to see each one)

### Spam Prevention

- Max 20 notifications per user per hour from system sources
- If a user gets 50+ notifications in 24h from the same sender → flag sender for review
- `streak_reminder` fires at most once per day, only if user hasn't logged in yet

### Implementation in `send-notification` function

Sort pending notifications by priority score before delivering via FCM. High-priority notifications always deliver immediately. Low-priority (like, badge) can be batched into a daily digest at 9am local time (if user's notification preferences allow it).

---

## PHASE 9 — CHAT OPTIMIZATION ALGORITHM

**Collections**: `messages`, `chats`, `typing_status`

### Message Ordering

Use Appwrite `$createdAt` (server timestamp) as the canonical ordering field. Do **not** use client-generated timestamps — they drift with device clock skew.

Query pattern:
```javascript
Query.orderAsc('$createdAt')  // always ascending for chat history
Query.cursorAfter(lastMessageId)  // cursor-based pagination for "load more"
```

### Unread Count Accuracy

**Current problem**: Unread counts can drift if messages arrive while the app is backgrounded and events are missed.

**Solution**: Store `lastReadAt` (ISO timestamp) per-user-per-chat in the `chats` document. Unread count = `countMessages where chatId = X AND $createdAt > lastReadAt`.

On chat open: write `lastReadAt = now` to the chat document.

This is a server-authoritative count — never computed from realtime events alone, which can miss messages.

### Typing Timeout

`typing_status` documents expire after 3 seconds client-side if no heartbeat arrives. Implementation:

```dart
// In the typing indicator widget:
// Writer: update typing_status every 2s while typing
// Reader: hide indicator if typing_status.$updatedAt is older than 3s
final isStillTyping = DateTime.now().difference(typingDoc.updatedAt).inSeconds < 3;
```

### Duplicate Message Detection

If a network error causes the client to retry a message send, the same message may be inserted twice. Prevention:

1. Generate a client-side `idempotencyKey = uuid()` before sending
2. Include `idempotencyKey` in the message document
3. Before inserting: check `messages` where `idempotencyKey = X` — if found, return existing doc
4. This requires an index on `idempotencyKey`

### Delivery Failure Detection

If a message has no `deliveredAt` timestamp and is older than 30s, mark it with a "delivery failed" indicator in the UI. The client can offer a "retry" button that re-calls the send endpoint.

---

## PHASE 10 — PERFORMANCE-SAFE ALGORITHM PATTERNS

### Rule: No heavy computation on the client

| Computation | Wrong place | Right place |
|-------------|------------|-------------|
| Feed ranking | Client CPU per-render | Provider (once per fetch) |
| Trending score | Client | update-trending CRON |
| Leaderboard sort | Client (from raw users) | update-leaderboard CRON |
| Winner determination | Client | calculate-winner function |
| XP math | Client | update-xp function |
| Spam check | Client only | anti-spam-check function (server) |

### Batch Updates

Instead of updating `agreeCount` synchronously on every vote write:
```
vote write → update agreeCount immediately (optimistic)
           → update-trending picks up new count in next 5-min run
```

For XP: call `update-xp` asynchronously after the primary write succeeds. XP update failure is non-fatal.

### Scheduled vs. Event-Triggered

| Function | Pattern | Frequency |
|----------|---------|-----------|
| `update-trending` | Scheduled | Every 5 min |
| `update-leaderboard` | Scheduled | Every 60 sec |
| `update-xp` | Event-triggered | Per user action |
| `calculate-winner` | Event-triggered + scheduled | On close + daily |
| `anti-spam-check` | Event-triggered | Per write attempt |
| `check-achievements` | Event-triggered | Per significant action |
| `send-notification` | Event-triggered | Per relevant event |

---

## PHASE 11 — REALTIME SAFETY

### Race Conditions: How to Avoid

**Problem**: Two users vote simultaneously. Both read `agreeCount = 5`, both increment to 6, both write 6. Net result: one vote lost.

**Solution**: Use server-side increment (optimistic retry loop):
```javascript
// Attempt update with version check (Appwrite supports ifVersion parameter)
// 1. Read document + $version
// 2. Compute new value
// 3. updateDocument with { ifVersion: currentVersion }
// 4. If 409 Conflict: re-read and retry (up to 3 times)
// 5. After 3 failures: log and alert (eventual inconsistency)
```

At current Appwrite versions without native atomic increment, this optimistic retry pattern is the safest approach.

### Double Counting Prevention

Every state-mutating function that can be called multiple times (e.g., from a retry) must include an **idempotency check**:

- `update-xp`: check daily cap via collection count (re-running gives same result if cap is hit)
- `calculate-winner`: reads current `winningSide` before proceeding — safe to re-run
- `check-achievements`: checks `existingBadges` before awarding — safe to re-run

### Consistency with Realtime Subscriptions

Use the **delta realtime pattern** in Flutter providers:

```dart
// WRONG: invalidate and re-fetch entire collection on every event
ref.invalidate(debatesProvider);

// RIGHT: apply event payload directly to local state
final updatedDebate = DebateModel.fromMap(event.payload);
state = state.map((d) => d.id == updatedDebate.id ? updatedDebate : d).toList();
```

This prevents the "thundering herd" problem where 1000 concurrent users all re-fetch the full debates collection when any single debate is updated.

### Message Ordering Under Realtime

When realtime delivers a new message, do not re-sort the entire message list. Append to the end — the server timestamp guarantees ordering correctness. Only re-sort on initial load.

---

## PHASE 12 — IMPLEMENTATION PLAN

### Functions Required

| Function | Already existed? | Status |
|----------|-----------------|--------|
| `update-trending` | ✅ Yes | **Replaced** with gravity decay formula |
| `update-leaderboard` | ✅ Yes | **Replaced** with pagination fix + tiebreakers + weekly reset |
| `check-achievements` | ✅ Yes | Fixed (stat key bug) |
| `send-notification` | ✅ Yes | Unchanged |
| `gemini-summary` | ✅ Yes | Unchanged |
| `update-xp` | ❌ New | **Created** |
| `calculate-winner` | ❌ New | **Created** |
| `anti-spam-check` | ❌ New | **Created** |

### When Each Runs

```
User votes on a debate
  → [client] anti-spam-check (vote_cast) → { allowed: true }
  → [client] write to votes collection
  → [client, async] update-xp (vote_cast, userId)
  → [client, async] update-xp (receive_vote, debate.creatorId)
  → [client, async] check-achievements (userId)
  → [CRON 5min] update-trending picks up new vote counts
  → [CRON 60sec] update-leaderboard picks up new XP

User creates a debate
  → [client] anti-spam-check (debate_created)
  → [client] write to debates collection
  → [client, async] update-xp (debate_created, userId)
  → [CRON 5min] update-trending — debate enters trending pool

Debate closes (or daily audit)
  → [event/cron] calculate-winner (debateId)
    → if winner != inconclusive/tie: update-xp (debate_won, creatorId)

Monday midnight UTC
  → [CRON 60sec] update-leaderboard detects isEarlyMonday
    → Resets weeklyXp: 0 for all users
    → Rebuilds leaderboard from zeroed weeklyXp

User opens app each day
  → [client] update-xp (daily_checkin, userId)
    → Streak logic, milestone bonuses, lastVoteDate updated
```

---

## PHASE 13 — OPTIMIZATION

### Required Indexes

Add these indexes to `setup_appwrite.dart` if not already present:

| Collection | Index | Type | Fields | Purpose |
|------------|-------|------|--------|---------|
| `debates` | `status_createdat` | key | `status ASC, $createdAt DESC` | Trending query |
| `debates` | `trending_score_idx` | key | `trendingScore DESC` | Feed sort |
| `debates` | `creator_createdat` | key | `creatorId ASC, $createdAt DESC` | Daily cap check |
| `votes` | `user_createdat` | key | `userId ASC, $createdAt DESC` | Rate limit + cap |
| `comments` | `user_createdat` | key | `userId ASC, $createdAt DESC` | Rate limit + cap |
| `messages` | `sender_createdat` | key | `senderId ASC, $createdAt DESC` | Rate limit |
| `users` | `xp_idx` | key | `xp DESC` | Leaderboard ✓ already exists |
| `users` | `weekly_xp_idx` | key | `weeklyXp DESC` | Weekly leaderboard ✓ already exists |

### Fields to Cache (Hive, client-side, TTL)

| Data | TTL | Invalidation |
|------|-----|--------------|
| User profiles (other users) | 5 minutes | Profile update event |
| Leaderboard top 100 | 30 seconds | Realtime on leaderboard collection |
| Trending top 50 | 5 minutes | Realtime on trending collection |
| Category list | 1 hour | No realtime needed (rarely changes) |
| Own user profile | Real-time (subscribed) | Immediate via realtime |

### Where to Denormalize

| Currently joining | Denormalize by | Benefit |
|-------------------|----------------|---------|
| Conversation → user profiles (N+1) | Store `participantSnapshots` in conversation doc | Eliminates N+1 on DM list |
| Debate → creator username | Store `creatorUsername` in debate doc | Feed render needs no extra lookup |
| Message → sender name | Store `senderDisplayName` in message doc | Chat render needs no extra lookup |

---

## PHASE 14 — FINAL OUTPUT FORMAT

### ALGORITHMS SUMMARY

| Algorithm | Formula | Complexity |
|-----------|---------|------------|
| Trending | `engagement / (hoursOld + 2)^1.8` | O(debates in 72h window) |
| Leaderboard | Sort by `xp → winRate → streak → age` | O(n log n) over all users |
| XP | Table lookup + daily cap count query | O(1) per action |
| Reputation | `log10(xp)*100 + winRate*300 + streak*5 + debates*3` | O(1) per user update |
| Winner | Wilson Score Lower Bound (95% CI) | O(1) per debate |
| Feed Score | `trending*0.35 + category*0.25 + social*0.20 + quality*0.10 + fresh*0.10` | O(page size) |
| Anti-Spam | Count query with sliding window | O(1) per check (indexed) |

---

### FUNCTION DESIGN

| Function | Trigger | Input | Output | Side effects |
|----------|---------|-------|--------|--------------|
| `update-trending` | CRON `*/5 * * * *` | — | `{ processed, updated, trendingRows }` | Writes `trendingScore` to debates, rebuilds trending collection |
| `update-leaderboard` | CRON `* * * * *` | — | `{ success, count, totalUsers, mondayReset }` | Rebuilds leaderboard collection, resets weeklyXp on Monday |
| `update-xp` | Post-action (client) | `{ userId, action, referenceId? }` | `{ awarded, xpAwarded, newXp, newReputation }` | Updates `users.xp`, `weeklyXp`, `reputation`, `currentStreak` |
| `calculate-winner` | On debate close / CRON daily | `{ debateId }` | `{ winningSide, confidence }` | Writes `debates.winningSide`, triggers `update-xp` if winner |
| `anti-spam-check` | Pre-write (client) | `{ userId, action }` | `{ allowed, remaining, retryAfter? }` | None (read-only) |
| `check-achievements` | Post-action (client) | `{ userId }` | `{ newBadges, stats }` | Creates badge documents, triggers `send-notification` |
| `send-notification` | Event-triggered | `{ userId, title, body, type }` | `{ sent }` | Writes to notifications collection, sends FCM |

---

### DATA FLOW

```
WRITE PATH                                   READ PATH
──────────────────────────────────────────   ─────────────────────────────────
User action (vote/comment/debate)             Feed screen
  │                                             │
  ├─ [sync] anti-spam-check                     ├─ Read debates (cursor-paginated)
  │   └─ { allowed: true/false }                │   └─ + trendingScore (pre-computed)
  │                                             │
  ├─ [sync] Write to source collection          ├─ Sort by feedScore (client)
  │   (votes / comments / debates)              │
  │                                             ├─ Render with cached user profiles
  ├─ [async] update-xp                        │
  │   └─ Updates users.xp + reputation          Leaderboard screen
  │                                             │
  ├─ [async] check-achievements                 ├─ Read leaderboard collection
  │   └─ Creates badges if threshold met        │   (pre-sorted, pre-ranked)
  │                                             │
  └─ [CRON] update-trending                   Chat screen
      └─ Reads updated counts                   │
          Writes trendingScore to debates        ├─ Read messages (cursor-paginated)
          Rebuilds trending snapshot             │   ordered by $createdAt ASC
                                                 └─ Delta realtime for new messages
```

---

### PERFORMANCE RISKS

| Risk | Description | Mitigation |
|------|-------------|------------|
| **update-leaderboard write storm** | 100 `createDocument` calls sequential in one function run | Acceptable at <10K users; at scale use batch write API when available |
| **Trending nuke-and-rebuild** | Delete all 50 trending docs then create 50 new ones | Not atomic — a reader during rebuild sees empty trending; use a shadowed double-buffer at scale |
| **Anti-spam count queries** | Two count queries per action (window + velocity) | Indexed queries are fast; risk at high-QPS is function cold start latency |
| **update-xp serial writes** | User document update + streak + reputation in one function | Single `updateDocument` with all fields — one round-trip, safe |
| **calculate-winner on debate close flood** | If 1000 debates close simultaneously | Queue-friendly: each execution is independent; Appwrite handles function concurrency |

---

### SCALING RISKS (What breaks at 10K users)

| Component | Breaks at | Reason | Fix |
|-----------|-----------|--------|-----|
| `update-leaderboard` | ~5K users | 100-page pagination loop with 100 sequential `createDocument` writes ≈ 200 serial Appwrite calls | Use Appwrite bulk API; or shard into top-500 only |
| Trending rebuild | ~2K debates/hour | Delete-then-create is not atomic — clients see empty trending during rebuild | Double-buffer: write to `trending_new`, then atomically swap |
| `anti-spam-check` cold starts | ~1K concurrent actions | Function cold start adds 500–2000ms latency | CRON keep-alive ping every 5 min |
| Realtime full-refresh pattern | ~500 concurrent users | Each event triggers collection re-fetch | Already identified — fix with delta realtime pattern |
| Client-side feed sort | ~200 items | Sorting 200 debates in Flutter on every build | Move to server at 200+ items; use `feedScore` index |

---

### BUG RISKS

| Bug | Location | Risk Level | Status |
|-----|----------|------------|--------|
| Double-scoring bug | `update-trending` (old version) | High — leaderboard never matched displayed scores | **Fixed** |
| 100-user leaderboard cap | `update-leaderboard` (old version) | High — users ranked 101+ never appeared | **Fixed** |
| `stats[badgeId]` instead of `stats[condition.stat]` | `check-achievements` (old version) | High — most badges never awarded | **Fixed** |
| Weekly rank = all-time rank | `update-leaderboard` (old version) | Medium — weekly competition meaningless | **Fixed** |
| `weeklyXp` never reset | `update-leaderboard` (old version) | High — weekly leaderboard grows monotonically | **Fixed** |
| No user validation before badge loop | `check-achievements` (old version) | Medium — arbitrary userId probing | **Fixed** |
| `agreeCount`/`disagreeCount` race on vote | All functions | Medium — counts can drift by ±1 at concurrency | Mitigated via optimistic retry pattern (see Phase 11) |
| Feed score weights hardcoded in client | `leaderboard_provider.dart` | Low — weights can't be tuned without app update | Move to remote config at scale |

---

### FINAL IMPROVEMENTS — PRODUCTION LEVEL

**Immediate (before launch)**:
1. Add compound indexes listed in Phase 13 via `setup_appwrite.dart`
2. Register all new functions (`update-xp`, `calculate-winner`, `anti-spam-check`) in Appwrite console with correct environment variables
3. Set CRON triggers: `update-trending` → `*/5 * * * *`, `update-leaderboard` → `* * * * *`
4. Call `anti-spam-check` from the Flutter client before every write (vote, comment, debate, message)
5. Call `update-xp` asynchronously from the Flutter client after every successful write

**Short-term (first month)**:
6. Implement delta realtime in all Riverpod providers (highest leverage performance fix)
7. Add Hive cache layer for user profiles and leaderboard with TTL
8. Denormalize `creatorUsername` into the debates document (eliminates N+1 on feed render)
9. Denormalize `participantSnapshots` into conversations (eliminates N+1 on DM list)
10. Switch feed pagination from offset to cursor-based (`Query.cursorAfter`)

**Medium-term (1–3 months)**:
11. Implement double-buffer trending rebuild (write `trending_staging`, then rename) to eliminate empty-trending flash
12. Move feed ranking to a `compute-feed` server function with per-user cache (60s TTL)
13. Add notification batching for likes and votes (one notification per hour per debate, not per event)
14. Implement `idempotencyKey` on messages to prevent duplicate sends on retry

**Architecture milestone — 50K users**:
15. Deploy event-router function (routes all DB writes to downstream aggregator functions)
16. Introduce `debates_feed_projection` collection (pre-computed feed with denormalized creator data)
17. Configure CDN for all public storage bucket reads (avatar images especially)
18. Upgrade to Appwrite Cloud Pro or self-hosted cluster (single node cannot handle 50K WebSocket connections)

---

*Cross-reference: `scripts/load_test_plan.md` for validation scenarios per tier.*  
*Cross-reference: `scripts/architecture_100k.md` for the full 4-phase scaling blueprint.*
