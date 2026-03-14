'use strict';
const sdk = require('node-appwrite');

// ---------------------------------------------------------------------------
// VERSZ Anti-Spam Algorithm — anti-spam-check function
// ---------------------------------------------------------------------------
// Implements server-side rate limiting using count queries on existing
// collections. Zero schema changes required.
//
// Rate limits (per user):
//   Action              Window    Limit   Penalty
//   vote_cast           1 hour    30      15-min soft block
//   comment_posted      1 hour    15      30-min soft block
//   debate_created      24 hours  5       24-hour soft block
//   message_sent        1 hour    100     1-hour soft block
//
// Velocity detection (bot pattern):
//   If a user performs the same action 10+ times within 60 seconds,
//   they are flagged as a potential bot and soft-blocked for 5 minutes.
//   This catches automation scripts that fire many requests quickly.
//
// Implementation layer: Appwrite Function called from client before writes.
//   Client checks → [anti-spam-check function] → { allowed: bool }
//   If allowed: proceed with write.
//   If blocked: show cooldown UI — do NOT write.
//
//   This is more robust than client-only validation (bypassable) and
//   more flexible than database rules (cannot express time-window logic).
//   For critical actions (votes), also enforce at the database permission
//   level as a second layer.
//
// Fail-open design: If the function errors or times out, it returns
//   { allowed: true } so a connectivity issue never blocks legitimate users.
//   This is a deliberate tradeoff — spam is preferable to service disruption.
//   For higher security, flip to fail-closed and accept false denials.
//
// Input:  { userId, action }
// Output: { allowed, action, count?, remaining?, reason?, retryAfter? }
// ---------------------------------------------------------------------------

const RATE_LIMITS = {
    vote_cast: {
        collection: 'votes',
        userField: 'userId',
        windowMs: 60 * 60 * 1000,        // 1 hour
        limit: 30,
        penaltyMs: 15 * 60 * 1000,       // 15-min soft block
    },
    comment_posted: {
        collection: 'comments',
        userField: 'userId',
        windowMs: 60 * 60 * 1000,
        limit: 15,
        penaltyMs: 30 * 60 * 1000,       // 30-min soft block
    },
    debate_created: {
        collection: 'debates',
        userField: 'creatorId',
        windowMs: 24 * 60 * 60 * 1000,   // 24 hours
        limit: 5,
        penaltyMs: 24 * 60 * 60 * 1000,  // 24-hour soft block
    },
    message_sent: {
        collection: 'messages',
        userField: 'senderId',
        windowMs: 60 * 60 * 1000,
        limit: 100,
        penaltyMs: 60 * 60 * 1000,       // 1-hour soft block
    },
};

// Velocity: N actions in V milliseconds = bot pattern
const VELOCITY_WINDOW_MS = 60 * 1000; // 60 seconds
const VELOCITY_LIMIT = 10;            // 10 identical actions/minute = suspicious

function getDatabaseId() {
    return process.env.DATABASE_ID || process.env.APPWRITE_DATABASE_ID || 'versz-db';
}

function getCallerUserId(req) {
    return req?.headers?.['x-appwrite-user-id'] || req?.headers?.['X-Appwrite-User-Id'] || null;
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
    const { userId, action } = body;

    if (!userId || !action) {
        return res.json({ error: 'Missing userId or action' }, 400);
    }
    if (callerUserId && callerUserId !== userId) {
        return res.json({ error: 'Forbidden: userId mismatch' }, 403);
    }

    const config = RATE_LIMITS[action];
    if (!config) {
        // Unknown action type — allow it but log for monitoring
        log(`Unknown action type '${action}' from user ${userId} — allowed (unknown action)`);
        return res.json({ allowed: true, reason: 'unknown_action_allowed' });
    }

    try {
        const now = Date.now();

        // ── 1. Rate limit check (sliding window) ──────────────────────────
        // Uses Appwrite's server-side .total for efficiency — only returns
        // the count metadata, not the actual documents.
        const windowStart = new Date(now - config.windowMs).toISOString();

        const countResult = await db.listDocuments(
            databaseId,
            config.collection,
            [
                sdk.Query.equal(config.userField, userId),
                sdk.Query.greaterThan('$createdAt', windowStart),
                sdk.Query.limit(1),
                sdk.Query.select(['$id']),
            ]
        );

        const actionCount = countResult.total;

        if (actionCount >= config.limit) {
            const retryAfter = new Date(now + config.penaltyMs).toISOString();
            log(`Rate limit hit: ${userId} action=${action} count=${actionCount}/${config.limit} retryAfter=${retryAfter}`);
            return res.json({
                allowed: false,
                reason: 'rate_limit_exceeded',
                action,
                count: actionCount,
                limit: config.limit,
                retryAfter,
            });
        }

        // ── 2. Velocity check (bot/automation detection) ──────────────────
        // If the user fired this action 10+ times in the last 60 seconds,
        // flag as bot regardless of the hourly limit.
        const velocityStart = new Date(now - VELOCITY_WINDOW_MS).toISOString();

        const velocityResult = await db.listDocuments(
            databaseId,
            config.collection,
            [
                sdk.Query.equal(config.userField, userId),
                sdk.Query.greaterThan('$createdAt', velocityStart),
                sdk.Query.limit(1),
                sdk.Query.select(['$id']),
            ]
        );

        if (velocityResult.total >= VELOCITY_LIMIT) {
            const retryAfter = new Date(now + 5 * 60 * 1000).toISOString(); // 5-min cooldown
            log(`Velocity limit hit: ${userId} action=${action} ${velocityResult.total} actions/min`);
            return res.json({
                allowed: false,
                reason: 'velocity_limit_exceeded',
                action,
                actionsPerMinute: velocityResult.total,
                velocityLimit: VELOCITY_LIMIT,
                retryAfter,
            });
        }

        // ── 3. All checks passed ───────────────────────────────────────────
        return res.json({
            allowed: true,
            action,
            count: actionCount,
            limit: config.limit,
            remaining: config.limit - actionCount - 1, // -1 accounts for the pending action
        });

    } catch (error) {
        // Fail-open: connectivity or function errors must not block users.
        // Deliberately allow the action and log the error for monitoring.
        log(`Error in anti-spam-check for ${userId} action=${action}: ${error.message} — fail-open`);
        return res.json({ allowed: true, reason: 'check_error_fail_open' });
    }
};
