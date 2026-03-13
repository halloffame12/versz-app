const sdk = require('node-appwrite');
const admin = require('firebase-admin');

module.exports = async ({ req, res, log }) => {
    const client = new sdk.Client()
        .setEndpoint(process.env.APPWRITE_ENDPOINT)
        .setProject(process.env.APPWRITE_PROJECT_ID)
        .setKey(process.env.APPWRITE_API_KEY);

    const db = new sdk.Databases(client);
    const body = JSON.parse(req.body || '{}');
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
    } = body;

    if (!userId || !title || !msgBody) {
        return res.json({ error: 'Missing required fields: userId, title, body' }, 400);
    }

    try {
        // Get user's FCM token
        const profile = await db.getDocument(
            process.env.DATABASE_ID,
            'users',
            userId
        );
        const token = profile.fcm_token;

        if (!token) {
            log('No FCM token for user: ' + userId);
            return res.json({ error: 'No FCM token found' }, 404);
        }

        // Initialize Firebase Admin if not already
        if (!admin.apps.length) {
            admin.initializeApp({
                credential: admin.credential.cert({
                    projectId: process.env.FIREBASE_PROJECT_ID,
                    clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
                    privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
                }),
            });
        }

        // Determine notification channel
        const channelId =
            type === 'new_message'
                ? 'versz_messages'
                : type === 'mention'
                    ? 'versz_mentions'
                    : 'versz_general';

        // Send FCM notification
        await admin.messaging().send({
            token,
            notification: { title, body: msgBody },
            data: {
                type: type ?? '',
                debateId: debateId ?? '',
                commentId: commentId ?? '',
                senderId: senderId ?? '',
                chatId: chatId ?? '',
                conversationId: conversationId ?? '',
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
            },
            android: {
                priority: 'high',
                notification: { channelId },
            },
        });

        // Create notification document
        await db.createDocument(
            process.env.DATABASE_ID,
            'notifications',
            sdk.ID.unique(),
            {
                user_id: userId,
                type: type ?? 'general',
                sender_id: senderId ?? null,
                target_id: debateId ?? commentId ?? chatId ?? conversationId ?? null,
                content: msgBody,
                title,
                body: msgBody,
                payload: payload ? JSON.stringify(payload) : null,
                is_read: false,
            }
        );

        log('Notification sent to user: ' + userId);
        return res.json({ success: true });
    } catch (error) {
        log('Error sending notification: ' + error.message);
        return res.json({ error: error.message }, 500);
    }
};
