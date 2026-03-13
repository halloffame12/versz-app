const sdk = require('node-appwrite');
const admin = require('firebase-admin');

function getFirebaseCredential() {
    const raw = process.env.FIREBASE_SERVICE_JSON;
    if (!raw) {
        throw new Error('Missing FIREBASE_SERVICE_JSON');
    }

    const parsed = JSON.parse(raw);
    if (parsed.private_key) {
        parsed.private_key = parsed.private_key.replace(/\\n/g, '\n');
    }
    return admin.credential.cert(parsed);
}

module.exports = async ({ req, res, log }) => {
    const client = new sdk.Client()
        .setEndpoint(process.env.APPWRITE_ENDPOINT)
        .setProject(process.env.APPWRITE_PROJECT_ID)
        .setKey(process.env.APPWRITE_API_KEY);

    const db = new sdk.Databases(client);
    const requestBody = JSON.parse(req.body || '{}');
    const {
        userId,
        title,
        body: msgBody,
        type,
        debateId,
        commentId,
        senderId,
        chatId,
        conversationId,
        payload,
    } = requestBody;

    if (!userId || !title || !msgBody) {
        return res.json({ error: 'Missing required fields: userId, title, body' }, 400);
    }

    try {
        const profile = await db.getDocument(process.env.DATABASE_ID, 'users', userId);
        const token = profile.fcmToken;

        if (!token) {
            log(`No FCM token for user: ${userId}`);
            return res.json({ error: 'No FCM token found' }, 404);
        }

        if (!admin.apps.length) {
            admin.initializeApp({
                credential: getFirebaseCredential(),
            });
        }

        const channelId =
            type === 'new_message'
                ? 'versz_messages'
                : type === 'mention'
                  ? 'versz_mentions'
                  : 'versz_general';

        await admin.messaging().send({
            token,
            notification: { title, body: msgBody },
            data: {
                type: type ?? '',
                debateId: debateId ?? '',
                commentId: commentId ?? '',
                senderId: senderId ?? '',
                chatId: chatId ?? conversationId ?? '',
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
            },
            android: {
                priority: 'high',
                notification: { channelId },
            },
        });

        await db.createDocument(process.env.DATABASE_ID, 'notifications', sdk.ID.unique(), {
            userId,
            senderId: senderId ?? null,
            type: type ?? 'general',
            title,
            body: msgBody,
            payload: payload ? JSON.stringify(payload) : null,
            read: false,
            createdAt: new Date().toISOString(),
        });

        log(`Notification sent to user: ${userId}`);
        return res.json({ success: true });
    } catch (error) {
        log(`Error sending notification: ${error.message}`);
        return res.json({ error: error.message }, 500);
    }
};
