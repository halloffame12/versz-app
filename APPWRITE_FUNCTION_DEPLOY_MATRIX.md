# Appwrite Function Deploy Matrix (Versz)

This is the exact deploy/wiring checklist for current backend hardening.

## Global Runtime Defaults

- Runtime: `Node.js 20` (or latest Appwrite Node runtime compatible with `node-appwrite@^14`)
- Entry point for all functions below: `src/index.js`
- Install command: `npm install`
- Build command: none

## Shared Environment Variables

Set these on all functions unless marked optional:

- `APPWRITE_ENDPOINT` = `https://sgp.cloud.appwrite.io/v1`
- `APPWRITE_PROJECT_ID` = your project id
- `APPWRITE_API_KEY` = server key with minimum required scopes
- `DATABASE_ID` = `versz-db`

Optional/specific:
- `GEMINI_API_KEY` (gemini-summary only)
- `FIREBASE_SERVICE_JSON` (send-notification only)

## Function Matrix

| Function ID | Source Folder | Trigger Type | Schedule / Invocation | Required Env | Notes |
|---|---|---|---|---|---|
| `send-notification` | `functions/send-notification` | Event + Callable | Called from app/functions when needed | Shared + `FIREBASE_SERVICE_JSON` | FCM push delivery |
| `gemini-summary` | `functions/gemini-summary` | Callable | On-demand summary generation | Shared + `GEMINI_API_KEY` | AI summary generation |
| `update-trending` | `functions/update-trending` | Scheduled | `*/5 * * * *` | Shared | Recompute trending scores/snapshot |
| `update-leaderboard` | `functions/update-leaderboard` | Scheduled | `* * * * *` | Shared | Rebuild leaderboard snapshot |
| `check-achievements` | `functions/check-achievements` | Callable/Event-driven | Post-action awards | Shared | Safe idempotent badge checks |
| `anti-spam-check` | `functions/anti-spam-check` | Callable | Pre-write checks from app | Shared | Fail-open anti-abuse gate |
| `cast-vote` | `functions/cast-vote` | Callable | App vote path | Shared | Server-authoritative vote mutation |
| `update-xp` | `functions/update-xp` | Callable | Post-action XP updates | Shared | XP economy and caps |
| `calculate-winner` | `functions/calculate-winner` | Callable + Optional Scheduled | On debate close, optional daily backstop | Shared | Wilson confidence winner computation |

## Required App Wiring (already in code)

- `anti-spam-check` invoked in:
  - `lib/providers/debate_provider.dart`
  - `lib/providers/message_provider.dart`
- `cast-vote` invoked in:
  - `lib/providers/debate_provider.dart`
- `update-xp` invoked in:
  - `lib/providers/debate_provider.dart`
  - `functions/cast-vote/src/index.js`
- `calculate-winner` invoked safely for closed debates in:
  - `functions/cast-vote/src/index.js`

## Appwrite Console Steps (per function)

1. Create Function with exact ID from matrix.
2. Set runtime and source root to the function folder.
3. Confirm entrypoint is `src/index.js`.
4. Add env vars from matrix.
5. Deploy.
6. Configure trigger:
   - Scheduled: set cron expression.
   - Callable/Event-driven: no cron; ensure app/function call path exists.

## Post-Deploy Smoke Checks

Run each from Appwrite console execution panel:

- `anti-spam-check` body:
  - `{ "userId": "test-user", "action": "vote_cast" }`
- `cast-vote` body:
  - `{ "userId": "test-user", "debateId": "test-debate", "side": "agree" }`
- `update-xp` body:
  - `{ "userId": "test-user", "action": "vote_cast", "referenceId": "test-debate" }`
- `calculate-winner` body:
  - `{ "debateId": "test-debate" }`

Expected: non-500 responses and structured JSON payloads.

## Security Note

Rotate any previously exposed API key immediately and re-run function env updates with the new key.
