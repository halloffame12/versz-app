'use strict';
const sdk = require('node-appwrite');

// ---------------------------------------------------------------------------
// VERSZ Leaderboard Algorithm
// ---------------------------------------------------------------------------
// All-time rank:  primary = xp DESC
//                 tiebreak 1 = winRate DESC
//                 tiebreak 2 = currentStreak DESC
//                 tiebreak 3 = account age ASC (earlier account = more loyal)
//
// Weekly rank:    primary = weeklyXp DESC
//                 tiebreak = winRate DESC
//
// Weekly reset:   On Monday within the first hour of midnight UTC.
//                 Writes weeklyXp:0 to every user in batch.
//                 This is the ONLY place weeklyXp is reset — not the client.
//
// Pagination fix: Previous code called listDocuments with limit:100 and no
//                 cursor — silently dropped everyone beyond rank 100.
//                 This version paginates through up to 10,000 users.
//
// Update trigger: Scheduled every 60 seconds `* * * * *`
//                 Also callable directly from update-xp after XP awards.
// ---------------------------------------------------------------------------

const MAX_LEADERBOARD_SIZE = 100;

function getDatabaseId() {
    return process.env.DATABASE_ID || process.env.APPWRITE_DATABASE_ID || 'versz-db';
}

module.exports = async ({ req, res, log }) => {
    let client;
    let db;
    let databaseId;

    try {
        client = new sdk.Client()
            .setEndpoint(process.env.APPWRITE_ENDPOINT)
            .setProject(process.env.APPWRITE_PROJECT_ID)
            .setKey(process.env.APPWRITE_API_KEY);

        db = new sdk.Databases(client);
        databaseId = getDatabaseId();
    } catch (initErr) {
        log(`Leaderboard init failed: ${initErr.message}`);
        return res.json({ error: `Initialization failed: ${initErr.message}` }, 500);
    }

    try {
        const now = new Date();

        // Monday detection — weekly reset fires once per Monday within first hour
        const dayOfWeek = now.getDay(); // 0=Sun, 1=Mon
        const startOfDay = new Date(now);
        startOfDay.setHours(0, 0, 0, 0);
        const isEarlyMonday = dayOfWeek === 1 && (now - startOfDay) < 3_600_000;

        // ISO week identifier
        const startOfYear = new Date(now.getFullYear(), 0, 1);
        const weekNum = Math.ceil(((now - startOfYear) / 86_400_000 + startOfYear.getDay() + 1) / 7);
        const weekStr = `${now.getFullYear()}-W${String(weekNum).padStart(2, '0')}`;
        const nowIso = now.toISOString();

        // ── 1. Paginate through ALL users (fixes 100-user cap bug) ────────
        const allUsers = [];
        let lastId = null;

        for (let page = 0; page < 100; page++) { // supports up to 10,000 users
            const queries = [
                sdk.Query.limit(100),
                sdk.Query.orderDesc('xp'),
                sdk.Query.select([
                    '$id', '$createdAt', 'displayName', 'username',
                    'avatar', 'xp', 'weeklyXp', 'winRate', 'currentStreak',
                ]),
            ];
            if (lastId) queries.push(sdk.Query.cursorAfter(lastId));

            const result = await db.listDocuments(databaseId, 'users', queries);
            allUsers.push(...result.documents);
            if (result.documents.length < 100) break;
            lastId = result.documents.at(-1).$id;
        }

        log(`Loaded ${allUsers.length} users for leaderboard calculation`);

        // ── 2. Weekly reset (Monday only, idempotent) ─────────────────────
        if (isEarlyMonday) {
            log('Monday detected — resetting weeklyXp for all users...');
            let resetCount = 0;
            for (const user of allUsers) {
                if ((user.weeklyXp || 0) > 0) {
                    await db.updateDocument(databaseId, 'users', user.$id, { weeklyXp: 0 });
                    user.weeklyXp = 0;
                    resetCount++;
                }
            }
            log(`Weekly reset complete: ${resetCount} users reset`);
        }

        // ── 3. All-time sort with full tie-breaking ────────────────────────
        const allTimeSorted = [...allUsers]
            .sort((a, b) => {
                const xpDiff = (b.xp || 0) - (a.xp || 0);
                if (xpDiff !== 0) return xpDiff;
                const winRateDiff = (b.winRate || 0) - (a.winRate || 0);
                if (Math.abs(winRateDiff) > 0.001) return winRateDiff;
                const streakDiff = (b.currentStreak || 0) - (a.currentStreak || 0);
                if (streakDiff !== 0) return streakDiff;
                return new Date(a.$createdAt) - new Date(b.$createdAt); // earlier = more loyal
            })
            .slice(0, MAX_LEADERBOARD_SIZE);

        // ── 4. Weekly sort and rank map ────────────────────────────────────
        const weeklyRankMap = new Map(
            [...allUsers]
                .sort((a, b) => {
                    const wxpDiff = (b.weeklyXp || 0) - (a.weeklyXp || 0);
                    return wxpDiff !== 0 ? wxpDiff : (b.winRate || 0) - (a.winRate || 0);
                })
                .slice(0, MAX_LEADERBOARD_SIZE)
                .map((u, i) => [u.$id, i + 1])
        );

        // ── 5. Clear existing leaderboard snapshot ─────────────────────────
        let hasMore = true;
        while (hasMore) {
            const existing = await db.listDocuments(databaseId, 'leaderboard', [
                sdk.Query.limit(100),
                sdk.Query.select(['$id']),
            ]);
            if (existing.documents.length === 0) { hasMore = false; break; }
            await Promise.all(
                existing.documents.map((d) => db.deleteDocument(databaseId, 'leaderboard', d.$id))
            );
        }

        // ── 6. Write new snapshot ──────────────────────────────────────────
        for (let i = 0; i < allTimeSorted.length; i++) {
            const user = allTimeSorted[i];
            await db.createDocument(databaseId, 'leaderboard', sdk.ID.unique(), {
                userId: user.$id,
                displayName: user.displayName || user.username || 'Unknown',
                avatar: user.avatar || null,
                xp: user.xp || 0,
                weeklyXp: user.weeklyXp || 0,
                rank: i + 1,
                weeklyRank: weeklyRankMap.get(user.$id) ?? (MAX_LEADERBOARD_SIZE + 1),
                winRate: user.winRate || 0,
                week: weekStr,
                createdAt: nowIso,
                updatedAt: nowIso,
            });
        }

        log(`Leaderboard rebuilt: ${allTimeSorted.length} entries, week=${weekStr}, mondayReset=${isEarlyMonday}`);
        return res.json({
            success: true,
            week: weekStr,
            count: allTimeSorted.length,
            totalUsers: allUsers.length,
            mondayReset: isEarlyMonday,
        });
    } catch (error) {
        log(`Error updating leaderboard: ${error.message}`);
        return res.json({ error: error.message }, 500);
    }
};
