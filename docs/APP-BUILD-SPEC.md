# Smriti Elder App — Build Specification (status-aware)

This is the same architecture given at project start, updated to reflect exactly what is
already built and verified in the current repo, and what remains. Read this fully before
touching code — it is the single source of truth for the tablet app.

---

## 0. Current state — verified against the actual repo, not just reported

| # | Milestone | Status | Verified how |
|---|---|---|---|
| 1 | Drift schema + DAOs | 🟢 **Done, correct** | All 10 tables present, every column matches spec including the 6 report-critical columns on `TrialEvents` (`itemId`, `initiationMs`/`movementMs`, `chosenId`/`errorClass`, `trialIndex`/`trialContext`, `metrics`) and `demoReplays` on `Sessions`. `AppConfigsDao` wired and tested. |
| 2 | AbilityEstimator | 🟡 **Present but incomplete — fix before continuing** | Implements the correct sigmoid/Elo-update *shape* but is missing: decaying K-factor, demographic seed function, `nextDifficulty()`, θ clamp, and response-time tracking. See §3 for the exact required implementation. |
| 3 | File path service | 🟡 **Functionally done, naming convention needs alignment** | All 7 directories created correctly under app documents dir. Uses subfolder-per-type (`people/photos/`, `people/voice/`) rather than flat filename convention (`people/{id}_photo.jpg`). Either works — pick one before MediaDownloader is built, since that's the first consumer. Recommendation: keep her directory structure, just confirm filenames inside are `{id}.jpg` / `{id}.m4a`. |
| 4–13 | Everything else | ⏳ **Not started** | Confirmed: `core/repo/`, `core/auth/`, `core/sync/`, `core/reminders/`, `core/voice/`, `lib/games/` are empty placeholder folders. `main.dart` still contains the default Flutter counter-app boilerplate. `login_screen.dart` has a QR button and Sign In button, both no-ops (`onPressed: () {}`). No `supabase_flutter` package added yet. |

**Do not restart or redesign items 1 and 3.** They are correct. Fix item 2, then proceed
in the order below.

---

## 1. The one principle

**SQLite on the tablet is the source of truth. Supabase is a sync destination, not a
database you query live.**

Games, reminders, ability estimation, photos and voice all read and write local SQLite and
local files. Nothing on screen ever waits on a network call. Supabase receives batches of
already-committed data after the fact, and supplies content updates when they exist.

Build against local SQLite with a mock content JSON first. Wire real Supabase calls last —
they already work server-side and are waiting for you, so this is the safest part to defer.

---

## 2. Packages — add now, none of this is in pubspec.yaml yet except drift/sqlite3/path

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8

  # already added — do not touch
  drift: ^2.31.0
  sqlite3_flutter_libs: ^0.5.42
  path_provider: ^2.1.5
  path: ^1.9.1

  # add these now
  flutter_riverpod: ^2.5.0
  supabase_flutter: ^2.5.0

  workmanager: ^0.5.2
  connectivity_plus: ^5.0.2
  android_alarm_manager_plus: ^4.0.0
  flutter_local_notifications: ^17.0.0
  permission_handler: ^11.3.0
  device_info_plus: ^9.1.2
  android_intent_plus: ^4.0.3
  wakelock_plus: ^1.2.0

  just_audio: ^0.9.36
  flutter_tts: ^4.0.2
  record: ^5.0.4
  speech_to_text: ^6.6.0

  kiosk_mode: ^0.5.0
  mobile_scanner: ^4.0.1
  url_launcher: ^6.2.5
  uuid: ^4.3.3
  fuzzywuzzy: ^1.1.6
  crypto: ^3.0.3

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  # already added
  drift_dev: ^2.31.0
  build_runner: ^2.15.1
```

```dart
// main.dart — DELETE the counter-app MyHomePage/_incrementCounter block entirely.
// Add before runApp():
await Supabase.initialize(
  url: 'https://yzhtgpaekoqaszxgbeyn.supabase.co',
  anonKey: '<ask for this — Settings → API in the Supabase dashboard>',
  authOptions: const FlutterAuthClientOptions(authFlowType: AuthFlowType.pkce),
);
```

Session persistence is automatic — the SDK stores and refreshes tokens itself.

---

## 3. Fix the AbilityEstimator — do this first, before Session Write Path

**Current implementation, for reference (in `lib/core/ability/estimator.dart`):**

```dart
class AbilityEstimator {
  double updateTheta({required double thetaBefore, required double itemDifficulty, required bool correct}) {
    final probability = _probability(thetaBefore, itemDifficulty);
    final response = correct ? 1.0 : 0.0;
    const learningRate = 0.1;
    return thetaBefore + learningRate * (response - probability);
  }
  double _probability(double theta, double difficulty) => 1.0 / (1.0 + exp(difficulty - theta));
}
```

This is the right shape but incomplete. **Replace with:**

```dart
import 'dart:math';

enum CognitiveDomain { memory, attention, executive, visuospatial, language }

class AbilityRecord {
  final double theta;
  final int nTrials;
  final double rtMeanLog;
  final double rtVar;
  const AbilityRecord({
    required this.theta, required this.nTrials,
    required this.rtMeanLog, required this.rtVar,
  });
  AbilityRecord copyWith({double? theta, int? nTrials, double? rtMeanLog, double? rtVar}) =>
      AbilityRecord(
        theta: theta ?? this.theta,
        nTrials: nTrials ?? this.nTrials,
        rtMeanLog: rtMeanLog ?? this.rtMeanLog,
        rtVar: rtVar ?? this.rtVar,
      );
}

class AbilityEstimator {
  static const double targetP = 0.78;
  static const double kMax = 0.40;
  static const double kMin = 0.08;
  static const double tau = 60.0;
  static const double rtAlpha = 0.1;

  /// Seed from demographics rather than zero — better than cold start.
  /// Coefficients are heuristic and documented as requiring local norming.
  static AbilityRecord seed(int age, int educationYears) {
    final theta = 0.35 * (educationYears - 8) / 4.0
                - 0.30 * (age - 70) / 10.0;
    return AbilityRecord(
      theta: theta.clamp(-2.0, 2.0),
      nTrials: 0,
      rtMeanLog: log(4000),
      rtVar: 0.25,
    );
  }

  static AbilityRecord update(
      AbilityRecord s, double itemDifficulty, bool correct, int responseTimeMs) {
    final p = 1.0 / (1.0 + exp(-(s.theta - itemDifficulty)));
    final k = kMin + (kMax - kMin) * exp(-s.nTrials / tau);
    final theta = s.theta + k * ((correct ? 1.0 : 0.0) - p);

    final clamped = responseTimeMs.clamp(200, 30000).toDouble();
    final lrt = log(clamped);
    final mean = s.rtMeanLog + rtAlpha * (lrt - s.rtMeanLog);
    final variance = s.rtVar + rtAlpha * (pow(lrt - mean, 2) - s.rtVar);

    return AbilityRecord(
      theta: theta.clamp(-4.0, 4.0),
      nTrials: s.nTrials + 1,
      rtMeanLog: mean,
      rtVar: variance,
    );
  }

  /// Difficulty that yields targetP success probability.
  static double nextDifficulty(double theta) =>
      theta - log(targetP / (1 - targetP));   // ≈ theta − 1.266
}
```

**Why each piece matters:**
- `seed()` — a new user starts near their expected baseline (education/age adjusted)
  instead of zero, so early sessions aren't wasted on badly miscalibrated difficulty.
- Decaying `k` — fast movement early (few trials seen), stable later. A fixed 0.1 rate
  never stabilizes and never adapts quickly either.
- `nextDifficulty()` — this is what the game harness calls to pick the next item's
  difficulty. Without it, nothing can actually adapt difficulty.
- RT tracking (`rtMeanLog`, `rtVar`) — response-time variability is one of the earliest
  cognitive-decline signals in the report pipeline. If this isn't captured now, it can
  never be backfilled once real sessions start.
- Clamp on θ — prevents runaway values from a pathological run of all-correct or
  all-incorrect trials.

**Required test — write this before moving on:**
```dart
test('theta converges to true ability', () {
  const trueTheta = 1.2;
  var s = AbilityEstimator.seed(76, 8);
  final rng = Random(42);
  for (var i = 0; i < 200; i++) {
    final b = AbilityEstimator.nextDifficulty(s.theta);
    final p = 1.0 / (1.0 + exp(-(trueTheta - b)));
    s = AbilityEstimator.update(s, b, rng.nextDouble() < p, 3000);
  }
  expect((s.theta - trueTheta).abs(), lessThan(0.3));
});
```
If this doesn't pass, nothing downstream — the games, the report, the whole cognitive
claim of the product — means anything. Fix this before writing a single game.

---

## 4. Layer architecture (target)

```
UI (screens, games) → Riverpod providers, zero network awareness
        ↓
Repositories (content_repo, event_repo, ability_repo, memo_repo) → SQLite only
        ↓
Drift (SQLite) ← source of truth
        ↓ (one-way, background only)
Sync layer (sync_engine, event_pusher, content_puller, media_downloader,
            memo_uploader, escalation_writer) → ONLY layer touching supabase_flutter
        ↓
Supabase (already live)
```

---

## 5. Local database schema — already correct, do not modify

`lib/core/db/tables.dart` matches spec exactly. Confirmed present: `TrialEvents`,
`Sessions`, `ReminderEvents`, `VoiceMemos`, `EscalationRequests`, `AbilityStates`,
`People`, `Medications`, `RoutineItems`, `AppConfigs`. All six report-critical columns on
`TrialEvents` are present. **Leave this file alone.**

`AppConfigs` keys to use (string key/value pairs, no schema change needed):
```
patientId · deviceUserId · langCode · script
elderName · age · educationYears
contentVersion · langPackVersion
primaryContactPhone · secondaryContactPhone
ladderConfigJson · caregiverPinHash
consentGivenAt · lastSyncAt · lastSyncError · clockSkewMs
```

---

## 6. File layout — already correct

`lib/core/files/file_paths.dart` correctly derives all paths from
`getApplicationDocumentsDirectory()` and creates directories on demand. Structure in use:

```
<docs>/people/photos/{personId}.jpg
<docs>/people/voice/{personId}.m4a
<docs>/medications/photos/{medId}.jpg
<docs>/medications/voice/{medId}.m4a
<docs>/language_packs/{langCode}/...
<docs>/memos/{memoId}.m4a
<docs>/tmp/
```

**Rule going forward:** nothing is ever fetched from the network at runtime. Games and
screens read files from disk only. If a file is missing, skip that item silently — never
show a broken-image placeholder to the elder.

---

## 7. The live backend — exact contract, do not deviate

This is real, deployed, and tested. Table/column names below are final.

**Project:** `https://yzhtgpaekoqaszxgbeyn.supabase.co`, region `ap-south-1`.

### Edge Functions (all live)
| Function | Called by app? | Purpose |
|---|---|---|
| `redeem-pairing-token` | **Yes** | QR/code pairing — returns device session |
| `pair-device-authenticated` | **Yes** | Caregiver-login pairing path |
| `escalation-worker` | No — fires automatically server-side | Places the phone call |
| `twilio-webhook` | No | Server-side only |
| `watchdog` | No | Server-side only, catches missed local alarms |

### RPCs the app calls
| RPC | Params | Returns |
|---|---|---|
| `get_patient_content` | `p_patient_id: uuid` | JSON: people[], medications[], routine[], escalation config |
| `device_heartbeat` | `p_patient_id, p_app_version, p_pending_events, p_device_time_ms` | `{ server_time_ms, clock_skew_ms }` |

### Tables the device writes (insert-only via Supabase client)
`events` · `sessions` · `reminder_events` · `memos` · `escalations`

All primary keys are client-generated UUID v4, except escalation rows which use
`{reminderEventId}_{step}`. All writes use `.upsert(rows, onConflict: 'id',
ignoreDuplicates: true)` — **never `.select()` after write, see AGENTS.md rule 4.**

`escalations.status` can be `requested | executing | completed | cancelled | failed` —
the device only ever writes `requested`. Do not treat any other value as an error if seen.

### Storage buckets
`patient-media` (photos, caregiver voice — private) · `patient-memos` (elder recordings —
private) · `lang-packs` (shared, read-only)

### Pairing code alphabet — exact, copy verbatim
```
ACDEFGHJKLMNPQRSTUVWXYZ2345679
```
(No `B`, `I`, `O`, `0`, `1`, `8` — excluded because they're visually or verbally
ambiguous.) If you build any client-side format validation for a typed-in code, it must
accept exactly this alphabet, 8 characters.

---

## 8. Auth and pairing — build this after fixing the estimator

### Three entry paths, one exit state

However pairing happens, the tablet ends identically: signed in as a device identity
whose JWT carries `app_metadata.patient_id` and `app_metadata.is_device = true`, with
`patientId`/`langCode` in `AppConfigs`, holding **no caregiver credentials**.

```dart
// lib/core/auth/pairing_service.dart

class PairingService {
  Future<void> redeemToken(String token) async {
    final res = await Supabase.instance.client.functions.invoke(
      'redeem-pairing-token',
      body: {'token': token.toUpperCase().replaceAll('-', '')},
    );
    if (res.status != 200) {
      throw PairingException(res.data?['error'] ?? 'invalid or expired code');
    }
    await _completePairing(res.data as Map);
  }

  Future<void> pairViaCaregiverLogin(String email, String password, String patientId) async {
    await Supabase.instance.client.auth.signInWithPassword(email: email, password: password);
    final res = await Supabase.instance.client.functions.invoke(
      'pair-device-authenticated',
      body: {'patient_id': patientId},
    );
    await Supabase.instance.client.auth.signOut();  // ★ mandatory, see AGENTS.md rule 8
    await _completePairing(res.data as Map);
  }

  Future<void> _completePairing(Map data) async {
    await Supabase.instance.client.auth.setSession(data['refresh_token']);
    await _config.setAll({
      'patientId': data['patient_id'],
      'deviceUserId': data['device_user_id'],
      'langCode': data['lang_code'],
      'elderName': data['elder_name'],
      'age': data['age'].toString(),
      'educationYears': data['education_years'].toString(),
    });
    await _abilityRepo.seedAll(
      int.parse(data['age'].toString()),
      int.parse(data['education_years'].toString()),
    );
  }
}
```

QR path calls `redeemToken` with the scanned string. 8-character code entry path calls the
same function with the typed string. Both are "Path A/B" from the original spec — one
mechanism, two input methods.

`login_screen.dart` currently has a QR button and Sign In button, both no-ops. Wire the QR
button to a scan screen (using `mobile_scanner`) that calls `redeemToken`. The Sign In
button becomes the caregiver-login fallback path, not primary — it should not be the most
prominent element on this screen once wired.

### Device replacement
Server already enforces one active device per patient and revokes the old one on re-pair.
On the old device receiving a 401 post-pairing, show a caregiver-facing "this tablet is no
longer active" screen. **Do not delete local data.**

### Auth loss
If the session is ever null after pairing, the app keeps working completely — games,
reminders, photos, everything. Only sync stops. Never show this to the elder.

---

## 9. Sync engine — build after pairing works

```dart
class SyncEngine {
  static const _minInterval = Duration(minutes: 2);
  Future<SyncResult> run({SyncTrigger trigger = SyncTrigger.periodic}) async {
    if (_running) return SyncResult.skipped('already running');
    if (!await _hasConnection()) return SyncResult.skipped('offline');
    if (Supabase.instance.client.auth.currentSession == null) {
      return SyncResult.skipped('not authed');
    }
    _running = true;
    final errors = <String>[];
    try { await _eventPusher.push(); }        catch (e) { errors.add('events: $e'); }
    try { await _escalationWriter.flush(); }  catch (e) { errors.add('escalations: $e'); }
    try { await _memoUploader.upload(); }     catch (e) { errors.add('memos: $e'); }
    try { await _contentPuller.pull(); }      catch (e) { errors.add('content: $e'); }
    try { await _heartbeat(); }               catch (e) { errors.add('heartbeat: $e'); }
    _running = false;
    return errors.isEmpty ? SyncResult.ok() : SyncResult.partial(errors);
  }
}
```

**Each sync stage is independently wrapped.** A content-pull failure must never prevent
event upload.

Triggers: connectivity regained, every 15 min via `Workmanager`, app foreground, and
immediately after a session ends.

### EventPusher
```dart
await sb.from('events').upsert(
  rows.map((r) => {...r.toRemoteJson(), 'patient_id': pid}).toList(),
  onConflict: 'id',
  ignoreDuplicates: true,
);
```
Same pattern for `sessions`, `reminder_events`. **Never `.select()` after this call.**

### ContentPuller
```
1. cheap version check (select content_version from patients)
2. if remote > local: full payload via get_patient_content RPC
3. download all referenced media to tmp/, verify complete, move into place
4. atomic Drift transaction: replace people/medications/routine rows, bump contentVersion
5. reschedule all alarms — medication times may have changed
6. language pack, if version bumped
```
**Order matters. Media before rows before alarms.** If a download fails halfway, keep the
old, fully-working content set — never bump `contentVersion` first.

### MemoUploader
Storage upload first, then the `memos` row insert. A row pointing at a file that never
uploaded is worse than a file with no row.

### Heartbeat
```dart
await Supabase.instance.client.rpc('device_heartbeat', params: {
  'p_patient_id': pid,
  'p_app_version': packageInfo.version,
  'p_pending_events': await _eventRepo.unsyncedCount(),
  'p_device_time_ms': DateTime.now().millisecondsSinceEpoch,
});
```

**The server watchdog already exists and is live-tested.** It independently detects a
device gone quiet or a dose never reported, and triggers the same real phone-call
escalation. You are not building any of that — just make sure the heartbeat fires
regularly so the server has accurate `device_last_seen_at` data.

---

## 10. Reminders — the highest-risk component

Allocate real time here. Test on a physical Android device every day you touch this code.

### Scheduling
```dart
class AlarmScheduler {
  int _alarmId(String medId, int dayOfWeek) =>
      (medId.hashCode & 0x00FFFFFF) * 10 + dayOfWeek;

  Future<void> rescheduleAll() async {
    final meds = await _contentRepo.activeMedications();
    for (final med in meds) {
      for (final day in med.daysOfWeekList) {
        await AndroidAlarmManager.cancel(_alarmId(med.id, day));
      }
    }
    for (final med in meds) {
      for (final day in med.daysOfWeekList) {
        await AndroidAlarmManager.oneShotAt(
          _nextOccurrence(day, med.chosenTimeMin),
          _alarmId(med.id, day),
          fireReminderCallback,
          exact: true, wakeup: true, allowWhileIdle: true, rescheduleOnReboot: true,
          params: {'medicationId': med.id, 'dayOfWeek': day},
        );
      }
    }
  }
}
```

### The isolate constraint
`AndroidAlarmManager` callbacks run in a separate isolate with **no access to anything in
the main isolate.**

```dart
@pragma('vm:entry-point')
Future<void> fireReminderCallback(int id, Map<String, dynamic> params) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  final db = SmritiDatabase(await openConnectionForIsolate());  // OWN connection
  final med = await db.getMedication(params['medicationId']);
  if (med == null || !med.active) return;

  final reminderEventId = const Uuid().v4();
  await db.insertReminderEvent(/* ... channel: 'in_app', ladderStep: 0 */);
  await _showFullScreenNotification(reminderEventId, med);
  await _playCaregiverAudio(med.voicePath);
  await _scheduleLadderStep(reminderEventId, med.id, step: 1, delayMin: 15);
  await _scheduleLadderStep(reminderEventId, med.id, step: 2, delayMin: 30);
  await _scheduleNextOccurrence(med, params['dayOfWeek'] as int);
  await db.close();
}
```

### Manifest
```xml
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS"/>
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT"/>
<uses-permission android:name="android.permission.CALL_PHONE"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>

<activity android:name=".MainActivity" android:screenOrientation="landscape"
  android:launchMode="singleTop" android:showWhenLocked="true"
  android:turnScreenOn="true" android:exported="true"/>
```
**None of these permissions exist in the manifest yet — confirmed by inspection.**

### The ladder
| Step | When | Owner |
|---|---|---|
| 0 | T+0 | Device — full-screen, caregiver's voice |
| 1 | T+15m | Device — repeat, louder |
| 2 | T+30m | Device writes `escalations` row → server places a real phone call (already proven working) |
| 3–5 | later | Server only |

Steps 0–1 work offline. Step 2 is a fire-and-forget write to `escalations` — the server
does everything after that, and it is already tested end-to-end including a real ringing
phone.

### Setup health check
```dart
Future<HealthCheckReport> run() async {
  // request scheduleExactAlarm, notification, ignoreBatteryOptimizations, microphone
  // detect OEM (Xiaomi/Oppo/Vivo/Huawei/Samsung) → open autostart settings
  // schedule a REAL test alarm 60s out, require caregiver to confirm they saw it
}
```
Granted permissions do not mean alarms fire — OEM battery managers kill background work
regardless. The live test is mandatory, not optional.

---

## 11. Games — build the harness before any specific game

```dart
abstract class CognitiveGame {
  String get id;
  CognitiveDomain get primaryDomain;
  PhraseKey get introPhrase;
  Future<void> playDemo(BuildContext context);       // ghost-hand demo
  GameItem generateItem(double difficulty, GameContent content);
  Stream<TrialResult> get trials;
}
```

The session runner owns: the 6-minute session cap, calling `AbilityEstimator.update()`
after every trial, writing every `TrialEvents` row with all required fields (see §5's
column list — every field must be populated, not just the obvious ones), incrementing
`demoReplays`, and the no-negative-feedback rule (AGENTS.md rule 11).

Games only emit `TrialResult { correct, itemDifficulty, initiationMs, movementMs, chosenId,
errorClass, metrics }`. They never call Drift or Supabase directly.

Build one game end-to-end against the harness before building the rest — this validates
the whole pipeline (estimator → event write → sync-ready row) in one vertical slice.

---

## 12. Diagnostics screen

Hidden behind kiosk exit (long-press corner → caregiver PIN). Shows: patient/device ID,
content version, last sync time/error, pending event count, auth status, clock skew,
health check results with re-run, next scheduled alarms, and a "fire test reminder now"
button. Caregiver-facing register — normal density, not elder styling.

---

## 13. The 48-hour offline test

Before considering sync "done": put the tablet in airplane mode, play sessions across two
days, confirm reminders fire and the ladder progresses locally, then reconnect and verify
everything uploads with no duplicates and no data loss. This is the test that proves the
core design promise actually holds.

---

## 14. Build order from here

| # | Task | Depends on |
|---|---|---|
| 1 | **Fix AbilityEstimator** per §3, add the convergence test | Nothing |
| 2 | Repositories (`content_repo`, `event_repo`, `ability_repo`, `memo_repo`) | Step 1, existing schema |
| 3 | Session write path + mock content JSON, one game harness | Step 2 |
| 4 | Add Supabase package, wire pairing (QR + code) on existing login screen | Nothing blocking — can run parallel to 2–3 |
| 5 | Content pull (`get_patient_content`) | Step 4 |
| 6 | Alarm scheduler + reminder isolate + health check | Steps 2, 5 |
| 7 | Event pusher, escalation writer, heartbeat | Steps 2, 4 |
| 8 | Remaining games on the harness from step 3 | Step 3 |
| 9 | Diagnostics screen | Steps 5, 7 |
| 10 | 48-hour offline test | Everything above |

Steps 1–3 need no backend at all and can proceed immediately. Step 4 is where real,
already-deployed infrastructure gets consumed for the first time.
