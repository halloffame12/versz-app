const sdk = require('node-appwrite');

const BADGE_CONDITIONS = {
    firstDebate: { threshold: 1, name: 'First Debate', stat: 'debates' },
    debater: { threshold: 5, name: 'Debater', stat: 'debates' },
    commentator: { threshold: 10, name: 'Commentator', stat: 'comments' },
    voter: { threshold: 20, name: 'Voter', stat: 'votes' },
};

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
    const { userId } = body;

    if (!userId) {
        return res.json({ error: 'Missing userId' }, 400);
    }
    if (callerUserId && callerUserId !== userId) {
        return res.json({ error: 'Forbidden: userId mismatch' }, 403);
    }

    // Validate userId is a real user. Reject if not found (prevents
    // calling this function with arbitrary IDs to probe badge state).
    try {
        await db.getDocument(databaseId, 'users', userId);
    } catch (e) {
        return res.json({ error: 'User not found' }, 404);
    }

    try {
        // Use limit(1) for network efficiency — Appwrite still returns the
        // accurate server-side `.total` count regardless of limit value.
        const [debatesResponse, commentsResponse, votesResponse] = await Promise.all([
            db.listDocuments(databaseId, 'debates', [
                sdk.Query.equal('creatorId', userId),
                sdk.Query.limit(1),
                sdk.Query.select(['$id']),
            ]),
            db.listDocuments(databaseId, 'comments', [
                sdk.Query.equal('userId', userId),
                sdk.Query.limit(1),
                sdk.Query.select(['$id']),
            ]),
            db.listDocuments(databaseId, 'votes', [
                sdk.Query.equal('userId', userId),
                sdk.Query.limit(1),
                sdk.Query.select(['$id']),
            ]),
        ]);

        // Map each stat key to its server-reported total. Each badge condition
        // declares which stat it compares against via the 'stat' property.
        const stats = {
            debates: debatesResponse.total,
            comments: commentsResponse.total,
            votes: votesResponse.total,
        };

        const existingBadges = await db.listDocuments(databaseId, 'badges', [
            sdk.Query.equal('userId', userId),
            sdk.Query.limit(100),
            sdk.Query.select(['badgeType']),
        ]);

        const earnedBadgeIds = existingBadges.documents.map((doc) => doc.badgeType);
        const newBadges = [];

        for (const [badgeId, condition] of Object.entries(BADGE_CONDITIONS)) {
            if (earnedBadgeIds.includes(badgeId)) {
                continue;
            }

            // Use condition.stat to look up the correct counter.
            // Previously all badges shared one object key per badge name which
            // caused firstDebate and debater to both reference stats['firstDebate']
            // instead of the shared debates total.
            const statValue = Number(stats[condition.stat] ?? 0);
            if (statValue < condition.threshold) {
                continue;
            }

            const now = new Date().toISOString();
            await db.createDocument(databaseId, 'badges', sdk.ID.unique(), {
                badgeType: badgeId,
                userId,
                awardedAt: now,
                createdAt: now,
            });

            newBadges.push({ badgeId, name: condition.name });
            log(`Badge awarded: ${condition.name} to user ${userId} (${condition.stat}=${statValue})`);

            // Fire notification asynchronously (async=true). Failure here must
            // NOT roll back the badge award — log and continue.
            try {
                const functions = new sdk.Functions(client);
                await functions.createExecution(
                    'send-notification',
                    JSON.stringify({
                        userId,
                        title: 'Badge Earned! 🏆',
                        body: `You earned the "${condition.name}" badge!`,
                        type: 'badge_earned',
                    }),
                    true,
                );
            } catch (notifErr) {
                log(`Non-fatal: badge notification failed for ${badgeId}: ${notifErr.message}`);
            }
        }

        log(`Checked achievements for ${userId}: ${newBadges.length} new badges`);
        return res.json({ newBadges, stats });
    } catch (error) {
        log(`Error checking achievements: ${error.message}`);
        return res.json({ error: error.message }, 500);
    }
};
