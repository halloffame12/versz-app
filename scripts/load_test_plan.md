# Versz Load-Test Harness Plan

## Overview
Three tiers of load testing targeting 100, 1000, and 5000 concurrently active users. Each tier has scenarios, pass/fail SLOs, and observation checkpoints. All tests assume traffic is distributed across debates, messaging, rooms, and voting — matching real user behavior ratios derived from the current feature set.

---

## Traffic Distribution Model (Realistic Mix)

| Action | % of requests |
|---|---|
| Fetch debate feed (list) | 30% |
| Read debate detail | 18% |
| Cast vote / like | 15% |
| Send/receive message | 14% |
| Navigate rooms / join | 8% |
| Load notifications | 7% |
| Post comment | 5% |
| Create debate | 2% |
| Profile view | 1% |

---

## Tier 1 — 100 Concurrent Users

### Goal
Establish a stable baseline. No errors, no latency spikes, realtime works correctly.

### Scenarios

**S1 — Debate feed scroll + vote (happy path)**
- 30 virtual users open the for-you feed and scroll two pages (20 + 20 debates).
- 50% of users cast a vote on the first debate they see.
- Assertions: all list responses ≤ 800ms p95; vote writes succeed 100%.

**S2 — Direct message conversation**
- 10 pairs of users (20 total) open a conversation and exchange 5 messages each over 60 seconds.
- Realtime delivery: receiver UI must reflect sent message within 2000ms (wall time).
- Assertions: no duplicate messages in conversation provider; no message with status stuck at 'sending' after 5s.

**S3 — Room join storm**
- 40 users each join a different room within 30s, then post 1 message to the room.
- Assertions: `memberCount` on each room document equals actual `room_members` document count (drift check).

**S4 — Notification delivery**
- 10 users each trigger a follow action (creates notification for followee).
- Assertions: all 10 notification documents created; FCM send function invoked 10 times (check function logs); no 500 errors.

### Pass/Fail SLOs (Tier 1)

| Metric | Pass | Fail |
|---|---|---|
| Debate list p95 latency | ≤ 800ms | > 1200ms |
| Vote write p99 latency | ≤ 1500ms | > 3000ms |
| Error rate (all requests) | < 0.1% | > 0.5% |
| Realtime message delivery | ≤ 2000ms p90 | > 4000ms |
| memberCount drift | Zero | Any mismatch |
| Function error rate | 0% | > 0% |

---

## Tier 2 — 1000 Concurrent Users

### Goal
Identify the first degradation point. Discover realtime amplification and N+1 query pressure.

### Scenarios

**S5 — Trending feed under concurrent write pressure**
- 800 users continuously scroll the trending feed (re-sorted by trendingScore).
- 200 users simultaneously cast votes (triggering client-side debate document updates).
- Every realtime subscription in `debate_provider` fires a debounced refresh per user.
- Predicted bottleneck: 200 vote writes → 200 realtime events → up to 800 users each re-fetching the debates list (page size 20). That is up to 800 × 2 = 1600 reads per vote burst.
- Assertions: no user sees stale data > 3s after a vote lands; debate list p95 ≤ 2000ms.

**S6 — Conversation list + unread counts**
- 500 users each have 20 conversations. 100 users simultaneously send messages.
- Each send triggers an `unreadCounts` JSON read-modify-write on the chat document.
- Predicted bottleneck: concurrent unread update race on the same chat document.
- Assertions: unread counts must converge to correct values within 5s; no lost unread increments > 2%.

**S7 — Achievement fanout**
- 100 users each create their 5th debate (triggering `check-achievements`).
- Assertions: all 100 users receive the 'debater' badge within 10s; no duplicate badge documents.

**S8 — Leaderboard read under rebuild**
- `update-leaderboard` function runs while 500 users are reading the leaderboard collection.
- Function clears and rebuilds (delete-all-then-insert).
- Assertions: no user gets a 404 or empty leaderboard during the 10–30s rebuild window.

### Pass/Fail SLOs (Tier 2)

| Metric | Pass | Fail |
|---|---|---|
| Debate list p95 latency | ≤ 2000ms | > 4000ms |
| Trending score staleness | < 3s after vote | > 10s |
| Error rate (all requests) | < 0.5% | > 2% |
| Unread count convergence | < 2% loss | > 5% loss |
| Badge award latency | < 10s p90 | > 30s |
| Leaderboard empty window | 0s | > 5s |
| Realtime p95 delivery | ≤ 3000ms | > 6000ms |

---

## Tier 3 — 5000 Concurrent Users

### Goal
Establish hard system limits and confirm which architectural changes are required before reaching this scale.

### Scenarios

**S9 — Full session simulation (all features)**
- 5000 users executing the traffic distribution mix above for 15 minutes.
- Each user has a session, reads feed, votes, messages at least one other user.
- Expected bottleneck cascade: realtime connection pool saturation → per-user refresh storms → Appwrite database connection exhaustion.

**S10 — Realtime subscription pressure**
- Each of 5000 clients holds open 3–5 realtime channel subscriptions simultaneously:
  - debates channel (all users)
  - notifications channel (all users)
  - messages/chats channel (all users)
  - rooms channel (room members)
- Total open WebSocket-equivalent connections: ~15,000–25,000.
- Assertions: connection establishment < 3s; no connection drops under steady-state load.

**S11 — Message throughput**
- 500 conversation pairs (1000 users) each exchange 1 message every 5 seconds for 5 minutes.
- That is 100 messages/second sustained.
- Predicted constraint: per-message `unreadCounts` read-modify-write, plus conversations list refresh per event.
- Assertions: message delivery p99 ≤ 5000ms; no messages lost.

**S12 — Trending and leaderboard rebuild under full load**
- Both `update-trending` and `update-leaderboard` fire simultaneously during peak S9 load.
- Assertions: no spike > 50% in error rate during rebuild; function completes < 60s.

### Pass/Fail SLOs (Tier 3)

| Metric | Pass | Fail |
|---|---|---|
| Feed list p95 latency | ≤ 3000ms | > 8000ms |
| Error rate | < 1% | > 5% |
| Message throughput | ≥ 80 msg/s sustained | < 50 msg/s |
| Realtime connection drop rate | < 0.5% | > 2% |
| Function timeout rate | < 1% | > 5% |
| Database 503/429 rate | 0% | > 0.1% |

---

## Tooling Recommendations

| Tool | Purpose |
|---|---|
| k6 (Grafana) | HTTP scenario scripting with JS, built-in thresholds |
| k6 browser extension | Client WebSocket/SSE subscription simulation |
| Appwrite console metrics | Real-time request counts, error rates, function execution logs |
| Firebase Performance Monitoring | End-to-end mobile latency (already wired via FCM project) |
| Custom Dart integration test suite | Device-side message delivery timing (complement server metrics) |

---

## Pre-Test Checklist

- [ ] `setSelfSigned(status: true)` removed from `AppwriteService` before any load test
- [ ] Test environment pointed at a staging Appwrite instance, not production
- [ ] Function environment variables set in staging
- [ ] `update-leaderboard` and `update-trending` scheduled triggers configured
- [ ] Seed minimum 200 debate documents across all 10 categories
- [ ] Seed minimum 500 user accounts with varying XP/activity levels
- [ ] Appwrite scaling plan reviewed (connection limits, function concurrency limits)

---

## Known Pre-Existing Risks That Will Cause Tier 2/3 Failures Without Architectural Changes

1. **Client-side `memberCount` counter** — concurrent joins/leaves will produce lost updates at ~10+ concurrent operations. Fix: atomic server-function increment.
2. **Full-list realtime refresh** — each vote event triggers a 20-debate list reload per connected user. At 1000 users + 50 votes/min = 50,000 list reads/min. Fix: delta-apply realtime events (update only the changed debate in state).
3. **`unreadCounts` JSON race** — concurrent read-modify-write on same chat document loses intermediate increments. Fix: per-sender atomic counter or server-function merge.
4. **Leaderboard blank window** — delete-all + rebuild creates a gap window. Fix: shadow collection swap (write to temp, rename atomically).
5. **N+1 user profile hydration** — conversations list fetches each participant profile sequentially. Fix: batch getDocuments or cache user profiles with short TTL.
