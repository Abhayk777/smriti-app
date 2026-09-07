# Smriti Elder App — Agent Instructions

## Before any task
1. Read `docs/APP-BUILD-SPEC.md` in full for the section relevant to your task.
2. Read `docs/TASKS.md` for the current task and its acceptance criteria.
3. Do only that task. Do not start the next one.

## What this app is
Flutter tablet app for an elderly dementia patient in North-East India. Voice-first,
offline-first, kiosk-locked. It talks to a Supabase backend that is **fully built,
deployed, and live-tested** (schema, RLS, pairing functions, escalation calls with a
confirmed real phone call, watchdog). You are not building the backend. You are building
the client that consumes it.

Supabase project: `https://yzhtgpaekoqaszxgbeyn.supabase.co` (ap-south-1). Anon key comes
from the person running this session — ask if not provided, never invent one.

## The one principle
**SQLite (Drift) on the tablet is the source of truth. Supabase is a sync destination, not
a database you query to render a screen.**

Every screen, every game, every reminder reads and writes local SQLite instantly. Nothing
on screen ever waits on a network call. If you find yourself writing `await supabase...`
inside a widget build method or a game's logic, stop — the design is wrong.

## Non-negotiables
1. No file outside `lib/core/sync/` and `lib/core/auth/` may import `supabase_flutter`.
2. Event, session, memo, and escalation IDs are always client-generated UUID v4, except
   escalation IDs which are deterministic: `{reminderEventId}_{step}`.
3. `TrialEvents`, `Sessions`, `ReminderEvents`, `VoiceMemos` are INSERT-only in application
   code. The only permitted UPDATE is flipping the `synced` boolean (and `endedAt`/
   `completed` on `Sessions` while a session is still open). Never mutate a finalized row.
4. Device writes to Supabase never use `.select()` or chain a `RETURNING`. The device's
   Supabase identity has insert-only access on these tables — a read-back fails with a
   misleading "violates row-level security policy" error even though the insert succeeded.
   Use bare `.insert()` / `.upsert(..., onConflict: 'id', ignoreDuplicates: true)`.
5. Content pull order is always: download media → verify on disk → atomic DB swap →
   reschedule alarms. Never bump `contentVersion` before media is verified present.
6. Alarm callbacks (`AndroidAlarmManager` callbacks) are top-level functions, annotated
   `@pragma('vm:entry-point')`, and open their own Drift connection. They cannot access
   anything from the main isolate — no Riverpod container, no existing DB instance, no
   static set in `main()`.
7. The pairing code alphabet is exactly `ACDEFGHJKLMNPQRSTUVWXYZ2345679` (no `B`, no `I`,
   `O`, `0`, `1`, `8`). Copy it verbatim from `docs/APP-BUILD-SPEC.md` §8, do not retype it.
8. After login-based pairing (`pair-device-authenticated`), the caregiver session is signed
   out immediately, before the device session is established. The tablet must never retain
   caregiver credentials.
9. Nothing about connectivity, sync status, battery optimization, or errors is ever shown
   to the elder. All of that lives behind the hidden diagnostics screen only.
10. Games never touch the database directly. They emit a `TrialResult` to the session
    runner, which owns all persistence, the 6-minute session cap, hint escalation, and the
    ghost-hand demo replay count.
11. The app never says "wrong," shows red, or plays a negative sound on an incorrect
    answer anywhere in the games layer. Cards return silently with a neutral tone.
12. Test every reminder/alarm change on a real Android device. An emulator does not
    reproduce OEM battery-optimization behavior and will give false confidence.

## Repo layout (target — some of this doesn't exist yet)
```
lib/
  core/
    db/           tables.dart, database.dart, dao/        [DONE]
    ability/      estimator.dart                          [NEEDS FIX — see TASKS.md]
    files/        file_paths.dart                          [DONE]
    repo/         content_repo.dart, event_repo.dart,
                  ability_repo.dart, memo_repo.dart         [NOT STARTED]
    auth/         pairing_service.dart                      [NOT STARTED]
    sync/         sync_engine.dart, event_pusher.dart,
                  content_puller.dart, media_downloader.dart,
                  memo_uploader.dart, escalation_writer.dart [NOT STARTED]
    reminders/    alarm_scheduler.dart, reminder_isolate.dart,
                  ladder.dart, health_check.dart             [NOT STARTED]
    voice/        voice_out.dart, voice_in.dart              [NOT STARTED]
  games/          (one game per subfolder, harness first)    [NOT STARTED]
  screens/        login_screen.dart (needs rewiring)          [PARTIAL]
```

## Workflow
- One task per session. Run `flutter analyze` after every change and paste the full
  output — not a summary.
- Do not add a package not already in `pubspec.yaml`'s target list in
  `docs/APP-BUILD-SPEC.md` §2 without asking first.
- If the spec is ambiguous or something you're told to build contradicts something already
  built, stop and say so. Do not silently pick one and proceed.
- Do not invent Supabase table/column names. Every name is fixed by the live backend
  schema, documented in `docs/APP-BUILD-SPEC.md` §7. If a name you need isn't listed, ask
  before guessing.
