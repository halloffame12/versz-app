# VERSZ Setup Guide (Appwrite v3 + Email OTP + FCM)

This guide is for running and shipping this project end-to-end.

## 1. Prerequisites

- Flutter SDK (stable) and Android Studio / Xcode.
- Dart SDK matching project constraint in [pubspec.yaml](pubspec.yaml).
- Appwrite project access with API key creation rights.
- Firebase project for Cloud Messaging.

## 2. Install Dependencies

From project root:

```powershell
cd C:\app_project\versz
flutter pub get
```

For setup scripts:

```powershell
cd C:\app_project\versz\scripts
dart pub get
```

## 3. Appwrite Schema v3 Setup

Script file: [scripts/setup_appwrite.dart](scripts/setup_appwrite.dart)

Important: this script wipes collections and buckets before recreating schema.

### Windows PowerShell

```powershell
cd C:\app_project\versz\scripts
$env:APPWRITE_API_KEY="YOUR_SERVER_API_KEY"
dart run setup_appwrite.dart
```

Expected output: collections, indexes, buckets, and category seed complete.

## 4. App Config Constants

Current client config is in [lib/core/constants/appwrite_constants.dart](lib/core/constants/appwrite_constants.dart).

Verify these values:

- endpoint
- projectId
- databaseId
- collection IDs
- function IDs

## 5. Email OTP Setup (Appwrite)

Current OTP UI exists at [lib/screens/auth/otp_screen.dart](lib/screens/auth/otp_screen.dart), but verification is placeholder-only right now.

### 5.1 Appwrite Console Setup

1. Enable email/password auth in Appwrite Auth settings.
2. Configure SMTP provider in Appwrite so token emails can be sent.
3. Add your app platform(s) and trusted domains.

### 5.2 Recommended OTP Flow

Use Appwrite Account token flow:

1. Request OTP token by email.
2. Store returned userId/session seed in memory.
3. Submit 6-digit code + identifier to verify.
4. Create/login session after successful verification.

### 5.3 Where to Wire It

- Trigger send OTP from login/signup flow in [lib/providers/auth_provider.dart](lib/providers/auth_provider.dart).
- Keep OTP entry in [lib/screens/auth/otp_screen.dart](lib/screens/auth/otp_screen.dart).
- Replace `_submitOtp()` placeholder with provider call.
- Persist verified session using existing auth state handling in [lib/providers/auth_provider.dart](lib/providers/auth_provider.dart).

### 5.4 Minimal Acceptance Criteria

- Wrong code -> inline error.
- Expired code -> resend path.
- Verified code -> authenticated route.
- Retry throttling and timer respected.

## 6. Firebase Cloud Messaging (FCM)

Notification service code: [lib/core/services/notification_service.dart](lib/core/services/notification_service.dart)

### 6.1 Firebase Project

1. Create Firebase project.
2. Add Android app (`applicationId`) and iOS app (`bundleId`).
3. Download config files:
   - Android: `google-services.json`
   - iOS: `GoogleService-Info.plist`

### 6.2 Android Setup

- Ensure `google-services.json` is placed at `android/app/google-services.json`.
- Verify Android manifest in [android/app/src/main/AndroidManifest.xml](android/app/src/main/AndroidManifest.xml).
- Confirm Gradle Google Services plugin is enabled in Android Gradle files.

### 6.3 iOS Setup

- Add `GoogleService-Info.plist` to Runner target.
- Enable Push Notifications and Background Modes -> Remote notifications in Xcode.
- Upload APNs key/certificate in Firebase.

### 6.4 App Wiring

- Initialize Firebase before using notifications.
- Call `NotificationService().init()` after app startup/session restore.
- Save FCM token to `users.fcm_token` so server functions can target users.

## 7. Appwrite Functions Deployment

Functions in repo:

- [functions/send-notification/src/index.js](functions/send-notification/src/index.js)
- [functions/gemini-summary/src/index.js](functions/gemini-summary/src/index.js)
- [functions/update-trending/src/index.js](functions/update-trending/src/index.js)
- [functions/update-leaderboard/src/index.js](functions/update-leaderboard/src/index.js)
- [functions/check-achievements/src/index.js](functions/check-achievements/src/index.js)
- [functions/update-xp/src/index.js](functions/update-xp/src/index.js)
- [functions/calculate-winner/src/index.js](functions/calculate-winner/src/index.js)
- [functions/anti-spam-check/src/index.js](functions/anti-spam-check/src/index.js)
- [functions/cast-vote/src/index.js](functions/cast-vote/src/index.js)

### 7.1 Required Env Vars

Set for function runtimes:

- APPWRITE_ENDPOINT
- APPWRITE_PROJECT_ID
- APPWRITE_API_KEY
- DATABASE_ID
- GEMINI_API_KEY (for summary)
- FIREBASE_SERVICE_JSON

### 7.2 Trigger Mapping

Suggested:

- `send-notification`: callable + event-based integrations.
- `gemini-summary`: debate/vote-driven trigger.
- `update-trending`: cron every 5 minutes (`*/5 * * * *`).
- `update-leaderboard`: cron every 1 minute (`* * * * *`).
- `calculate-winner`: on debate close; optional daily cron for stale active debates.
- `check-achievements`: vote/debate/comment activity trigger.
- `anti-spam-check`: callable from app before write actions.
- `cast-vote`: callable from app for server-authoritative vote mutations.
- `update-xp`: callable from app/functions after successful actions.

## 8. Local Run

From project root:

```powershell
cd C:\app_project\versz
flutter run
```

Useful checks:

```powershell
flutter analyze
flutter devices
```

## 9. Production Hardening Checklist

- Never hardcode API keys.
- Rotate server keys periodically.
- Restrict Appwrite function scopes to minimum needed.
- Set strict auth + document permissions.
- Add rate limits for OTP and sensitive actions.
- Add crash/analytics and alerting.
- Validate notification payload size and null-safe parsing.

## 10. Current State Notes

- App schema and major providers are migrated to v3-first with compatibility fallback.
- OTP screen exists but backend verification wiring is pending implementation.
- FCM service exists; ensure Firebase app initialization and native config files are complete for each platform.
