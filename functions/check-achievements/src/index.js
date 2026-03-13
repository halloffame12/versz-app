const sdk = require('node-appwrite');

const BADGE_CONDITIONS = {
    firstDebate: { threshold: 1, name: 'First Debate' },
    debater: { threshold: 5, name: 'Debater' },
    commentator: { threshold: 10, name: 'Commentator' },
    voter: { threshold: 20, name: 'Voter' },
};

module.exports = async ({ req, res, log }) => {
    const client = new sdk.Client()
        .setEndpoint(process.env.APPWRITE_ENDPOINT)
        .setProject(process.env.APPWRITE_PROJECT_ID)
        .setKey(process.env.APPWRITE_API_KEY);

    const db = new sdk.Databases(client);
    const body = JSON.parse(req.body || '{}');
    const { userId } = body;

    if (!userId) {
        return res.json({ error: 'Missing userId' }, 400);
    }

    try {
        await db.getDocument(process.env.DATABASE_ID, 'users', userId);

        const [debatesResponse, commentsResponse, votesResponse] = await Promise.all([
            db.listDocuments(process.env.DATABASE_ID, 'debates', [
                sdk.Query.equal('creatorId', userId),
                sdk.Query.limit(1),
            ]),
            db.listDocuments(process.env.DATABASE_ID, 'comments', [
                sdk.Query.equal('userId', userId),
                sdk.Query.limit(1),
            ]),
            db.listDocuments(process.env.DATABASE_ID, 'votes', [
                sdk.Query.equal('userId', userId),
                sdk.Query.limit(1),
            ]),
        ]);

        const stats = {
            firstDebate: debatesResponse.total,
            debater: debatesResponse.total,
            commentator: commentsResponse.total,
            voter: votesResponse.total,
        };

        const existingBadges = await db.listDocuments(process.env.DATABASE_ID, 'badges', [
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

            const statValue = Number(stats[badgeId] ?? 0);
            if (statValue < condition.threshold) {
                continue;
            }

            const now = new Date().toISOString();
            await db.createDocument(process.env.DATABASE_ID, 'badges', sdk.ID.unique(), {
                badgeType: badgeId,
                userId,
                awardedAt: now,
                createdAt: now,
            });

            newBadges.push({ badgeId, name: condition.name });
            log(`Badge awarded: ${condition.name} to user ${userId}`);

            try {
                const functions = new sdk.Functions(client);
                await functions.createExecution(
                    'send-notification',
                    JSON.stringify({
                        userId,
                        title: 'Badge Earned! 🏆',
                        body: `You earned the ${condition.name} badge!`,
                        type: 'badge_earned',
                    }),
                    true
                );
            } catch (notifErr) {
                log(`Failed to send badge notification: ${notifErr.message}`);
            }
        }

        log(`Checked achievements for ${userId}: ${newBadges.length} new badges`);
        return res.json({ newBadges });
    } catch (error) {
        log(`Error checking achievements: ${error.message}`);
        return res.json({ error: error.message }, 500);
    }
};
