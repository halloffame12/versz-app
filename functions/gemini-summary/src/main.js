const sdk = require('node-appwrite');

module.exports = async ({ req, res, log }) => {
    const client = new sdk.Client()
        .setEndpoint(process.env.APPWRITE_ENDPOINT)
        .setProject(process.env.APPWRITE_PROJECT_ID)
        .setKey(process.env.APPWRITE_API_KEY);

    const db = new sdk.Databases(client);
    const body = JSON.parse(req.body || '{}');
    const { debate_id } = body;

    if (!debate_id) {
        return res.json({ error: 'Missing debate_id' }, 400);
    }

    try {
        // Fetch debate document
        const debate = await db.getDocument(
            process.env.DATABASE_ID,
            'debates',
            debate_id
        );

        // Fetch top 20 comments by upvotes desc, filter out deleted
        const commentsRes = await db.listDocuments(
            process.env.DATABASE_ID,
            'comments',
            [
                sdk.Query.equal('debate_id', [debate_id]),
                sdk.Query.equal('is_deleted', [false]),
                sdk.Query.orderDesc('upvotes'),
                sdk.Query.limit(20),
                sdk.Query.select(['content', 'side', 'upvotes', 'username']),
            ]
        );

        const commentsList = commentsRes.documents
            .map(
                (c, i) =>
                    `${i + 1}. @${c.username || 'user'} (${c.side || 'neutral'}, ${c.upvotes || 0} upvotes): "${c.content || ''}"`
            )
            .join('\n');

        // Build prompt
        const prompt = `You are a debate summarizer. Summarize in exactly 2 sentences. Be completely neutral. Give a verdict on which side has stronger arguments based on votes and comment quality.

Topic: ${debate.title}
${debate.context ? `Context: ${debate.context}` : ''}
Votes: ${debate.agree_count} Agree vs ${debate.disagree_count} Disagree
Top comments:
${commentsList || 'No comments yet.'}

Respond in exactly 2 sentences.`;

        // Call Gemini 1.5 Flash
        const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${process.env.GEMINI_API_KEY}`;

        const geminiRes = await fetch(geminiUrl, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                contents: [{ parts: [{ text: prompt }] }],
                generationConfig: {
                    maxOutputTokens: 200,
                    temperature: 0.4,
                },
            }),
        });

        const geminiData = await geminiRes.json();
        const summary =
            geminiData.candidates?.[0]?.content?.parts?.[0]?.text || 'Unable to generate summary.';

        // Update debate document with AI summary
        await db.updateDocument(
            process.env.DATABASE_ID,
            'debates',
            debate_id,
            { ai_summary: summary.trim() }
        );

        log('Summary generated for debate: ' + debate_id);
        return res.json({ summary: summary.trim() });
    } catch (error) {
        log('Error generating summary: ' + error.message);
        return res.json({ error: error.message }, 500);
    }
};
