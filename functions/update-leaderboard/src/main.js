const sdk = require('node-appwrite');

module.exports = async ({ req, res, log }) => {
    const client = new sdk.Client()
        .setEndpoint(process.env.APPWRITE_ENDPOINT)
        .setProject(process.env.APPWRITE_PROJECT_ID)
        .setKey(process.env.APPWRITE_API_KEY);

    const db = new sdk.Databases(client);

    try {
        // Get current ISO week string for weekly leaderboard
        const now = new Date();
        const startOfYear = new Date(now.getFullYear(), 0, 1);
        const weekNum = Math.ceil(
            ((now - startOfYear) / 86400000 + startOfYear.getDay() + 1) / 7
        );
        const weekStr = `${now.getFullYear()}-W${String(weekNum).padStart(2, '0')}`;

        // Step 1: Clear existing leaderboard documents
        log('Clearing existing leaderboard entries...');
        let hasMore = true;
        while (hasMore) {
            const existing = await db.listDocuments(
                process.env.DATABASE_ID,
                'leaderboard',
                [sdk.Query.limit(100), sdk.Query.select(['$id'])]
            );
            if (existing.documents.length === 0) {
                hasMore = false;
                break;
            }
            for (const doc of existing.documents) {
                await db.deleteDocument(
                    process.env.DATABASE_ID,
                    'leaderboard',
                    doc.$id
                );
            }
        }

        // Step 2: Build leaderboard from users.xp (fallback: reputation)
        const users = await db.listDocuments(
            process.env.DATABASE_ID,
            'users',
            [
                sdk.Query.limit(100),
                sdk.Query.select([
                    '$id',
                    'display_name',
                    'avatar_url',
                    'xp',
                    'reputation',
                    'win_rate',
                ]),
            ]
        );

        const sorted = users.documents
            .map((u) => ({
                id: u.$id,
                display_name: u.display_name || u.username || 'Unknown',
                avatar_url: u.avatar_url || null,
                xp: Number(u.xp ?? u.reputation ?? 0),
                weekly_xp: Number(u.weekly_xp ?? 0),
                win_rate: Number(u.win_rate ?? 0),
            }))
            .sort((a, b) => b.xp - a.xp)
            .slice(0, 100);

        for (let i = 0; i < sorted.length; i++) {
            const user = sorted[i];
            await db.createDocument(
                process.env.DATABASE_ID,
                'leaderboard',
                sdk.ID.unique(),
                {
                    user_id: user.id,
                    display_name: user.display_name,
                    avatar_url: user.avatar_url,
                    xp: user.xp,
                    weekly_xp: user.weekly_xp,
                    rank: i + 1,
                    weekly_rank: i + 1,
                    win_rate: user.win_rate,
                }
            );
        }

        log(`Leaderboard update complete: ${sorted.length} entries`);
        return res.json({ success: true, week: weekStr, count: sorted.length });
    } catch (error) {
        log('Error updating leaderboard: ' + error.message);
        return res.json({ error: error.message }, 500);
    }
};
