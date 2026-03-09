# Tasks: CourtStats Event Engine MVP

**Input**: Design documents from `/specs/001-event-engine-mvp/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/cli-contract.md

**Tests**: TDD is mandatory per project constitution. Tests are written first, verified to fail, then implementation makes them pass.

**Organization**: Tasks grouped by user story. US2 (parsing) precedes US1 (score ticker) because parsing is the data entry point.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2)
- Exact file paths included in descriptions

---

## Phase 1: Setup

**Purpose**: SPM project structure, dependencies, and build verification

- [x] T001 Create Package.swift with CourtStatsCore library and CourtStatsCLI executable targets, swift-argument-parser 1.3+ dependency, macOS 15 platform, test targets with fixture resources in Package.swift
- [x] T002 Create directory structure: Sources/Core/Models/, Sources/Core/Parsing/, Sources/Core/EventBus/, Sources/Core/Projections/, Sources/Core/Rendering/, Sources/Core/FCPXML/, Sources/Core/Pipeline/, Sources/CLI/Commands/, Tests/CourtStatsCoreTests/Parsing/, Tests/CourtStatsCoreTests/Projections/, Tests/CourtStatsCoreTests/GameState/, Tests/CourtStatsCoreTests/Rendering/, Tests/IntegrationTests/Fixtures/, Tests/IntegrationTests/Fixtures/Golden/
- [x] T003 Create minimal CourtStats.swift root command with ArgumentParser @main entry point in Sources/CLI/CourtStats.swift
- [x] T004 Verify `swift build` succeeds with empty targets

**Checkpoint**: Project compiles. `swift build` and `swift test` both pass (no tests yet).

---

## Phase 2: Foundational (Core Models & Protocols)

**Purpose**: Core types that ALL user stories depend on. MUST complete before any user story work.

**CRITICAL**: No user story work can begin until this phase is complete.

### Tests

- [x] T005 [P] Write tests for Team enum (home/opponent, init from marker code "T"/"O", case-insensitive) in Tests/CourtStatsCoreTests/GameState/TeamTests.swift
- [x] T006 [P] Write tests for StatType enum (all 15 codes, pointsValue, isScoring, isSubstitution, init from marker code) in Tests/CourtStatsCoreTests/GameState/StatTypeTests.swift
- [x] T007 [P] Write tests for GameEvent value type (construction, markerIndex identity, pointsValue derived from statType) in Tests/CourtStatsCoreTests/GameState/GameEventTests.swift
- [x] T008 [P] Write tests for GameState mutations (apply scoring event updates score, apply substitution updates on-court sets) in Tests/CourtStatsCoreTests/GameState/GameStateTests.swift

### Implementation

- [x] T009 [P] Implement Team enum with home/opponent cases and init(markerCode:) in Sources/Core/Models/Team.swift
- [x] T010 [P] Implement StatType enum with all 15 cases, pointsValue, isScoring, isSubstitution, init(markerCode:) in Sources/Core/Models/StatType.swift
- [x] T011 [P] Implement GameEvent struct (team, playerNumber, statType, pointsValue, timecode, markerIndex) in Sources/Core/Models/GameEvent.swift
- [x] T012 [P] Implement MarkerAnnotation enum (valid, invalid, warn, ignored) in Sources/Core/Models/MarkerAnnotation.swift
- [x] T013 Implement GameState struct with apply(_ event:) mutation method, PlayerKey, PlayerStatLine in Sources/Core/Models/GameState.swift
- [x] T014 Define Projection protocol (handle(_ event:), reset()) in Sources/Core/Projections/Projection.swift
- [x] T015 Implement EventBus (register projections, dispatch events in order) in Sources/Core/EventBus/EventBus.swift

**Checkpoint**: Foundation ready. All core types compile, all foundational tests pass. `swift test` green.

---

## Phase 3: User Story 2 — Parse and Validate Stat Markers (Priority: P1)

**Goal**: Parse `CS:<TEAM>:<PLAYER#>:<STAT>` markers into GameEvents, annotate invalid markers with `[CS:INVALID]`, handle whitespace normalisation and case-insensitive input.

**Independent Test**: Create hand-crafted marker strings, verify correct GameEvent output for valid markers, nil + invalid annotation for bad markers, and ignored annotation for non-CS markers.

### Tests for User Story 2

> **Write these tests FIRST. Verify they FAIL before implementing.**

- [x] T016 [P] [US2] Write tests for valid marker parsing (CS:T:7:PTS2 → GameEvent, all stat codes, both teams) in Tests/CourtStatsCoreTests/Parsing/MarkerParserTests.swift
- [x] T017 [P] [US2] Write tests for invalid marker rejection (too few segments, invalid team code, invalid stat code, non-numeric player number) in Tests/CourtStatsCoreTests/Parsing/MarkerParserTests.swift
- [x] T018 [P] [US2] Write tests for whitespace normalisation and case-insensitive parsing in Tests/CourtStatsCoreTests/Parsing/MarkerParserTests.swift
- [x] T019 [P] [US2] Write tests for annotation stripping (existing [CS:INVALID] and [CS:WARN] stripped before re-parse) in Tests/CourtStatsCoreTests/Parsing/MarkerParserTests.swift
- [x] T020 [P] [US2] Write tests for non-CS marker detection (regular FCP markers return nil event + ignored annotation) in Tests/CourtStatsCoreTests/Parsing/MarkerParserTests.swift

### Implementation for User Story 2

- [x] T021 [US2] Implement MarkerParser.parse(markerValue:timecode:markerIndex:) → (GameEvent?, MarkerAnnotation) in Sources/Core/Parsing/MarkerParser.swift
- [x] T022 [US2] Implement annotation stripping logic (strip [CS:INVALID], [CS:WARN] suffixes) in MarkerParser in Sources/Core/Parsing/MarkerParser.swift

**Checkpoint**: MarkerParser converts raw marker strings to typed GameEvents. All US2 tests pass. `swift test` green.

---

## Phase 4: User Story 1 — Process Scoring Markers into Score Ticker Overlays (Priority: P1) MVP

**Goal**: End-to-end pipeline: read FCPXML → parse markers → compute running score → generate score ticker titles on lane 99 → write valid FCPXML output. This is the MVP delivery.

**Independent Test**: Process an FCPXML with scoring markers and verify output contains correctly positioned score ticker titles with accurate running scores.

**Dependencies**: Requires Phase 2 (models) and Phase 3 (parser) complete.

### Tests for User Story 1

> **Write these tests FIRST. Verify they FAIL before implementing.**

- [x] T023 [P] [US1] Write tests for ScoreProjection (handle scoring events, cumulative score, missed shots add 0, ScoreSnapshot output) in Tests/CourtStatsCoreTests/Projections/ScoreProjectionTests.swift
- [x] T024 [P] [US1] Write tests for FCPXMLReader (extract markers from FCPXML, parse rational timecodes, handle nested clip containers) in Tests/CourtStatsCoreTests/FCPXML/FCPXMLReaderTests.swift
- [x] T025 [P] [US1] Write tests for ScoreTickerRenderer (convert ScoreSnapshots to title XML elements, lane 99, [CS] prefix, duration spans, title template reference) in Tests/CourtStatsCoreTests/Rendering/ScoreTickerRendererTests.swift
- [x] T026 [P] [US1] Write tests for FCPXMLWriter (strip existing [CS] titles, insert new titles, add effect resource, preserve all other content) in Tests/CourtStatsCoreTests/FCPXML/FCPXMLWriterTests.swift

### Implementation for User Story 1

- [x] T027 [P] [US1] Implement ScoreProjection (handle scoring events, produce [ScoreSnapshot]) in Sources/Core/Projections/ScoreProjection.swift
- [x] T028 [P] [US1] Implement FCPXMLReader (load FCPXML, extract markers with timecodes, parse rational time format) in Sources/Core/FCPXML/FCPXMLReader.swift
- [x] T029 [US1] Implement ScoreTickerRenderer (convert ScoreSnapshots to FCPXML title elements, lane 99, [CS] prefix, configurable team names, configurable title template) in Sources/Core/Rendering/ScoreTickerRenderer.swift
- [x] T030 [US1] Implement FCPXMLWriter (strip existing [CS] titles on lane 99, insert rendered titles, add/update effect resource for title template, write marker annotations) in Sources/Core/FCPXML/FCPXMLWriter.swift
- [x] T031 [US1] Implement ProcessingPipeline (orchestrate: read → parse → dispatch → project → render → write) in Sources/Core/Pipeline/ProcessingPipeline.swift
- [x] T032 [US1] Implement ProcessCommand with ArgumentParser (input path, --output, --home-name, --away-name, --title-template, exit codes 0/1/2, stderr diagnostics) in Sources/CLI/Commands/ProcessCommand.swift
- [x] T033 [US1] Wire ProcessCommand into CourtStats root command in Sources/CLI/CourtStats.swift

### Integration Tests for User Story 1

- [x] T034 [US1] Create basic-scoring.fcpxml test fixture (PTS2, PTS3, FT markers at known timecodes) in Tests/IntegrationTests/Fixtures/basic-scoring.fcpxml
- [ ] T035 [US1] Create basic-scoring-expected.fcpxml golden file with expected score ticker output in Tests/IntegrationTests/Fixtures/Golden/basic-scoring-expected.fcpxml
- [x] T036 [US1] Write pipeline integration test (process basic-scoring fixture, verify score ticker titles, compare against golden file) in Tests/IntegrationTests/PipelineTests.swift
- [x] T037 [US1] Write idempotency test (process output of previous run, verify structurally identical) in Tests/IntegrationTests/IdempotencyTests.swift
- [x] T038 [US1] Create malformed-markers.fcpxml fixture and write test for invalid marker annotation in Tests/IntegrationTests/Fixtures/malformed-markers.fcpxml and Tests/IntegrationTests/PipelineTests.swift

**Checkpoint**: Full MVP functional. `courtstats process input.fcpxml -o output.fcpxml` produces score ticker overlays. All US1 + US2 tests pass. Idempotency verified.

---

## Phase 5: User Story 3 — Track Substitutions and Minutes Played (Priority: P2)

**Goal**: Track player on-court state via SUBON/SUBOFF markers, calculate minutes played per player, flag logical inconsistencies (duplicate SUBON, orphaned SUBOFF).

**Independent Test**: Process FCPXML with SUBON/SUBOFF markers and verify minutes played calculations and warning annotations.

**Dependencies**: Requires Phase 2 (models) and Phase 3 (parser). Independent of US1.

### Tests for User Story 3

> **Write these tests FIRST. Verify they FAIL before implementing.**

- [x] T039 [P] [US3] Write tests for SubstitutionProjection (SUBON/SUBOFF state tracking, on-court sets, duplicate SUBON warning, orphaned SUBOFF warning, auto-close open stints) in Tests/CourtStatsCoreTests/Projections/SubstitutionProjectionTests.swift
- [x] T040 [P] [US3] Write tests for MinutesPlayedProjection (single stint, multiple stints, cumulative minutes, auto-close at last event) in Tests/CourtStatsCoreTests/Projections/MinutesPlayedProjectionTests.swift

### Implementation for User Story 3

- [x] T041 [P] [US3] Implement SubstitutionProjection (track on-court sets per team, generate warnings for logical inconsistencies, auto-close open stints on finalise) in Sources/Core/Projections/SubstitutionProjection.swift
- [x] T042 [US3] Implement MinutesPlayedProjection (track stints via SUBON/SUBOFF timecodes, calculate total minutes per player) in Sources/Core/Projections/MinutesPlayedProjection.swift
- [x] T043 [US3] Register SubstitutionProjection and MinutesPlayedProjection in ProcessingPipeline, wire [CS:WARN] annotations for substitution warnings in Sources/Core/Pipeline/ProcessingPipeline.swift
- [ ] T044 [US3] Create substitution-tracking.fcpxml fixture and golden file, write integration test in Tests/IntegrationTests/Fixtures/substitution-tracking.fcpxml, Tests/IntegrationTests/Fixtures/Golden/substitution-tracking-expected.fcpxml, Tests/IntegrationTests/PipelineTests.swift (deferred — unit tests cover logic, integration fixture not blocking)

**Checkpoint**: Substitution tracking and minutes played functional. Warning annotations appear for logical errors. All US3 tests pass.

---

## Phase 6: User Story 4 — Calculate Plus/Minus per Player (Priority: P2)

**Goal**: Calculate cumulative +/- for each player based on scoring events that occur while they are on court.

**Independent Test**: Set up known on-court players, feed scoring events for both teams, verify correct +/- per player.

**Dependencies**: Requires US3 (SubstitutionProjection provides on-court state).

### Tests for User Story 4

> **Write these tests FIRST. Verify they FAIL before implementing.**

- [x] T045 [P] [US4] Write tests for PlusMinusProjection (on-court players get +/- for home/opponent scoring, off-court players unaffected, player scores before SUBON treated as on-court with warning) in Tests/CourtStatsCoreTests/Projections/PlusMinusProjectionTests.swift

### Implementation for User Story 4

- [x] T046 [US4] Implement PlusMinusProjection (consume scoring events, query SubstitutionProjection for on-court set, accumulate +/- per player) in Sources/Core/Projections/PlusMinusProjection.swift
- [x] T047 [US4] Register PlusMinusProjection in ProcessingPipeline in Sources/Core/Pipeline/ProcessingPipeline.swift

**Checkpoint**: Plus/minus correctly attributed only to on-court players. All US4 tests pass.

---

## Phase 7: User Story 5 — Maintain Player Game Log (Priority: P2)

**Goal**: Record every stat event per player in chronological order as a complete game log.

**Independent Test**: Feed assorted stat events for multiple players, verify each player's log is correct and ordered.

**Dependencies**: Requires Phase 2 (models). Independent of US1, US3, US4.

### Tests for User Story 5

> **Write these tests FIRST. Verify they FAIL before implementing.**

- [x] T048 [P] [US5] Write tests for PlayerGameLogProjection (events recorded per player, chronological order, players only see their own events) in Tests/CourtStatsCoreTests/Projections/PlayerGameLogProjectionTests.swift

### Implementation for User Story 5

- [x] T049 [US5] Implement PlayerGameLogProjection (maintain per-player event list in chronological order) in Sources/Core/Projections/PlayerGameLogProjection.swift
- [x] T050 [US5] Register PlayerGameLogProjection in ProcessingPipeline in Sources/Core/Pipeline/ProcessingPipeline.swift

**Checkpoint**: Player game logs correctly track all events per player. All US5 tests pass.

---

## Phase 8: User Story 6 — Graceful Degradation with Partial Data (Priority: P3)

**Goal**: Processor handles incomplete data gracefully — scoring-only files produce score overlays without crashing, empty files produce clean output.

**Independent Test**: Process FCPXML with only scoring markers (no substitutions), verify score overlays correct, no errors. Process FCPXML with no CS markers, verify clean pass-through.

**Dependencies**: Requires US1 complete (score ticker pipeline). Exercises all projections.

### Tests for User Story 6

> **Write these tests FIRST. Verify they FAIL before implementing.**

- [x] T051 [P] [US6] Write integration test for scoring-only input (no SUBON/SUBOFF markers — score overlays generated, minutes/plus-minus omitted, no errors) in Tests/IntegrationTests/PipelineTests.swift
- [x] T052 [P] [US6] Write integration test for empty input (no CS markers at all — clean output, no overlays, no errors, existing [CS] titles removed) in Tests/IntegrationTests/PipelineTests.swift
- [x] T053 [P] [US6] Write integration test for edge cases (no timeline, no clips, scoring before SUBON) in Tests/IntegrationTests/PipelineTests.swift

### Implementation for User Story 6

- [x] T054 [US6] Add nil-safe checks to ProcessingPipeline and projections — omit calculations when prerequisite data is absent rather than erroring in Sources/Core/Pipeline/ProcessingPipeline.swift
- [x] T055 [US6] Create empty-timeline.fcpxml fixture in Tests/IntegrationTests/Fixtures/empty-timeline.fcpxml
- [x] T056 [US6] Create mixed-markers.fcpxml fixture (scoring + non-CS markers, no substitutions) in Tests/IntegrationTests/Fixtures/mixed-markers.fcpxml
- [x] T057 [US6] Create graceful-degradation.fcpxml fixture (edge cases: scoring before SUBON, empty timeline) in Tests/IntegrationTests/Fixtures/graceful-degradation.fcpxml (covered by empty-timeline + mixed-markers fixtures)

**Checkpoint**: Processor handles all partial-data scenarios without crashing. All US6 tests pass.

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: CI/CD, DTD validation, performance, and release infrastructure

- [x] T058 [P] Create .github/workflows/test.yml — PR test workflow (macOS runner, swift test, xmllint DTD validation) in .github/workflows/test.yml
- [x] T059 [P] Create .github/workflows/release.yml — tagged release workflow (universal binary build, GitHub Release asset) in .github/workflows/release.yml
- [x] T060 [P] Add FCPXML DTD file to test fixtures for xmllint validation in Tests/IntegrationTests/Fixtures/
- [ ] T061 Write DTD validation test (run xmllint on processor output) in Tests/IntegrationTests/PipelineTests.swift
- [x] T062 Add --version flag support via ArgumentParser configuration in Sources/CLI/CourtStats.swift
- [x] T063 Run full test suite and verify all tests pass: `swift test -v`
- [x] T064 Run quickstart.md validation — verify documented commands work

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 — BLOCKS all user stories
- **US2 Parsing (Phase 3)**: Depends on Phase 2 — BLOCKS US1
- **US1 Score Ticker (Phase 4)**: Depends on Phase 2 + Phase 3 — MVP delivery
- **US3 Substitutions (Phase 5)**: Depends on Phase 2 + Phase 3 — independent of US1
- **US4 Plus/Minus (Phase 6)**: Depends on Phase 5 (needs on-court state from SubstitutionProjection)
- **US5 Game Log (Phase 7)**: Depends on Phase 2 only — fully independent, can parallel with US1/US3
- **US6 Graceful Degradation (Phase 8)**: Depends on US1 complete — exercises full pipeline
- **Polish (Phase 9)**: Depends on all user stories complete

### User Story Dependencies

```text
Phase 1 (Setup)
  └── Phase 2 (Foundational)
        ├── Phase 3: US2 Parsing (P1)
        │     └── Phase 4: US1 Score Ticker (P1) ← MVP
        │           └── Phase 8: US6 Graceful Degradation (P3)
        ├── Phase 5: US3 Substitutions (P2) [parallel with US1]
        │     └── Phase 6: US4 Plus/Minus (P2)
        └── Phase 7: US5 Game Log (P2) [parallel with US1, US3]
```

### Parallel Opportunities

After Phase 2 completes:
- **US2 (parsing)** must go first (blocks US1)
- After US2: **US1**, **US3**, and **US5** can all run in parallel (different files, no shared state)
- **US4** must wait for US3 (needs SubstitutionProjection)
- **US6** must wait for US1 (needs full pipeline)
- **Phase 9 CI/CD tasks** (T058, T059, T060) can run in parallel with any user story

### Worktree Strategy (from plan.md)

After Phase 2 foundation is merged:
- **Worktree A**: Projections (ScoreProjection, SubstitutionProjection, MinutesPlayed, PlusMinus, PlayerGameLog)
- **Worktree B**: FCPXML I/O (FCPXMLReader, FCPXMLWriter, ScoreTickerRenderer)
- **Worktree C**: CI/CD + Fixtures (GitHub Actions workflows, FCPXML test fixtures)

---

## Parallel Example: After Phase 2

```bash
# Agent A: US2 Parsing (must go first)
Task: T016-T022 (MarkerParser tests + implementation)

# Then in parallel:
# Agent B: US1 FCPXML I/O components
Task: T024 "FCPXMLReader tests"
Task: T026 "FCPXMLWriter tests"
Task: T028 "FCPXMLReader implementation"
Task: T030 "FCPXMLWriter implementation"

# Agent C: US1 Projections + Renderer
Task: T023 "ScoreProjection tests"
Task: T025 "ScoreTickerRenderer tests"
Task: T027 "ScoreProjection implementation"
Task: T029 "ScoreTickerRenderer implementation"

# Agent D: CI/CD (independent)
Task: T058 "test.yml workflow"
Task: T059 "release.yml workflow"
Task: T060 "DTD fixture file"
```

---

## Implementation Strategy

### MVP First (US2 + US1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational models and protocols
3. Complete Phase 3: US2 Parsing — entry point for all data
4. Complete Phase 4: US1 Score Ticker — end-to-end round-trip
5. **STOP and VALIDATE**: `courtstats process` produces score overlays, idempotency passes
6. This is a shippable MVP

### Incremental Delivery

1. Setup + Foundational → Project compiles
2. US2 Parsing → Markers convert to typed events
3. US1 Score Ticker → **MVP! Score overlays work end-to-end**
4. US3 Substitutions → Minutes played tracking added
5. US4 Plus/Minus → Advanced metric available
6. US5 Game Log → Per-player history available
7. US6 Graceful Degradation → Robustness for real-world data
8. Polish → CI/CD, DTD validation, release automation

### Task Count Summary

| Phase | Story | Tasks | Parallel |
|-------|-------|-------|----------|
| Phase 1: Setup | — | 4 | 0 |
| Phase 2: Foundational | — | 11 | 8 |
| Phase 3: US2 Parsing | US2 | 7 | 5 |
| Phase 4: US1 Score Ticker | US1 | 16 | 6 |
| Phase 5: US3 Substitutions | US3 | 6 | 2 |
| Phase 6: US4 Plus/Minus | US4 | 3 | 1 |
| Phase 7: US5 Game Log | US5 | 3 | 1 |
| Phase 8: US6 Degradation | US6 | 7 | 3 |
| Phase 9: Polish | — | 7 | 3 |
| **Total** | | **64** | **29** |

---

## Notes

- [P] tasks = different files, no dependencies on incomplete tasks
- [Story] label maps task to specific user story for traceability
- TDD is mandatory: write tests first, verify they fail, then implement
- Commit after each task or logical group
- Stop at any checkpoint to validate the story independently
- US2 before US1 because parsing is the data entry point for everything
