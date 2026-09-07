# Smriti App - Complete Development Task List

*Generated: 2026-09-08*  
*Project: Smriti - Voice-first, offline-first Flutter tablet app for elderly dementia patients*  
*Status: Backend foundation complete (A01-A08), Frontend & Sync layers in progress*

---

## Rules & Guidelines

1. **One task per session** - Focus on completing one major feature at a time
2. **Run `flutter analyze`** after every change and paste full output
3. **Commit after each task** - Keep commits atomic and well-described
4. **Backend architecture is FIXED** - Do not modify the core principles:
   - SQLite (Drift) is the source of truth
   - Supabase is a sync destination only
   - No file outside `lib/core/sync/` and `lib/core/auth/` may import `supabase_flutter`
5. **Test on real Android devices** - Emulators don't reproduce OEM battery optimization

---

## Phase 0 - FOUNDATION (COMPLETED ✅)

### Core Infrastructure
- [x] **A01** Drift schema + DAOs - All 10 tables implemented and verified
- [x] **A02** File path service - All directories and path utilities working
- [x] **A03** AbilityEstimator - Complete with seed, update, nextDifficulty, RT tracking
- [x] **A04** Supabase initialization - Connected to live backend, PKCE auth configured

### Data Layer
- [x] **A05** Repositories - content_repo, event_repo, ability_repo, memo_repo all implemented
- [x] **A06** Session runner + CognitiveGame interface + Market Basket game - End-to-end tested

### Pairing System
- [x] **A07** QR code pairing path - Working with real tokens, integrated with camera
- [x] **A08** Caregiver-login pairing path - Mandatory signOut before setSession verified

**Status**: All foundational backend and data layer tasks are complete and tested.

---

## Phase 1 - SYNC & CONTENT (PRIORITY HIGH)

### Sync Engine & Content Management
- [ ] **A09** ContentPuller + MediaDownloader
  - Implement `ContentPuller` class in `lib/core/sync/content_puller.dart`
  - Implement `MediaDownloader` class in `lib/core/sync/media_downloader.dart`
  - Fetch patient content via `get_patient_content` RPC
  - Download media files to temp directory
  - Verify all files on disk before DB swap
  - Atomic transaction: delete old content → insert new content → update contentVersion
  - **AC**: Real patient content populates People/Medications/RoutineItems and downloads media

- [ ] **A10** EventPusher + MemoUploader + EscalationWriter + Heartbeat
  - Implement `EventPusher` class - Pushes unsynced TrialEvents and Sessions to Supabase
  - Implement `MemoUploader` class - Uploads voice memos to patient-memos bucket
  - Implement `EscalationWriter` class - Writes escalation requests to Supabase
  - Implement `Heartbeat` service - Calls `device_heartbeat` RPC with patient_id, app_version, pending_events count
  - **AC**: Playing a session online results in rows appearing in Supabase with matching IDs
  - **AC**: No `.select()` used anywhere (verify by grep)

- [ ] **A11** SyncEngine Orchestrator
  - Implement `SyncEngine` class that coordinates all sync operations
  - Runs on: connectivity regained, every 15 min via Workmanager, app foreground, after session ends
  - Each sync stage independently wrapped (failure in one doesn't block others)
  - Track last sync time and errors in AppConfigs
  - **AC**: Independent sync stages verified

---

## Phase 2 - REMINDERS & HEALTH CHECK (PRIORITY HIGH)

### Medication Reminder System
- [ ] **A12** AlarmScheduler
  - Implement `AlarmScheduler` class in `lib/core/reminders/alarm_scheduler.dart`
  - Schedule alarms using AndroidAlarmManager with exact timing
  - Calculate next occurrence for each medication based on daysOfWeek and chosenTimeMin
  - Handle alarm cancellation and rescheduling
  - Use deterministic alarm IDs: `(medId.hashCode & 0x00FFFFFF) * 10 + dayOfWeek`
  - **AC**: Alarms scheduled for all active medications

- [ ] **A13** Reminder Isolate + Ladder System
  - Implement `fireReminderCallback` as top-level function with `@pragma('vm:entry-point')`
  - Opens own Drift connection (NO main isolate access)
  - Creates ReminderEvent row when alarm fires
  - Shows full-screen notification with medication info
  - Plays caregiver voice recording (med.voicePath)
  - Schedule ladder steps: Step 1 (15 min later), Step 2 (30 min later - escalation)
  - Schedule next medication occurrence
  - **AC**: Alarm fires with app fully killed, and again after device reboot

- [ ] **A14** Ladder Steps Implementation
  - Step 0: Full-screen notification with caregiver's voice
  - Step 1: Repeat notification, louder (15 min after Step 0)
  - Step 2: Write to EscalationRequests table → server places real phone call
  - Implement `LadderManager` to track and execute ladder steps
  - **AC**: Escalation row written when Step 2 triggered

### Setup & Validation
- [ ] **A15** Health Check System
  - Implement `HealthCheck` class in `lib/core/reminders/health_check.dart`
  - Request required permissions: SCHEDULE_EXACT_ALARM, NOTIFICATION, IGNORE_BATTERY_OPTIMIZATIONS, MICROPHONE
  - Detect OEM (Xiaomi/Oppo/Vivo/Huawei/Samsung) and open autostart settings
  - Schedule a real test alarm 60s out, require caregiver confirmation
  - **AC**: On Xiaomi/Oppo/Vivo test device, test alarm actually fires after health check

---

## Phase 3 - USER INTERFACE & EXPERIENCE

### Main Application Flow
- [ ] **B01** Main Home Screen (Elder-facing)
  - Create `HomeScreen` in `lib/screens/home_screen.dart`
  - Large, touch-friendly UI with minimal text
  - Show time, date, weather (if available)
  - Quick access to games, memos, routine
  - Elder name display
  - Voice-first navigation
  - **AC**: Screen works in both portrait and landscape

- [ ] **B02** Game Selection Screen
  - Create `GameSelectScreen` in `lib/screens/game_select_screen.dart`
  - Visual representation of available games
  - Large, colorful game icons with minimal text
  - Animation/preview of each game
  - Adaptive difficulty display (optional)
  - **AC**: All games accessible from this screen

- [ ] **B03** Session Start Flow
  - Create `SessionStartScreen` or integrate into game screens
  - Ghost-hand demo plays automatically on first game start
  - Clear visual instructions without text
  - Touch anywhere to begin
  - **AC**: Session starts and first item displayed

- [ ] **B04** Session In Progress UI
  - Create reusable session UI components
  - Progress indicator (visual, not numerical)
  - Time remaining visualization
  - Touch interaction for game responses
  - Feedback animation (praise/neutral tones only)
  - Demo replay button
  - **AC**: Full session plays with visual feedback

- [ ] **B05** Session End Screen
  - Create `SessionEndScreen` in `lib/screens/session_end_screen.dart`
  - Positive reinforcement animation
  - Summary of session (visual, no scores)
  - Option to continue or return home
  - **AC**: Session properly closed and data saved

### Medication & Routine UI
- [ ] **B06** Medication Reminder Screen (Full-screen)
  - Create `ReminderScreen` in `lib/screens/reminder_screen.dart`
  - Full-screen take-over when medication is due
  - Large medication name and photo display
  - Play caregiver voice recording automatically
  - Big "Taken" and "Skip" buttons
  - Visual confirmation when taken
  - **AC**: Reminder displays correctly and records response

- [ ] **B07** Medication List Screen (Caregiver-facing)
  - Create `MedicationListScreen` in `lib/screens/medication_list_screen.dart`
  - List all medications with times
  - Edit medication details
  - Toggle active/inactive
  - **AC**: Caregiver can view and manage medications

- [ ] **B08** Routine Display Screen
  - Create `RoutineScreen` in `lib/screens/routine_screen.dart`
  - Visual timeline of daily routine
  - Icons for each activity
  - Time-based highlighting of current/next activity
  - **AC**: Routine displays correctly throughout the day

### Voice & Media UI
- [ ] **B09** Voice Memo Recording Screen
  - Create `VoiceMemoScreen` in `lib/screens/voice_memo_screen.dart`
  - Large record button
  - Visual feedback during recording
  - Playback functionality
  - Context tag selection (morning, evening, thought, etc.)
  - **AC**: Memos recorded and saved to local storage

- [ ] **B10** Photo Viewer Screen
  - Create `PhotoViewerScreen` in `lib/screens/photo_viewer_screen.dart`
  - Full-screen photo display
  - Swipe between photos
  - Play associated voice recording (if available)
  - Memory prompt display (if available)
  - **AC**: Photos display with associated media

- [ ] **B11** People Directory Screen
  - Create `PeopleScreen` in `lib/screens/people_screen.dart`
  - Grid of family member photos
  - Touch to view details and hear voice
  - Filter living/deceased (caregiver mode)
  - **AC**: All people displayed with their media

### Diagnostics & Settings
- [ ] **B12** Diagnostics Screen (Caregiver-only)
  - Create `DiagnosticsScreen` in `lib/screens/diagnostics_screen.dart`
  - Hidden behind kiosk exit (long-press corner + PIN)
  - Patient/device ID display
  - Content version, last sync time/error
  - Pending event count
  - Auth status, clock skew
  - Health check results with re-run button
  - Next scheduled alarms
  - "Fire test reminder now" button
  - Normal density UI (not elder styling)
  - **AC**: All diagnostic information visible and actionable

- [ ] **B13** Settings Screen (Caregiver-only)
  - Create `SettingsScreen` in `lib/screens/settings_screen.dart`
  - Volume controls
  - Screen brightness/timeout
  - Language selection
  - Kiosk mode toggle
  - Caregiver PIN change
  - **AC**: Settings persist and apply correctly

---

## Phase 4 - ADDITIONAL COGNITIVE GAMES

### Game Development Tasks
- [ ] **B14** Visual Memory Game (Picture Match)
  - Create `picture_match/` directory under `lib/games/`
  - Elder sees a picture, then must find the same picture among distractors
  - Primary domain: Visual Memory
  - Difficulty: Number of distractors + visual similarity
  - Implement ghost-hand demo
  - **AC**: Game fully integrated with session runner

- [ ] **B15** Attention Game (Following Instructions)
  - Create `attention_game/` directory under `lib/games/`
  - Elder must follow a sequence of visual cues
  - Primary domain: Attention
  - Difficulty: Sequence length + complexity
  - Implement ghost-hand demo
  - **AC**: Game fully integrated with session runner

- [ ] **B16** Executive Function Game (Planning)
  - Create `planning_game/` directory under `lib/games/`
  - Elder must complete multi-step tasks
  - Primary domain: Executive Function
  - Difficulty: Number of steps + dependency complexity
  - Implement ghost-hand demo
  - **AC**: Game fully integrated with session runner

- [ ] **B17** Language Game (Word Finding)
  - Create `language_game/` directory under `lib/games/`
  - Elder must identify or categorize items
  - Primary domain: Language
  - Difficulty: Vocabulary level + category complexity
  - Implement ghost-hand demo
  - **AC**: Game fully integrated with session runner

- [ ] **B18** Visuospatial Game (Puzzle)
  - Create `puzzle_game/` directory under `lib/games/`
  - Elder must solve simple spatial puzzles
  - Primary domain: Visuospatial
  - Difficulty: Puzzle complexity + piece count
  - Implement ghost-hand demo
  - **AC**: Game fully integrated with session runner

**Note**: Each game must:
- Implement the `CognitiveGame` interface
- Emit proper `TrialResult` objects
- Never touch the database directly
- Never show negative feedback
- Support ghost-hand demo

---

## Phase 5 - VOICE & AUDIO SYSTEM

### Voice Output
- [ ] **B19** Voice Output System
  - Create `voice_out.dart` in `lib/core/voice/`
  - Integrate `just_audio` package for playback
  - Map PhraseKey enum to audio files
  - Pre-recorded voice phrases for all UI interactions
  - Volume control and ducking for overlapping audio
  - **AC**: All voice phrases play correctly

- [ ] **B20** Voice Phrase Management
  - Create voice phrase files for all PhraseKey values
  - Organize in language-specific directories
  - Support multiple languages (starting with English)
  - **AC**: All phrases available in at least one language

### Voice Input
- [ ] **B21** Voice Input System
  - Create `voice_in.dart` in `lib/core/voice/`
  - Integrate `record` package for recording
  - Simple voice command recognition for home screen
  - Constrained vocabulary (start game, go home, etc.)
  - **AC**: Voice commands work reliably

- [ ] **B22** Voice Memo System Enhancement
  - Enhance MemoRepo with audio processing
  - Compression and format handling for memos
  - Duration tracking and metadata
  - **AC**: Voice memos recorded and saved properly

---

## Phase 6 - KIOSK MODE & DEVICE MANAGEMENT

### Kiosk Mode Implementation
- [ ] **B23** Kiosk Mode Service
  - Create `kiosk_service.dart` in `lib/core/`
  - Integrate `kiosk_mode` package
  - Lock tablet to single app mode
  - Disable home button, recent apps, notifications
  - Handle system buttons gracefully
  - **AC**: Tablet locked down, elder cannot exit app

- [ ] **B24** Kiosk Exit Mechanism
  - Implement caregiver exit: long-press in specific corner
  - PIN entry screen for exit confirmation
  - Configurable corner and gesture
  - **AC**: Caregiver can exit kiosk mode with PIN

### Device Management
- [ ] **B25** Device Replacement Handling
  - Detect when device session becomes invalid (401)
  - Show caregiver-facing "tablet no longer active" screen
  - Do NOT delete local data
  - Option to re-pair
  - **AC**: Graceful handling of device replacement

- [ ] **B26** Battery Optimization Handling
  - Request IGNORE_BATTERY_OPTIMIZATIONS permission
  - Educate caregiver on enabling for specific OEMs
  - Detect and warn if optimization is enabled
  - **AC**: Alarms work even with battery optimization

---

## Phase 7 - ANDROID NATIVE INTEGRATION

### Permissions & Manifest
- [ ] **B27** Add Required Android Permissions
  - Add to `android/app/src/main/AndroidManifest.xml`:
    - SCHEDULE_EXACT_ALARM
    - USE_EXACT_ALARM
    - RECEIVE_BOOT_COMPLETED
    - WAKE_LOCK
    - POST_NOTIFICATIONS
    - REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
    - USE_FULL_SCREEN_INTENT
    - CALL_PHONE
    - RECORD_AUDIO
  - **AC**: All required permissions declared

- [ ] **B28** Main Activity Configuration
  - Configure MainActivity in AndroidManifest.xml
  - screenOrientation="landscape"
  - launchMode="singleTop"
  - showWhenLocked="true"
  - turnScreenOn="true"
  - **AC**: Activity configured correctly for kiosk mode

### Broadcast Receivers
- [ ] **B29** Boot Completed Receiver
  - Register receiver for BOOT_COMPLETED
  - Reschedule all alarms on device boot
  - **AC**: Alarms fire correctly after reboot

- [ ] **B30** Alarm Receiver
  - Register receiver for alarm intents
  - Forward to reminder isolate
  - **AC**: Alarms trigger correctly

---

## Phase 8 - RIVERPOD STATE MANAGEMENT

### State Management
- [ ] **B31** Setup Riverpod Providers
  - Create provider files in `lib/providers/`
  - Provider for database instance
  - Provider for repositories
  - Provider for current patient
  - Provider for sync status
  - **AC**: All major services available via providers

- [ ] **B32** Migrate Screens to Riverpod
  - Update existing screens to use providers
  - Remove direct dependency injection where appropriate
  - Maintain testability
  - **AC**: Screens use providers for dependencies

---

## Phase 9 - VISUAL DESIGN & ANIMATION

### UI Components
- [ ] **B33** Elder-friendly UI Component Library
  - Create reusable widgets in `lib/widgets/`
  - Large touch targets (minimum 48x48 logical pixels)
  - High contrast color schemes
  - Readable fonts at large sizes
  - Minimal text, maximum icons/images
  - **AC**: All UI elements accessible for elderly users

- [ ] **B34** Custom App Theme
  - Define comprehensive theme in `app_theme.dart`
  - Elder-appropriate color palette
  - Large default font sizes
  - High contrast ratios
  - **AC**: Consistent theme throughout app

### Animations
- [ ] **B35** Ghost-Hand Animation
  - Replace stub implementation in `ghost_hand.dart`
  - Smooth, realistic hand movement
  - Configurable paths and timing
  - Visual feedback during demo
  - **AC**: Real ghost-hand animation working

- [ ] **B36** Feedback Animations
  - Positive feedback animations (praise)
  - Neutral feedback animations
  - No negative animations
  - Smooth, non-distracting transitions
  - **AC**: Feedback animations enhance UX without confusing

- [ ] **B37** Loading Animations
  - Custom loading indicators
  - Elder-appropriate visuals
  - No spinning wheels or confusing metaphors
  - **AC**: Loading states clearly communicated

---

## Phase 10 - TESTING & VALIDATION

### Unit Tests
- [ ] **B38** Sync Layer Tests
  - Test ContentPuller with mock responses
  - Test MediaDownloader with file system mocks
  - Test EventPusher, MemoUploader, EscalationWriter
  - Test SyncEngine orchestration
  - **AC**: All sync components have comprehensive tests

- [ ] **B39** Reminder System Tests
  - Test AlarmScheduler calculations
  - Test ladder step scheduling
  - Test escalation request creation
  - **AC**: Reminder system logic verified

- [ ] **B40** Voice System Tests
  - Test voice output playback
  - Test voice recording
  - Test audio file management
  - **AC**: Voice system working correctly

### Integration Tests
- [ ] **B41** End-to-End Sync Test
  - Create test that simulates offline usage then sync
  - Generate trial events locally
  - Sync to Supabase
  - Verify data appears in backend
  - **AC**: Full sync cycle works

- [ ] **B42** Multi-Game Session Test
  - Play multiple games in one session
  - Verify all trials recorded correctly
  - Verify ability estimates updated for each domain
  - **AC**: Multi-game sessions work correctly

- [ ] **B43** Content Pull Test
  - Test with real patient content
  - Verify media downloads
  - Verify DB swap
  - Verify alarm rescheduling
  - **AC**: Content pull works end-to-end

### Real Device Testing
- [ ] **B44** Alarm System Validation (Real Android Device)
  - Test on Xiaomi/Oppo/Vivo/Huawei/Samsung devices
  - Verify alarms fire with app killed
  - Verify alarms fire after reboot
  - Verify battery optimization doesn't interfere
  - **AC**: Alarms work on real devices with OEM battery managers

- [ ] **B45** Offline Functionality Test
  - Put device in airplane mode
  - Play sessions, create memos, trigger reminders
  - Verify all data saved locally
  - Reconnect and verify sync
  - **AC**: Full offline functionality verified

- [ ] **B46** 48-Hour Offline Test (A17)
  - Put tablet in airplane mode
  - Play sessions across two days
  - Confirm reminders fire and ladder progresses locally
  - Reconnect and verify everything uploads
  - Verify no duplicates and no data loss
  - **AC**: 48-hour offline test passes with zero data loss

---

## Phase 11 - POLISH & OPTIMIZATION

### Performance
- [ ] **B47** Performance Optimization
  - Optimize database queries
  - Reduce memory usage
  - Minimize widget rebuilds
  - **AC**: Smooth performance on low-end tablets

- [ ] **B48** Battery Optimization
  - Minimize background work
  - Optimize alarm scheduling
  - Reduce wake locks
  - **AC**: Minimal battery impact

### Accessibility
- [ ] **B49** Accessibility Enhancements
  - Screen reader support (for caregiver screens)
  - High contrast mode
  - Large text support
  - **AC**: Accessibility features working

### Documentation
- [ ] **B50** Update Documentation
  - Update README.md with setup instructions
  - Document all configuration options
  - Create caregiver guide
  - **AC**: Comprehensive documentation available

---

## Task Summary by Category

### Backend & Sync (Original A09-A17)
| ID | Task | Phase | Priority |
|----|------|-------|----------|
| A09 | ContentPuller + MediaDownloader | 1 | HIGH |
| A10 | EventPusher + MemoUploader + EscalationWriter + Heartbeat | 1 | HIGH |
| A11 | SyncEngine Orchestrator | 1 | HIGH |
| A12 | AlarmScheduler | 2 | HIGH |
| A13 | Reminder Isolate + Ladder Steps | 2 | HIGH |
| A14 | Ladder System | 2 | HIGH |
| A15 | Health Check System | 2 | HIGH |
| A17 | 48-Hour Offline Test | 10 | HIGH |

### User Interface & Experience (B01-B13)
| ID | Task | Phase | Priority |
|----|------|-------|----------|
| B01 | Main Home Screen | 3 | HIGH |
| B02 | Game Selection Screen | 3 | HIGH |
| B03 | Session Start Flow | 3 | HIGH |
| B04 | Session In Progress UI | 3 | HIGH |
| B05 | Session End Screen | 3 | HIGH |
| B06 | Medication Reminder Screen | 3 | HIGH |
| B07 | Medication List Screen | 3 | MEDIUM |
| B08 | Routine Display Screen | 3 | MEDIUM |
| B09 | Voice Memo Recording Screen | 3 | MEDIUM |
| B10 | Photo Viewer Screen | 3 | MEDIUM |
| B11 | People Directory Screen | 3 | MEDIUM |
| B12 | Diagnostics Screen | 3 | MEDIUM |
| B13 | Settings Screen | 3 | MEDIUM |

### Additional Games (B14-B18)
| ID | Task | Phase | Priority |
|----|------|-------|----------|
| B14 | Picture Match Game | 4 | MEDIUM |
| B15 | Attention Game | 4 | MEDIUM |
| B16 | Planning Game | 4 | MEDIUM |
| B17 | Language Game | 4 | MEDIUM |
| B18 | Puzzle Game | 4 | MEDIUM |

### Voice & Audio (B19-B22)
| ID | Task | Phase | Priority |
|----|------|-------|----------|
| B19 | Voice Output System | 5 | MEDIUM |
| B20 | Voice Phrase Management | 5 | MEDIUM |
| B21 | Voice Input System | 5 | MEDIUM |
| B22 | Voice Memo System Enhancement | 5 | MEDIUM |

### Kiosk & Device (B23-B26)
| ID | Task | Phase | Priority |
|----|------|-------|----------|
| B23 | Kiosk Mode Service | 6 | MEDIUM |
| B24 | Kiosk Exit Mechanism | 6 | MEDIUM |
| B25 | Device Replacement Handling | 6 | MEDIUM |
| B26 | Battery Optimization Handling | 6 | MEDIUM |

### Native Integration (B27-B30)
| ID | Task | Phase | Priority |
|----|------|-------|----------|
| B27 | Android Permissions | 7 | HIGH |
| B28 | Main Activity Configuration | 7 | HIGH |
| B29 | Boot Completed Receiver | 7 | HIGH |
| B30 | Alarm Receiver | 7 | HIGH |

### State Management (B31-B32)
| ID | Task | Phase | Priority |
|----|------|-------|----------|
| B31 | Riverpod Providers Setup | 8 | MEDIUM |
| B32 | Migrate Screens to Riverpod | 8 | MEDIUM |

### Visual Design (B33-B37)
| ID | Task | Phase | Priority |
|----|------|-------|----------|
| B33 | Elder-friendly UI Components | 9 | LOW |
| B34 | Custom App Theme | 9 | LOW |
| B35 | Ghost-Hand Animation | 9 | MEDIUM |
| B36 | Feedback Animations | 9 | LOW |
| B37 | Loading Animations | 9 | LOW |

### Testing & Validation (B38-B46)
| ID | Task | Phase | Priority |
|----|------|-------|----------|
| B38 | Sync Layer Tests | 10 | HIGH |
| B39 | Reminder System Tests | 10 | HIGH |
| B40 | Voice System Tests | 10 | MEDIUM |
| B41 | End-to-End Sync Test | 10 | HIGH |
| B42 | Multi-Game Session Test | 10 | MEDIUM |
| B43 | Content Pull Test | 10 | HIGH |
| B44 | Alarm Validation (Real Device) | 10 | HIGH |
| B45 | Offline Functionality Test | 10 | HIGH |
| B46 | 48-Hour Offline Test | 10 | HIGH |

### Polish (B47-B50)
| ID | Task | Phase | Priority |
|----|------|-------|----------|
| B47 | Performance Optimization | 11 | LOW |
| B48 | Battery Optimization | 11 | LOW |
| B49 | Accessibility Enhancements | 11 | LOW |
| B50 | Documentation Update | 11 | LOW |

---

## Recommended Development Order

### Priority 1: Core Functionality (Must have for basic app)
```
A09 → A10 → A11 → B01 → B02 → B03 → B04 → B05 → A12 → A13 → A14 → A15
```

### Priority 2: Medication System (Critical for healthcare)
```
B06 → A12 → A13 → A14 → B27 → B28 → B29 → B30 → B44
```

### Priority 3: User Experience (Complete app)
```
B07 → B08 → B09 → B10 → B11 → B12 → B13 → B31 → B32 → B35
```

### Priority 4: Additional Games (Enhanced cognitive assessment)
```
B14 → B15 → B16 → B17 → B18
```

### Priority 5: Voice System (Full voice-first experience)
```
B19 → B20 → B21 → B22 → B40
```

### Priority 6: Kiosk & Polish (Production ready)
```
B23 → B24 → B25 → B26 → B47 → B48 → B49 → B50
```

### Priority 7: Visual Polish (Enhanced UX)
```
B33 → B34 → B36 → B37
```

---

## Estimate Completion Status

- **Foundation (A01-A08)**: 100% ✅
- **Sync & Content (A09-A11, B38-B43)**: 0% ⏳
- **Reminders (A12-A15, B06, B44)**: 0% ⏳
- **UI/UX (B01-B13)**: 0% ⏳
- **Additional Games (B14-B18)**: 0% ⏳
- **Voice System (B19-B22)**: 0% ⏳
- **Kiosk (B23-B26)**: 0% ⏳
- **Native (B27-B30)**: 0% ⏳
- **State Management (B31-B32)**: 0% ⏳
- **Visual Design (B33-B37)**: 0% ⏳
- **Testing (B41-B46)**: 0% ⏳
- **Polish (B47-B50)**: 0% ⏳

**Overall Completion: ~30% (Foundation complete, ~70% remaining)**

---

## Critical Path (Minimum Viable Product)

To have a functional app for basic cognitive assessment:
1. ✅ A01-A08 (Foundation)
2. A09-A11 (Sync & Content)
3. B01-B05 (Basic UI Flow)
4. B14 (One additional game)

This would provide: Pairing, content loading, basic game flow, and sync capability.

---

## Notes

- All backend architecture (AGENTS.md rules) must be preserved
- Sync layer (A09-A11) is the highest priority after foundation
- Reminder system (A12-A15) requires real device testing
- UI/UX tasks can be worked on in parallel with backend tasks
- Voice system depends on Riverpod setup
- 48-hour test (B46) should be done last as a final validation
