const sdk = require('node-appwrite');

module.exports = async ({ req, res, log }) => {
    const client = new sdk.Client()
        .setEndpoint(process.env.APPWRITE_ENDPOINT)
        .setProject(process.env.APPWRITE_PROJECT_ID)
        .setKey(process.env.APPWRITE_API_KEY);

    const db = new sdk.Databases(client);

    try {
        const now = new Date();
        const startOfYear = new Date(now.getFullYear(), 0, 1);
        const weekNum = Math.ceil(((now - startOfYear) / 86400000 + startOfYear.getDay() + 1) / 7);
        const weekStr = `${now.getFullYear()}-W${String(weekNum).padStart(2, '0')}`;
        const nowIso = now.toISOString();

        log('Clearing existing leaderboard entries...');
        let hasMore = true;
        while (hasMore) {
            const existing = await db.listDocuments(process.env.DATABASE_ID, 'leaderboard', [
                sdk.Query.limit(100),
                sdk.Query.select(['$id']),
            ]);
            if (existing.documents.length === 0) {
                hasMore = false;
                break;
            }
            for (const doc of existing.documents) {
                await db.deleteDocument(process.env.DATABASE_ID, 'leaderboard', doc.$id);
            }
        }

        const users = await db.listDocuments(process.env.DATABASE_ID, 'users', [
            sdk.Query.limit(100),
            sdk.Query.select(['$id', 'displayName', 'avatar', 'xp', 'reputation', 'weeklyXp', 'winRate', 'username']),
        ]);

        const sorted = users.documents
            .map((user) => ({
                id: user.$id,
                displayName: user.displayName || user.username || 'Unknown',
                avatar: user.avatar || null,
                xp: Number(user.xp ?? 0),
                weeklyXp: Number(user.weeklyXp ?? 0),
                winRate: Number(user.winRate ?? 0),
            }))
            .sort((a, b) => b.xp - a.xp)
            .slice(0, 100);

        for (let index = 0; index < sorted.length; index += 1) {
            const user = sorted[index];
            await db.createDocument(process.env.DATABASE_ID, 'leaderboard', sdk.ID.unique(), {
                userId: user.id,
                displayName: user.displayName,
                avatar: user.avatar,
                xp: user.xp,
                weeklyXp: user.weeklyXp,
                rank: index + 1,
                weeklyRank: index + 1,
                winRate: user.winRate,
                week: weekStr,
                createdAt: nowIso,
                updatedAt: nowIso,
            });
        }

        log(`Leaderboard update complete: ${sorted.length} entries`);
        return res.json({ success: true, week: weekStr, count: sorted.length });
    } catch (error) {
        log(`Error updating leaderboard: ${error.message}`);
        return res.json({ error: error.message }, 500);
    }
};
