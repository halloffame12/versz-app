const sdk = require('node-appwrite');

// Badge definitions with their conditions
const BADGE_CONDITIONS = {
    first_debate: { field: 'debates_created', threshold: 1, name: 'First Debate' },
    votes_10: { field: 'xp', threshold: 10, name: 'Rising Star' },
    votes_50: { field: 'xp', threshold: 50, name: 'Star Debater' },
    votes_100: {
        field: 'xp',
        threshold: 100,
        name: 'Elite Debater',
    },
    votes_1000: { field: 'xp', threshold: 1000, name: 'Legend' },
    streak_7: { field: 'current_streak', threshold: 7, name: 'Week Warrior' },
    streak_30: {
        field: 'current_streak',
        threshold: 30,
        name: 'Monthly Master',
    },
    followers_100: {
        field: 'followers_count',
        threshold: 100,
        name: 'Influencer',
    },
    followers_1000: {
        field: 'followers_count',
        threshold: 1000,
        name: 'Icon',
    },
    top_commenter: {
        field: 'total_votes',
        threshold: 100,
        name: 'Voice of Reason',
    },
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
        // Fetch user record
        const userDoc = await db.getDocument(
            process.env.DATABASE_ID,
            'users',
            userId
        );

        // Fetch existing badges for this user
        const existingBadges = await db.listDocuments(
            process.env.DATABASE_ID,
            'badges',
            [
                sdk.Query.equal('user_id', [userId]),
                sdk.Query.limit(100),
                sdk.Query.select(['badge_id']),
            ]
        );

        const earnedBadgeIds = existingBadges.documents.map((d) => d.badge_id);
        const newBadges = [];

        // Check each badge condition
        for (const [badgeId, condition] of Object.entries(BADGE_CONDITIONS)) {
            // Skip if already earned
            if (earnedBadgeIds.includes(badgeId)) continue;

            const profileValue = userDoc[condition.field] || 0;

            if (profileValue >= condition.threshold) {
                // Award the badge
                const now = new Date().toISOString();

                await db.createDocument(
                    process.env.DATABASE_ID,
                    'badges',
                    sdk.ID.unique(),
                    {
                        badge_id: badgeId,
                        user_id: userId,
                        earned_at: now,
                    }
                );

                newBadges.push({ badgeId, name: condition.name });
                log(`Badge awarded: ${condition.name} to user ${userId}`);

                // Send notification for new badge
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
                        true // async
                    );
                } catch (notifErr) {
                    log(
                        'Failed to send badge notification: ' + notifErr.message
                    );
                }
            }
        }

        log(
            `Checked achievements for ${userId}: ${newBadges.length} new badges`
        );
        return res.json({ newBadges });
    } catch (error) {
        log('Error checking achievements: ' + error.message);
        return res.json({ error: error.message }, 500);
    }
};
