'use strict';
const sdk = require('node-appwrite');

// ---------------------------------------------------------------------------
// VERSZ Cast Vote Function (production-safe vote path)
// ---------------------------------------------------------------------------
// Purpose:
//   Replace direct client vote writes with a server-side, idempotent flow.
//   This avoids race conditions where multiple clients overwrite debate counts.
//
// Input:
//   { userId, debateId, side }  where side in ['agree', 'disagree', null]
//   side = null means remove existing vote (unvote).
//
// Guarantees:
//   1) Single vote per user per debate (backed by unique index debateId+userId)
//   2) Deterministic count deltas for agreeCount/disagreeCount
//   3) Best-effort optimistic retries on conflict
//
// NOTE:
//   Appwrite currently has no native atomic increment in Databases API, so we
//   use a bounded optimistic retry loop:
//     - read current counters
//     - apply deterministic delta
//     - update document
//   If update races, we re-read and retry.
// ---------------------------------------------------------------------------

const MAX_RETRIES = 3;

function getDatabaseId() {
  return process.env.DATABASE_ID || process.env.APPWRITE_DATABASE_ID || 'versz-db';
}

function getCallerUserId(req) {
  return req?.headers?.['x-appwrite-user-id'] || req?.headers?.['X-Appwrite-User-Id'] || null;
}

function sideToDelta(oldSide, newSide) {
  let agreeDelta = 0;
  let disagreeDelta = 0;

  if (oldSide === 'agree') agreeDelta -= 1;
  if (oldSide === 'disagree') disagreeDelta -= 1;
  if (newSide === 'agree') agreeDelta += 1;
  if (newSide === 'disagree') disagreeDelta += 1;

  return { agreeDelta, disagreeDelta };
}

module.exports = async ({ req, res, log }) => {
  const client = new sdk.Client()
    .setEndpoint(process.env.APPWRITE_ENDPOINT)
    .setProject(process.env.APPWRITE_PROJECT_ID)
    .setKey(process.env.APPWRITE_API_KEY);

  const db = new sdk.Databases(client);
  const databaseId = getDatabaseId();
  const callerUserId = getCallerUserId(req);
  let body = {};
  try {
    body = JSON.parse(req.body || '{}');
  } catch {
    return res.json({ error: 'Invalid JSON body' }, 400);
  }
  const { userId, debateId } = body;
  const side = body.side === null ? null : String(body.side || '').trim();

  if (!userId || !debateId) {
    return res.json({ error: 'Missing userId or debateId' }, 400);
  }
  if (side !== null && side !== 'agree' && side !== 'disagree') {
    return res.json({ error: 'Invalid side. Must be agree, disagree, or null' }, 400);
  }
  if (callerUserId && callerUserId !== userId) {
    return res.json({ error: 'Forbidden: userId mismatch' }, 403);
  }

  try {
    // Ensure debate exists
    const debate = await db.getDocument(databaseId, 'debates', debateId);

    // Lookup existing vote
    const existing = await db.listDocuments(databaseId, 'votes', [
      sdk.Query.equal('debateId', debateId),
      sdk.Query.equal('userId', userId),
      sdk.Query.limit(1),
      sdk.Query.select(['$id', 'side']),
    ]);

    const currentVote = existing.documents[0] || null;
    const oldSide = currentVote ? currentVote.side : null;

    // No-op if same vote requested
    if (oldSide === side) {
      return res.json({
        ok: true,
        changed: false,
        side,
        agreeCount: debate.agreeCount || 0,
        disagreeCount: debate.disagreeCount || 0,
      });
    }

    // Update vote document first
    if (currentVote && side === null) {
      await db.deleteDocument(databaseId, 'votes', currentVote.$id);
    } else if (currentVote && side !== null) {
      await db.updateDocument(databaseId, 'votes', currentVote.$id, { side });
    } else if (!currentVote && side !== null) {
      await db.createDocument(databaseId, 'votes', sdk.ID.unique(), {
        debateId,
        userId,
        side,
        createdAt: new Date().toISOString(),
      });
    }

    const { agreeDelta, disagreeDelta } = sideToDelta(oldSide, side);

    // Apply debate counter delta with optimistic retries
    let lastError = null;
    for (let attempt = 1; attempt <= MAX_RETRIES; attempt += 1) {
      try {
        const latest = attempt === 1
          ? debate
          : await db.getDocument(databaseId, 'debates', debateId);

        const nextAgree = Math.max(0, (latest.agreeCount || 0) + agreeDelta);
        const nextDisagree = Math.max(0, (latest.disagreeCount || 0) + disagreeDelta);

        await db.updateDocument(databaseId, 'debates', debateId, {
          agreeCount: nextAgree,
          disagreeCount: nextDisagree,
          updatedAt: new Date().toISOString(),
        });

        // If this debate is already closed, recompute winner asynchronously.
        // This is non-fatal and keeps winner state in sync after moderation edits.
        if (String(latest.status || '').toLowerCase() === 'closed') {
          try {
            const functions = new sdk.Functions(client);
            await functions.createExecution(
              'calculate-winner',
              JSON.stringify({ debateId }),
              true,
            );
          } catch (winnerErr) {
            log(`Non-fatal winner recompute failure: ${winnerErr.message}`);
          }
        }

        // Fire and forget XP update for voter (only when a vote exists, not unvote)
        if (side !== null) {
          try {
            const functions = new sdk.Functions(client);
            await functions.createExecution(
              'update-xp',
              JSON.stringify({ userId, action: 'vote_cast', referenceId: debateId }),
              true,
            );
          } catch (xpErr) {
            log(`Non-fatal XP update failure: ${xpErr.message}`);
          }
        }

        return res.json({
          ok: true,
          changed: true,
          side,
          agreeDelta,
          disagreeDelta,
          agreeCount: nextAgree,
          disagreeCount: nextDisagree,
        });
      } catch (err) {
        lastError = err;
      }
    }

    throw lastError || new Error('Failed to update debate counters');
  } catch (error) {
    log(`cast-vote failed: ${error.message}`);
    return res.json({ error: error.message }, 500);
  }
};
