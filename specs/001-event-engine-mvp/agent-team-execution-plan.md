# Agent Team Execution Plan: CourtStats Event Engine MVP

**Branch**: `001-event-engine-mvp` | **Date**: 2026-03-09
**Input**: tasks.md (user story view), plan.md (architecture)

## Execution Model

This plan maps tasks.md (organized by **user story** for traceability) into
an **agent team model** organized by **file ownership** (to eliminate merge
conflicts). Three stages:

1. **Lead Session** — sequential work on the feature branch
2. **Agent Team** — parallel worktrees, one agent per architectural layer
3. **Lead Session** — merge worktrees, wire everything together, integration tests

```text
┌─────────────────────────────────────────────────────┐
│  STAGE 1: Lead Session (feature branch)             │
│  Setup → Foundation → Parser                        │
│  T001–T022                                          │
└──────────────────────┬──────────────────────────────┘
                       │ commit: "foundation complete"
                       │ create 3 worktrees from this commit
          ┌────────────┼────────────┐
          ▼            ▼            ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│  STAGE 2A    │ │  STAGE 2B    │ │  STAGE 2C    │
│  Agent A     │ │  Agent B     │ │  Agent C     │
│  Projections │ │  FCPXML I/O  │ │  CI/CD +     │
│              │ │  + Renderer  │ │  Fixtures    │
└──────┬───────┘ └──────┬───────┘ └──────┬───────┘
       │                │                │
       └────────────────┼────────────────┘
                        │ merge all 3 worktrees
                        ▼
┌─────────────────────────────────────────────────────┐
│  STAGE 3: Lead Session (feature branch)             │
│  Integration wiring → Integration tests →           │
│  Graceful degradation → Polish                      │
│  T031–T038, T043–T044, T047, T050–T064              │
└─────────────────────────────────────────────────────┘
```

---

## Stage 1: Lead Session (Sequential)

**Who**: You (or a single Claude session) on the `001-event-engine-mvp` branch.
**Purpose**: Build the foundation that all agents will read from.

### Phase 1: Setup (T001–T004)

```
T001  Package.swift
T002  Directory structure
T003  Sources/CLI/CourtStats.swift (minimal @main)
T004  Verify swift build
```

**Gate**: `swift build` succeeds.

### Phase 2: Foundational Models & Protocols (T005–T015)

```
Tests (parallel — different files):
  T005  Tests/CourtStatsCoreTests/GameState/TeamTests.swift
  T006  Tests/CourtStatsCoreTests/GameState/StatTypeTests.swift
  T007  Tests/CourtStatsCoreTests/GameState/GameEventTests.swift
  T008  Tests/CourtStatsCoreTests/GameState/GameStateTests.swift

Implementation (parallel where marked):
  T009  [P] Sources/Core/Models/Team.swift
  T010  [P] Sources/Core/Models/StatType.swift
  T011  [P] Sources/Core/Models/GameEvent.swift
  T012  [P] Sources/Core/Models/MarkerAnnotation.swift
  T013      Sources/Core/Models/GameState.swift
  T014      Sources/Core/Projections/Projection.swift (protocol)
  T015      Sources/Core/EventBus/EventBus.swift
```

**Gate**: `swift test` green. All model + protocol tests pass.

### Phase 3: US2 — MarkerParser (T016–T022)

```
Tests (all same file, write together):
  T016  Tests/CourtStatsCoreTests/Parsing/MarkerParserTests.swift
  T017  (same file — invalid markers)
  T018  (same file — whitespace/case)
  T019  (same file — annotation stripping)
  T020  (same file — non-CS markers)

Implementation:
  T021  Sources/Core/Parsing/MarkerParser.swift
  T022  (same file — annotation stripping logic)
```

**Gate**: `swift test` green. Parser converts raw strings to typed events.

### Stage 1 Completion

Commit with message: `Foundation + parser complete — ready for agent team`

This commit is the **fork point**. Every worktree branches from here.
All agents inherit these read-only shared files:

- `Sources/Core/Models/*` (Team, StatType, GameEvent, GameState, MarkerAnnotation)
- `Sources/Core/Projections/Projection.swift` (protocol only)
- `Sources/Core/EventBus/EventBus.swift`
- `Sources/Core/Parsing/MarkerParser.swift`
- `Tests/CourtStatsCoreTests/GameState/*`
- `Tests/CourtStatsCoreTests/Parsing/*`

---

## Stage 2: Agent Team (Parallel Worktrees)

**Three agents**, each in their own git worktree, each owning a
non-overlapping set of files. They share the Stage 1 foundation
as read-only context. No agent touches another agent's files.

### Agent A — Projections Specialist

**Worktree**: `worktree-projections`
**Owns**: `Sources/Core/Projections/*` (except `Projection.swift` protocol — read-only)
**Also owns**: `Tests/CourtStatsCoreTests/Projections/*`

**File ownership** (writes to these files ONLY):

| File | Tasks |
|------|-------|
| `Tests/CourtStatsCoreTests/Projections/ScoreProjectionTests.swift` | T023 |
| `Sources/Core/Projections/ScoreProjection.swift` | T027 |
| `Tests/CourtStatsCoreTests/Projections/SubstitutionProjectionTests.swift` | T039 |
| `Sources/Core/Projections/SubstitutionProjection.swift` | T041 |
| `Tests/CourtStatsCoreTests/Projections/MinutesPlayedProjectionTests.swift` | T040 |
| `Sources/Core/Projections/MinutesPlayedProjection.swift` | T042 |
| `Tests/CourtStatsCoreTests/Projections/PlusMinusProjectionTests.swift` | T045 |
| `Sources/Core/Projections/PlusMinusProjection.swift` | T046 |
| `Tests/CourtStatsCoreTests/Projections/PlayerGameLogProjectionTests.swift` | T048 |
| `Sources/Core/Projections/PlayerGameLogProjection.swift` | T049 |

**Execution order** (TDD per projection):

```
1. T023  ScoreProjection tests           (write, verify fails)
2. T027  ScoreProjection implementation  (verify tests pass)
3. T039  SubstitutionProjection tests    (write, verify fails)
4. T041  SubstitutionProjection impl     (verify tests pass)
5. T040  MinutesPlayedProjection tests   (write, verify fails)
6. T042  MinutesPlayedProjection impl    (verify tests pass)
7. T045  PlusMinusProjection tests       (write, verify fails)
8. T046  PlusMinusProjection impl        (verify tests pass)
9. T048  PlayerGameLogProjection tests   (write, verify fails)
10. T049 PlayerGameLogProjection impl    (verify tests pass)
```

**Verification**: `swift test --filter CourtStatsCoreTests.ScoreProjection` etc.
Agent A can run all projection unit tests because projections are pure
functions of `GameEvent` sequences — no FCPXML dependency.

**Commit strategy**: One commit per test+implementation pair (5 commits).

**Does NOT touch**:
- `ProcessingPipeline.swift` (that's Stage 3 wiring)
- `PipelineTests.swift` (that's Stage 3 integration)
- Any FCPXML, Rendering, or CLI files

---

### Agent B — FCPXML I/O Specialist

**Worktree**: `worktree-fcpxml-io`
**Owns**: `Sources/Core/FCPXML/*`, `Sources/Core/Rendering/*`
**Also owns**: `Tests/CourtStatsCoreTests/FCPXML/*`, `Tests/CourtStatsCoreTests/Rendering/*`

**File ownership** (writes to these files ONLY):

| File | Tasks |
|------|-------|
| `Tests/CourtStatsCoreTests/FCPXML/FCPXMLReaderTests.swift` | T024 |
| `Sources/Core/FCPXML/FCPXMLReader.swift` | T028 |
| `Tests/CourtStatsCoreTests/FCPXML/FCPXMLWriterTests.swift` | T026 |
| `Sources/Core/FCPXML/FCPXMLWriter.swift` | T030 |
| `Tests/CourtStatsCoreTests/Rendering/ScoreTickerRendererTests.swift` | T025 |
| `Sources/Core/Rendering/ScoreTickerRenderer.swift` | T029 |

**Execution order** (TDD per component):

```
1. T024  FCPXMLReader tests              (write, verify fails)
2. T028  FCPXMLReader implementation     (verify tests pass)
3. T026  FCPXMLWriter tests              (write, verify fails)
4. T030  FCPXMLWriter implementation     (verify tests pass)
5. T025  ScoreTickerRenderer tests       (write, verify fails)
6. T029  ScoreTickerRenderer impl        (verify tests pass)
```

**Verification**: `swift test --filter CourtStatsCoreTests.FCPXMLReader` etc.
Agent B tests with inline XML strings in unit tests — no dependency on
fixture files or projections.

**Commit strategy**: One commit per test+implementation pair (3 commits).

**Does NOT touch**:
- Any Projection files
- `ProcessingPipeline.swift`
- Integration test files
- CLI files

---

### Agent C — Infrastructure & Fixtures Specialist

**Worktree**: `worktree-cicd-fixtures`
**Owns**: `.github/workflows/*`, `Tests/IntegrationTests/Fixtures/*`

**File ownership** (writes to these files ONLY):

| File | Tasks |
|------|-------|
| `.github/workflows/test.yml` | T058 |
| `.github/workflows/release.yml` | T059 |
| `Tests/IntegrationTests/Fixtures/basic-scoring.fcpxml` | T034 |
| `Tests/IntegrationTests/Fixtures/Golden/basic-scoring-expected.fcpxml` | T035 |
| `Tests/IntegrationTests/Fixtures/malformed-markers.fcpxml` | T038 (fixture only) |
| `Tests/IntegrationTests/Fixtures/substitution-tracking.fcpxml` | T044 (fixture only) |
| `Tests/IntegrationTests/Fixtures/Golden/substitution-tracking-expected.fcpxml` | T044 (fixture only) |
| `Tests/IntegrationTests/Fixtures/empty-timeline.fcpxml` | T055 |
| `Tests/IntegrationTests/Fixtures/mixed-markers.fcpxml` | T056 |
| `Tests/IntegrationTests/Fixtures/graceful-degradation.fcpxml` | T057 |
| `Tests/IntegrationTests/Fixtures/FCPXMLv1_11.dtd` | T060 |

**Execution order** (no TDD dependencies — these are data files and YAML):

```
1. T058  .github/workflows/test.yml
2. T059  .github/workflows/release.yml
3. T060  DTD fixture file
4. T034  basic-scoring.fcpxml
5. T035  basic-scoring-expected.fcpxml (golden file)
6. T038  malformed-markers.fcpxml (fixture file only)
7. T044  substitution-tracking.fcpxml + golden (fixture files only)
8. T055  empty-timeline.fcpxml
9. T056  mixed-markers.fcpxml
10. T057 graceful-degradation.fcpxml
```

**Context needed**: Agent C must understand the FCPXML structure from
research.md to hand-craft valid fixtures. The marker format from spec.md
defines what goes in each fixture. Golden files must match the expected
output format from the ScoreTickerRenderer (title elements on lane 99).

**Verification**: `xmllint --noout *.fcpxml` for well-formedness.
YAML files can be validated with `yamllint` if available.

**Commit strategy**: One commit for CI workflows, one for all fixtures.

**Does NOT touch**:
- Any Swift source files
- Any Swift test files
- `PipelineTests.swift` or `IdempotencyTests.swift`

---

## Stage 2 Summary: What Each Agent Produces

```text
Agent A (Projections):          Agent B (FCPXML I/O):         Agent C (CI/CD + Fixtures):
  5 projection impls              FCPXMLReader                  test.yml workflow
  5 projection test files         FCPXMLWriter                  release.yml workflow
  10 tasks total                  ScoreTickerRenderer           DTD file
                                  3 test files                  7 fixture files
                                  6 tasks total                 10 tasks total
```

**Zero file overlap between agents.** Merges should be conflict-free.

---

## Merging Worktrees

After all three agents complete, merge sequentially into the feature branch:

```bash
# From the feature branch (001-event-engine-mvp):
git merge worktree-projections --no-ff -m "Merge projections: all 5 projection types with tests"
git merge worktree-fcpxml-io --no-ff -m "Merge FCPXML I/O: reader, writer, renderer with tests"
git merge worktree-cicd-fixtures --no-ff -m "Merge CI/CD workflows and FCPXML test fixtures"
```

**Order doesn't matter** — no file conflicts between worktrees. But
merging projections first is natural since it's the largest changeset.

**Post-merge gate**: `swift build` succeeds. `swift test` passes all
unit tests from Agents A and B (26 tasks worth of tests). Fixtures
exist on disk.

---

## Stage 3: Lead Session (Sequential Integration)

**Who**: You (or a single Claude session) on the merged feature branch.
**Purpose**: Wire everything together, write integration tests, handle
cross-cutting concerns.

### Integration Wiring (Pipeline + CLI)

These tasks touch `ProcessingPipeline.swift`, `ProcessCommand.swift`,
and `CourtStats.swift` — files that no agent owned because they
depend on components from multiple agents.

```
T031  Sources/Core/Pipeline/ProcessingPipeline.swift
      (orchestrate: read → parse → dispatch → project → render → write)
T043  (same file — register SubstitutionProjection + MinutesPlayedProjection)
T047  (same file — register PlusMinusProjection)
T050  (same file — register PlayerGameLogProjection)
T032  Sources/CLI/Commands/ProcessCommand.swift
      (ArgumentParser command with exit codes, stderr diagnostics)
T033  Sources/CLI/CourtStats.swift
      (wire ProcessCommand as subcommand)
T062  Sources/CLI/CourtStats.swift
      (add --version flag via ArgumentParser configuration)
```

**Gate**: `swift build` succeeds. `courtstats process --help` prints usage.

### Integration Tests

These tests exercise the full pipeline with Agent C's fixtures and
Agent A's projections through Agent B's FCPXML I/O layer.

```
T036  Tests/IntegrationTests/PipelineTests.swift
      (process basic-scoring fixture, verify score tickers, golden file comparison)
T037  Tests/IntegrationTests/IdempotencyTests.swift
      (process output again, verify structurally identical)
T038  Tests/IntegrationTests/PipelineTests.swift
      (malformed marker annotation test — fixture from Agent C)
T044  Tests/IntegrationTests/PipelineTests.swift
      (substitution integration test — fixture from Agent C)
T061  Tests/IntegrationTests/PipelineTests.swift
      (DTD validation with xmllint)
```

**Gate**: `swift test` green. Full pipeline verified end-to-end.

### US6: Graceful Degradation

```
T051  Tests/IntegrationTests/PipelineTests.swift (scoring-only input test)
T052  Tests/IntegrationTests/PipelineTests.swift (empty input test)
T053  Tests/IntegrationTests/PipelineTests.swift (edge case test)
T054  Sources/Core/Pipeline/ProcessingPipeline.swift (nil-safe checks)
```

Fixtures T055–T057 were already created by Agent C.

**Gate**: `swift test` green. Processor handles all partial-data scenarios.

### Final Validation

```
T063  swift test -v (full suite — should already be green)
T064  Quickstart.md validation (run documented commands, verify output)
```

**Gate**: All 64 tasks complete. All tests pass. `courtstats process`
works end-to-end with real FCPXML input.

---

## Task Reassignment Summary

The following tasks from tasks.md are **split** between agents and
Stage 3 because they touch files across ownership boundaries:

| Task | tasks.md Phase | Agent Owner | Stage 3 Owner | Why Split |
|------|---------------|-------------|---------------|-----------|
| T038 | US1 (Phase 4) | Agent C (fixture file) | Lead (test code) | Fixture is data, test is Swift |
| T044 | US3 (Phase 5) | Agent C (fixture files) | Lead (test code) | Fixture is data, test is Swift |
| T043 | US3 (Phase 5) | — | Lead | Touches ProcessingPipeline.swift (multi-agent dependency) |
| T047 | US4 (Phase 6) | — | Lead | Touches ProcessingPipeline.swift (multi-agent dependency) |
| T050 | US5 (Phase 7) | — | Lead | Touches ProcessingPipeline.swift (multi-agent dependency) |

---

## Agent Briefing Template

Each agent receives this briefing when dispatched:

### Common Context (all agents)

```
You are working on the CourtStats Event Engine MVP (branch: 001-event-engine-mvp).

Read these files for context (DO NOT modify them):
- specs/001-event-engine-mvp/spec.md (user stories and acceptance criteria)
- specs/001-event-engine-mvp/data-model.md (type definitions)
- specs/001-event-engine-mvp/research.md (FCPXML structure, design decisions)
- specs/001-event-engine-mvp/plan.md (architecture, project structure)
- CLAUDE.md (project conventions)

The foundation is already built. You can read but MUST NOT modify:
- Sources/Core/Models/* (Team, StatType, GameEvent, GameState, MarkerAnnotation)
- Sources/Core/Projections/Projection.swift (protocol)
- Sources/Core/EventBus/EventBus.swift
- Sources/Core/Parsing/MarkerParser.swift

TDD is mandatory: write tests first, verify they fail, then implement.
Commit after each test+implementation pair.
```

### Agent A Briefing

```
Role: Projections Specialist
Worktree: worktree-projections

You own ALL files in:
- Sources/Core/Projections/ (except Projection.swift — read-only)
- Tests/CourtStatsCoreTests/Projections/

Your task list (execute in this order):
[T023, T027, T039, T041, T040, T042, T045, T046, T048, T049]

Each projection is a pure function of [GameEvent] sequences.
Test with hand-crafted GameEvent arrays — no FCPXML needed.
Verify: swift test --filter Projections

DO NOT create or modify:
- ProcessingPipeline.swift (wiring happens after merge)
- Any FCPXML, Rendering, CLI, or integration test files
```

### Agent B Briefing

```
Role: FCPXML I/O Specialist
Worktree: worktree-fcpxml-io

You own ALL files in:
- Sources/Core/FCPXML/
- Sources/Core/Rendering/
- Tests/CourtStatsCoreTests/FCPXML/
- Tests/CourtStatsCoreTests/Rendering/

Your task list (execute in this order):
[T024, T028, T026, T030, T025, T029]

Use inline XML strings in unit tests. Reference research.md for
FCPXML structure (marker elements, rational timecode format,
title element structure, lane 99 convention).
Verify: swift test --filter FCPXML && swift test --filter Rendering

DO NOT create or modify:
- Any Projection files
- ProcessingPipeline.swift
- Integration tests or fixture files
- CLI files
```

### Agent C Briefing

```
Role: Infrastructure & Fixtures Specialist
Worktree: worktree-cicd-fixtures

You own ALL files in:
- .github/workflows/
- Tests/IntegrationTests/Fixtures/
- Tests/IntegrationTests/Fixtures/Golden/

Your task list (execute in this order):
[T058, T059, T060, T034, T035, T038, T044, T055, T056, T057]

For CI workflows: reference research.md for GitHub Actions config.
For FCPXML fixtures: reference research.md for XML structure and
spec.md for marker format and acceptance scenarios. Hand-craft
valid FCPXML files — these are test data, not generated output.
Golden files must match expected output format (score ticker
titles on lane 99 with [CS] prefix).
Verify: xmllint --noout Tests/IntegrationTests/Fixtures/*.fcpxml

DO NOT create or modify:
- Any Swift source files (.swift)
- PipelineTests.swift or IdempotencyTests.swift
```

---

## Timeline Estimate

```text
Stage 1 (Lead):    ~22 tasks, sequential
Stage 2 (Agents):  ~26 tasks, parallel across 3 agents
                   Agent A: 10 tasks (longest — paces the stage)
                   Agent B:  6 tasks
                   Agent C: 10 tasks (but simpler — data files + YAML)
Stage 3 (Lead):    ~16 tasks, sequential (wiring + integration)
```

The bottleneck is Stage 2 Agent A (5 projection pairs). Agents B
and C will likely finish first. Stage 3 cannot begin until all
three agents complete and merge.

---

## Dispatch Checklist

Before launching Stage 2:

- [ ] Stage 1 complete — all T001–T022 done
- [ ] `swift build` succeeds
- [ ] `swift test` green (foundation + parser tests)
- [ ] Commit tagged or noted as fork point
- [ ] Three worktrees created from fork point commit
- [ ] Each agent briefing reviewed and dispatched
- [ ] File ownership boundaries confirmed (no overlaps)

After Stage 2, before Stage 3:

- [ ] All three agents report completion
- [ ] All three worktrees merged into feature branch
- [ ] `swift build` succeeds on merged branch
- [ ] `swift test` passes all unit tests (projections + FCPXML I/O)
- [ ] Fixture files exist in Tests/IntegrationTests/Fixtures/
- [ ] CI workflow files exist in .github/workflows/
