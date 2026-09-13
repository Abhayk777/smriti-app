# Full-Screen Medication Reminders — Research & Implementation Plan

Status: **Phases 1 and 2 implemented** (full-screen reminder + setup checklist), plus fixes G6/G7. Not yet verified on a device. Phase 4 (push when the app is killed) is waiting on backend access. See section 7 for the decisions made.

**Implementation note:** instead of the separate local plugin proposed in §4, the alarm isolate sends an explicit broadcast through `android_intent_plus` (already a dependency, and registered in every engine) to `ReminderReceiver` in the app module. Same result, no new package.

## 1. Goal

A caregiver adds a medicine on the web app (name, dose, **description**, time, days, **pill photo**, **voice note**). At the scheduled time the phone shows a **full-screen** reminder with the photo, the description, and the voice note **playing automatically**:

| Device state | Required behaviour |
|---|---|
| Screen off / locked (PIN, pattern, etc.) | Screen turns on, the reminder shows **over the lock screen without asking for the PIN**. Dismissing it returns to the lock screen. The phone stays locked. |
| Unlocked, on the home screen or idle | Full-screen reminder appears. |
| Unlocked, using another app | Full-screen reminder appears over that app. |
| App killed / swiped away / after reboot | Same as above. |

## 2. What Android actually allows (research summary)

### 2.1 Full-screen intent (FSI) notifications
- **The system decides when an FSI notification goes full screen.** If the device is locked or the screen is off, it launches the full-screen activity. If the user is **actively using the device, the system shows a heads-up banner instead**. This is by design and cannot be overridden. FSI alone can never satisfy requirement 2.
- **Android 10–13:** `USE_FULL_SCREEN_INTENT` is granted at install.
- **Android 14+:** The permission is on by default for installed apps, but **Google Play revokes it at install** unless the app's Play Console declaration is approved for a core use case. Play only approves "setting an alarm" or "receiving phone or video calls". **A medication reminder app does not qualify.** Apps that aren't approved must prompt the user (Settings → Special app access → Full-screen notifications, via `ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT`) and degrade gracefully. If the permission is denied, the user gets a persistent heads-up notification for about 60 s.
- **Sideloaded APKs** (not installed via Play) keep the default grant on stock Android. The AOSP doc leaves the final state to the installer or OEM, so always check `NotificationManager.canUseFullScreenIntent()`.

### 2.2 "Display over other apps" (`SYSTEM_ALERT_WINDOW`)
- Android has blocked background activity launches (BAL) since Android 10. One of the listed exemptions is **"the app has the `SYSTEM_ALERT_WINDOW` permission granted by the user."** With it, the app can call `startActivity()` from the background, which is exactly what requirement 2 needs.
- **Android 15** narrowed this exemption **only for starting foreground services** (they now also need a visible overlay window). Starting **activities** with SAW is still exempt. So the plan must not depend on starting a foreground service from the background.
- **Android 14/15/17** added opt-in rules for BAL through `PendingIntent`/`IntentSender`. These don't affect a direct `startActivity()` call made while holding SAW. FSI `PendingIntent`s are sent by the system, which is its own exemption.
- The user must grant SAW manually (`Settings.ACTION_MANAGE_OVERLAY_PERMISSION`). **On Android 11+ this opens the app list, not our app's page**, so the user must find "Smriti" in it. The onboarding copy has to say so. **Android Go devices cannot grant SAW at all**, so we fall back to FSI there.

### 2.3 Showing over the lock screen without the PIN
- An activity with `showWhenLocked=true` + `turnScreenOn=true` (or `setShowWhenLocked()`/`setTurnScreenOn()` on API 27+) is drawn **on top of the keyguard while the keyguard stays active**. The PIN is only asked for if we call `KeyguardManager.requestDismissKeyguard()` or the user tries to leave the activity. **So we never call it.** When the activity `finish()`es, the lock screen is still there. This is how alarm-clock and incoming-call screens work.
- Today **`MainActivity` has these flags permanently**, plus `FLAG_DISMISS_KEYGUARD` and `FLAG_KEEP_SCREEN_ON` ([MainActivity.kt:37-49](../android/app/src/main/kotlin/com/example/smriti/MainActivity.kt), [AndroidManifest.xml:41-42](../android/app/src/main/AndroidManifest.xml)). That exposes the **whole app** (home, family, diagnostics) over the lock screen, keeps the screen on forever, and `FLAG_DISMISS_KEYGUARD` can trigger a PIN prompt on secure locks. These flags must move to a dedicated reminder activity.

### 2.4 Voice auto-play
- Native Android has no autoplay-gesture rule. Audio can start as soon as the activity is visible.
- **Android 17 background-audio hardening** (applies to *all* apps running on 17): audio started while the app has **no visible activity** and no foreground service is **silently muted**. There is no error. Apps targeting 17 also need a while-in-use foreground service, *or* the exact-alarm permission **and** `USAGE_ALARM` audio. Today we play the voice from the background alarm isolate with default (media) attributes ([reminder_isolate.dart:198-214](../lib/core/reminders/reminder_isolate.dart)). On Android 17 that is muted. It is also silent whenever media volume is 0.
- **Fix:** play the voice from the visible reminder activity with `AudioAttributes.USAGE_ALARM` + `CONTENT_TYPE_SPEECH`. This follows alarm volume, gets through Do Not Disturb when alarms are allowed, and counts as foreground playback.

### 2.5 OEM restrictions (critical for India: Xiaomi/Redmi/POCO, Vivo/iQOO, Oppo/Realme, Samsung)
- **Xiaomi (MIUI/HyperOS)** has *extra* per-app toggles that the standard Android APIs cannot read or grant: **"Show on lock screen"**, **"Display pop-up windows while running in the background"**, and **"Autostart"**. If any is off, `showWhenLocked` or the background `startActivity()` is silently blocked. We can only deep-link the user to the page: `miui.intent.action.APP_PERM_EDITOR` with extra `extra_pkgname`, with a fallback to app details.
- **Vivo/iQOO:** "Display on lock screen" and "Background pop-ups". **Oppo/Realme:** "Auto launch" and floating windows. **Samsung:** "Appear on top" (the standard SAW) and removing the app from "Sleeping apps".
- These can't be verified in code. That's why the spec §10 **live test** (a real reminder fired while the phone is locked) is mandatory.

## 3. Current implementation — gaps found

| # | Where | Problem | Effect on the goal |
|---|---|---|---|
| G1 | `MainActivity` + manifest | Lock-screen flags on the main activity, permanently | Whole app visible without the PIN; screen never sleeps |
| G2 | [reminder_isolate.dart:153](../lib/core/reminders/reminder_isolate.dart) | FSI notification from `flutter_local_notifications` targets `MainActivity`. Nothing uses SAW, although it is declared in the manifest | Unlocked device shows only a heads-up banner (requirement 2 fails) |
| G3 | reminder_isolate + [full_screen_reminder_screen.dart](../lib/screens/full_screen_reminder_screen.dart) | Voice played twice (isolate and screen). The isolate's player is never disposed and uses media attributes | Double audio, silent at media volume 0, muted on Android 17 |
| G4 | `Medications` table, [content_puller.dart:190](../lib/core/sync/content_puller.dart) | No description field. The screen shows hard-coded instruction text | Caregiver's description never reaches the phone |
| G5 | [main.dart:160](../lib/main.dart), [sync_engine.dart:325](../lib/core/sync/sync_engine.dart) | Workmanager callback is a stub (returns `true`, does nothing). Realtime only runs while the app is open | A medicine added on the web while the app is killed is **never scheduled** until the app is next opened |
| G6 | [alarm_scheduler.dart:89](../lib/core/reminders/alarm_scheduler.dart) | `_cancelAllAlarms()` runs *after* the content swap, so it only cancels alarms for the **new** medication list | A med whose days changed (e.g. Mon → Tue) **still fires on Monday**, and reschedules itself there every week. Deleted meds' alarms linger |
| G7 | alarm_scheduler | Uses `setExactAndAllowWhileIdle` (the default) | `alarmClock: true` (`setAlarmClock`) is the most OEM-resistant exact alarm and exempt from Doze and battery saver |
| G8 | Reminder screen layout | Landscape-only `Row` layout | Cramped and awkward over a portrait phone lock screen |

## 4. Target architecture

```
WEB APP (caregiver)                SUPABASE                               PHONE
───────────────────                ────────                               ─────
Add/edit medicine  ─────────►  medications row + patient-media  ─┐
(name, dose, description,       storage (photo, voice)            │ DB webhook
 time, days, photo, voice)                                         ▼
                               Edge fn `notify-device` ── FCM high-priority data msg
                                                                   │  {type: "content_changed"}
                                                                   ▼
                                     firebase_messaging background handler (own isolate)
                                       → ContentPuller.pull(): download photo+voice → verify
                                         → Drift swap → AlarmScheduler.rescheduleAll()
                                     (+ Realtime when app is open, + working periodic sync)

AT THE SCHEDULED TIME
AlarmManager.setAlarmClock (exact, Doze-exempt)
  └─► fireReminderCallback (Dart alarm isolate — existing)
        • insert ReminderEvent, schedule ladder steps 1/2, schedule next occurrence (existing)
        • SmritiReminder.showReminder(medId, eventId)     ◄── NEW local plugin, works in any isolate
              Kotlin:
              1. Post notification on channel `medication_reminder_v2`:
                 CATEGORY_ALARM, PRIORITY_MAX, VISIBILITY_PUBLIC, BigPictureStyle(pill photo),
                 title = name, text = dose + description, ongoing,
                 setFullScreenIntent(PendingIntent → ReminderActivity)
              2. if Settings.canDrawOverlays():  startActivity(ReminderActivity, NEW_TASK)
                    → full screen even when unlocked / inside another app   (requirement 2)
              3. else if locked or screen off: the FSI launches ReminderActivity  (requirement 1)
              4. else (unlocked, no SAW): heads-up banner + chime; voice plays when tapped

ReminderActivity (NEW — separate from MainActivity)
  • showWhenLocked + turnScreenOn, NO requestDismissKeyguard → over the lock screen, no PIN
  • own taskAffinity, excludeFromRecents, singleTask → finishing returns to lock screen/previous app
  • FlutterActivity running Dart entrypoint `reminderMain` → FullScreenReminderScreen
  • voice plays natively with USAGE_ALARM as soon as the activity is visible
  • "I have taken it" / "Remind in 10 min" → Drift write, cancel ladder + notification, finish()
```

### Why a local plugin instead of the existing `MethodChannel`
`NativeReminderBridge`'s channel is registered in `MainActivity.configureFlutterEngine`, so it **only exists in the UI engine**. The alarm callback runs in a separate engine started by `android_alarm_manager_plus`. That engine auto-registers only plugins listed in `GeneratedPluginRegistrant`. Packaging our Kotlin as a **local path plugin** (`packages/smriti_reminder/`) makes it available in every engine: UI, alarm isolate, FCM handler, and `reminderMain`.

### Why Flutter (not native) for the reminder UI
`FullScreenReminderScreen` already exists and matches the design. A second engine costs about 1 s cold start. That's acceptable with a native launch background in the same colour. A fully native Kotlin screen stays an option if cold start proves too slow on low-end devices (decide after the Phase 1 device test).

## 5. Implementation phases

Each phase ends with a real-device test (AGENTS.md rule 12) and `flutter analyze`.

### Phase 1: Native reminder plugin + ReminderActivity (requirements 1 and 2)
1. Create `packages/smriti_reminder/` (Flutter plugin, Android only) and add it as a path dependency.
   - Move the existing `NativeReminderBridge` methods into it: `canUseFullScreenIntent`, `openFullScreenIntentSettings`, `canScheduleExactAlarms`, `openExactAlarmSettings`, `wakeUpScreen`.
   - Add `canDrawOverlays()`, `openOverlaySettings()`, `openOemPermissionSettings()`, `showReminder({medicationId, reminderEventId, title, body, photoPath})`, `cancelReminder(reminderEventId)`, `playVoice(path)`, `stopVoice()`, and a voice state event stream.
   - `ReminderNotifier.kt`: channel `medication_reminder_v2` (new ID, because channel settings can't change after creation), notification, BigPicture (photo decoded and downsampled to ~1024 px), FSI `PendingIntent` (`FLAG_IMMUTABLE`), and the direct `startActivity` when `canDrawOverlays()`.
   - `ReminderAudio.kt`: `MediaPlayer` with `USAGE_ALARM` / `CONTENT_TYPE_SPEECH` and transient audio focus.
2. Add `ReminderActivity.kt` in the app module: a `FlutterActivity` with `getDartEntrypointFunctionName() = "reminderMain"`. Pass medicationId/reminderEventId as entrypoint args. Handle `onNewIntent` so a second reminder queues instead of replacing. Set `setShowWhenLocked(true)`, `setTurnScreenOn(true)`, and `FLAG_KEEP_SCREEN_ON` only while it is visible.
3. Manifest: declare `ReminderActivity` (`showWhenLocked`, `turnScreenOn`, `excludeFromRecents`, `taskAffinity=".reminder"`, `launchMode="singleTask"`, `exported=false`, orientation unlocked). **Remove** `showWhenLocked`/`turnScreenOn` from `MainActivity` and delete `configureLockScreenFlags()` (G1).
4. Add `@pragma('vm:entry-point') void reminderMain(List<String> args)` in `lib/main.dart`. Entrypoints must live in the main library unless a library URI is overridden. It opens its own Drift connection and renders only `FullScreenReminderScreen`, with no route back into the app.
5. In `reminder_isolate.dart`, replace the `flutter_local_notifications` call and `_playCaregiverAudio` with `SmritiReminder.showReminder(...)` (G2, G3). Ladder step 1 uses the same call.
6. `FullScreenReminderScreen`: use the plugin's voice player; on Taken/Snooze, `cancelReminder()` and then finish the activity (`SystemNavigator.pop()`), not `Navigator.pop()`. Make the layout responsive: a column in portrait, the current row in landscape (G8).
7. Add a debug-only "Fire test reminder in 20 s" button on the diagnostics screen.

**Exit test:** on a phone with a PIN, test (a) screen off, (b) lock screen showing, (c) home screen, (d) YouTube playing full screen, (e) app swiped away. Each must show the full-screen reminder with the photo and auto-playing voice. After Taken, the phone is still locked.

### Phase 2: Permission onboarding (requirement 3)
1. Add a new `ReminderSetupScreen`, shown after pairing and on app start whenever a critical item is missing. It is a checklist; each row has a status, a one-line "why", and a **Turn on** button. It re-checks on `AppLifecycleState.resumed`.
   | Item | API | Critical? |
   |---|---|---|
   | Notifications | `Permission.notification` (Android 13+) | Yes |
   | **Display over other apps** | `Permission.systemAlertWindow` (already in permission_handler). Copy: "Find **Smriti** in the list and turn it on" | Yes (for requirement 2) |
   | Full-screen notifications | `canUseFullScreenIntent` / `ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT` (Android 14+) | Yes (for requirement 1 without SAW) |
   | Alarms & reminders | `canScheduleExactAlarms` (Android 12+) | Yes |
   | Battery: Unrestricted | `Permission.ignoreBatteryOptimizations` | Yes |
   | OEM: lock screen / background pop-ups / autostart | Deep link per manufacturer (§2.5); a manual "I've done this" tick | Xiaomi/Vivo/Oppo only |
   | **Live test** | Fires a real reminder 30 s out and says "Lock the phone now"; asks "Did it appear?" | Yes (spec §10) |
2. Extend `HealthCheck` with the SAW and OEM items so the diagnostics screen reports them.
3. In `main.dart`, remove the chained permission requests at startup (they fire several system dialogs with no explanation) and route to the setup screen instead.
4. Degrade gracefully (Play policy): if SAW or FSI is denied, reminders still arrive as heads-up notifications with the photo and description. The setup screen keeps the item marked "recommended".

### Phase 3: Description field end-to-end (G4)
1. Backend: add a medication description column and return it from `get_patient_content` (name to be confirmed; see Decisions).
2. Drift: add a nullable `description` column to `Medications`, bump `schemaVersion` to 2, and add a `MigrationStrategy` with `m.addColumn(...)`. **This deviates from APP-BUILD-SPEC §5 ("do not modify") and needs sign-off.**
3. Update `ContentPuller._parseMedications`, the reminder screen (replacing the hard-coded instructions), the notification body, and `medicine_screen.dart`.
4. Web app: add the description field to the add/edit medicine form.

### Phase 4: Delivery when the app is killed (G5, G6, G7)
1. **FCM push:** add `firebase_core` + `firebase_messaging` and a Firebase project (`google-services.json`). The device registers its FCM token with the backend. A Supabase DB webhook on `medications` insert/update/delete calls an Edge Function `notify-device`, which sends an FCM HTTP v1 **high-priority data-only** message `{type: "content_changed"}`.
2. Background handler (in `lib/core/sync/`, top-level, `vm:entry-point`): init Supabase, open its own Drift connection, run `ContentPuller.pull()`, and reschedule alarms. Keep it under about 20 s. Photos and voice notes are small; if not, hand off to an expedited WorkManager task.
3. Implement the Workmanager `callbackDispatcher` for real, as a safety net that runs the same pull.
4. **Fix G6:** persist the set of scheduled alarm IDs in `AppConfigs` (`scheduledAlarmIdsJson`). `rescheduleAll()` cancels *that* set, then schedules the new one.
5. **G7:** pass `alarmClock: true` to every reminder `oneShotAt` (main, ladder, snooze).
6. Optional: a web "Send reminder now" button, as an FCM `{type: "remind_now", medicationId}` message. The handler ensures media is on disk, then calls `showReminder`.

### Phase 5: Device test matrix
- **Android versions:** 10, 12, 13, 14, 15, 16 (and 17 if available).
- **Manufacturers:** Pixel/stock, Samsung, Xiaomi/Redmi, Vivo or Oppo/Realme.
- **States:** screen off + PIN, lock screen showing, home, another app full screen, app swiped away, after reboot, Do Not Disturb on, battery saver on, media volume 0, offline at fire time, a medicine added on the web while the app is killed, and two medicines due in the same minute.
- **Debug aids:** `adb shell cmd audio set-enable-hardening throw` (Android 17 audio) and `StrictMode.detectBlockedBackgroundActivityLaunch()` (16+).

## 6. Files touched (expected)

| File | Change |
|---|---|
| `packages/smriti_reminder/**` | **New** local plugin (Kotlin + Dart API) |
| `android/app/src/main/kotlin/.../ReminderActivity.kt` | **New** |
| `android/app/src/main/kotlin/.../MainActivity.kt` | Remove lock-screen flags; channel moves to the plugin |
| `android/app/src/main/AndroidManifest.xml` | Add `ReminderActivity`; clean up `MainActivity` |
| `lib/main.dart` | `reminderMain` entrypoint; setup-screen gate; remove startup permission spam |
| `lib/core/reminders/reminder_isolate.dart` | Use `showReminder`; drop isolate audio |
| `lib/core/reminders/native_reminder_bridge.dart` | Becomes a thin wrapper over the plugin (or is removed) |
| `lib/core/reminders/alarm_scheduler.dart` | `alarmClock: true`; tracked-ID cancellation |
| `lib/core/reminders/health_check.dart` | SAW + OEM checks |
| `lib/screens/full_screen_reminder_screen.dart` | Responsive layout, description, native audio, finish the activity |
| `lib/screens/reminder_setup_screen.dart` | **New** |
| `lib/core/db/tables.dart`, `database.dart` | `description` column, schema v2 migration (needs approval) |
| `lib/core/sync/content_puller.dart` | Parse description |
| `lib/core/sync/push_handler.dart` | **New** FCM background handler (Phase 4) |
| Backend (not in this repo) | Description column + RPC, push-token storage, `notify-device` Edge Function |

## 7. Decisions

Resolved (2026-09-13):
- **Distribution:** sideloaded APK for now. On a normal APK install, full-screen notifications are on by default; the checklist still verifies them.
- **Description = dose.** The dose is already synced, so there is no Drift schema change and Phase 3 shrinks to showing the dose (done).
- **Packages / spec deviations:** OK if needed. None were needed for Phases 1 and 2.
- **Setup screen:** OK to show after pairing and again when something critical is off.
- **Devices:** everything must work on all Android phones, not one brand. The core uses only standard Android APIs; brand-specific instructions are extras, with a generic card for unknown brands.

Still open: **push token storage** (Phase 4), which needs someone with Supabase access to add a table and an Edge Function.

Original questions, kept for reference:

1. **Distribution:** Play Store or sideloaded APK? On Play, FSI must be user-granted on Android 14+ (we already have the settings deep link). `USE_EXACT_ALARM` is also Play-restricted to alarm/calendar apps and should probably be dropped in favour of `SCHEDULE_EXACT_ALARM` alone.
2. **Description column:** exact Supabase column name (`description`? `instructions`?). Also: who changes the web app and the `get_patient_content` RPC? The web app code is not in this repo.
3. **Spec deviations:** approve (a) the Drift `Medications` schema change (spec §5 says "do not modify"), (b) the new local plugin package, and (c) `firebase_core` + `firebase_messaging` (AGENTS.md: ask before adding packages).
4. **Push token storage:** the backend needs a table or column plus an RLS policy for the device to write its FCM token. The name must come from the backend owner; it can't be invented client-side.
5. **Who sees the permission screen:** AGENTS.md rule 9 keeps permissions away from the elder. The proposal is to show the setup checklist during pairing (caregiver present) and re-show it only when something critical gets revoked. Confirm that's acceptable for phones the elder uses alone.
6. **Phone vs tablet:** the app is currently landscape-locked for tablets. The reminder screen will support portrait. Should the rest of the app also unlock orientation on phones?

## Sources
- [Restrictions on starting activities from the background](https://developer.android.com/guide/components/activities/background-starts)
- [Full-screen intent limits (AOSP)](https://source.android.com/docs/core/permissions/fsi-limits)
- [Play Console: foreground service and full-screen intent requirements](https://support.google.com/googleplay/android-developer/answer/13392821?hl=en)
- [Display time-sensitive notifications](https://developer.android.com/develop/ui/views/notifications/time-sensitive)
- [Behavior changes: Android 15](https://developer.android.com/about/versions/15/behavior-changes-15)
- [Behavior changes: Android 17](https://developer.android.com/about/versions/17/behavior-changes-17)
- [Android 17 background audio hardening](https://developer.android.com/about/versions/17/changes/bg-audio)
- [The meaning of all MIUI permissions](https://xiaomiui.net/the-meaning-of-all-miui-permissions-4380/)
- [Receive messages in Flutter apps (FCM)](https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages)
