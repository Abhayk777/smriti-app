# Smriti Elder App - Workflow & Architecture

_Generated: 2026-09-08 | Version: Complete Guide_
_Project: Voice-first, offline-first Flutter tablet app for elderly dementia patients_

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture Layers](#architecture-layers)
3. [Non-Negotiable Rules](#non-negotiable-rules)
4. [File Structure](#file-structure)
5. [Module Responsibilities](#module-responsibilities)
6. [Workflow Diagrams](#workflow-diagrams)
7. [Data Flows](#data-flows)
8. [Backend Integration](#backend-integration)
9. [Testing](#testing)
10. [Status](#status)

---

## Overview

**Smriti** is a Flutter tablet app for elderly dementia patients in North-East India.

**Key Characteristics:**

- Voice-first (minimal text, audio prompts)
- Offline-first (SQLite = source of truth)
- Kiosk mode (tablet lockdown)
- Hidden diagnostics (caregiver-only)

**Target Users:**

- Primary: Elderly dementia patients
- Secondary: Caregivers (setup & monitoring)

---

## Architecture Layers

```
┌─────────────────────────────────────────────────────────────┐
│  UI LAYER (lib/screens/, lib/games/)                              │
│  - Screens, widgets, game interfaces                              │
│  - Zero network awareness, zero DB access                         │
└─────────────────────────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│  APPLICATION LAYER (lib/games/session_runner.dart)               │
│  - Session management, trial orchestration                        │
│  - Uses Repositories for data access                               │
└─────────────────────────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│  REPOSITORY LAYER (lib/core/repo/)                                 │
│  - ability_repo.dart, content_repo.dart, event_repo.dart        │
│  - memo_repo.dart                                                   │
│  - SQLite ONLY, no network, no supabase_flutter imports            │
└─────────────────────────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│  DATABASE LAYER (lib/core/db/)                                      │
│  - Drift ORM, SQLite, 10 tables                                      │
│  - SOURCE OF TRUTH: <docs>/smriti.sqlite                            │
└─────────────────────────────────────────────────────────────┘
        ┌────────────────────────────────────────────────┬
        ▼                                            ▼
┌───────────────────┐              ┌─────────────────────┐
│  CORE SERVICES     │              │  SYNC LAYER          │
│  (ability/, auth/,  │              │  (sync/, reminders/)  │
│   files/)          │              │  ONLY supabase_flutter│
└───────────────────┘              └──────────┬──────────┘
                                               │
                                               ▼
                                      ┌──────────────────┐
                                      │   SUPABASE       │
                                      │   (Live backend)  │
                                      └──────────────────┘
```

---

## Non-Negotiable Rules

### 🔴 CRITICAL - Never Violate

1. **Data Sovereignty**: SQLite is SOURCE OF TRUTH. Supabase is sync destination ONLY.
2. **Network Isolation**: ONLY `lib/core/sync/` and `lib/core/auth/` may import `supabase_flutter`
3. **INSERT-only Tables**: TrialEvents, Sessions, ReminderEvents, VoiceMemos, EscalationRequests
4. **Client UUIDs**: All IDs are client-generated UUID v4 (except escalation: `{reminderEventId}_{step}`)
5. **No Select After Write**: Never `.select()` after device writes to Supabase - only `.insert()`/`.upsert()`

### 🟡 HIGH PRIORITY

6. **Content Pull Order**: download media → verify on disk → atomic DB swap → reschedule alarms
7. **Alarm Isolates**: NO access to main isolate state, must open own Drift connection
8. **Pairing Order**: MANDATORY signOut() BEFORE setSession() in caregiver-login path
9. **Pairing Alphabet**: `ACDEFGHJKLMNPQRSTUVWXYZ2345679` (no B, I, O, 0, 1, 8)

### 🟢 UX Rules

10. **No Error Display**: Never show errors to elders - caregiver-only diagnostics
11. **Games Indirect**: Games never touch DB directly - emit TrialResult to SessionRunner
12. **No Negative Feedback**: Never say "wrong", show red, or play negative sounds
13. **Real Device Testing**: MUST test on real Android devices (emulators fail OEM battery optimization)

---

## File Structure

```
smriti-app/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── app_colors.dart              # Theme colors
│   │
│   ├── core/
│   │   ├── ability/
│   │   │   └── estimator.dart        # Cognitive ability math
│   │   │
│   │   ├── auth/
│   │   │   ├── pairing_service.dart  # Pairing logic
│   │   │   └── supabase_bootstrap.dart # Supabase init
│   │   │
│   │   ├── db/
│   │   │   ├── database.dart         # Drift DB definition
│   │   │   ├── tables.dart          # 10 table schemas
│   │   │   ├── app_database.dart    # Singleton DB access
│   │   │   └── dao/
│   │   │       └── app_configs_dao.dart
│   │   │
│   │   ├── files/
│   │   │   └── file_paths.dart      # Path utilities
│   │   │
│   │   ├── repo/
│   │   │   ├── ability_repo.dart     # Ability state
│   │   │   ├── content_repo.dart     # People, meds, routine
│   │   │   ├── event_repo.dart       # Trials, sessions, reminders
│   │   │   └── memo_repo.dart        # Voice memos
│   │   │
│   │   ├── sync/
│   │   │   ├── sync_engine.dart      # Sync orchestrator
│   │   │   ├── content_puller.dart   # Download content
│   │   │   ├── media_downloader.dart # Download media
│   │   │   ├── event_pusher.dart      # Upload events
│   │   │   ├── memo_uploader.dart    # Upload memos
│   │   │   ├── escalation_writer.dart # Upload escalations
│   │   │   └── heartbeat.dart         # Device heartbeat
│   │   │
│   │   └── reminders/
│   │       ├── alarm_scheduler.dart  # Schedule alarms
│   │       ├── reminder_isolate.dart # Background handler
│   │       └── health_check.dart     # OEM verification
│   │
│   ├── games/
│   │   ├── cognitive_game.dart       # Game interface
│   │   ├── ghost_hand.dart           # Demo animation
│   │   ├── session_runner.dart       # Session manager
│   │   └── market_basket/
│   │       └── market_basket_game.dart # Memory game
│   │
│   └── screens/
│       ├── main_screen.dart
│       ├── home_screen.dart
│       ├── login_screen.dart
│       ├── game_select_screen.dart
│       ├── diagnostics_screen.dart
│       └── pairing/
│           ├── scan_screen.dart
│           ├── code_entry_screen.dart
│           ├── patient_picker_screen.dart
│           └── pair_confirm_screen.dart
│
├── test/                            # 65 tests
│   ├── core/
│   │   ├── ability/estimator_test.dart
│   │   ├── auth/pairing_service_test.dart
│   │   └── repo/*_test.dart (4 files)
│   ├── games/session_runner_test.dart
│   └── screens/*_test.dart (2 files)
│
├── assets/
│   ├── images/smriti_login_logo.png
│   └── mock_content/mock_content.json
│
├── docs/
│   ├── APP-BUILD-SPEC.md
│   ├── TASKS.md
│   └── IMPLEMENTATION_SUMMARY.md
│
└── android/, ios/, web/, macos/     # Platform code
```

---

## Module Responsibilities

### Database Layer (lib/core/db/)

**10 SQLite Tables:**

1. **TrialEvents** (21 cols): Cognitive trial records
2. **Sessions** (8 cols): Game session metadata
3. **ReminderEvents** (9 cols): Medication reminder events
4. **VoiceMemos** (6 cols): Elder voice recordings
5. **EscalationRequests** (6 cols): Caregiver intervention requests
6. **AbilityStates** (5 cols): Per-domain ability estimates
7. **People** (8 cols): Family members & contacts
8. **Medications** (9 cols): Medication info & scheduling
9. **RoutineItems** (4 cols): Daily routine activities
10. **AppConfigs** (2 cols): App configuration key-value store

### Repository Layer (lib/core/repo/)

| Repo        | Responsibility                           | Tables                                                    |
| ----------- | ---------------------------------------- | --------------------------------------------------------- |
| AbilityRepo | Per-domain cognitive ability             | AbilityStates                                             |
| ContentRepo | People, medications, routine             | People, Medications, RoutineItems                         |
| EventRepo   | Trials, sessions, reminders, escalations | TrialEvents, Sessions, ReminderEvents, EscalationRequests |
| MemoRepo    | Voice memo recordings                    | VoiceMemos + filesystem                                   |

### Core Services

**Ability Estimator** (`core/ability/estimator.dart`):

- Sigmoid response model: p = 1 / (1 + exp(-(theta - difficulty)))
- Decaying K-factor: k = 0.08 + (0.40 - 0.08) \* exp(-nTrials / 60)
- Theta update: theta + k \* (correct - p)
- Clamped: [-4.0, 4.0]
- Convergence: within 0.3 after ~200 trials

**Pairing Service** (`core/auth/pairing_service.dart`):

- 3 pairing paths: QR scan, manual code, caregiver login
- Validates codes against alphabet: `ACDEFGHJKLMNPQRSTUVWXYZ2345679`
- Calls Supabase edge functions: `redeem-pairing-token`, `pair-device-authenticated`
- **CRITICAL**: signOut() BEFORE setSession() for caregiver path
- Exit state: Device identity, NO caregiver credentials stored

**Session Runner** (`games/session_runner.dart`):

- 6-minute session cap
- Trial sequencing & indexing
- Hint escalation (max 2 levels)
- Writes TrialEvents (all 21 columns)
- Updates AbilityStates
- Feedback: praise (correct) or neutral (incorrect) - NEVER negative

**Market Basket Game** (`games/market_basket/`):

- Memory game: see list, pick from shelf
- Difficulty: list length (2-6) + distractors (0-3)
- Error classes: semantic_near, semantic_far, omission, perseveration
- Metrics: picked count, targets, missed, intrusions, repeats

### Sync Layer (lib/core/sync/)

| Component        | Responsibility                         | Direction      |
| ---------------- | -------------------------------------- | -------------- |
| ContentPuller    | Download patient content from Supabase | Remote → Local |
| MediaDownloader  | Download media files                   | Remote → Local |
| EventPusher      | Upload trial events, sessions          | Local → Remote |
| MemoUploader     | Upload voice memos                     | Local → Remote |
| EscalationWriter | Upload escalation requests             | Local → Remote |
| Heartbeat        | Device status to server                | Local → Remote |
| SyncEngine       | Orchestrates all sync operations       | Both           |

---

## Workflow Diagrams

### 1. Pairing Flow (All Paths → Same Exit)

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ Caregiver    │────▶│ QR Code/     │────▶│ Edge Function│
│ Web App      │     │ Token        │     │ (redeem/     │
└─────────────┘     └─────────────┘     │  pair-device)│
                                               └───────┬───────┘
                                                       │
┌─────────────────┐     ┌──────────────────┐           │
│ Tablet:         │     │                  │           │
│ LoginScreen    │────▶│ ScanScreen /      │───────────┘
│                 │     │ CodeEntryScreen   │
└─────────────────┘     └──────────┬───────┘
                                    │
                                    ▼
                           ┌──────────────────┐
                           │ PairingService    │
                           │ .redeemToken()    │
                           └────────┬─────────┘
                                    │
                    ┌──────────────────────┴──────────────────────┐
                    ▼                                  ▼
          ┌──────────────────┐              ┌──────────────────┐
          │ Supabase Function │              │ _completePairing()│
          │ Call              │              │                  │
          └──────────────────┘              │ 1. setSession()  │
                                                │ (device JWT)   │
                                                │ 2. AppConfigs  │
                                                │    .setAll()   │
                                                │ 3. abilityRepo │
                                                │    .seedAll()  │
                                                └──────────────────┘
                                                    │
                    ┌────────────────────────────────────────┐
                    ▼                                    ▼
            ┌──────────────────┐              ┌──────────────────┐
            │ AppConfigs       │              │ AbilityStates    │
            │ (SQLite)         │              │ (SQLite)         │
            └──────────────────┘              └──────────────────┘

EXIT STATE: Device identity, NO caregiver credentials, ability seeded
```

### 2. Game Session Flow

```
Elder taps game
       │
       ▼
┌─────────────────────────────────────┐
│ SessionRunner.start([game])           │
│ 1. eventRepo.insertSession(synced=false)│
│ 2. Listen to game.trials stream        │
│ 3. trialIndex = 0                     │
└─────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│ SessionRunner.nextItem(game)          │
│ 1. abilityRepo.getOrSeed(domain)       │
│ 2. nextDifficulty = estimator.next()  │
│ 3. game.generateItem(difficulty)      │
│ 4. Return GameItem                    │
└─────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│ Game UI: Display item                 │
│ (Optional: GhostHand demo)            │
└─────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│ Elder taps shelf item                 │
│ Game captures: initiationMs, movementMs, chosenId │
└─────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│ game.submit() → TrialResult           │
│ - correct, responseTimeMs              │
│ - chosenId, errorClass (if wrong)      │
│ - metrics (JSON)                      │
└─────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│ SessionRunner._recordTrial()          │
│ 1. eventRepo.insertTrial(all 21 cols) │
│ 2. abilityRepo.applyTrial()           │
│    - estimator.update(theta)          │
│    - save AbilityStates               │
│ 3. trialIndex++                       │
│ 4. Feedback: praise/neutral NEVER negative│
│ 5. Emit feedback to UI               │
└─────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│ Check: < 6 minutes?                  │
│ Yes → nextItem()                     │
│ No → SessionRunner.end()             │
│   - eventRepo.endSession()            │
│   - Stop subscriptions                │
│   - Return to HomeScreen             │
└─────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│ Local SQLite:                         │
│ ✓ TrialEvents row added              │
│ ✓ AbilityStates updated               │
│ ✓ Sessions updated                   │
└─────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│ FUTURE: EventPusher.flush()            │
│ Upload to Supabase events table       │
│ Mark as synced locally                │
└─────────────────────────────────────┘
```

### 3. Content Sync Flow (A09)

```
SyncEngine.run()
   │
   ├── heartbeat.send()
   │      └── RPC: device_heartbeat()
   │
   ├── contentPuller.checkVersion()
   │      └── Compare local vs remote
   │
   ├── contentPuller.fetchContent()
   │      └── RPC: get_patient_content()
   │      └── Returns: people[], medications[], routine[]
   │
   ├── mediaDownloader.downloadAll()
   │      └── Download to tmp/
   │      └── Verify all files
   │
   ├── contentRepo.replaceContent()
   │      └── BEGIN TRANSACTION
   │      └── Delete old content
   │      └── Insert new content
   │      └── Update contentVersion
   │      └── COMMIT
   │
   ├── mediaDownloader.moveToFinal()
   │      └── Move from tmp/ to final paths
   │
   ├── alarmScheduler.rescheduleAll()
   │      └── Schedule all medication alarms
   │
   ├── eventPusher.flush()
   │      └── Upload unsynced trials
   │
   └── memoUploader.flush()
          └── Upload pending memos
```

### 4. Medication Reminder Flow (A11)

```
alarmScheduler.rescheduleAll()
   │
   └── For each active medication:
          For each day of week:
             Calculate next occurrence
             AndroidAlarmManager.setExactAndAllowWhileIdle()

   │
   ▼ (At scheduled time)

fireReminderCallback (Isolate Entry Point)
   │
   ├── 1. Open NEW Drift connection (NO main isolate access)
   ├── 2. Get medication from Medications table
   ├── 3. If inactive: return
   ├── 4. Create ReminderEvent (ladderStep=0)
   │
   ├── 5. Show full-screen notification
   │      - Display: medication name, dose, photo
   │      - Play: medication.voicePath
   │      - Buttons: "Taken" | "Skip" | "Need Help"
   │
   ├── 6. Schedule Step 1 (15 min later, ladderStep=1)
   │      └── Repeat notification if no response
   │
   ├── 7. Schedule Step 2 (30 min after original)
   │      └── Create EscalationRequest
   │      └── escalationWriter.flush() → Supabase
   │      └── Server: escalation-worker → phone call
   │
   ├── 8. Schedule next occurrence
   └── 9. Close Drift connection
```

---

## Data Flows

### Layer Separation

```
UI (Screens/Games)
   │
   ▼
Application (SessionRunner)
   │
   ▼
Repositories (SQLite only)
   │
   ├────────────────┬────────────────┐
   ▼                ▼                ▼
Local SQLite    File System     Isolates
   │                │                │
   └────────────────┼────────────────┘
                    │
                    ▼
            Sync Layer (Supabase)
                    │
                    ▼
            Supabase Backend
```

### Data Ownership

| Data               | Storage     | Sync                | Owner     |
| ------------------ | ----------- | ------------------- | --------- |
| TrialEvents        | SQLite      | ✅ EventPusher      | Device    |
| Sessions           | SQLite      | ✅ EventPusher      | Device    |
| ReminderEvents     | SQLite      | ✅ EventPusher      | Device    |
| EscalationRequests | SQLite      | ✅ EscalationWriter | Device    |
| VoiceMemos         | SQLite + FS | ✅ MemoUploader     | Device    |
| AbilityStates      | SQLite      | ❌                  | Device    |
| People             | SQLite + FS | ❌ (ContentPuller)  | Caregiver |
| Medications        | SQLite + FS | ❌ (ContentPuller)  | Caregiver |
| AppConfigs         | SQLite      | ❌                  | Device    |

---

## Backend Integration

**Supabase URL**: `https://yzhtgpaekoqaszxgbeyn.supabase.co`
**Region**: `ap-south-1` (Mumbai)
**Package**: `supabase_flutter: ^2.5.0`
**Auth**: PKCE flow

### Edge Functions

| Function                  | Endpoint                                     | Called By      |
| ------------------------- | -------------------------------------------- | -------------- |
| redeem-pairing-token      | POST /functions/v1/redeem-pairing-token      | PairingService |
| pair-device-authenticated | POST /functions/v1/pair-device-authenticated | PairingService |

### RPC Endpoints

| RPC                 | Params                                                          | Called By     |
| ------------------- | --------------------------------------------------------------- | ------------- |
| get_patient_content | p_patient_id                                                    | ContentPuller |
| device_heartbeat    | p_patient_id, p_app_version, p_pending_events, p_device_time_ms | Heartbeat     |

### Storage Buckets

| Bucket        | Access      | Content                  |
| ------------- | ----------- | ------------------------ |
| patient-media | Private     | Person/med photos, voice |
| patient-memos | Private     | Elder voice recordings   |
| lang-packs    | Public Read | Language packs           |

### Tables (Supabase)

Device writes to: events, sessions, reminder_events, memos, escalations
Caregiver reads: patients, patient_members

---

## Testing

### Coverage: 65 tests, 9 files, ALL PASSING

| Module               | Tests |
| -------------------- | ----- |
| AbilityEstimator     | 7     |
| PairingService       | 22    |
| AbilityRepo          | 6     |
| ContentRepo          | 3     |
| EventRepo            | 4     |
| MemoRepo             | 3     |
| SessionRunner        | 10    |
| CaregiverLoginScreen | 6     |
| CodeEntryScreen      | 4     |

### Test Infrastructure

**In-memory DB** (`test/core/repo/_test_db.dart`):

```dart
SmritiDatabase newTestDb() =>
    SmritiDatabase.connect(NativeDatabase.memory());
```

**Fake Gateway** for Supabase mocking:

```dart
class FakePairingGateway implements PairingGateway {
  final List<String> calls = [];  // Record all calls
  int signOuts = 0;             // Verify order
  final PairingResponse? response; // Configurable
}
```

### Key Test Scenarios

**Pairing:**

- Code validation (alphabet, length)
- Path equivalence (QR = manual code)
- **Critical**: signOut() BEFORE setSession() verification
- Error handling (bad tokens, network failures)

**Session Runner:**

- All 21 TrialEvents columns populated
- Error classification (semantic_near, etc.)
- Difficulty tracks ability estimate
- 6-minute cap enforced
- Feedback never negative

**Ability Estimator:**

- Theta convergence within 0.3 after 200 trials
- Seeding from demographics verified
- Next difficulty targets p=0.78
- Theta clamped to [-4.0, 4.0]

### Execution

```bash
# All tests
flutter test

# Specific file
flutter test test/core/ability/estimator_test.dart

# With coverage
flutter test --coverage

# Required before commit
flutter analyze
```

---

## Status

### ✅ Completed (A01-A08)

| Task | Component                                    | Status                    |
| ---- | -------------------------------------------- | ------------------------- |
| A01  | Drift schema + DAOs                          | ✅ Verified               |
| A02  | File path service                            | ✅ Verified               |
| A03  | AbilityEstimator                             | ✅ Tests passing          |
| A04  | Supabase initialization                      | ✅ Live backend connected |
| A05  | Repositories (4)                             | ✅ Unit tests passing     |
| A06  | SessionRunner + CognitiveGame + MarketBasket | ✅ End-to-end tested      |
| A07  | QR code pairing                              | ✅ Real tokens tested     |
| A08  | Caregiver-login pairing                      | ✅ Order verified         |

### 📝 Files Exist, Not Implemented

| Task | Components                                             |
| ---- | ------------------------------------------------------ |
| A09  | ContentPuller, MediaDownloader                         |
| A10  | EventPusher, MemoUploader, EscalationWriter, Heartbeat |
| A11  | AlarmScheduler, ReminderIsolate                        |
| A12  | HealthCheck                                            |
| A14  | DiagnosticsScreen                                      |

### ⏳ Not Started

| Task | Components       |
| ---- | ---------------- |
| A11  | Ladder System    |
| A13  | Additional Games |
| A15  | Kiosk Mode       |
| A16  | Voice I/O        |

---

## Summary

**Architecture**: Clean layer separation, offline-first, strict network isolation

**Strengths**:

- ✅ SQLite as source of truth
- ✅ Only sync layer touches Supabase
- ✅ 65 passing tests
- ✅ Live Supabase backend
- ✅ Working pairing with real tokens
- ✅ Sophisticated ability estimation
- ✅ Complete session runner

**Next Priorities**:

1. A09: ContentPuller + MediaDownloader
2. A10: Sync layer (EventPusher, etc.)
3. A11: AlarmScheduler + ReminderIsolate
4. A12: HealthCheck

**Critical Notes**:

- OEM testing required for A11+
- Never show errors to elders
- All features must work offline
- Voice-first, minimal text

---

_Project ~50-60% complete with excellent foundation_
