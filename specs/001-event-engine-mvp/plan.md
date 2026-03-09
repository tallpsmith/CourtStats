# Implementation Plan: CourtStats Event Engine MVP

**Branch**: `001-event-engine-mvp` | **Date**: 2026-03-08 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-event-engine-mvp/spec.md`

## Summary

Build the event-sourced basketball stats processing engine as a
standalone Swift Package Manager CLI tool. Parse CS: markers from
FCPXML, compute running game stats via independent projections,
generate score ticker overlays, and write valid FCPXML output.
CLI interface: `courtstats process <input> -o <output>`. Automated
CI via GitHub Actions on macOS runners. Releases as universal
macOS binaries via GitHub Releases on tagged commits.

## Technical Context

**Language/Version**: Swift 5.9+
**Primary Dependencies**: swift-argument-parser 1.3+, Foundation XMLDocument
**Storage**: N/A (file-based I/O only — FCPXML in, FCPXML out)
**Testing**: XCTest via `swift test`, xmllint for DTD validation
**Target Platform**: macOS 15+ (Sequoia)
**Project Type**: CLI tool + reusable library
**Performance Goals**: < 5 seconds for ~100 markers on a 2-hour timeline
**Constraints**: Self-contained binary, no runtime dependencies beyond macOS system libs
**Scale/Scope**: Single-user CLI, typical input ~50-200 markers per game

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Evidence |
|-----------|--------|----------|
| I. Test-First | PASS | TDD workflow mandated. Tests written before implementation in every phase. Unit tests for each projection, integration tests with FCPXML fixtures, golden file regression tests. |
| II. Incremental Delivery | PASS | Four implementation phases, each producing testable working software. Phase 1 foundation → Phase 2 parser → Phase 3 projections (parallelisable) → Phase 4 integration + CI/CD. |
| III. Single Responsibility | PASS | One projection per file. One renderer per file. Parser, bus, projections, renderers are separate types with single purposes. |
| IV. Readability First | PASS | Descriptive naming conventions defined in data model. Short focused methods. Comments for "why" only. |
| V. Event-Sourced Purity | PASS | GameEvent is the single source of truth. Projections are pure functions testable with hand-crafted event sequences. Adding future projections is purely additive. |
| VI. Idempotency | PASS | First-class test target with dedicated fixtures. Full replacement of generated titles on each run. Annotation stripping before re-parse. |
| VII. Simplicity | PASS | Foundation XMLDocument (no third-party XML). Basic Title via FCPXML params. FCPXML 1.9+ single file. No speculative abstractions. |

No violations. No complexity tracking entries needed.

## Project Structure

### Documentation (this feature)

```text
specs/001-event-engine-mvp/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── cli-contract.md
└── tasks.md                 # Created by /speckit.tasks
```

### Source Code (repository root)

```text
Package.swift
Sources/
├── Core/
│   ├── Models/
│   │   ├── GameEvent.swift
│   │   ├── StatType.swift
│   │   ├── Team.swift
│   │   ├── GameState.swift
│   │   └── MarkerAnnotation.swift
│   ├── Parsing/
│   │   └── MarkerParser.swift
│   ├── EventBus/
│   │   └── EventBus.swift
│   ├── Projections/
│   │   ├── Projection.swift          # Protocol
│   │   ├── ScoreProjection.swift
│   │   ├── SubstitutionProjection.swift
│   │   ├── MinutesPlayedProjection.swift
│   │   ├── PlusMinusProjection.swift
│   │   └── PlayerGameLogProjection.swift
│   ├── Rendering/
│   │   └── ScoreTickerRenderer.swift
│   ├── FCPXML/
│   │   ├── FCPXMLReader.swift
│   │   └── FCPXMLWriter.swift
│   └── Pipeline/
│       └── ProcessingPipeline.swift
└── CLI/
    ├── CourtStats.swift              # @main root command
    └── Commands/
        └── ProcessCommand.swift

Tests/
├── CourtStatsCoreTests/
│   ├── Parsing/
│   │   └── MarkerParserTests.swift
│   ├── Projections/
│   │   ├── ScoreProjectionTests.swift
│   │   ├── SubstitutionProjectionTests.swift
│   │   ├── MinutesPlayedProjectionTests.swift
│   │   ├── PlusMinusProjectionTests.swift
│   │   └── PlayerGameLogProjectionTests.swift
│   ├── GameState/
│   │   └── GameStateTests.swift
│   └── Rendering/
│       └── ScoreTickerRendererTests.swift
└── IntegrationTests/
    ├── PipelineTests.swift
    ├── IdempotencyTests.swift
    ├── Fixtures/
    │   ├── basic-scoring.fcpxml
    │   ├── substitution-tracking.fcpxml
    │   ├── malformed-markers.fcpxml
    │   ├── idempotency.fcpxml
    │   ├── empty-timeline.fcpxml
    │   ├── mixed-markers.fcpxml
    │   └── graceful-degradation.fcpxml
    └── Fixtures/Golden/
        ├── basic-scoring-expected.fcpxml
        └── substitution-tracking-expected.fcpxml

.github/
└── workflows/
    ├── test.yml                      # PR test workflow
    └── release.yml                   # Tagged release workflow
```

**Structure Decision**: Swift Package Manager with separate library
target (`CourtStatsCore`) and executable target (`CourtStatsCLI`).
The library contains all domain logic; the CLI is a thin shell using
ArgumentParser. This enables direct reuse in the Phase 2 Workflow
Extension without code duplication.

## Parallelisation Strategy

The event-sourced architecture provides natural seams for parallel
development using git worktrees and concurrent Claude agents.

### Dependency Graph

```text
Phase 1: Foundation (sequential — must complete first)
  └── Package.swift, core models, Projection protocol

Phase 2: Parser (can start after Phase 1)
  └── MarkerParser + MarkerParserTests

Phase 3: Parallel workstreams (can ALL start after Phase 1)
  ┌── Worktree A: Projections
  │   ├── ScoreProjection + tests
  │   ├── SubstitutionProjection + tests
  │   ├── MinutesPlayedProjection + tests
  │   ├── PlusMinusProjection + tests
  │   └── PlayerGameLogProjection + tests
  │
  ├── Worktree B: FCPXML I/O
  │   ├── FCPXMLReader + tests
  │   ├── FCPXMLWriter + tests
  │   └── ScoreTickerRenderer + tests
  │
  └── Worktree C: CI/CD + Fixtures
      ├── .github/workflows/test.yml
      ├── .github/workflows/release.yml
      └── FCPXML test fixtures (hand-crafted)

Phase 4: Integration (sequential — after all worktrees merge)
  ├── EventBus wiring
  ├── ProcessingPipeline
  ├── ProcessCommand (CLI)
  ├── Integration tests
  ├── Golden file tests
  └── Idempotency tests
```

### Agent Team Execution Plan

After Phase 1 (foundation) is complete on mainline:

1. **Create three worktrees** from the foundation commit:
   - `worktree-projections` — Agent A works on all 5 projections
   - `worktree-fcpxml-io` — Agent B works on FCPXML read/write + renderer
   - `worktree-cicd-fixtures` — Agent C works on CI/CD workflows + test fixtures

2. **Each agent works independently** — no shared files between
   worktrees. The only shared dependency is the `Models/` directory
   from Phase 1, which is read-only for all agents.

3. **Merge worktrees** back to the feature branch sequentially.
   Conflicts are unlikely because each worktree touches different
   files entirely.

4. **Phase 4 integration** runs on the merged branch, wiring
   everything together and running the full test suite.

### Why This Split Works

- **Projections** (Agent A) are pure functions of `GameEvent` —
  they need zero knowledge of FCPXML structure or CLI.
- **FCPXML I/O** (Agent B) deals with XML parsing/writing — it
  needs `GameEvent` and `ScoreSnapshot` types but not projection
  internals.
- **CI/CD + Fixtures** (Agent C) is entirely infrastructure — YAML
  workflows and hand-crafted XML files with no Swift code
  dependencies.

## Complexity Tracking

> No constitution violations. No entries needed.
