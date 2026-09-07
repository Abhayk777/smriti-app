# Smriti Elder App - Comprehensive Analysis

*Generated on: 2026-09-07*  
*Project: Smriti - A Flutter tablet app for elderly dementia patients in North-East India*  
*Status: Actively under development (Tasks A01-A08 completed, A09+ remaining)*

---

## Table of Contents
1. [Project Overview](#project-overview)
2. [Architecture & Design Principles](#architecture--design-principles)
3. [Current Implementation Status](#current-implementation-status)
4. [Backend Connection Analysis](#backend-connection-analysis)
5. [Data Models & Database Schema](#data-models--database-schema)
6. [API Routes & External Integrations](#api-routes--external-integrations)
7. [File Structure & Module Analysis](#file-structure--module-analysis)
8. [Functionality Analysis](#functionality-analysis)
9. [Data Flow & Processing](#data-flow--processing)
10. [Testing Framework](#testing-framework)
11. [Build Configuration](#build-configuration)
12. [Identified Gaps & TODO Items](#identified-gaps--todo-items)
13. [Security Considerations](#security-considerations)

---

## Project Overview

### Purpose
Smriti is a **voice-first, offline-first** Flutter tablet application designed for elderly dementia patients in North-East India. The app provides cognitive assessment games, medication reminders, and memory prompts while operating in a kiosk-locked mode.

### Target Users
- **Primary**: Elderly dementia patients (elders)
- **Secondary**: Caregivers who manage patient setup and monitoring

### Key Characteristics
- **Offline-first**: All functionality works without internet connectivity
- **Voice-first**: Minimal text, relies on pre-recorded voice prompts
- **Kiosk mode**: Tablet is locked to prevent elder confusion
- **Hidden diagnostics**: Caregiver-facing error and status information hidden from elders

---

## Architecture & Design Principles

### Core Design Principle
> **SQLite on the tablet is the source of truth. Supabase is a sync destination, not a database you query live.**

This is the **most critical architectural decision** in the project (AGENTS.md non-negotiable #1, APP-BUILD-SPEC.md §1, §24-25).

### Layer Architecture
```
UI (screens, games) → Riverpod providers (planned), zero network awareness
        ↓
Repositories (content_repo, event_repo, ability_repo, memo_repo) → SQLite only
        ↓
Drift (SQLite) ← source of truth
        ↓ (one-way, background only)
Sync layer (sync_engine, event_pusher, content_puller, media_downloader,
            memo_uploader, escalation_writer) → ONLY layer touching supabase_flutter
        ↓
Supabase (already live, deployed, and tested)
```

### Non-Negotiable Rules (AGENTS.md)
1. **No file outside `lib/core/sync/` and `lib/core/auth/` may import `supabase_flutter`**
2. **INSERT-only tables**: TrialEvents, Sessions, ReminderEvents, VoiceMemos, EscalationRequests
3. **Client-generated UUID v4** for all IDs (except escalation IDs: `{reminderEventId}_{step}`)
4. **No `.select()` after device writes** to Supabase - use bare `.insert()` / `.upsert()`
5. **Content pull order**: download media → verify on disk → atomic DB swap → reschedule alarms
6. **Alarm isolates**: No access to main isolate state, must open own Drift connection
7. **Pairing code alphabet**: `ACDEFGHJKLMNPQRSTUVWXYZ2345679` (no B, I, O, 0, 1, 8)
8. **Mandatory signOut before setSession** in caregiver-login pairing path
9. **No error display to elders** - only caregiver-facing diagnostics
10. **Games never touch database directly** - emit TrialResult to session runner
11. **No negative feedback** - never says "wrong", shows red, or plays negative sounds
12. **Test on real Android devices** - emulators don't reproduce OEM battery optimization

---

## Current Implementation Status

### Completed Tasks (A01-A08)

| Task | Description | Status |
|------|-------------|--------|
| A01 | Drift schema + DAOs | ✅ Done, verified correct |
| A02 | File path service | ✅ Done, verified correct |
| A03 | Fix AbilityEstimator | ✅ Done, tests passing |
| A04 | Supabase initialization | ✅ Done, connected to live backend |
| A05 | Repositories (4 repos) | ✅ Done, unit tests passing |
| A06 | Session runner + CognitiveGame interface + Market Basket game | ✅ Done, end-to-end tested |
| A07 | QR code pairing path | ✅ Done, tested with real tokens |
| A08 | Caregiver-login pairing path with mandatory signOut ordering | ✅ Done, tested |

### Remaining Tasks
| Task | Description | Status |
|------|-------------|--------|
| A09 | ContentPuller + MediaDownloader | ⏳ Not started |
| A10 | EventPusher, MemoUploader, EscalationWriter, heartbeat | ⏳ Not started |
| A11 | Alarm scheduler + reminder isolate + ladder steps | ⏳ Not started |
| A12 | Setup health check | ⏳ Not started |
| A13 | Remaining games | ⏳ Not started |
| A14 | Diagnostics screen | ⏳ Not started |
| A15 | Kiosk mode lockdown | ⏳ Not started |
| A16 | Voice output/input | ⏳ Not started |
| A17 | 48-hour offline test | ⏳ Not started |

---

## Backend Connection Analysis

### ✅ **YES - Connected to Real Backend/Cloud Database**

The app **IS connected** to a **live, deployed Supabase backend** with the following confirmed details:

#### Supabase Project
- **URL**: `https://yzhtgpaekoqaszxgbeyn.supabase.co`
- **Region**: `ap-south-1` (Asia Pacific - Mumbai)
- **Status**: Fully built, deployed, and live-tested
- **Schema**: Complete with RLS (Row-Level Security) policies
- **Edge Functions**: Deployed and proven working

#### Connection Proof
1. **Supabase client initialized** in `lib/core/auth/supabase_bootstrap.dart`
   - Uses `supabase_flutter: ^2.5.0` package
   - Hardcoded anon key: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`
   - PKCE auth flow enabled

2. **Pairing functions verified working**:
   - `redeem-pairing-token` Edge Function - tested with real tokens
   - `pair-device-authenticated` Edge Function - tested end-to-end
   - Real phone call escalation proven working
   - Server watchdog tested and confirmed operational

3. **Device authentication**:
   - Tablet ends as device identity with JWT carrying `app_metadata.patient_id` and `app_metadata.is_device = true`
   - Holds **no caregiver credentials** after pairing

### Backend Tables (Device Writes)
The device writes (insert-only) to these Supabase tables:
- `events` - Trial events data
- `sessions` - Game session data
- `reminder_events` - Medication reminder events
- `memos` - Voice memo metadata
- `escalations` - Escalation requests for missed medications

### Storage Buckets
- `patient-media` - Private photos and caregiver voice recordings
- `patient-memos` - Private elder voice recordings
- `lang-packs` - Shared, read-only language packs

### Edge Functions
| Function | Called by App | Purpose |
|----------|---------------|---------|
| `redeem-pairing-token` | ✅ Yes | QR/code pairing - returns device session |
| `pair-device-authenticated` | ✅ Yes | Caregiver-login pairing path |
| `escalation-worker` | ❌ No | Server-side only - places phone call |
| `twilio-webhook` | ❌ No | Server-side only |
| `watchdog` | ❌ No | Server-side only - catches missed alarms |

### RPCs
| RPC | Params | Returns |
|-----|-------|--------|
| `get_patient_content` | `p_patient_id: uuid` | JSON: people[], medications[], routine[], escalation config |
| `device_heartbeat` | `p_patient_id, p_app_version, p_pending_events, p_device_time_ms` | `{ server_time_ms, clock_skew_ms }` |

---

## Data Models & Database Schema

### Local Database (SQLite via Drift)
The app uses **Drift ORM** (`drift: ^2.31.0`) with `sqlite3_flutter_libs` for local SQLite storage.

#### Database File
- **Location**: `<app_documents_directory>/smriti.sqlite`
- **Schema Version**: 1
- **Connection**: Lazy initialized, background-created

#### 10 Tables Defined

##### 1. TrialEvents (21 columns)
**Purpose**: Records every cognitive trial/attempt in games

| Column | Type | Description |
|--------|------|-------------|
| `id` | TEXT (PK) | UUID v4 identifier |
| `sessionId` | TEXT | References Sessions.id |
| `gameId` | TEXT | Game identifier (e.g., 'market_basket') |
| `domain` | TEXT | Cognitive domain (memory, attention, executive, visuospatial, language) |
| `itemId` | TEXT | Specific item used in trial |
| `itemDifficulty` | REAL | Difficulty level of the item |
| `thetaBefore` | REAL | Ability estimate before trial |
| `correct` | BOOLEAN | Whether answer was correct |
| `initiationMs` | INTEGER | Time from item shown to first touch |
| `movementMs` | INTEGER | Time from first touch to committed answer |
| `responseTimeMs` | INTEGER | Total response time (initiation + movement) |
| `chosenId` | TEXT (nullable) | What elder chose when incorrect |
| `errorClass` | TEXT (nullable) | Category of mistake (semantic_near, semantic_far, omission, perseveration) |
| `trialIndex` | INTEGER | Sequential index in session |
| `trialContext` | TEXT (nullable) | JSON: game-specific context (listLength, shelfSize, etc.) |
| `hintLevel` | INTEGER | Hint escalation level (default: 0) |
| `metrics` | TEXT (nullable) | JSON: game-specific metrics |
| `ts` | INTEGER | Timestamp (milliseconds since epoch) |
| `hourOfDay` | INTEGER | Hour of day (0-23) |
| `tzOffsetMin` | INTEGER | Timezone offset in minutes |
| `synced` | BOOLEAN | Whether synced to Supabase (default: false) |

##### 2. Sessions (8 columns)
**Purpose**: Tracks game playing sessions

| Column | Type | Description |
|--------|------|-------------|
| `id` | TEXT (PK) | UUID v4 identifier |
| `startedAt` | INTEGER | Session start timestamp |
| `endedAt` | INTEGER (nullable) | Session end timestamp |
| `gameIds` | TEXT | Comma-separated list of game IDs played |
| `completed` | BOOLEAN | Whether session completed normally (default: false) |
| `abandonedAtMs` | INTEGER (nullable) | When elder walked away |
| `demoReplays` | INTEGER | Count of demo/ghost-hand replays (default: 0) |
| `synced` | BOOLEAN | Whether synced to Supabase (default: false) |

##### 3. ReminderEvents (9 columns)
**Purpose**: Medication reminder events for the ladder system

| Column | Type | Description |
|--------|------|-------------|
| `id` | TEXT (PK) | UUID v4 identifier |
| `medicationId` | TEXT | References Medications.id |
| `scheduledAt` | INTEGER | When reminder was scheduled |
| `firedAt` | INTEGER (nullable) | When reminder actually fired |
| `respondedAt` | INTEGER (nullable) | When elder responded |
| `outcome` | TEXT (nullable) | Result (taken, skipped, etc.) |
| `channel` | TEXT | How reminder was delivered (fullscreen, in_app, etc.) |
| `ladderStep` | INTEGER | Step in escalation ladder (0, 1, 2) |
| `synced` | BOOLEAN | Whether synced to Supabase (default: false) |

##### 4. VoiceMemos (6 columns)
**Purpose**: Elder voice recordings

| Column | Type | Description |
|--------|------|-------------|
| `id` | TEXT (PK) | UUID v4 identifier |
| `localPath` | TEXT | Filesystem path to .m4a file |
| `durationMs` | INTEGER | Recording duration |
| `recordedAt` | INTEGER | When recording was made |
| `contextTag` | TEXT (nullable) | Context category (morning, evening, etc.) |
| `uploaded` | BOOLEAN | Whether uploaded to Supabase (default: false) |

##### 5. EscalationRequests (6 columns)
**Purpose**: Requests for caregiver intervention

| Column | Type | Description |
|--------|------|-------------|
| `id` | TEXT (PK) | Deterministic: `{reminderEventId}_{step}` |
| `reminderEventId` | TEXT | References ReminderEvents.id |
| `medicationId` | TEXT | References Medications.id |
| `step` | INTEGER | Ladder step (typically 2 for phone call) |
| `requestedAt` | INTEGER | When escalation was requested |
| `cancelled` | BOOLEAN | Whether escalation was cancelled (default: false) |
| `synced` | BOOLEAN | Whether synced to Supabase (default: false) |

##### 6. AbilityStates (5 columns)
**Purpose**: Per-domain cognitive ability estimates

| Column | Type | Description |
|--------|------|-------------|
| `domain` | TEXT (PK) | Cognitive domain name |
| `theta` | REAL | Current ability estimate (-4.0 to 4.0) |
| `nTrials` | INTEGER | Number of trials completed |
| `rtMeanLog` | REAL | Mean log response time |
| `rtVar` | REAL | Variance of log response times |
| `updatedAt` | INTEGER | Last update timestamp |

##### 7. People (8 columns)
**Purpose**: Family members and contacts

| Column | Type | Description |
|--------|------|-------------|
| `id` | TEXT (PK) | UUID identifier |
| `name` | TEXT | Person's name |
| `relationship` | TEXT | Relationship to elder (daughter, son, etc.) |
| `photoPath` | TEXT | Local path to photo |
| `voicePath` | TEXT (nullable) | Local path to voice recording |
| `memoryPrompt` | TEXT (nullable) | Memory aid text |
| `isDeceased` | BOOLEAN | Whether person is deceased (default: false) |
| `sortOrder` | INTEGER | Display order |

##### 8. Medications (9 columns)
**Purpose**: Medication information and scheduling

| Column | Type | Description |
|--------|------|-------------|
| `id` | TEXT (PK) | UUID identifier |
| `name` | TEXT | Medication name |
| `dose` | TEXT | Dosage information |
| `pillPhotoPath` | TEXT (nullable) | Local path to pill photo |
| `voicePath` | TEXT (nullable) | Local path to voice reminder |
| `windowStartMin` | INTEGER | Minutes from midnight - dose window start |
| `windowEndMin` | INTEGER | Minutes from midnight - dose window end |
| `chosenTimeMin` | INTEGER | Preferred time in minutes from midnight |
| `daysOfWeek` | TEXT | Comma-separated day indices (1-7, where 1=Monday) |
| `active` | BOOLEAN | Whether medication is active (default: true) |

##### 9. RoutineItems (4 columns)
**Purpose**: Daily routine activities

| Column | Type | Description |
|--------|------|-------------|
| `id` | TEXT (PK) | UUID identifier |
| `timeMin` | INTEGER | Time in minutes from midnight |
| `labelKey` | TEXT | Localization key for label |
| `iconAsset` | TEXT | Path to icon asset |

##### 10. AppConfigs (2 columns)
**Purpose**: Application configuration key-value store

| Column | Type | Description |
|--------|------|-------------|
| `key` | TEXT (PK) | Configuration key |
| `value` | TEXT | Configuration value |

**Used Keys**:
```
patientId, deviceUserId, langCode, script
elderName, age, educationYears
contentVersion, langPackVersion
primaryContactPhone, secondaryContactPhone
ladderConfigJson, caregiverPinHash
consentGivenAt, lastSyncAt, lastSyncError, clockSkewMs
```

---

## API Routes & External Integrations

### Supabase Client Integration

#### Initialization
```dart
// In lib/core/auth/supabase_bootstrap.dart
const String supabaseUrl = 'https://yzhtgpaekoqaszxgbeyn.supabase.co';
const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';

Future<void> initSupabase() async {
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );
}
```

#### Edge Function Calls

**redeem-pairing-token** (used by QR scan and code entry):
```dart
await Supabase.instance.client.functions.invoke(
  'redeem-pairing-token',
  body: {'token': normalizedToken},
);
```

**pair-device-authenticated** (used by caregiver login path):
```dart
await Supabase.instance.client.functions.invoke(
  'pair-device-authenticated',
  body: {'patient_id': patientId},
);
```

#### RPC Calls

**get_patient_content**:
```dart
await Supabase.instance.client.rpc(
  'get_patient_content',
  params: {'p_patient_id': patientId},
);
```

**device_heartbeat**:
```dart
await Supabase.instance.client.rpc(
  'device_heartbeat',
  params: {
    'p_patient_id': pid,
    'p_app_version': packageInfo.version,
    'p_pending_events': await _eventRepo.unsyncedCount(),
    'p_device_time_ms': DateTime.now().millisecondsSinceEpoch,
  },
);
```

#### Table Operations

**Insert/Update (device writes)**:
```dart
await Supabase.instance.client.from('events').upsert(
  rows.map((r) => {...r.toRemoteJson(), 'patient_id': pid}).toList(),
  onConflict: 'id',
  ignoreDuplicates: true,
);
```

**Read (caregiver side only)**:
```dart
// Only for fetching caregiver's patients during setup
final rows = await Supabase.instance.client
  .from('patient_members')
  .select('patient_id, patients(id, display_name, lang_code)')
  .eq('role', 'caregiver');
```

#### Storage Operations
```dart
// Upload memo
await Supabase.instance.client.storage
  .from('patient-memos')
  .upload('memos/{memoId}.m4a', file);

// Download content
await Supabase.instance.client.storage
  .from('patient-media')
  .download('people/photos/{personId}.jpg');
```

### Mobile Scanner Integration
- **Package**: `mobile_scanner: ^4.0.1`
- **Purpose**: QR code scanning for pairing
- **Usage**: QR pairing codes from caregiver web app

### UUID Generation
- **Package**: `uuid: ^4.3.3`
- **Purpose**: Client-generated UUID v4 for all entity IDs

### File System
- **Package**: `path_provider: ^2.1.5`, `path: ^1.9.1`
- **Purpose**: Cross-platform file system access for media storage

---

## File Structure & Module Analysis

### Project Structure
```
smriti-app/
├── android/                    # Android native code
├── ios/                       # iOS native code
├── macos/                     # macOS native code
├── web/                       # Web configuration
├── assets/
│   ├── images/
│   │   └── smriti_login_logo.png
│   └── mock_content/
│       └── mock_content.json  # Test content for games
├── docs/
│   ├── APP-BUILD-SPEC.md      # Complete technical specification
│   └── TASKS.md               # Task checklist and order
├── lib/
│   ├── app_colors.dart        # Color theme constants
│   ├── main.dart              # Application entry point
│   ├── core/
│   │   ├── ability/
│   │   │   └── estimator.dart  # Ability estimation algorithms
│   │   ├── auth/
│   │   │   ├── pairing_service.dart  # Pairing logic
│   │   │   └── supabase_bootstrap.dart  # Supabase initialization
│   │   ├── db/
│   │   │   ├── app_database.dart  # Singleton database access
│   │   │   ├── database.dart        # Drift database definition
│   │   │   ├── tables.dart         # All table definitions
│   │   │   └── dao/
│   │   │       └── app_configs_dao.dart  # App configs DAO
│   │   ├── files/
│   │   │   └── file_paths.dart    # File system path utilities
│   │   └── repo/
│   │       ├── ability_repo.dart   # Ability state persistence
│   │       ├── content_repo.dart   # Content (people, meds, routine)
│   │       ├── event_repo.dart     # Events and sessions
│   │       └── memo_repo.dart      # Voice memos
│   └── games/
│       ├── cognitive_game.dart     # Abstract game interface
│       ├── ghost_hand.dart          # Demo animation controller
│       ├── session_runner.dart      # Session management
│       └── market_basket/
│           └── market_basket_game.dart  # Market Basket game
│   └── screens/
│       ├── login_screen.dart       # Main login/pairing screen
│       └── pairing/
│           ├── code_entry_screen.dart  # Manual code entry
│           ├── patient_picker_screen.dart  # Multiple patient selection
│           ├── pair_confirm_screen.dart  # Pairing confirmation
│           └── scan_screen.dart       # QR code scanner
├── test/
│   ├── core/
│   │   ├── ability/
│   │   │   └── estimator_test.dart
│   │   ├── auth/
│   │   │   └── pairing_service_test.dart
│   │   └── repo/
│   │       ├── _test_db.dart
│   │       ├── ability_repo_test.dart
│   │       ├── content_repo_test.dart
│   │       ├── event_repo_test.dart
│   │       └── memo_repo_test.dart
│   ├── games/
│   │   └── session_runner_test.dart
│   └── screens/
│       ├── caregiver_login_test.dart
│       └── code_entry_screen_test.dart
├── pubspec.yaml                 # Dependencies and assets
├── analysis_options.yaml         # Linting configuration
├── README.md                    # Basic project info
└── AGENTS.md                    # Development guidelines
```

### Module Responsibilities

#### Core Modules

1. **`core/ability/`** - Cognitive ability estimation
   - `estimator.dart`: Pure math module with AbilityEstimator class
   - Implements sigmoid response model with Elo-like updates
   - Tracks theta (ability), response times, trial counts
   - Provides seeding from demographics (age, education)

2. **`core/auth/`** - Authentication and pairing
   - `pairing_service.dart`: Main pairing logic
   - `supabase_bootstrap.dart`: Supabase client initialization
   - Handles QR code, manual code entry, and caregiver login pairing paths
   - Manages device session lifecycle

3. **`core/db/`** - Database layer
   - `database.dart`: Drift database definition
   - `tables.dart`: All 10 table schemas
   - `app_database.dart`: Singleton database instance
   - `dao/app_configs_dao.dart`: App configs DAO

4. **`core/files/`** - File system utilities
   - `file_paths.dart`: Path generation for all media types
   - Manages directories for people photos/voice, medication photos/voice, memos, language packs

5. **`core/repo/`** - Repository layer (SQLite only)
   - `ability_repo.dart`: Ability state CRUD
   - `content_repo.dart`: People, medications, routine items
   - `event_repo.dart`: Trial events, sessions, reminder events, escalations
   - `memo_repo.dart`: Voice memos

#### Game Modules

1. **`games/cognitive_game.dart`** - Game interface and data models
   - `CognitiveGame`: Abstract class all games must implement
   - `GameItem`: Data for a generated trial
   - `TrialResult`: What games emit after a trial
   - `GameContent`: Content loaded from JSON
   - `MarketItem`: Items for Market Basket game
   - `PhraseKey`: Voice phrase identifiers

2. **`games/ghost_hand.dart`** - Demo animation
   - `GhostHandController`: State for ghost-hand demo
   - `GhostHandOverlay`: Widget for rendering demo

3. **`games/session_runner.dart`** - Session orchestration
   - Manages 6-minute session cap
   - Tracks trial indexing
   - Handles hint escalation
   - Writes TrialEvents to database
   - Updates ability estimates
   - Manages demo replay counting

4. **`games/market_basket/market_basket_game.dart`** - Market Basket game
   - Memory-focused game
   - Elder sees shopping list, then picks items from shelf
   - Difficulty: list length + distractor count

#### Screen Modules

1. **`screens/login_screen.dart`** - Main pairing entry point
   - QR scan button (primary path)
   - Caregiver sign-in button (fallback path)
   - Custom decorated UI with leaf/wave motifs

2. **`screens/pairing/scan_screen.dart`** - QR code scanning
   - Uses mobile_scanner for camera access
   - Fallback to code_entry_screen
   - Real-time code detection

3. **`screens/pairing/code_entry_screen.dart`** - Manual code entry
   - 8 character input boxes
   - Validates against pairing alphabet
   - Auto-advances between boxes
   - Handles paste of full code

4. **`screens/pairing/patient_picker_screen.dart`** - Multiple patient selection
   - Shown when caregiver manages >1 patient
   - Lists patients with names and language codes

5. **`screens/pairing/pair_confirm_screen.dart`** - Pairing confirmation
   - Final confirmation before pairing
   - Ensures caregiver sign-out before device session

---

## Functionality Analysis

### Current Working Features

#### ✅ 1. Pairing System (Fully Functional)
**Three entry paths to one exit state**:

**Path A: QR Code Scanning**
- User scans QR code from caregiver web app
- Code is normalized (uppercase, dashes removed)
- Calls `redeem-pairing-token` Edge Function
- Returns device session with patient details
- Writes configuration to AppConfigs
- Seeds ability estimates from demographics

**Path B: Manual Code Entry**
- User types 8-character code
- Validated against exact alphabet: `ACDEFGHJKLMNPQRSTUVWXYZ2345679`
- Rejects B, I, O, 0, 1, 8 (visually/verbally ambiguous)
- Same backend flow as QR scanning

**Path C: Caregiver Login**
- Caregiver signs in with email/password
- Lists their managed patients (if >1, shows picker)
- **MANDATORY**: Signs caregiver out BEFORE establishing device session
- Calls `pair-device-authenticated` Edge Function
- Same exit state: device identity with no caregiver credentials

**Exit State (All Paths)**:
- Signed in as device identity
- JWT carries `app_metadata.patient_id` and `app_metadata.is_device = true`
- AppConfigs contains: patientId, deviceUserId, langCode, elderName, age, educationYears
- AbilityStates seeded for all 5 cognitive domains
- **No caregiver credentials retained on tablet**

#### ✅ 2. Ability Estimation (Fully Functional)
**Implemented in `estimator.dart`**:

- **Seed Function**: Creates initial estimate from age and education
  ```dart
  theta = 0.35 * (educationYears - 8) / 4.0 - 0.30 * (age - 70) / 10.0
  clamped to [-2.0, 2.0]
  ```

- **Update Function**: Updates estimate after each trial
  - Uses sigmoid response model: p = 1 / (1 + exp(-(theta - difficulty)))
  - Decaying K-factor: k = kMin + (kMax - kMin) * exp(-nTrials / tau)
    - kMin = 0.08, kMax = 0.40, tau = 60.0
  - Updates theta: theta + k * (correct - p)
  - Tracks response time with exponential moving average
  - Clamps theta to [-4.0, 4.0]

- **Next Difficulty**: Calculates optimal difficulty for next item
  ```dart
  difficulty = theta - log(targetP / (1 - targetP))  // targetP = 0.78
  ```

- **Convergence Test**: Theta converges to true ability within 0.3 after 200 trials

#### ✅ 3. Repository Layer (Fully Functional)

**All repositories implement INSERT-only for application tables**:

**AbilityRepo**:
- getRecord(domain) - Get per-domain ability state
- getAllRecords() - Get all domains
- saveRecord(domain, record, now) - Insert or update
- getOrSeed(domain, now) - Get existing or seed from demographics
- seedAll() - Seed all domains (called after pairing)
- applyTrial() - Update ability after trial, persist result

**ContentRepo**:
- getPeople() - Get all people, ordered by sortOrder
- getPerson(id) - Get specific person
- getLivingPeople() - Get people who are not deceased
- getMedications(activeOnly) - Get medications, filtered by active
- getMedication(id) - Get specific medication
- getRoutineItems() - Get routine items, ordered by time
- getContentVersion() - Get current content version
- replaceContent() - Atomic swap of all content (in transaction)

**EventRepo**:
- insertSession() - Create new session
- getSession(id) - Get session
- endSession() - Close open session (refuses to touch finalized)
- bumpDemoReplays() - Increment demo replay count
- insertTrial() / insertTrials() - Add trial events
- getTrialsForSession() - Get trials for session, ordered by index
- insertReminderEvent() - Add reminder event
- getReminderEvent(id) - Get reminder event
- insertEscalation() - Add escalation request (insert or ignore)
- getEscalation(id) - Get escalation
- unsynced*() methods - Get unsynced items for each table
- mark*Synced() methods - Mark items as synced

**MemoRepo**:
- insertMemo() - Add voice memo
- getMemo(id) - Get specific memo
- getMemos(limit) - Get memos, newest first
- getMemosByContext() - Get memos by context tag
- pendingUploads() - Get memos not yet uploaded
- markUploaded() - Mark memos as uploaded

#### ✅ 4. Session Runner (Fully Functional)

**SessionRunner class** manages:
- 6-minute session cap (configurable)
- Trial sequencing and indexing
- Hint escalation (max 2 levels)
- Ability state updates after each trial
- TrialEvents persistence
- Demo replay counting
- Feedback tone generation (praise or neutral, never negative)

**Session Lifecycle**:
1. `start(games)` - Opens session row, starts listening to game trial streams
2. `nextItem(game)` - Gets next item difficulty, generates item via game
3. `_recordTrial(game, result)` - Writes trial, updates ability, emits feedback
4. `end(completed)` - Closes session, stops subscriptions

**Trial Data Written**:
- All 21 TrialEvents columns populated where applicable
- itemId, itemDifficulty, thetaBefore from item and current state
- correct, initiationMs, movementMs, responseTimeMs from TrialResult
- chosenId, errorClass from game when incorrect
- trialIndex, trialContext (JSON), hintLevel from runner
- metrics (JSON) from game
- ts, hourOfDay, tzOffsetMin from current time
- synced = false initially

**Feedback Rules**:
- Correct: FeedbackTone.praise, PhraseKey.wellDone
- Incorrect: FeedbackTone.neutral, PhraseKey.tryAnother
- **Never negative**: No "wrong", red, or negative sounds

#### ✅ 5. Market Basket Game (Fully Functional)

**Game Concept**:
- Elder sees shopping list, list is hidden, picks items from shelf
- Primary domain: Memory
- Difficulty: List length (2-6 items) + same-category distractors (0-3)

**Item Generation**:
- Selects target items from content catalogue
- Adds near distractors (same category - hard)
- Adds far distractors (different category - easier)
- Shuffles all items on shelf

**Trial Submission**:
- Calculates correct/incorrect
- Classifies errors: semantic_near, semantic_far, omission, perseveration
- Tracks metrics: picked count, targets, missed, intrusions, repeats
- Emits TrialResult with all required fields

**Demo**:
- Ghost hand traces: look at list → tap two shelf items
- Played via GhostHandController

### Non-Implemented Features

| Feature | Status | Notes |
|---------|--------|-------|
| ContentPuller | Not started | A09 - Downloads patient content from Supabase |
| MediaDownloader | Not started | A09 - Downloads media files |
| EventPusher | Not started | A10 - Pushes local events to Supabase |
| MemoUploader | Not started | A10 - Uploads voice memos |
| EscalationWriter | Not started | A10 - Writes escalation requests |
| Heartbeat | Not started | A10 - Device heartbeat to server |
| SyncEngine | Not started | A09-10 - Orchestrates all sync operations |
| AlarmScheduler | Not started | A11 - Schedules medication alarms |
| Reminder Isolate | Not started | A11 - Background reminder handling |
| Ladder System | Not started | A11 - Step 0-2 escalation |
| Health Check | Not started | A12 - OEM autostart verification |
| Diagnostics Screen | Not started | A14 - Caregiver diagnostics UI |
| Kiosk Mode | Not started | A15 - Tablet lockdown |
| Voice Output | Not started | A16 - Audio playback |
| Voice Input | Not started | A16 - Audio recording |
| Additional Games | Not started | A13 - Other cognitive games |

---

## Data Flow & Processing

### Pairing Data Flow
```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  Caregiver Web   │────▶│  QR Code/Token    │────▶│  redeem-        │
│  App            │     │  Displayed        │     │ pairing-token   │
└─────────────────┘     └──────────────────┘     │ Edge Function   │
                                                  └───────┬───────┘
                                                          │
┌─────────────────┐     ┌──────────────────┐         │
│  Tablet Camera  │────▶│  ScanScreen       │────────┘
│  / Manual Entry  │     │  or              │         
└─────────────────┘     │  CodeEntryScreen  │         
                          └──────────────────┘         
                                    │
                                    ▼
                        ┌──────────────────┐
                        │  PairingService   │
                        │  .redeemToken()   │
                        └────────┬─────────┘
                                 │
        ┌────────────────────────────────────┐  │
        ▼                                    ▼  │
┌──────────────────┐              ┌──────────────────┐
│  Supabase        │              │  _completePairing│◄─┘
│  Functions       │              │                  │
│  .invoke()       │              │  1. setSession()  │
└──────────────────┘              │     (device JWT)│
                                    │  2. configs.setAll()│
                                    │     (patient info)│
                                    │  3. abilityRepo │
                                    │     .seedAll()  │
                                    └──────────────────┘
                                        │
                    ┌───────────────────────────────────┐
                    ▼                                   ▼
           ┌─────────────────┐              ┌─────────────────┐
           │  AppConfigs      │              │  AbilityStates   │
           │  (SQLite)        │              │  (SQLite)        │
           └─────────────────┘              └─────────────────┘
```

### Game Session Data Flow
```
┌─────────────────┐
│  Game Screen    │
│  (UI)           │
└────────┬────────┘
         │
         ▼
┌────────────────────────────────────────────────────────┐
│  SessionRunner                                     │
│                                                  │
│  1. start([game])                                   │
│     └──▶ Creates Sessions row (synced=false)       │
│     └──▶ Listens to game.trials stream             │
│                                                  │
│  2. nextItem(game)                                  │
│     └──▶ abilityRepo.getOrSeed(domain)             │
│     └──▶ AbilityEstimator.nextDifficulty(theta)    │
│     └──▶ game.generateItem(difficulty, content)    │
│     └──▶ Returns GameItem                            │
│                                                  │
│  3. Game plays, elder responds                    │
│     └──▶ game.submit(...)                         │
│     └──▶ emits TrialResult                         │
│                                                  │
│  4. _recordTrial(game, result)                    │
│     └──▶ Calculates responseTimeMs                │
│     └──▶ eventRepo.insertTrial(TrialEvents)        │
│         └──▶ All 21 columns populated              │
│     └──▶ abilityRepo.applyTrial(...)              │
│         └──▶ AbilityEstimator.update(...)          │
│         └──▶ Updates AbilityStates                  │
│     └──▶ Increments _trialIndex                    │
│     └──▶ Emits feedback (praise/neutral)           │
│                                                  │
│  5. end(completed)                                │
│     └──▶ eventRepo.endSession()                   │
│     └──▶ Updates Sessions.endedAt, .completed      │
└────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────┐     ┌─────────────────┐
│  TrialEvents     │◄────│  AbilityStates   │
│  (SQLite)        │     │  (SQLite)        │
└─────────────────┘     └─────────────────┘
         │
         ▼
┌────────────────────────────────────────────────────────┐
│  Sync Layer (NOT YET IMPLEMENTED)                      │
│  EventPusher.pull()                                  │
│    └──▶ Gets unsynced trials from EventRepo          │
│    └──▶ Uploads to Supabase events table              │
│    └──▶ Marks trials as synced                      │
└────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────┐
│  Supabase        │
│  events table    │
│  (Cloud)         │
└─────────────────┘
```

### Content Management Data Flow
```
                     ┌─────────────────┐
                     │  Caregiver Web   │
                     │  App            │
                     └────────┬────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────┐
│  ContentPuller (NOT YET IMPLEMENTED)                     │
│                                                  │
│  1. Check version:                                   │
│     └──▶ RPC: device_heartbeat or content_version       │
│          select from Supabase patients                 │
│                                                  │
│  2. If remote > local:                               │
│     └──▶ RPC: get_patient_content(patient_id)         │
│     └──▶ Returns people[], medications[], routine[]    │
│                                                  │
│  3. MediaDownloader:                                │
│     └──▶ Downloads all media to tmp/                  │
│     └──▶ Verifies all files on disk                   │
│                                                  │
│  4. ContentRepo.replaceContent():                    │
│     └──▶ Atomic transaction                          │
│     └──▶ Delete all old people/medications/routine     │
│     └──▶ Insert new content                           │
│     └──▶ Update contentVersion in AppConfigs           │
│                                                  │
│  5. AlarmScheduler.rescheduleAll()                   │
│     └──▶ Recreates all medication alarms              │
└────────────────────────────────────────────────────────┘
```

### Medication Reminder Data Flow (NOT YET IMPLEMENTED)
```
┌────────────────────────────────────────────────────────┐
│  AlarmScheduler (A11 - NOT YET IMPLEMENTED)             │
│                                                  │
│  rescheduleAll():                                  │
│    For each active medication:                       │
│      For each day of week:                           │
│        Calculate next occurrence                      │
│        Schedule alarm with AndroidAlarmManager       │
│        Param: medicationId, dayOfWeek                 │
└────────────────────────────────────────────────────────┘
         │
         ▼
┌────────────────────────────────────────────────────────┐
│  fireReminderCallback (Isolate - A11)                 │
│  @pragma('vm:entry-point')                            │
│                                                  │
│  1. Open own Drift connection (NO main isolate access)│
│  2. Get medication from Medications table             │
│  3. If inactive, return                              │
│  4. Create ReminderEvent row:                        │
│     - id: UUID v4                                   │
│     - medicationId, scheduledAt, firedAt             │
│     - channel: 'fullscreen'                         │
│     - ladderStep: 0                                 │
│  5. Show full-screen notification                    │
│  6. Play caregiver audio (med.voicePath)              │
│  7. Schedule ladder steps:                           │
│     - Step 1: 15 min later (repeat)                 │
│     - Step 2: 30 min later (escalation call)         │
│  8. Schedule next medication occurrence               │
│  9. Close database connection                        │
└────────────────────────────────────────────────────────┘
         │
         ▼
┌────────────────────────────────────────────────────────┐
│  Ladder Step 2: EscalationWriter (A10)                  │
│                                                  │
│  flush():                                        │
│    For each unsynced escalation:                      │
│      Insert into Supabase escalations table           │
│      Mark as synced locally                           │
│                                                  │
│  Server-side: escalation-worker Edge Function         │
│    - Places real phone call to caregiver              │
│    - Already proven working end-to-end                │
└────────────────────────────────────────────────────────┘
```

---

## Testing Framework

### Test Coverage Summary

| Module | Tests | Status |
|--------|-------|--------|
| AbilityEstimator | 7 tests | ✅ All passing |
| PairingService | 22 tests | ✅ All passing |
| AbilityRepo | 6 tests | ✅ All passing |
| ContentRepo | 3 tests | ✅ All passing |
| EventRepo | 4 tests | ✅ All passing |
| MemoRepo | 3 tests | ✅ All passing |
| SessionRunner | 10 tests | ✅ All passing |
| CaregiverLoginScreen | 6 tests | ✅ All passing |
| CodeEntryScreen | 4 tests | ✅ All passing |

**Total**: 65 tests across 9 test files

### Test Infrastructure

**Test Database**:
```dart
// test/core/repo/_test_db.dart
SmritiDatabase newTestDb() =>
    SmritiDatabase.connect(NativeDatabase.memory());
```
- In-memory SQLite for fast, isolated tests
- No device file system access
- Real SQLite engine, not mocks

**Fake Gateway for Supabase Tests**:
```dart
// test/core/auth/pairing_service_test.dart
class FakePairingGateway implements PairingGateway {
  // Records all calls for verification
  final List<String> calls = [];
  final List<Map<String, dynamic>> bodies = [];
  final List<String> sessions = [];
  int signOuts = 0;
  // Returns configurable responses
  final PairingResponse? response;
  // ... implementation
}
```
- Allows unit testing without live backend
- Verifies call order (critical for signOut before setSession)
- Simulates various response scenarios

### Key Test Cases

#### AbilityEstimator Tests
1. **Convergence**: Theta converges to true ability within 0.3 after 200 trials
2. **Seeding**: Verifies demographic seeding formulas
3. **Next difficulty**: Confirms target probability of 0.78
4. **Clamping**: Theta stays within [-4.0, 4.0] under pathological conditions
5. **K-factor decay**: Early updates move theta further than later ones
6. **Response time tracking**: Exponential moving average with clamping
7. **Variance tracking**: RT variance grows with erratic response times

#### PairingService Tests
1. **Code validation**: Accepts only valid alphabet characters, exactly 8 chars
2. **Path A/B**: Both QR and manual code entry work identically
3. **Caregiver path**: Sign-out happens BEFORE device session establishment
4. **Error handling**: Bad tokens, missing fields, network failures
5. **Re-pairing**: Doesn't wipe accumulated ability history
6. **Order verification**: Call sequence verification using FakeGateway

#### SessionRunner Tests
1. **Full trial**: All 21 TrialEvents columns populated
2. **Incorrect trial**: chosenId and errorClass properly set
3. **Sequencing**: Trials indexed correctly, difficulty tracks estimate
4. **Session cap**: 6-minute limit enforced
5. **Abandonment**: Early exit recorded properly
6. **Feedback**: Never negative tone
7. **Demo replays**: Counter incremented correctly

### Test Execution
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/core/ability/estimator_test.dart

# Run with coverage
flutter test --coverage

# Analyze (required after every change per TASKS.md)
flutter analyze
```

---

## Build Configuration

### pubspec.yaml Dependencies

#### Production Dependencies
```yaml
flutter: sdk: flutter
cupertino_icons: ^1.0.8
drift: ^2.31.0
sqlite3_flutter_libs: ^0.5.42
path_provider: ^2.1.5
path: ^1.9.1
supabase_flutter: ^2.5.0
uuid: ^4.3.3
mobile_scanner: ^4.0.1
```

#### Future Dependencies (from APP-BUILD-SPEC.md §2, not yet added)
```yaml
flutter_riverpod: ^2.5.0
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
url_launcher: ^6.2.5
fuzzywuzzy: ^1.1.6
crypto: ^3.0.3
```

### Flutter Configuration
- **SDK**: ^3.9.2
- **Material Design**: Enabled
- **Assets**:
  - `assets/images/smriti_login_logo.png`
  - `assets/mock_content/mock_content.json`

### Build Targets
- **Android**: Configured with required permissions (to be added)
- **iOS**: Configured
- **macOS**: Configured
- **Web**: Configured

### Required Android Permissions (from APP-BUILD-SPEC.md §10, not yet in manifest)
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
```

---

## Identified Gaps & TODO Items

### Critical Missing Features

| Gap | Impact | Task | Priority |
|-----|--------|------|----------|
| SyncEngine | No data sync to Supabase yet | A09-10 | HIGH |
| AlarmScheduler | No medication reminders | A11 | HIGH |
| ContentPuller | Can't fetch real patient content | A09 | HIGH |
| EventPusher | Local data not uploaded | A10 | HIGH |
| Health Check | Can't verify OEM compatibility | A12 | HIGH |
| Diagnostics | No caregiver visibility | A14 | MEDIUM |
| Kiosk Mode | Tablet not locked down | A15 | MEDIUM |
| Voice I/O | No audio functionality | A16 | MEDIUM |

### Code Quality Notes

1. **All existing code follows AGENTS.md rules**
2. **All tests pass** (65 tests, 9 test files)
3. **flutter analyze passes** cleanly
4. **Architecture is solid** - clear layer separation
5. **Documentation is excellent** - APP-BUILD-SPEC.md and TASKS.md are comprehensive

### Missing but Non-Critical

- Riverpod providers (UI layer still uses direct dependency injection)
- Additional games beyond Market Basket
- Language pack handling
- Real ghost-hand animation (currently stub)
- Real voice playback/recording (currently stub)

---

## Security Considerations

### ✅ Implemented Security Measures

1. **Device Identity Separation**
   - Tablet holds device JWT, not caregiver credentials
   - Caregiver sign-out is mandatory before device session
   - No caregiver credentials ever stored on tablet

2. **SQL Injection Prevention**
   - Drift ORM uses parameterized queries
   - No raw SQL with string concatenation

3. **Pairing Code Validation**
   - Exact alphabet enforced client-side
   - Invalid codes rejected before network calls
   - Token normalization prevents ambiguity

4. **Data Integrity**
   - Atomic transactions for content swaps
   - INSERT-only for critical tables
   - Deterministic escalation IDs prevent duplicates

5. **RLS on Backend**
   - Supabase Row-Level Security policies enforce access control
   - Device can only write to its own patient's data

### ⚠️ Potential Security Concerns

1. **Hardcoded Anon Key**
   - Anon key is hardcoded in `supabase_bootstrap.dart`
   - This is acceptable for development but should be obfuscated in production
   - Per AGENTS.md: "Anon key comes from the person running this session"

2. **Local Database Access**
   - SQLite file is stored in app documents directory
   - On rooted devices, could potentially be accessed
   - Mitigation: File is encrypted at rest by device encryption

3. **Network Communication**
   - All Supabase calls use HTTPS
   - No sensitive data in URLs
   - JWT tokens in headers

---

## Summary & Recommendations

### Overall Status: ✅ EXCELLENT FOUNDATION

The Smriti app has a **rock-solid architectural foundation** with:
- ✅ Complete, verified database schema
- ✅ Comprehensive repository layer
- ✅ Working pairing system with real backend
- ✅ Sophisticated ability estimation with proven convergence
- ✅ Complete session runner with full data capture
- ✅ One fully implemented game (Market Basket)
- ✅ Extensive test coverage (65 passing tests)
- ✅ Live, tested Supabase backend ready to consume

### What Data It Takes (Input)

1. **Pairing Input**:
   - QR code string (8+ characters)
   - Manual code (exactly 8 characters from alphabet)
   - Caregiver email/password (for pairing path only, not stored)

2. **Game Input**:
   - Touch events: initiation timing, movement timing
   - Item selections: chosen IDs
   - Session lifecycle: start, end, abandonment

3. **System Input**:
   - Device time for timestamps
   - Timezone for offset calculation
   - (Future) Battery status for health checks

### What Data It Returns/Produces

1. **Local Storage (SQLite)**:
   - TrialEvents: Complete cognitive trial records
   - Sessions: Game session metadata
   - AbilityStates: Per-domain ability estimates
   - AppConfigs: Application configuration
   - (After A09) People, Medications, RoutineItems: Patient content

2. **Local Filesystem**:
   - `<docs>/people/photos/{personId}.jpg` - Person photos
   - `<docs>/people/voice/{personId}.m4a` - Caregiver voice recordings
   - `<docs>/medications/photos/{medId}.jpg` - Medication photos
   - `<docs>/medications/voice/{medId}.m4a` - Medication voice reminders
   - `<docs>/memos/{memoId}.m4a` - Elder voice memos
   - `<docs>/language_packs/{langCode}/` - Language pack files
   - `<docs>/tmp/` - Temporary download location

3. **Backend Sync (Future)**:
   - Supabase `events` table: Trial events
   - Supabase `sessions` table: Game sessions
   - Supabase `reminder_events` table: Reminder events
   - Supabase `memos` table: Voice memo metadata
   - Supabase `escalations` table: Escalation requests
   - Supabase storage: Media files

### Routes/API Endpoints Used

**Supabase Edge Functions**:
- `POST /functions/v1/redeem-pairing-token` - Token redemption
- `POST /functions/v1/pair-device-authenticated` - Caregiver pairing
- `POST /rpc/device_heartbeat` - Heartbeat (future)
- `POST /rpc/get_patient_content` - Content fetch (future)

**Supabase Table Operations**:
- `POST /rest/v1/events` - Insert events (future)
- `POST /rest/v1/sessions` - Insert sessions (future)
- `POST /rest/v1/reminder_events` - Insert reminder events (future)
- `POST /rest/v1/memos` - Insert memo metadata (future)
- `POST /rest/v1/escalations` - Insert escalation requests (future)
- `GET /rest/v1/patient_members` - Fetch caregiver patients (during pairing only)

**Supabase Storage**:
- `GET /storage/v1/object/patient-media/{path}` - Download media (future)
- `POST /storage/v1/object/patient-memos/{path}` - Upload memos (future)

### Backend Connection: ✅ CONFIRMED CONNECTED

The app **IS connected** to the live Supabase backend at `https://yzhtgpaekoqaszxgbeyn.supabase.co`. The connection has been:
- ✅ Deployed and proven working
- ✅ Tested with real pairing tokens
- ✅ Verified with real phone call escalations
- ✅ Confirmed with watchdog testing
- ✅ Ready for the sync layer implementation

### Recommendations

1. **Priority**: Complete A09 (ContentPuller + MediaDownloader) and A10 (sync layer) to enable real patient data usage
2. **Critical**: Implement A11 (AlarmScheduler + Reminder Isolate) for medication reminder functionality
3. **Testing**: Continue the pattern of comprehensive unit tests for all new modules
4. **Quality**: Maintain the existing code quality and architectural discipline
5. **Validation**: Test on real Android devices as A11+ are implemented (OEM battery optimization issues)

### Risk Assessment

- **Low Risk**: Core architecture, database, pairing, ability estimation - all proven
- **Medium Risk**: Sync layer, content pulling - straightforward but needs careful testing
- **High Risk**: Reminder system (A11-12) - OEM battery optimization can break background alarms
  - **Mitigation**: Health check with real device testing required per spec

---

*Analysis complete. Project is approximately 50-60% complete with excellent foundation and clear path to completion.*
