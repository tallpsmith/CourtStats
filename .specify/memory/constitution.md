<!--
Sync Impact Report
  Version change: N/A → 1.0.0 (initial ratification)
  Added principles:
    I.   Test-First (NON-NEGOTIABLE)
    II.  Incremental Delivery
    III. Single Responsibility
    IV.  Readability First
    V.   Event-Sourced Purity
    VI.  Idempotency
    VII. Simplicity
  Added sections:
    - Quality Standards
    - Development Workflow
    - Governance
  Templates requiring updates:
    - .specify/templates/plan-template.md ✅ aligned (Constitution Check
      section references constitution gates — no changes needed)
    - .specify/templates/spec-template.md ✅ aligned (user stories with
      acceptance scenarios support TDD and incremental delivery)
    - .specify/templates/tasks-template.md ✅ aligned (tests-first ordering,
      user-story grouping, checkpoint gates all present)
  Follow-up TODOs: None
-->

# CourtStats Constitution

## Core Principles

### I. Test-First (NON-NEGOTIABLE)

Every behaviour MUST be described by a failing test before
implementation code is written. No exceptions.

- Red-Green-Refactor is the only accepted development cycle.
- Unit tests cover individual components in isolation — hand-crafted
  inputs, no dependency on FCPXML files or Final Cut Pro.
- Integration tests exercise the full pipeline (parse → events →
  projections → render → FCPXML output) against committed fixtures.
- Golden file tests serve as regression safety nets and living
  documentation of processor output.
- FCPXML output MUST validate against Apple's DTD via `xmllint` in
  every integration test run.
- Existing tests MUST NOT be deleted. If a test breaks, fix the
  cause — do not remove the evidence.

### II. Incremental Delivery

Each delivery phase MUST produce independently demonstrable,
working software. No "big bang" integrations.

- The phased delivery plan (Engine → Extension Shell → Integrated
  Processing → Advanced Projections) defines the increment boundary.
- Each phase builds on the previous phase's stable, tested output.
- A phase is not complete until its tests pass, its checkpoint is
  validated, and it can be demonstrated end-to-end within its scope.
- Features land behind working interfaces — never half-wired
  internals pushed to mainline.

### III. Single Responsibility

Every type, method, and module MUST do exactly one thing.

- One projection per file. One renderer per file. One parser
  responsibility per type.
- Methods MUST be short, focused, and named to describe their
  purpose without needing a comment to explain intent.
- If a method needs an "and" in its description, it needs splitting.
- The event-sourced architecture provides natural seams — respect
  them. Projections do not parse. Parsers do not render. The bus
  dispatches and nothing else.

### IV. Readability First

Code is written for humans. The compiler gets it for free.

- Method and variable names MUST be descriptive enough that a
  reader understands purpose without scrolling to a doc comment.
- Favour clarity over cleverness. A straightforward ten-line
  implementation beats a cryptic two-liner every time.
- Consistent formatting, naming conventions, and file organisation
  across the entire codebase — no stylistic drift between modules.
- Comments explain *why*, not *what*. If the *what* needs a
  comment, the code needs rewriting.

### V. Event-Sourced Purity

Projections are pure functions of their input events. The event
bus is a trivial synchronous dispatcher. These boundaries are
sacred.

- `GameEvent` is the single source of truth. All derived state
  flows from replaying events through projections.
- Projections MUST be independently testable by constructing event
  sequences directly — no bus, no other projections, no file I/O.
- Adding new capabilities (Phase 4 projections, new renderers)
  MUST be purely additive — no changes to the core engine, existing
  projections, or the FCPXML parsing layer.
- GameState accumulation and projection replay MUST remain
  deterministic: same events in, same state out, always.

### VI. Idempotency

Processing the same input MUST produce identical output every
time. Processing output MUST produce identical output again.

- The idempotency contract is a first-class test target with
  dedicated fixtures and assertions.
- Previously generated `[CS]` overlays on lane 99 MUST be fully
  replaced on each run — no accumulation, no duplication.
- Marker annotations (`[CS:INVALID]`, `[CS:WARN]`) MUST be
  stripped and re-derived on each run.
- User-created markers, clips, and titles MUST remain untouched.

### VII. Simplicity

Start simple. Stay simple. Add complexity only when a real,
current requirement demands it.

- YAGNI applies at every level: no speculative abstractions, no
  "just in case" parameters, no design-pattern theatre.
- Basic Title via FCPXML parameters is sufficient for MVP overlays.
  Custom Motion templates are a later-phase enhancement, not a
  prerequisite.
- Target FCPXML 1.9+ (single-file format) initially. Bundle format
  support is an enhancement, not a blocker.
- Three similar lines of code are better than a premature
  abstraction. Extract only when duplication is proven painful.

## Quality Standards

- All unit and integration tests MUST pass before any merge to
  mainline.
- FCPXML output MUST validate against Apple's DTD with zero errors.
- Code MUST compile with zero warnings under strict compiler
  settings.
- Every public interface MUST have at least one test exercising its
  contract.
- Graceful degradation: if optional data is missing (e.g., no
  substitution markers), the processor MUST still produce correct
  output for what *is* present, with no errors.

## Development Workflow

- **Branch per feature/phase**: Work happens on feature branches,
  merged to mainline only when the phase checkpoint passes.
- **Commit discipline**: Concise messages focused on *why*. Commit
  after each logical unit of work — not at end-of-day.
- **Podman only**: All containerised tooling uses `podman` and
  `podman compose`. Never Docker. (Documentation for external
  readers uses `docker` for accessibility.)
- **CI on macOS runners**: Unit and integration tests run in CI
  with no dependency on Final Cut Pro. `xmllint` is pre-installed
  on macOS and used for DTD validation.
- **Manual E2E at milestones**: Full FCP round-trip smoke tests at
  each phase completion, following the manual checklist in the
  testing strategy.

## Governance

This constitution is the highest-authority document for
CourtStats development. It supersedes default practices,
framework conventions, and personal preferences.

- **Amendments** require documented rationale, a version bump
  following semver (MAJOR for principle removals/redefinitions,
  MINOR for additions/expansions, PATCH for clarifications), and
  update of the Last Amended date.
- **Compliance** is verified at every code review. A PR that
  violates a principle MUST either fix the violation or document a
  justified exception in the Complexity Tracking table of the
  implementation plan.
- **Precedence**: Constitution → Implementation Plan → Task List →
  ad-hoc decisions. When in conflict, the higher-authority
  document wins.

**Version**: 1.0.0 | **Ratified**: 2026-03-08 | **Last Amended**: 2026-03-08
