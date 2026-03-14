'use strict';
const sdk = require('node-appwrite');

const GRAVITY = 1.8;
const TRENDING_WINDOW_HOURS = 72;
const TOP_N = 50;
const SPAM_VELOCITY_THRESHOLD = 5.0;

function getDatabaseId() {
    return process.env.DATABASE_ID || process.env.APPWRITE_DATABASE_ID || 'versz-db';
}

module.exports = async ({ req, res, log }) => {
    const client = new sdk.Client()
        .setEndpoint(process.env.APPWRITE_ENDPOINT)
        .setProject(process.env.APPWRITE_PROJECT_ID)
        .setKey(process.env.APPWRITE_API_KEY);

    const db = new sdk.Databases(client);
    const databaseId = getDatabaseId();

    try {
        const now = Date.now();
        const cutoff = new Date(now - TRENDING_WINDOW_HOURS * 3_600_000).toISOString();

        const allDebates = [];
        let lastId = null;

        for (let page = 0; page < 20; page++) {
            const queries = [
                sdk.Query.equal('status', 'active'),
                sdk.Query.greaterThan('$createdAt', cutoff),
                sdk.Query.limit(100),
                sdk.Query.select([
                    '$id', '$createdAt', 'topic', 'category',
                    'agreeCount', 'disagreeCount', 'commentCount',
                    'likeCount', 'viewCount', 'trendingScore',
                ]),
            ];
            if (lastId) queries.push(sdk.Query.cursorAfter(lastId));

            const result = await db.listDocuments(databaseId, 'debates', queries);
            allDebates.push(...result.documents);
            if (result.documents.length < 100) break;
            lastId = result.documents.at(-1).$id;
        }

        let updated = 0;
        const scored = [];

        for (const debate of allDebates) {
            const hoursOld = (now - new Date(debate.$createdAt).getTime()) / 3_600_000;
            const totalVotes = (debate.agreeCount || 0) + (debate.disagreeCount || 0);
            const prevScore = debate.trendingScore || 0;

            const engagement =
                (debate.commentCount || 0) * 5 +
                totalVotes * 2 +
                (debate.likeCount || 0) +
                (debate.viewCount || 0) * 0.05;

            const agreeRatio = totalVotes > 0 ? (debate.agreeCount || 0) / totalVotes : 0.5;
            const controversy = Math.abs(agreeRatio - 0.5) < 0.2 ? 1.2 : 1.0;

            const spamGuard = prevScore > 10 && engagement > prevScore * SPAM_VELOCITY_THRESHOLD
                ? 0.1
                : 1.0;

            if (spamGuard < 1.0) {
                log(`Spam guard triggered: debate ${debate.$id} prev=${prevScore} engagement=${engagement}`);
            }

            const rawScore = engagement * controversy * spamGuard;
            const newScore = Math.max(0, rawScore / Math.pow(hoursOld + 2, GRAVITY));
            const roundedScore = Math.round(newScore * 1000) / 1000;

            scored.push({
                id: debate.$id,
                title: debate.topic || '',
                category: debate.category || '',
                score: roundedScore,
            });

            if (Math.abs(roundedScore - prevScore) > 0.01) {
                await db.updateDocument(databaseId, 'debates', debate.$id, {
                    trendingScore: roundedScore,
                    isTrending: roundedScore > 1.0,
                });
                updated += 1;
            }
        }

        const top = scored.sort((a, b) => b.score - a.score).slice(0, TOP_N);

        let hasMoreTrending = true;
        while (hasMoreTrending) {
            const existing = await db.listDocuments(databaseId, 'trending', [
                sdk.Query.limit(100),
                sdk.Query.select(['$id']),
            ]);
            if (existing.documents.length === 0) {
                hasMoreTrending = false;
                break;
            }
            await Promise.all(
                existing.documents.map((doc) =>
                    db.deleteDocument(databaseId, 'trending', doc.$id)
                )
            );
        }

        const nowIso = new Date().toISOString();
        for (const row of top) {
            await db.createDocument(databaseId, 'trending', sdk.ID.unique(), {
                debateId: row.id,
                title: row.title,
                category: row.category,
                score: row.score,
                createdAt: nowIso,
            });
        }

        log(`Done: processed=${allDebates.length} updated=${updated} top=${top.length}`);
        return res.json({ processed: allDebates.length, updated, trendingRows: top.length });
    } catch (error) {
        log(`Error updating trending: ${error.message}`);
        return res.json({ error: error.message }, 500);
    }
};
