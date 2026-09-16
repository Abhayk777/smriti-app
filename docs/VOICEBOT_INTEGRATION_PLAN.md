# "Talk to Smriti" — VoiceBot Integration Plan

Status: **Plan only. Nothing implemented.** Written 2026-09-15 against branch `complete-app`
(last commit `7c10034`).

**How to use this document (for the implementing agent):**
1. Read `AGENTS.md` first. Every non-negotiable there still applies.
2. Do **one task (V01, V02, …) per session**, in order. Each task has acceptance criteria (AC).
3. Run `flutter analyze` after every Flutter change and paste the full output.
4. Only touch the files listed for that task. If something here contradicts the code you
   find, **stop and ask**. Don't pick one silently.
5. The VoiceBot reference docs live in `VOICE BOT ML/` (untracked folder at the repo root).
   The Flutter-specific guide is not in that folder. It is at
   https://github.com/harshita10sharma/Smriti-VoiceBot/blob/main/docs/FLUTTER_VOICEBOT_INTEGRATION.md
   Authority order when docs disagree: `INTEGRATION_CONTRACT.md` > `VOICEBOT_INTEGRATION_GUIDE.md`
   > the Flutter/Backend guides > `API_INTEGRATION.md`. See §9 for the known conflicts.

---

## 1. Goal

A **"Talk to Smriti"** button in the home screen's bottom strip, **between "Message" and
"Medicine"**. One tap opens a voice-assistant screen. Smriti greets the elder. The elder
taps a large mic, speaks, and Smriti answers on screen right away, then out loud when the
voice audio is ready. The assistant can answer questions about the elder's family, medicines
and routine (from the caregiver's data). It can also open Games / My Family / My Day /
Medicine when asked.

**The rule that overrides everything:** adding the bot must not change or break any existing
feature. Reminders, alarms, games, memos, sync, pairing and the web-app sync keep working
exactly as today, **including when the VoiceBot is down or the tablet is offline**.

---

## 2. Hard constraints

From `AGENTS.md`:
- **C1.** Only files in `lib/core/sync/` and `lib/core/auth/` may import `supabase_flutter`.
- **C2.** Nothing about connectivity, errors or sync is ever shown to the elder. Failures show
  a gentle, non-technical line. Details go to the hidden diagnostics screen only.
- **C3.** No new package without asking. **This plan needs none** (see D5).
- **C4.** Do not invent Supabase table/column names.
- **C5.** Test on a real Android device, never only an emulator.
- **C6.** Must work on **every Android brand and version** (minSdk 24, target 36). Use standard
  APIs only; no OEM-specific code is needed for this feature. When reporting results, say
  which devices and Android versions were actually tested.

From the VoiceBot contract (`INTEGRATION_CONTRACT.md` §9, §14; Flutter guide §2, §23):
- **C7.** **The VoiceBot `x-api-key` never goes in the app**: not in code, config, `.env`,
  assets or logs. The app talks only to our own backend, which holds the key.
- **C8.** Record only on an explicit tap. One WAV per utterance.
- **C9.** Show `response_text` immediately. Never block the UI on speech synthesis (TTS).
- **C10.** Poll a voice job every 1–2 s and stop the instant it is `completed`/`failed`/`cancelled`.
- **C11.** Cancel the job (don't just stop polling) when the user backs out. Ignore any late
  result for a cancelled/superseded job.
- **C12.** Only act on `action` when `action_accepted == true`, and only for allow-listed
  strings. Never act on `response_text` or the transcript.
- **C13.** Medication-reminder/alarm audio always wins over bot audio. They never overlap.
- **C14.** Calling (`call_family_member`) and conversational reminders (`create_reminder`)
  stay **disabled**. Nothing in the app places a call or schedules an alarm because the bot
  said so.
- **C15.** Discard the bot `session_id` when the tablet is re-paired to a different patient.

---

## 3. Decisions

| # | Decision | Why |
|---|---|---|
| **D1** | **Add a Supabase Edge Function `voicebot-gateway` as the proxy.** The app calls it with its existing device session. The function holds `VOICEBOT_API_KEY` as a Supabase secret and calls VoiceBot. | Required by C7. The app already calls Edge Functions (`redeem-pairing-token`, `pair-device-authenticated`) with the device JWT, so there is **no new auth system**. Calling VoiceBot directly with the key in the APK is **rejected**: an APK can be decompiled, and whoever holds the key can talk as the patient and read their memory. |
| **D2** | **VoiceBot `user_id` = `patients.id` (UUID)**, taken **server-side from the device JWT's `app_metadata.patient_id`**. Never from the request body. | Documented 1:1 mapping (`BACKEND_VOICEBOT_INTEGRATION.md` §2). Taking it from the JWT stops one tablet from talking as another patient. |
| **D3** | **Memory sync happens lazily inside the gateway on `welcome`**: fetch `get_patient_content` as the device, whitelist fields, then `POST /v1/memory/sync` with `source_revision = content version`. | **Zero changes to the web app, `ContentPuller` or the DB schema.** Revision semantics make repeats a cheap `no_op`. Trade-off: a caregiver edit made mid-conversation reaches the bot on the next screen open. A durable webhook-based sync can come later (§10). |
| **D4** | **Language:** send the patient's `langCode` on `welcome`. **Omit `language` on voice turns** so VoiceBot auto-detects per turn and code-switching works. Keep it behind one constant (`kSendLanguageOnTurns = false`) so it can be flipped after device testing. | Contract §12 priority order. An explicit `language` always wins and would block mid-conversation switching. |
| **D5** | **No new packages.** Use `record` (WAV, the same config as `voice_memo_screen.dart`), `just_audio`, `permission_handler`, `uuid`, `connectivity_plus`, `path_provider` and `Supabase.instance.client.functions.invoke`. | Verified: `functions_client 2.7.1` sends a `Uint8List` body as `application/octet-stream` and returns an `application/octet-stream` response as a `Uint8List`. It also supports `queryParameters`, custom headers and an `abortSignal`. So no `package:http` is needed. |
| **D6** | **No Drift schema change, no new tables.** The bot session id lives in `AppConfigs` (key-value). Transcripts are **not stored** on the device. | Zero migration risk. Privacy: the conversation stays on screen only. |
| **D7** | **The app does not implement** calling or reminder actions (C14). Only the navigation actions `OPEN_PLAY`, `OPEN_MY_PEOPLE`, `OPEN_TODAY`, `OPEN_MEDICINE`, plus `HELP` and `STOP`. | The contract gates these off. The app has no executor for them. |
| **D8** | **Tap-to-talk, not auto-listen.** After the greeting, the elder taps the big mic to start and taps again to send. Recording also auto-stops at 30 s. | C8. It also avoids recording Smriti's own greeting through the speaker. |

---

## 4. Prerequisites: owner actions before any agent starts

These are **not agent tasks**. They need a human with access.

- [ ] **P1. BLOCKER: VoiceBot key → patient mapping.** The live VoiceBot runs in
  **single-user mode bound to `elder-1`** (`INTEGRATION_CONTRACT.md` §1, `SECURITY.md`). Every
  request with a real patient UUID will get **403** until the VoiceBot operator (the
  Smriti-VoiceBot repo owner) switches to `SMRITI_API_KEYS` with our key mapped to a **list of
  real `patients.id` UUIDs**. Do **not** map every patient to `elder-1`. They would share one
  memory. For the pilot, list the paired patient(s) UUIDs explicitly.
- [ ] **P2. VoiceBot rate limit.** VoiceBot has a 60 requests/min fixed-window limiter. One
  conversation uses about 1 turn + 3–10 polls + 1 audio fetch. Ask the operator to raise the
  limit for our key, or at least confirm it. The client polls every 2 s to stay within budget.
- [ ] **P3. Confirm call/reminder tools are off** on the live deployment (the operator can check
  `GET /v1/tools`). If they're advertised, the bot may *say* "I'll call Bina" even though
  nothing happens.
- [ ] **P4. Supabase deploy access.** Someone must be able to run
  `supabase functions deploy` and `supabase secrets set` on project `yzhtgpaekoqaszxgbeyn`. The
  Edge Function source belongs in the backend/web repo (`Abhayk777/SMRITI`,
  `supabase/functions/`), next to the existing functions. **It is not in this Flutter repo.**
- [ ] **P5. Set secrets yourself.** Never paste the key into chat, the repo or this doc:
  ```
  supabase secrets set VOICEBOT_BASE_URL=https://15-206-144-216.nip.io
  supabase secrets set VOICEBOT_API_KEY=<your key>
  supabase secrets set VOICEBOT_ENABLED=true
  supabase secrets set VOICEBOT_PATIENT_ALLOWLIST=<uuid1>,<uuid2>   # optional pilot gate; empty = all
  ```
- [ ] **P6. Confirm two backend facts** for the V02 agent:
  (a) the JSON type of `get_patient_content`'s `version` field (integer or not);
  (b) whether a device-binding/revocation table exists that the gateway should check in
  addition to the JWT. Give the agent the exact table/column name, or say "none".

---

## 5. Architecture

```
Tablet (Flutter)                          Supabase                          AWS
────────────────                          ────────                          ───
HomeScreen ─tap─▶ VoiceBotScreen
                    │
             VoiceBotController (core/voice, no Supabase import)
                    │  record WAV / play WAV / poll / cancel
             SupabaseVoiceBotGateway (core/sync — only file that
                    │   touches Supabase for the bot)
                    │  functions.invoke('voicebot-gateway/…')
                    │  Authorization: device JWT (automatic)
                    ▼
                                  Edge Function `voicebot-gateway`
                                   1. verify JWT, is_device == true
                                   2. patient_id = app_metadata.patient_id
                                   3. kill-switch / allowlist
                                   4. (welcome) lazy memory sync
                                   5. forward with x-api-key ───────────▶ VoiceBot API
                                   6. whitelist response fields ◀─────── (nip.io, HTTPS)
```

### File map

**New (Flutter, this repo):**
| File | Purpose |
|---|---|
| `lib/core/sync/voicebot_gateway.dart` | `VoiceBotGateway` interface + `SupabaseVoiceBotGateway`. The **only** bot file that imports `supabase_flutter` (C1). |
| `lib/core/voice/voicebot_models.dart` | Typed DTOs and enums: `VoiceBotTurn`, `VoiceBotWelcome`, `VoiceBotJob`, `TurnKind`, `JobStatus`, `VoiceBotAction`, `VoiceBotFailure`, `VoiceBotException`. |
| `lib/core/voice/voicebot_audio.dart` | Thin `BotRecorder` / `BotPlayer` interfaces over `record` / `just_audio`, so the controller is unit-testable. |
| `lib/core/voice/voicebot_controller.dart` | State machine (a `ChangeNotifier`): welcome, record, send, poll, play, cancel, interrupt, session persistence. |
| `lib/screens/voicebot_screen.dart` | The assistant UI. |
| `test/voicebot/…` | Unit tests (V03, V04). |

**New (backend repo `Abhayk777/SMRITI`):**
| File | Purpose |
|---|---|
| `supabase/functions/voicebot-gateway/index.ts` | The gateway (V01, V02). |

**Modified: additive only, nothing existing is removed or reworked:**
| File | Change |
|---|---|
| `lib/screens/home_screen.dart` | Add the Talk button between Message and Medicine (V06). |
| `lib/screens/diagnostics_screen.dart` | Add a "VoiceBot" status block + test button (V09). |
| `android/app/src/main/AndroidManifest.xml` | Add `android.permission.INTERNET` (V03). **Pre-existing gap:** today only the `debug`/`profile` manifests declare it, so a **release** APK has no network for Supabase *or* the bot. |

**Must not be touched:** `pubspec.yaml`, `lib/core/db/**` (schema/DAOs), `sync_engine.dart`,
`content_puller.dart` and the rest of `lib/core/sync/*` except the new file,
`lib/core/reminders/**`, `lib/core/auth/**`, all Kotlin files, `main.dart`, games, and every
other screen.

---

## 6. Tasks

### V01 — Edge Function `voicebot-gateway` (backend repo)

One function with sub-routes. `functions.invoke('voicebot-gateway/welcome')` reaches
`/functions/v1/voicebot-gateway/welcome`, so the function routes on `new URL(req.url).pathname`.
*(If sub-path routing misbehaves, fall back to a `?op=welcome` query parameter. Same code.)*
Keep JWT verification **on** (the default `verify_jwt`). Match the import style and CORS
helpers of the existing functions in that repo.

**Routes** (the client never sends `user_id`; the gateway adds it):

| Gateway route | Method | Client sends | Gateway calls VoiceBot | Returns to client |
|---|---|---|---|---|
| `/voicebot-gateway/health` | GET | — | `GET /v1/health` | `{ok: bool, enabled: bool}` |
| `/voicebot-gateway/welcome` | POST | JSON `{session_id?, language?, speak}` | (V02 sync) then `POST /v1/conversation/welcome` | Welcome DTO |
| `/voicebot-gateway/voice` | POST | **raw WAV bytes** (`application/octet-stream`); query `session_id?`, `language?`, `speak`; header `X-Idempotency-Key` | `POST /v1/conversation/voice` (multipart: `audio_wav` as `audio/wav`, `user_id`, `session_id`, `language`, `speak`) + the idempotency header, forwarded verbatim | Turn DTO |
| `/voicebot-gateway/text` | POST | JSON `{session_id?, message, language?}`; header `X-Idempotency-Key` | `POST /v1/conversation` | Turn DTO |
| `/voicebot-gateway/jobs/{id}` | GET | — | `GET /v1/voice/jobs/{id}` | Job DTO |
| `/voicebot-gateway/jobs/{id}/cancel` | POST | — | `POST /v1/voice/jobs/{id}/cancel` | `{cancelled: bool, status}` |
| `/voicebot-gateway/audio/{id}` | GET | — | `GET /v1/audio/{id}` | raw bytes with **`Content-Type: application/octet-stream`** (so the Dart client receives a `Uint8List`) |

**Every request, in order:**
1. `createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {global: {headers: {Authorization: req.headers.get('Authorization')}}})`,
   then `auth.getUser()`. No user → `401 {error:'UNAUTHENTICATED'}`.
2. Require `user.app_metadata.is_device === true` and a non-empty
   `user.app_metadata.patient_id` → else `403 {error:'NOT_A_DEVICE'}`. (Caregiver/web access is
   out of scope.)
3. If P6(b) names a device-binding table, check it here.
4. `VOICEBOT_ENABLED !== 'true'` or patient not in a non-empty `VOICEBOT_PATIENT_ALLOWLIST` →
   `503 {error:'VOICEBOT_DISABLED'}`.
5. Validate path ids against `^[A-Za-z0-9]{8,64}$` and `encodeURIComponent` them. **Only the
   fixed VoiceBot paths above are ever called. No arbitrary URL proxying, no redirects**
   (`redirect: 'error'`).
6. Voice route: the body must be ≤ 10 MiB and start with `RIFF`…`WAVE` (bytes 0–3 and 8–11),
   else `415 {error:'BAD_AUDIO'}`. `X-Idempotency-Key` must be ≤ 128 characters.
7. Language mapping (applies to `language` from the client): `en→eng, hi→hin, as→asm,
   mni→mni, kha→kha, lus→lus`. Pass through a value that is already a 3-letter code. Drop
   anything unknown (never send a code VoiceBot will reject with 400).
8. Upstream timeouts via `AbortSignal.timeout`: voice/text/welcome 45 s, jobs/cancel 10 s,
   audio 20 s.

**Response whitelist:** don't pass the raw VoiceBot body through. Build these DTOs:
- **Turn:** `request_id, session_id, response_text, language, kind, action, action_accepted,
  requires_confirmation, transcript (voice only), job_id, job_status, audio_available,
  audio_unavailable_reason, action_id (from metadata.action_id), error_code (from
  metadata.error_code), tool_failed (true if any tool_results[].ok == false)`.
- **Welcome:** `request_id, session_id, response_text, language, session_restored, job_id, job_status`.
- **Job:** `job_id, status, audio_id, error_code, audio_expired`. **Drop `audio_url`.** The
  client only ever uses `audio_id` through the gateway.

**Error mapping** (always a JSON `{error: CODE}`; never echo VoiceBot's `detail`, headers or the key):

| VoiceBot | Gateway → client |
|---|---|
| 400 | 400 `BAD_REQUEST` |
| 401 / 503 | 502 `UPSTREAM_AUTH` (our config is broken; alert, don't retry) |
| 403 | 403 `PATIENT_FORBIDDEN` (key not mapped, see P1, or patient disabled) |
| 404 | 404 `NOT_FOUND` |
| 409 | 409 `CONFLICT` |
| 413 / 415 / 422 | same status, `TOO_LARGE` / `BAD_AUDIO` / `INVALID` |
| 429 | 429 `RATE_LIMITED` |
| 5xx | 502 `UPSTREAM_ERROR` |
| network / timeout | 504 `UPSTREAM_UNAVAILABLE` |

**Logging:** only `patient_id`, route, upstream status, latency ms and `request_id`. **Never**
the transcript, `response_text`, audio, memory payload, `Authorization` or `x-api-key`.

**AC:**
- `curl` with a real device JWT: `health`, then `welcome`, `voice` (a sample 16 kHz WAV),
  `jobs/{id}` until completed, then `audio/{id}` saves a playable WAV.
- A request that adds `user_id` of another patient in the body/query has **no effect** (the
  gateway ignores it).
- No JWT → 401. A caregiver (non-device) JWT → 403. `VOICEBOT_ENABLED=false` → 503.
- `grep -ri "api.key\|x-api-key" supabase/functions/voicebot-gateway` shows it only read from
  `Deno.env`, never logged.

### V02 — Lazy memory sync on `welcome` (backend repo)

Before forwarding `welcome`, sync the patient's caregiver data into VoiceBot:
1. Call `rpc('get_patient_content', {p_patient_id})` **with the device's JWT** (the same call
   `ContentPuller` makes; no service-role key needed).
2. Build a `MemorySyncRequest` (schema: `VOICE BOT ML/memory_schema.json`,
   `additionalProperties: false`, so **any extra field → 422 for the whole sync**):

| VoiceBot field | From `get_patient_content` | Rule |
|---|---|---|
| `user_id` | `patient_id` (from JWT) | |
| `display_name` | `elder_name` | truncate to 120 |
| `timezone` | `timezone` | |
| `language_code` | `lang_code` | map as in V01 step 7 |
| `source_revision` | `version` | **only if it is a non-negative integer** (P6a); otherwise omit (always-apply) |
| `family_members[]` | `people[]` | `external_id=id`, `name` (≤80, **skip row if empty**), **`relationship`** (≤40; if empty use `"family"`, since minLength is 1), `memory_prompt` (≤500), `is_deceased`, `phone_available: false` |
| `medicines[]` | `medications[]` | `external_id=id`, `name` (≤80, skip if empty), `dose` (≤40), `chosen_time_min`, `window_start_min`, `window_end_min` (send only if `start ≤ chosen ≤ end`, else omit all three), `days_of_week`, `active` |
| `daily_routines[]` | `routine[]` (or `routine_items[]`) | `external_id=id`, `time = HH:MM` from `time_min`, `activity = label_key` (≤120, skip if empty; the app's My Day screen already shows `label_key` as plain text) |

   **Never send:** `photo_path`, `voice_path`, `pill_photo_path`, escalation config, phone
   numbers, age, education. **Sort every array by `external_id`** so the same revision always
   produces identical content. Otherwise VoiceBot reports a 409 conflict. Always send all three
   arrays (use `[]` for empty).
3. `POST /v1/memory/sync` with a **4 s timeout**. `200 applied/no_op` → fine. 409 (stale/
   conflict) → log and continue. Any failure → log and **still return the welcome**. A sync
   problem must never block the conversation.

**AC:** after a caregiver edits a family member on the web app, opening the bot and asking
"What is my daughter's name?" returns the new data. A second `welcome` with no content
change logs `no_op`. An empty relationship or a long memory prompt never produces a 422.

### V03 — Flutter models + gateway client

- `android/app/src/main/AndroidManifest.xml`: add
  `<uses-permission android:name="android.permission.INTERNET"/>` (see §5; fixes release builds
  for the whole app).
- `lib/core/voice/voicebot_models.dart`: DTO parsing is tolerant: unknown enum strings map to
  `unknown`, missing optionals are null. `VoiceBotAction.fromWire` knows only `OPEN_PLAY,
  OPEN_MY_PEOPLE, OPEN_TODAY, OPEN_MEDICINE, HELP, STOP`. Everything else is `none`.
  `JobStatus.isTerminal` covers `completed|failed|cancelled` (compare case-insensitively:
  the turn response says `QUEUED`, the job endpoint says `queued`).
- `lib/core/sync/voicebot_gateway.dart`: follow the `PairingGateway` pattern in
  `pairing_service.dart`: an abstract interface plus a Supabase implementation.
  ```dart
  abstract class VoiceBotGateway {
    Future<bool> health();
    Future<VoiceBotWelcome> welcome({String? sessionId, String? language, required bool speak});
    Future<VoiceBotTurn> sendVoice({required Uint8List wav, String? sessionId, String? language,
        required bool speak, required String idempotencyKey, Future<void>? abort});
    Future<VoiceBotTurn> sendText({required String message, String? sessionId, String? language,
        required String idempotencyKey});
    Future<VoiceBotJob> getJob(String jobId);
    Future<void> cancelJob(String jobId);           // swallow errors: best-effort
    Future<Uint8List?> fetchAudio(String audioId);  // null on 404 = expired, not an error
  }
  ```
  - `sendVoice` calls `functions.invoke('voicebot-gateway/voice', body: wav,
    queryParameters: {...}, headers: {'X-Idempotency-Key': key}, abortSignal: abort)`.
  - Before each call, if `auth.currentSession == null`, restore it from
    `AppConfigs.deviceRefreshToken` exactly as `SyncEngine._run` does (copy the few lines;
    **don't modify SyncEngine**).
  - Map exceptions to `VoiceBotException(VoiceBotFailure.x)`: `FunctionsHttpException.status`
    → by the V01 table. `FunctionsFetchException`/`SocketException`/`TimeoutException` →
    `offline`. `RequestAbortedException` → `cancelled`.
  - Client timeouts via `.timeout()`: voice 40 s, text/welcome 20 s, job/cancel 8 s, audio 15 s.
  - After any failure, write `lastVoicebotError` = `"<failure> <status> <ISO time>"` to AppConfigs
    (diagnostics only). After a success, write `lastVoicebotOkAt`.

**AC:** `test/voicebot/models_test.dart` parses the example JSON from
`INTEGRATION_CONTRACT.md` §2/§4 (welcome, turn, job completed/failed/`audio_expired`).
Unknown action → `none`. `QUEUED`/`queued` → the same status. `grep -rn supabase_flutter lib/`
shows no new file outside `core/sync`/`core/auth`. `flutter analyze` is clean.

### V04 — Conversation controller

`lib/core/voice/voicebot_controller.dart`, a `ChangeNotifier` holding an immutable view state:

```
enum BotPhase { connecting, ready, recording, sending, unavailable }
state: phase, messages (last ~6 {fromElder, text}), speaking (bool),
       awaitingConfirmation (bool), canRetry (bool), recordSeconds
```

Flow (maps onto the contract's §14 state machine):
- **open()**: if there is no connectivity → `unavailable`. Otherwise `connecting` → `welcome(
  sessionId: storedSession, language: langCode, speak: true)` → add Smriti's greeting →
  `ready` → start the job flow for its `job_id`. A welcome failure → `unavailable` (except
  `offline` from a flaky call: allow one automatic retry after 2 s).
- **startRecording()**: stop any bot playback, **cancel the pending job**, bump `_gen`, check
  mic permission (`recorder.hasPermission()` → `Permission.microphone.request()`), then record
  to `<temp>/voicebot/<uuid>.wav` with **`RecordConfig(encoder: AudioEncoder.wav, numChannels:
  1, sampleRate: 16000)`**. This is the exact config `voice_memo_screen.dart` uses, chosen
  because it plays and uploads identically on every chipset. Auto-stop at **30 s**.
- **stopAndSend()**: recordings shorter than 0.7 s are discarded with the reply "I didn't
  catch that. Tap and speak again." Otherwise `sending`. Generate `idempotencyKey = Uuid().v4()`
  **once per recording** and keep it with the WAV bytes. Call `sendVoice(speak: true,
  language: kSendLanguageOnTurns ? langCode : null)`. On success: add the transcript (if
  non-empty) as the elder's bubble and `response_text` as Smriti's bubble, save the
  `session_id`, then go to `ready` (the mic is usable while the audio is still loading) and
  start the job flow. On `offline`/`timeout`: `canRetry = true`, keep the WAV and key, and
  **assume nothing executed**. **retry()** resends the *same* bytes with the *same* key. On
  `patientForbidden`/`upstreamAuth`/`disabled` → `unavailable`. Delete the WAV file once it's
  no longer needed.
- **Job flow(jobId, gen)**: first poll after 1 s, then **every 2 s** (P2). Stop at a terminal
  status, or after a 90 s client cap (then cancel). `429` → wait 4 s and continue. On
  `completed && !audio_expired` → `fetchAudio` → write it to `<temp>/voicebot/<jobId>.wav` →
  play, and set `speaking` while it plays. A `failed` status, expired audio or a null fetch →
  text-only, silently. **Every await checks `gen == _gen` and drops the result if it's stale**
  (C11).
- **interrupt()**: called on `STOP`, back navigation, dispose and lifecycle pause (V08). It
  stops the recorder (and discards its file), stops the player, cancels the job (best-effort),
  aborts the in-flight request via `abortSignal`, and bumps `_gen`.
- **Session persistence (C15, D6):** AppConfigs keys `voicebotSessionId`,
  `voicebotSessionPatientId`, `voicebotSessionAt`. Reuse the stored id only if
  `voicebotSessionPatientId == AppConfigs.patientId` and it's under 30 min old. Otherwise
  send `null`. **This avoids touching `PairingService`:** a re-paired tablet has a different
  `patientId`, so the old session is never reused.
- The controller receives `VoiceBotGateway`, `BotRecorder`, `BotPlayer` and `AppConfigsDao`
  in its constructor, with defaults for production.

**AC:** `test/voicebot/controller_test.dart` with fakes proves:
1. The happy path leads to 2 bubbles, polling stops at terminal, and play is called once.
2. `interrupt()` during polling means cancel is called and a later poll result is ignored
   (play never called).
3. The session is reused for the same patient and discarded for a different `patientId`.
4. Retry after `offline` reuses the same idempotency key and bytes.
5. `failed` / `NO_TTS_PROVIDER_SUPPORTS_LANGUAGE` / null audio shows text only, with no error
   message.
6. Poll count stops at terminal (no extra polls).

### V05 — VoiceBot screen UI

`lib/screens/voicebot_screen.dart`. It follows the landscape layout and style of
`voice_memo_screen.dart` (same header, same colors, same fonts), so it feels native.

```
┌───────────────────────────────────────────────────────────────────────┐
│ (←)  🗣️  Talk to Smriti                                               │  header: raisedSurface
├──────────────────────────────┬────────────────────────────────────────┤
│                              │  ┌──────────────────────────────┐      │
│         ╭──────────╮         │  │ Smriti: Namaste! I'm here     │ (🔊) │ Smriti bubble,
│        │   🎤      │         │  │ with you. Tap and speak.      │      │ indigo tint, 24pt
│         ╰──────────╯         │  └──────────────────────────────┘      │
│      (160px mic orb)         │        ┌─────────────────────────┐     │
│                              │        │ You: What medicine now? │     │ elder bubble,
│      Tap and speak           │        └─────────────────────────┘     │ raisedSurface, 22pt
│                              │  ┌──────────────────────────────┐      │
│                              │  │ Smriti: It's time for …       │      │
│                              │  └──────────────────────────────┘      │
│                              │   [  ✓  Yes  ]      [  ✗  No  ]        │ only when confirming
└──────────────────────────────┴────────────────────────────────────────┘
```

- **Orb states:** `ready`: indigo, mic icon, "Tap and speak". `recording`: `recordingDot`,
  stop icon, pulsing ring, "I'm listening… tap when done", seconds counter. `sending`: indigo
  at 60 % opacity, three breathing dots, "Thinking…", not tappable. `speaking`: indigo,
  speaker icon, "Tap to talk again" (a tap interrupts and starts recording). `connecting`: soft
  spinner, "Waking up Smriti…".
- **`unavailable`** (C2: no error words): grey orb, and the right panel says **"Smriti is resting
  right now. Please try again a little later."** with a big "Go back home" button. Never show
  "network", "error", "server" or status codes.
- **Retry state:** "I couldn't hear back. Tap to try again." The orb resends (`retry()`).
- A replay (🔊) button on the latest Smriti bubble replays the cached audio (only if the file
  exists).
- Conversation list: newest at the bottom, auto-scroll, text is selectable = false. Bubble
  text 22–24 pt, minimum 64 dp touch targets everywhere.
- Mic permanently denied: "Please ask your family to allow the microphone for Smriti." (This is
  the only non-generic message, because the elder needs it to get help.)
- Keep the screen awake while it's open with `WakelockPlus.enable()` / `disable()` on
  dispose. **First grep for existing `WakelockPlus` use.** If the app already keeps the screen
  on globally, skip this.
- Back button and system back: `interrupt()`, then pop.

**AC:** every orb state is reachable and renders at compact (`height < 500`) and normal sizes.
No string on this screen contains "error", "network", "offline", "server", "failed" or a
status code. `flutter analyze` is clean.

### V06 — "Talk to Smriti" button on the home screen

**Edit only `_buildQuickActions()` in `lib/screens/home_screen.dart` (currently lines 384–418)
and add one private builder method.** Message and Medicine keep their exact look and
behavior.

**Design:**
```
 ┌──────────────────────────── bottomStrip (E7D9BF), radius 20 ───────────────────────────┐
 │                                                                                         │
 │      ( ✉ )                          ⦿(🗣)⦿                            ( ✚ )             │
 │      52px, terracotta 15%           64px, solid indigo gradient      52px, leafGreen 15% │
 │      Message                        Talk to Smriti                    Medicine           │
 │                                     (indigo, bold)                                        │
 └─────────────────────────────────────────────────────────────────────────────────────────┘
```
- **Position:** the middle of the Row. The children become Message, `SizedBox(32)`, **Talk**,
  `SizedBox(32)`, Medicine.
- **Size:** a 64 × 64 circle (the others are 52). It's the primary quick action, and bigger for
  older hands.
- **Fill:** a solid `LinearGradient([AppColors.indigo, AppColors.indigoDark])`, topLeft →
  bottomRight. It's the only *filled* circle in the strip, so the eye finds it first. Indigo is
  the palette's calm "conversation" color and doesn't compete with the terracotta and green
  neighbors.
- **Icon:** `Icons.record_voice_over_rounded`, size 32, color `AppColors.onColor`. It shows a
  person speaking, which is distinct from Message's envelope/mic.
- **Glow:** reuse the **existing** `_breathController` (don't add a controller). Use
  `BoxShadow(color: indigo.withValues(alpha: 0.20 + 0.20 * v), blurRadius: 10 + 8 * v,
  spreadRadius: 1 + 2 * v)`, a gentle 3 s "breathing" that invites a tap.
- **Label:** "Talk to Smriti", 12 pt, `FontWeight.w700`, `AppColors.indigo` (the others use
  w600 secondaryText).
- **Alignment:** set the Row's `crossAxisAlignment: CrossAxisAlignment.end` so all three labels
  sit on one baseline despite the bigger circle.
- **Accessibility:** `Semantics(button: true, label: 'Talk to Smriti')`,
  `HitTestBehavior.opaque`, and a hit area of at least 72 × 88 dp.
- **Double-tap guard:** a bool `_openingBot` that ignores taps until the pushed route returns.
- **onTap:** `Navigator.push(MaterialPageRoute(builder: (_) => const VoiceBotScreen()))`. **No
  network check on the button.** The screen handles offline itself, so the button is always
  there and always responds.

Reference implementation (adapt names to the file):
```dart
Widget _buildTalkAction() {
  return Semantics(
    button: true,
    label: 'Talk to Smriti',
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _openVoiceBot,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _breathController,
            builder: (context, child) {
              final v = _breathController.value;
              return Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.indigo, AppColors.indigoDark],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.indigo.withValues(alpha: 0.20 + 0.20 * v),
                      blurRadius: 10 + 8 * v,
                      spreadRadius: 1 + 2 * v,
                    ),
                  ],
                ),
                child: child,
              );
            },
            child: const Icon(Icons.record_voice_over_rounded,
                color: AppColors.onColor, size: 32),
          ),
          const SizedBox(height: 6),
          const Text(
            'Talk to Smriti',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.indigo),
          ),
        ],
      ),
    ),
  );
}
```

**AC:** the button is centered between Message and Medicine on a phone and a tablet, in
landscape, compact and normal. The labels are aligned. Message and Medicine open their screens
exactly as before. The hidden 5-tap diagnostics corner still works (the strip doesn't overlap
the bottom-left 100 × 100 area). Rapid double taps open one screen.

### V07 — Actions and confirmations

In the controller/screen, after a turn arrives and **only if `action_accepted == true`**:

| `action` | Behavior |
|---|---|
| `OPEN_PLAY` | Show the reply for 1.5 s, `interrupt()`, then `Navigator.pushReplacement` → `GameSelectScreen()` |
| `OPEN_MY_PEOPLE` | the same → `FamilyScreen()` |
| `OPEN_TODAY` | the same → `MyDayScreen()` |
| `OPEN_MEDICINE` | the same → `MedicineScreen()` |
| `HELP` | No navigation. The reply is the help. |
| `STOP` | `interrupt()`, stay on the screen in `ready` |
| anything else (incl. call/reminder) | **Ignore.** Show the text only. Log `ignored_action:<name>` to AppConfigs diagnostics. |

`pushReplacement` means back from the target screen returns to Home, not to a dead bot
screen. Opening Games never creates a session or trial event (the contract §14 requirement is
already satisfied because we only navigate).

**Confirmation:** when `kind == CONFIRMATION && requires_confirmation`, show big **Yes**
(leafGreen) and **No** (neutral `border` color, **not red**) buttons under the reply. They
send `sendText(message: 'yes' | 'no', sessionId, new idempotency key)`. The elder can also
just speak their answer. Hide the buttons when the next turn arrives. Correlate with
`action_id` if it's present. Never auto-confirm, never treat silence as yes.

**AC:** unit tests: `action_accepted=false` with `OPEN_PLAY` doesn't navigate. An unknown
action doesn't navigate. `STOP` interrupts. Device test: saying "open my games" (English and
Hindi) lands on the game select screen, and back returns Home.

### V08 — Alarm priority, interruptions and lifecycle (C13)

- `VoiceBotScreen` mixes in `WidgetsBindingObserver`. On `inactive`, `hidden` or `paused` it
  calls `interrupt()`. **This is the main guarantee:** when a medication alarm fires, native
  `ReminderActivity` comes to the front, `MainActivity.onPause` runs, and the Flutter main engine
  goes `inactive`. The bot stops recording, playback and polling **before** the caregiver's
  voice note plays on the alarm stream. Also covers phone calls and the home button.
- Belt-and-braces: keep `just_audio`'s default `handleInterruptions: true`, so the bot player
  pauses on audio-focus loss. `ReminderVoicePlayer.kt` requests `AUDIOFOCUS_GAIN_TRANSIENT`.
  Nothing to change in Kotlin.
- On `resumed`, **don't** auto-resume audio or recording. Stay in `ready`.
- On `dispose`: `interrupt()`, dispose the recorder/player, delete `<temp>/voicebot/`.
- **Optional (do only if the owner approves):** on-device TTS fallback. When a job fails with
  `NO_TTS_PROVIDER_SUPPORTS_LANGUAGE` (expected for Assamese today), speak `response_text` with
  the already-present `flutter_tts` **only if** `isLanguageAvailable(<exact locale for the
  turn's language>)` is true. Never substitute another language's voice (the contract forbids
  it). If that's unavailable, stay text-only.

**AC (real device):** (1) An alarm fires while the elder is **recording**: recording stops, the
reminder screen and its voice play normally, and nothing is sent. (2) An alarm fires while the
**bot is speaking**: the bot audio stops and the reminder audio is clean, with no overlap.
(3) An alarm fires while **sending**: the response is discarded after return, and no late audio
plays. (4) After the reminder closes, the bot screen is idle and usable.

### V09 — Diagnostics

Add a "VoiceBot" block to `lib/screens/diagnostics_screen.dart` (behind the existing hidden
5-tap entry): `lastVoicebotOkAt`, `lastVoicebotError`, the stored session age, and a **"Test
VoiceBot"** button that calls `gateway.health()` and then a `welcome(speak:false)`, showing
OK/failure with the failure code. This is where `PATIENT_FORBIDDEN` (P1 not done) or
`UPSTREAM_AUTH` (bad secret) becomes visible to the caregiver/developer.

**AC:** with `VOICEBOT_ENABLED=false`, diagnostics shows `disabled`. With a wrong secret it
shows `upstream_auth`. The elder-facing screen shows only the resting message in both cases.

### V10 — Device acceptance and regression

**Device matrix:** this must work on all Android devices, so test on at least:
- a Xiaomi/Redmi/POCO (MIUI/HyperOS),
- one non-Xiaomi brand (Samsung One UI, or stock Android such as Pixel or Motorola),
- one device on Android ≤ 10 (API ≤ 29) and one on Android 13+ (API 33+, the notification
  permission era).

Record in the report **exactly which models and Android versions were tested and which were
not.**

**Functional:** English and Hindi voice round-trip (speech in, text, then audio). Assamese
gives text and transcript, and no audio (expected, and not shown as an error). A family,
medicine and routine question each answer from caregiver data. Navigation by voice. The
yes/no confirmation flow. Re-pair the tablet to another patient: the old session is not
reused and memory doesn't leak (ask a family question and get the new patient's family).

**Resilience:** airplane mode → the bot shows the resting message and **reminders, games,
memos, family/medicine/my-day screens all work normally**. Pull the network mid-send → retry
works with no double action. VoiceBot down (set `VOICEBOT_ENABLED=false`) → the same as
offline. A 30 s monologue auto-stops and sends.

**Regression (must be unchanged):** a medication alarm with the app killed, locked and on the
home screen. Memo record, play and upload. A game session writes events. Content pull from
the web app plus alarm reschedule. Pairing. Heartbeat. `flutter test` all green.

**Security:** `grep -rniE "x-api-key|VOICEBOT_API_KEY|nip\.io" lib/ android/` → no matches.
Build a release APK and run `strings` on it: the key does not appear.

---

## 7. What is explicitly NOT changed

Drift schema and migrations · `SyncEngine` / `ContentPuller` / `EventPusher` / `MemoUploader`
/ `EscalationWriter` / heartbeat · reminder isolate, alarm scheduler and native Kotlin
reminder code · pairing and auth · `main.dart` (startup order, permissions, Workmanager) ·
games and session runner · every screen except `home_screen.dart` (one button) and
`diagnostics_screen.dart` (one block) · `pubspec.yaml` · the web app.

---

## 8. Risks

| Risk | Mitigation |
|---|---|
| P1 not done → every call returns 403 | Diagnostics shows `PATIENT_FORBIDDEN`. The elder sees the resting message. |
| VoiceBot 60/min rate limit (P2) | 2 s polling, 429 back-off, ask the operator for a higher limit |
| Slow TTS (Indic Parler can take > 1 min on CPU) | Text is shown immediately (C9). The 90 s poll cap then cancels. The mic stays usable. |
| No TTS for Assamese/Bodo/Manipuri/Nepali | Text-only by design, plus the optional device-TTS fallback (V08) |
| The bot *says* it will call someone (P3) | Client never executes it (C14). Ask the operator to disable the tools. |
| The VoiceBot host is an IP-based `nip.io` address that may change | `VOICEBOT_BASE_URL` is a gateway secret, so it can change without an app release |
| Every language is `validated: false` | Don't market any language as validated. Pilot with native speakers first. |

---

## 9. Conflicts found in the VoiceBot docs (resolved here)

1. **Family field name:** `BACKEND_VOICEBOT_INTEGRATION.md` §5 maps to
   `family_members[].relation`, but `memory_schema.json` requires **`relationship`** and forbids
   extra fields. `relation` would 422 the whole sync. **Use `relationship`.**
2. **Idempotency header name:** the prose says `Idempotency-Key`, but `openapi.json` declares
   the header as **`x-idempotency-key`**. **Send `X-Idempotency-Key`.**
3. **Stale/conflicting revision status:** `API_INTEGRATION.md` says 400, but the authoritative
   contract says **409**. The gateway treats both as "log and continue".
4. **TTS languages:** `API_INTEGRATION.md` lists Indic Parler voices for asm/brx/mni/npi, but
   `LANGUAGE_SUPPORT.md` / `language_matrix.json` say Sarvam Bulbul with **no asm TTS**. Trust
   live behavior and handle `NO_TTS_PROVIDER_SUPPORTS_LANGUAGE` gracefully either way.
5. **Live auth mode:** the docs describe multi-patient keys, but the live deployment is
   single-user `elder-1` (see P1).
6. **`audio_url`** in job responses is a VoiceBot-relative path. The client must never call it.
   The gateway drops it, and audio is fetched by `audio_id` through the gateway.

---

## 10. Later (out of scope for this plan)

- Durable memory sync on caregiver save (a DB webhook on the content version → gateway),
  i.e. "VB-04" in the backend repo's own `VOICEBOT-INTEGRATION-PLAN.md`.
- Caregiver-side bot status on the web app ("VB-07").
- Controlled calling / reminders via an authorized executor ("VB-08").
- Auto-listen after the greeting (voice-activity detection), once tap-to-talk is proven with
  real elders.
