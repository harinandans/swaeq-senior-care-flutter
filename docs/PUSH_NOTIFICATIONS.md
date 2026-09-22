# Push notifications (SwaEQ)

Two layers:

| Kind | How it works | Status |
|------|----------------|--------|
| **Reminder alerts (app-scheduled)** | `flutter_local_notifications` schedules each reminder time/day on-device | Wired now |
| **Server / external pushes** | Device registers via `POST /devices`; cron + admin send via FCM | API ready; needs Firebase project |

## Reminder (local)

On Reminders load / save, the app calls `NotificationService.syncReminders(...)`.
Android channels: `swaeq_reminders`, `swaeq_general`.

Works offline. Survives reboot via the boot receiver in `AndroidManifest.xml`.

## Device registration

After login / bootstrap the app calls:

```http
POST /devices
{ "deviceId": "<uuid>", "platform": "android|ios", "pushToken": "<fcm-token or omit>" }
```

Tokens are stored in DynamoDB `devices` table (already provisioned).

## Server reminder dispatch

EventBridge cron → `reminder_cron` → `reminders.dispatchDue` every 5 minutes.

- `PUSH_PROVIDER=stub` (default): logs only  
- `PUSH_PROVIDER=fcm`: sends FCM HTTP v1 to each device `pushToken`

Env vars for FCM:

```bash
PUSH_PROVIDER=fcm
FCM_PROJECT_ID=your-firebase-project
FCM_CLIENT_EMAIL=firebase-adminsdk-...@....iam.gserviceaccount.com
FCM_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
```

(Use a Firebase service account with Firebase Cloud Messaging API enabled.)

## External / ops pushes

```http
POST /admin/notifications
Authorization: Bearer <admin>
{
  "userId": "...",
  "title": "Prescription ready",
  "body": "Your doctor has shared a prescription.",
  "data": { "type": "prescription_ready", "journeyId": "..." }
}
```

## Enabling FCM in the Flutter app (next step)

1. Create a Firebase project; add Android app with package `com.vidarka.swaeq_senior` (or prod id).
2. Download `google-services.json` → `android/app/`.
3. Add to `pubspec.yaml`: `firebase_core`, `firebase_messaging`.
4. Apply Google Services Gradle plugin.
5. On token refresh, call `registerWithApi(api, pushToken: token)`.
6. Handle foreground messages with `FirebaseMessaging.onMessage` → optional local show.

Until then, local reminder scheduling still works; server pushes will no-op without tokens / with `PUSH_PROVIDER=stub`.
