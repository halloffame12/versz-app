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

        for (let page = 0; page < 5; page += 1) {
            const queries = [
                sdk.Query.equal('status', ['active']),
                sdk.Query.greaterThan('$createdAt', cutoff48h),
                sdk.Query.limit(pageSize),
                sdk.Query.select([
                    '$id',
                    '$createdAt',
                    'topic',
                    'category',
                    'agreeCount',
                    'disagreeCount',
                    'commentCount',
                    'likeCount',
                    'viewCount',
                    'trendingScore',
                ]),
            ];
            if (lastId) {
                queries.push(sdk.Query.cursorAfter(lastId));
            }

            const result = await db.listDocuments(process.env.DATABASE_ID, 'debates', queries);
            allDebates = allDebates.concat(result.documents);
            if (result.documents.length < pageSize) {
                break;
            }
            lastId = result.documents[result.documents.length - 1].$id;
        }

        log(`Found ${allDebates.length} active debates from last 48h`);

        let updated = 0;
        for (const debate of allDebates) {
            const createdAt = new Date(debate.$createdAt).getTime();
            const hoursOld = (now - createdAt) / 3600000;
            const totalVotes = (debate.agreeCount || 0) + (debate.disagreeCount || 0);

            let score =
                totalVotes * 2 +
                (debate.commentCount || 0) * 3 +
                (debate.likeCount || 0) * 2 +
                (debate.viewCount || 0) * 0.5 -
                hoursOld * 0.8;

            score = Math.max(0, Math.round(score * 100) / 100);

            if (Math.abs(score - (debate.trendingScore || 0)) > 0.1) {
                await db.updateDocument(process.env.DATABASE_ID, 'debates', debate.$id, {
                    trendingScore: score,
                    isTrending: score > 0,
                });
                updated += 1;
            }
        }

        let hasMoreTrending = true;
        while (hasMoreTrending) {
            const existing = await db.listDocuments(process.env.DATABASE_ID, 'trending', [
                sdk.Query.limit(100),
                sdk.Query.select(['$id']),
            ]);
            if (existing.documents.length === 0) {
                hasMoreTrending = false;
                break;
            }
            for (const doc of existing.documents) {
                await db.deleteDocument(process.env.DATABASE_ID, 'trending', doc.$id);
            }
        }

        const top = allDebates
            .map((debate) => ({
                id: debate.$id,
                title: debate.topic || '',
                category: debate.category || '',
                score:
                    Math.max(
                        0,
                        ((debate.agreeCount || 0) + (debate.disagreeCount || 0)) * 2 +
                            (debate.commentCount || 0) * 3 +
                            (debate.likeCount || 0) * 2 +
                            (debate.viewCount || 0) * 0.5
                    ) || 0,
            }))
            .sort((a, b) => b.score - a.score)
            .slice(0, 50);

        const nowIso = new Date().toISOString();
        for (const row of top) {
            await db.createDocument(process.env.DATABASE_ID, 'trending', sdk.ID.unique(), {
                debateId: row.id,
                title: row.title,
                category: row.category,
                score: row.score,
                createdAt: nowIso,
            });
        }

        log(`Updated ${updated} trending scores and rebuilt ${top.length} trending docs`);
        return res.json({ processed: allDebates.length, updated, trendingRows: top.length });
    } catch (error) {
        log(`Error updating trending: ${error.message}`);
        return res.json({ error: error.message }, 500);
    }
};
