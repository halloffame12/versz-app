const sdk = require('node-appwrite');

module.exports = async ({ req, res, log }) => {
    const client = new sdk.Client()
        .setEndpoint(process.env.APPWRITE_ENDPOINT)
        .setProject(process.env.APPWRITE_PROJECT_ID)
        .setKey(process.env.APPWRITE_API_KEY);

    const db = new sdk.Databases(client);

    try {
        const now = Date.now();
        const cutoff48h = new Date(now - 48 * 60 * 60 * 1000).toISOString();
        let allDebates = [];
        let lastId = null;
        const pageSize = 100;

        // Fetch all active debates from last 48h (up to 500)
        for (let i = 0; i < 5; i++) {
            const queries = [
                sdk.Query.equal('status', ['active']),
                sdk.Query.greaterThan('$createdAt', cutoff48h),
                sdk.Query.limit(pageSize),
                sdk.Query.select([
                    '$id',
                    '$createdAt',
                    'title',
                    'category_id',
                    'agree_count',
                    'disagree_count',
                    'comment_count',
                    'like_count',
                    'view_count',
                    'trending_score',
                ]),
            ];
            if (lastId) {
                queries.push(sdk.Query.cursorAfter(lastId));
            }

            const result = await db.listDocuments(
                process.env.DATABASE_ID,
                'debates',
                queries
            );

            allDebates = allDebates.concat(result.documents);
            if (result.documents.length < pageSize) break;
            lastId = result.documents[result.documents.length - 1].$id;
        }

        log(`Found ${allDebates.length} active debates from last 48h`);

        let updated = 0;
        for (const debate of allDebates) {
            const createdAt = new Date(debate.$createdAt).getTime();
            const hoursOld = (now - createdAt) / 3600000;
            const totalVotes =
                (debate.agree_count || 0) + (debate.disagree_count || 0);

            let score =
                totalVotes * 2 +
                (debate.comment_count || 0) * 3 +
                (debate.like_count || 0) * 2 +
                (debate.view_count || 0) * 0.5 -
                hoursOld * 0.8;

            score = Math.max(0, Math.round(score * 100) / 100);

            // Only update if score changed significantly
            if (Math.abs(score - (debate.trending_score || 0)) > 0.1) {
                await db.updateDocument(
                    process.env.DATABASE_ID,
                    'debates',
                    debate.$id,
                    {
                        trending_score: score,
                        is_trending: score > 0,
                    }
                );
                updated++;
            }
        }

        // Rebuild trending collection with top scored debates.
        let hasMoreTrending = true;
        while (hasMoreTrending) {
            const existing = await db.listDocuments(
                process.env.DATABASE_ID,
                'trending',
                [sdk.Query.limit(100), sdk.Query.select(['$id'])]
            );
            if (existing.documents.length === 0) {
                hasMoreTrending = false;
                break;
            }
            for (const doc of existing.documents) {
                await db.deleteDocument(process.env.DATABASE_ID, 'trending', doc.$id);
            }
        }

        const top = allDebates
            .map((d) => ({
                id: d.$id,
                title: d.title || '',
                category: d.category_id || '',
                score:
                    Math.max(
                        0,
                        ((d.agree_count || 0) + (d.disagree_count || 0)) * 2 +
                            (d.comment_count || 0) * 3 +
                            (d.like_count || 0) * 2 +
                            (d.view_count || 0) * 0.5
                    ) || 0,
            }))
            .sort((a, b) => b.score - a.score)
            .slice(0, 50);

        const nowIso = new Date().toISOString();
        for (const row of top) {
            await db.createDocument(
                process.env.DATABASE_ID,
                'trending',
                sdk.ID.unique(),
                {
                    debate_id: row.id,
                    title: row.title,
                    category: row.category,
                    score: row.score,
                    computed_at: nowIso,
                }
            );
        }

        log(`Updated ${updated} trending scores and rebuilt ${top.length} trending docs`);
        return res.json({ processed: allDebates.length, updated, trendingRows: top.length });
    } catch (error) {
        log('Error updating trending: ' + error.message);
        return res.json({ error: error.message }, 500);
    }
};
