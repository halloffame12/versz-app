'use strict';
const sdk = require('node-appwrite');

// ---------------------------------------------------------------------------
// VERSZ Debate Winner Algorithm — Wilson Score Lower Bound
// ---------------------------------------------------------------------------
// Problem with naive majority (agreeCount > disagreeCount):
//   A debate with 2 agree / 1 disagree reports 67% win — sample size of 3.
//   A debate with 600 agree / 400 disagree reports 60% win — sample size of 1000.
//   The naive method treats both the same, which is wrong.
//
// Wilson Score Lower Bound solves this:
//   It returns the LOWER BOUND of the true win probability at a given
//   confidence level (95% here). Small samples yield low lower bounds even
//   with 100% agree, because there is high statistical uncertainty.
//   Large samples with 60% agree yield a higher lower bound than small
//   samples with 100% agree.
//
// Formula (95% confidence, z = 1.96):
//   p = positive / n
//   lower = (p + z²/2n - z√(p(1-p)/n + z²/4n²)) / (1 + z²/n)
//
// Winner decision logic:
//   total < MIN_VOTES_FOR_VERDICT (10): → 'inconclusive'   (insufficient data)
//   |agreeConf - disagreeConf| < 0.05: → 'tie'             (statistically indistinguishable)
//   agreeConf > disagreeConf:          → 'agree'           (agree side wins)
//   disagreeConf > agreeConf:          → 'disagree'        (disagree side wins)
//
// Confidence score stored:
//   max(agreeConf, disagreeConf) — represents how statistically certain the winner is.
//   Range: 0.0–1.0. Displayed to users as a percentage.
//
// Post-win XP:
//   When a clear winner is determined, the debate creator receives +50 XP
//   via the update-xp function (async, non-blocking).
//
// When to call:
//   - On debate close (status change to 'closed')
//   - On a daily cron job for debates with status='active' and age > 24h
//   - Manually triggered by admin
//
// Input:  { debateId }
// Output: { debateId, winningSide, confidence, agreeCount, disagreeCount, total }
// ---------------------------------------------------------------------------

const MIN_VOTES_FOR_VERDICT = 10;
const TIE_THRESHOLD = 0.05; // < 5% difference in confidence = statistical tie

/**
 * Wilson Score Lower Bound for a binomial proportion.
 * Answers: "What is the LOWER BOUND of the true win rate, at 95% confidence?"
 * @param {number} positive - Count of positive outcomes (agree or disagree votes)
 * @param {number} n        - Total sample size
 * @returns {number} Lower bound in [0, 1]
 */
function wilsonLowerBound(positive, n) {
    if (n === 0) return 0;
    const z = 1.96; // 95% confidence z-score
    const p = positive / n;
    const numerator =
        p + (z * z) / (2 * n) -
        z * Math.sqrt((p * (1 - p)) / n + (z * z) / (4 * n * n));
    const denominator = 1 + (z * z) / n;
    return Math.max(0, numerator / denominator);
}

module.exports = async ({ req, res, log }) => {
    const client = new sdk.Client()
        .setEndpoint(process.env.APPWRITE_ENDPOINT)
        .setProject(process.env.APPWRITE_PROJECT_ID)
        .setKey(process.env.APPWRITE_API_KEY);

    const db = new sdk.Databases(client);
    const body = JSON.parse(req.body || '{}');
    const { debateId } = body;

    if (!debateId) {
        return res.json({ error: 'Missing debateId' }, 400);
    }

    try {
        const debate = await db.getDocument(process.env.DATABASE_ID, 'debates', debateId);

        const agreeCount = debate.agreeCount || 0;
        const disagreeCount = debate.disagreeCount || 0;
        const total = agreeCount + disagreeCount;

        // ── Insufficient data ──────────────────────────────────────────────
        if (total < MIN_VOTES_FOR_VERDICT) {
            log(`Debate ${debateId}: inconclusive (${total}/${MIN_VOTES_FOR_VERDICT} votes)`);
            return res.json({
                debateId,
                winningSide: 'inconclusive',
                confidence: 0,
                agreeCount,
                disagreeCount,
                total,
                reason: `Need ${MIN_VOTES_FOR_VERDICT} votes minimum, have ${total}`,
            });
        }

        // ── Wilson Score for each side ─────────────────────────────────────
        const agreeConf = wilsonLowerBound(agreeCount, total);
        const disagreeConf = wilsonLowerBound(disagreeCount, total);
        const diff = Math.abs(agreeConf - disagreeConf);

        let winningSide;
        let confidence;

        if (diff < TIE_THRESHOLD) {
            // Statistically indistinguishable — it's a tie
            // Confidence here represents how "close" they are (100% = perfect tie)
            winningSide = 'tie';
            confidence = Math.round((1 - diff / TIE_THRESHOLD) * 100) / 100;
        } else if (agreeConf > disagreeConf) {
            winningSide = 'agree';
            confidence = Math.round(agreeConf * 100) / 100;
        } else {
            winningSide = 'disagree';
            confidence = Math.round(disagreeConf * 100) / 100;
        }

        log(`Debate ${debateId}: winner=${winningSide} confidence=${confidence} (agreeConf=${agreeConf.toFixed(3)} disagreeConf=${disagreeConf.toFixed(3)})`);

        // ── Write winner to debate document ───────────────────────────────
        await db.updateDocument(process.env.DATABASE_ID, 'debates', debateId, {
            winningSide,
        });

        // ── Award XP to debate creator (async, non-blocking) ──────────────
        if (winningSide !== 'inconclusive' && winningSide !== 'tie' && debate.creatorId) {
            try {
                const functions = new sdk.Functions(client);
                await functions.createExecution(
                    'update-xp',
                    JSON.stringify({
                        userId: debate.creatorId,
                        action: 'debate_won',
                        referenceId: debateId,
                        metadata: { winningSide, confidence },
                    }),
                    true, // async execution
                );
                log(`XP award triggered for creator ${debate.creatorId} (debate_won)`);
            } catch (xpErr) {
                // Non-fatal: XP failure must not roll back the winner determination
                log(`Non-fatal: XP award failed for ${debateId}: ${xpErr.message}`);
            }
        }

        return res.json({ debateId, winningSide, confidence, agreeCount, disagreeCount, total });

    } catch (error) {
        log(`Error calculating winner for ${debateId}: ${error.message}`);
        return res.json({ error: error.message }, 500);
    }
};
