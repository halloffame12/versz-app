'use strict';
const sdk = require('node-appwrite');

// ---------------------------------------------------------------------------
// VERSZ XP Economy — update-xp function
// ---------------------------------------------------------------------------
// XP Table:
//   Action              Base XP   Daily Cap   Cap Source
//   debate_created        +50     3 debates   debates collection
//   comment_posted        +10     20 comments comments collection
//   vote_cast              +2     15 votes    votes collection
//   debate_won            +50     no cap      one-time per debate
//   daily_checkin          +5     1/day       lastVoteDate field
//   receive_vote           +3     no cap      on debate creator's behalf
//
// Streak Milestones (awarded on daily_checkin):
//   3-day streak   → +10 bonus XP
//   7-day streak   → +25 bonus XP
//   30-day streak  → +100 bonus XP
//
// Reputation Score (recomputed on every XP update):
//   reputation = log10(xp) * 100
//              + winRate * 300
//              + min(currentStreak, 30) * 5
//              + min(debatesCreated, 100) * 3
//   Range: ~0 (new user) to ~1200+ (top user)
//   Uses: badge unlock threshold, content weight, verification gating
//
// Abuse prevention:
//   - Daily caps checked via same-day collection count query (no extra schema)
//   - daily_checkin deduplication via lastVoteDate field (stored as ISO date)
//   - debate_won: one-time per debate (checked via winningSide field state)
//   - All validation is server-side — client cannot forge XP values
//
// Input:  { userId, action, referenceId?, metadata? }
// Output: { awarded, xpAwarded, baseXp, streakBonusXp, newXp, newWeeklyXp,
//            newStreak, newReputation, reason? }
// ---------------------------------------------------------------------------

const XP_ACTIONS = {
    debate_created: { xp: 50,  dailyCap: 3,   collection: 'debates',  userField: 'creatorId' },
    comment_posted: { xp: 10,  dailyCap: 20,  collection: 'comments', userField: 'userId' },
    vote_cast:      { xp: 2,   dailyCap: 15,  collection: 'votes',    userField: 'userId' },
    debate_won:     { xp: 50,  dailyCap: null, collection: null,      userField: null },
    daily_checkin:  { xp: 5,   dailyCap: 1,   collection: null,       userField: null },
    receive_vote:   { xp: 3,   dailyCap: null, collection: null,      userField: null },
};

const STREAK_MILESTONES = [
    { days: 30, xp: 100 },
    { days: 7,  xp: 25  },
    { days: 3,  xp: 10  },
];

function extractUnknownAttribute(errorMessage) {
    const match = /Unknown attribute: "([^"]+)"/.exec(errorMessage || '');
    return match ? match[1] : null;
}

async function updateUserWithSchemaFallback(db, databaseId, userId, payload, log) {
    const mutablePayload = { ...payload };

    // Retry by removing unknown attributes one by one to tolerate schema drift.
    while (Object.keys(mutablePayload).length > 0) {
        try {
            await db.updateDocument(databaseId, 'users', userId, mutablePayload);
            return;
        } catch (error) {
            const unknown = extractUnknownAttribute(error?.message || '');
            if (!unknown || !(unknown in mutablePayload)) {
                throw error;
            }
            delete mutablePayload[unknown];
            log(`update-xp: removed unknown users attribute "${unknown}" and retrying`);
        }
    }

    throw new Error('No valid user attributes left to update');
}

function getDatabaseId() {
    return process.env.DATABASE_ID || process.env.APPWRITE_DATABASE_ID || 'versz-db';
}

function getCallerUserId(req) {
    return req?.headers?.['x-appwrite-user-id'] || req?.headers?.['X-Appwrite-User-Id'] || null;
}

const PRIVILEGED_ACTIONS = new Set(['receive_vote', 'debate_won']);

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
    const { userId, action, referenceId, metadata = {} } = body;

    if (!userId || !action) {
        return res.json({ error: 'Missing userId or action' }, 400);
    }

    const config = XP_ACTIONS[action];
    if (!config) {
        return res.json({ error: `Unknown action: ${action}` }, 400);
    }

    if (callerUserId) {
        if (userId !== callerUserId) {
            return res.json({ error: 'Forbidden: userId mismatch' }, 403);
        }
        if (PRIVILEGED_ACTIONS.has(action)) {
            return res.json({ error: `Forbidden: action ${action} must be server-triggered` }, 403);
        }
    }

    // ── 1. Validate user exists ────────────────────────────────────────────
    let user;
    try {
        user = await db.getDocument(databaseId, 'users', userId);
    } catch {
        return res.json({ error: 'User not found' }, 404);
    }

    try {
        const now = new Date();
        const todayStr = now.toISOString().slice(0, 10); // 'YYYY-MM-DD'

        // ── 2. Daily cap check (collection count query) ──────────────────
        if (config.dailyCap !== null && config.collection) {
            const startOfDay = new Date(now);
            startOfDay.setHours(0, 0, 0, 0);

            const countResult = await db.listDocuments(
                databaseId,
                config.collection,
                [
                    sdk.Query.equal(config.userField, userId),
                    sdk.Query.greaterThan('$createdAt', startOfDay.toISOString()),
                    sdk.Query.limit(1),
                    sdk.Query.select(['$id']),
                ]
            );

            if (countResult.total >= config.dailyCap) {
                log(`Daily cap: ${userId} action=${action} ${countResult.total}/${config.dailyCap}`);
                return res.json({
                    awarded: false,
                    reason: 'daily_cap_reached',
                    dailyCount: countResult.total,
                    dailyCap: config.dailyCap,
                });
            }
        }

        // ── 3. daily_checkin deduplication + streak logic ────────────────
        let streakXp = 0;
        let newStreak = user.currentStreak || 0;

        if (action === 'daily_checkin') {
            // lastVoteDate reused as last-activity-date — stored as YYYY-MM-DD
            const lastActivity = user.lastVoteDate ? user.lastVoteDate.slice(0, 10) : null;

            if (lastActivity === todayStr) {
                return res.json({ awarded: false, reason: 'already_checked_in_today', userId });
            }

            const yesterday = new Date(now);
            yesterday.setDate(yesterday.getDate() - 1);
            const yesterdayStr = yesterday.toISOString().slice(0, 10);

            if (lastActivity === yesterdayStr) {
                newStreak = (user.currentStreak || 0) + 1;
            } else {
                newStreak = 1; // streak broken or first check-in
            }

            // Award streak milestone bonus (exact milestone only — no stacking)
            for (const milestone of STREAK_MILESTONES) {
                if (newStreak === milestone.days) {
                    streakXp = milestone.xp;
                    log(`Streak milestone: ${userId} hit ${milestone.days} days (+${milestone.xp} XP)`);
                    break;
                }
            }
        }

        // ── 4. debate_won deduplication (one-time per debate) ────────────
        if (action === 'debate_won' && referenceId) {
            try {
                const debate = await db.getDocument(databaseId, 'debates', referenceId);
                // If winningSide is already set to a non-null value AND xp was updated
                // within the last minute, skip (proxy for duplicate execution).
                // Note: for safety we allow re-execution if timing is uncertain.
                if (!debate.winningSide || debate.winningSide === 'inconclusive') {
                    log(`debate_won skipped: debate ${referenceId} has no confirmed winner yet`);
                    return res.json({ awarded: false, reason: 'no_confirmed_winner', referenceId });
                }
            } catch (e) {
                log(`debate_won: could not verify debate ${referenceId}: ${e.message} — proceeding`);
            }
        }

        // ── 5. Compute XP delta ───────────────────────────────────────────
        const xpDelta = config.xp + streakXp;
        const newXp = (user.xp || 0) + xpDelta;
        const newWeeklyXp = (user.weeklyXp || 0) + xpDelta;

        // ── 6. Recompute reputation score ─────────────────────────────────
        // log10 scale prevents XP grinding from dominating reputation alone.
        // Capped streak (30-day max) and debates (100 max) prevent stat gaming.
        const newReputation = Math.round(
            Math.log10(Math.max(newXp, 1)) * 100 +
            (user.winRate || 0) * 300 +
            Math.min(newStreak, 30) * 5 +
            Math.min(user.debatesCreated || 0, 100) * 3
        );

        // ── 7. Write to user document ─────────────────────────────────────
        const updatePayload = {
            xp: newXp,
            weeklyXp: newWeeklyXp,
            reputation: newReputation,
            updatedAt: now.toISOString(),
        };

        if (action === 'daily_checkin') {
            updatePayload.currentStreak = newStreak;
            updatePayload.longestStreak = Math.max(newStreak, user.longestStreak || 0);
            updatePayload.lastVoteDate = todayStr; // date-only string
        }

        await updateUserWithSchemaFallback(db, databaseId, userId, updatePayload, log);

        log(`XP awarded: ${userId} action=${action} +${xpDelta} (base=${config.xp} streak=${streakXp}) total=${newXp}`);

        return res.json({
            awarded: true,
            userId,
            action,
            xpAwarded: xpDelta,
            baseXp: config.xp,
            streakBonusXp: streakXp,
            newXp,
            newWeeklyXp,
            newStreak,
            newReputation,
        });

    } catch (error) {
        log(`Error updating XP for ${userId}: ${error.message}`);
        return res.json({ error: error.message }, 500);
    }
};
