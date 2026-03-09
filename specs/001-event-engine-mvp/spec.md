# Feature Specification: CourtStats Event Engine MVP

**Feature Branch**: `001-event-engine-mvp`
**Created**: 2026-03-08
**Status**: Draft
**Input**: Product Specification v0.8 — CourtStats Final Cut Pro Workflow Extension

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Process Scoring Markers into Score Ticker Overlays (Priority: P1)

A parent has recorded a youth basketball game and edited the footage
in Final Cut Pro. During editing they placed structured markers
(`CS:T:7:PTS2`, `CS:O:12:PTS3`, etc.) at the timecodes where scoring
events occurred. They export the timeline as FCPXML, run the
CourtStats processor, and import the result back into FCP. Score
ticker titles now appear on a dedicated lane showing the running
score at each point in the game.

**Why this priority**: Without score tracking and overlay generation,
nothing else in the system has value. This is the core round-trip
that proves the architecture works.

**Independent Test**: Export an FCPXML file with scoring markers from
FCP, run the processor, and verify that the output FCPXML contains
correctly positioned score ticker titles on lane 99 with accurate
running scores. Import into FCP and visually confirm.

**Acceptance Scenarios**:

1. **Given** an FCPXML file with `CS:T:7:PTS2` at 00:01:30 and
   `CS:O:12:PTS3` at 00:02:45, **When** the processor runs,
   **Then** the output contains a title on lane 99 showing
   "Home 2 — Away 0" starting at 00:01:30 and "Home 2 — Away 3"
   starting at 00:02:45.

2. **Given** an FCPXML file with a mix of PTS2, PTS3, and FT markers,
   **When** the processor runs, **Then** each title reflects the
   cumulative score at that point in the timeline.

3. **Given** an FCPXML file with missed shot markers (PTS2X, PTS3X,
   FTX), **When** the processor runs, **Then** the score does not
   change for missed shots.

4. **Given** the processor output is run through the processor again,
   **When** comparing the two outputs, **Then** they are
   structurally identical (idempotency).

---

### User Story 2 — Parse and Validate Stat Markers (Priority: P1)

The user has placed markers in their FCP timeline using the
structured format `CS:<TEAM>:<PLAYER#>:<STAT>`. Some markers may
contain typos or invalid data. The processor MUST parse valid
markers into game events, reject invalid markers with clear
annotations, and leave non-CS markers completely untouched.

**Why this priority**: Parsing is the entry point for all data.
Without robust, validated parsing, every downstream projection
produces garbage.

**Independent Test**: Create an FCPXML file containing a mix of
valid markers, invalid markers (bad syntax, unknown stat codes),
and regular FCP markers. Run the processor and verify that valid
markers produce correct events, invalid markers receive
`[CS:INVALID]` annotations, and non-CS markers are unchanged.

**Acceptance Scenarios**:

1. **Given** a marker `CS:T:7:PTS2`, **When** parsed, **Then** it
   produces a GameEvent with team=home, playerNumber=7,
   stat=fieldGoal2pt, points=2.

2. **Given** a marker `CS:T:7` (too few segments), **When** parsed,
   **Then** it returns nil and the marker receives a `[CS:INVALID]`
   annotation in the output.

3. **Given** a marker `CS:X:7:PTS2` (invalid team code), **When**
   parsed, **Then** it returns nil and receives `[CS:INVALID]`.

4. **Given** a marker with extra whitespace `  CS: T : 7 : PTS2  `,
   **When** parsed, **Then** it normalises and parses successfully.

5. **Given** a marker in mixed case `cs:t:7:pts2`, **When** parsed,
   **Then** it parses successfully (case-insensitive).

6. **Given** a regular FCP marker `Chapter 1` or `TODO: fix audio`,
   **When** the processor runs, **Then** the marker is completely
   unchanged in the output.

7. **Given** a previously annotated marker `CS:T:7:PTS2 [CS:INVALID]`,
   **When** re-processed, **Then** the annotation is stripped before
   parsing and the marker parses as valid.

---

### User Story 3 — Track Substitutions and Minutes Played (Priority: P2)

The user places substitution markers (`CS:T:7:SUBON`,
`CS:T:7:SUBOFF`) at the timecodes where players enter and leave the
game. The processor tracks which players are on court at any point,
calculates minutes played per player, and flags logical
inconsistencies (e.g., a player subbed on who is already on court).

**Why this priority**: Substitution tracking enables minutes played
and plus/minus calculations — key stats for any basketball parent
who wants to understand playing time distribution.

**Independent Test**: Create an FCPXML with SUBON/SUBOFF markers at
known timecodes. Run the processor and verify minutes played
calculations and warning annotations for logical errors.

**Acceptance Scenarios**:

1. **Given** `CS:T:7:SUBON` at t=0 and `CS:T:7:SUBOFF` at t=300s,
   **When** the processor runs, **Then** player 7 has 5.0 minutes
   played.

2. **Given** a player with multiple stints (SUBON/SUBOFF/SUBON/SUBOFF),
   **When** the processor runs, **Then** total minutes is the sum of
   all stints.

3. **Given** a player subbed on but never subbed off, **When** the
   processor finalises, **Then** the open stint is closed using the
   last event timecode.

4. **Given** `CS:T:7:SUBON` when player 7 is already on court,
   **When** parsed, **Then** the marker receives a `[CS:WARN]`
   annotation.

5. **Given** `CS:T:7:SUBOFF` when player 7 is not on court, **When**
   parsed, **Then** the marker receives a `[CS:WARN]` annotation.

---

### User Story 4 — Calculate Plus/Minus per Player (Priority: P2)

While players are on court (tracked via substitution markers),
scoring events for both teams affect those players' plus/minus
ratings. The processor calculates cumulative +/− for each player
based on the scoring that occurs during their on-court time.

**Why this priority**: Plus/minus is a core basketball metric that
parents and coaches want to see, and it depends on both
substitution tracking and score tracking being in place.

**Independent Test**: Set up SUBON markers for known players, feed
scoring events for both teams, and verify that each on-court player
receives the correct +/− adjustment while off-court players are
unaffected.

**Acceptance Scenarios**:

1. **Given** players 7 and 10 are on court and the home team scores
   2 points, **When** the processor runs, **Then** players 7 and 10
   each have +2.

2. **Given** players 7 and 10 are on court and the opponent scores
   3 points, **When** the processor runs, **Then** players 7 and 10
   each have −3.

3. **Given** player 5 is off court when the home team scores,
   **When** the processor runs, **Then** player 5's plus/minus is
   unchanged.

---

### User Story 5 — Maintain Player Game Log (Priority: P2)

Every stat event for a player is recorded in chronological order as
a per-player game log. This provides a complete event history for
each player across the game.

**Why this priority**: The game log is the foundation for box score
generation in later phases and gives parents a detailed per-player
breakdown.

**Independent Test**: Feed assorted stat events for multiple players
and verify each player's event history is correctly ordered and
complete.

**Acceptance Scenarios**:

1. **Given** events for player 7 (PTS2 at t=60, REB at t=120, AST
   at t=180), **When** the processor runs, **Then** player 7's game
   log contains all three events in chronological order.

2. **Given** events for players 7 and 10, **When** the processor
   runs, **Then** each player's game log contains only their own
   events.

---

### User Story 6 — Graceful Degradation with Partial Data (Priority: P3)

Not every game recording will have complete marker data. A user
might only place scoring markers without any substitution markers.
The processor MUST still produce correct output for the data that
IS present and silently omit calculations that require missing data.

**Why this priority**: Real-world usage is messy. A tool that
crashes or produces confusing output when data is incomplete will
be abandoned immediately.

**Independent Test**: Create an FCPXML with only scoring markers
(no substitutions). Run the processor and verify score overlays
are correct, minutes played and plus/minus are omitted, and no
errors occur.

**Acceptance Scenarios**:

1. **Given** an FCPXML with scoring markers but no SUBON/SUBOFF
   markers, **When** the processor runs, **Then** score ticker
   overlays are generated correctly, minutes played is omitted,
   and plus/minus is omitted.

2. **Given** an FCPXML with no CS markers at all, **When** the
   processor runs, **Then** the output is clean with no overlays,
   no errors, and any previously generated `[CS]` titles removed.

---

### Edge Cases

- What happens when a player scores before any SUBON marker exists
  for them? The score is recorded; the player is treated as "on
  court by implication" for plus/minus purposes, with a `[CS:WARN]`
  annotation.
- What happens with duplicate consecutive scoring events at the
  same timecode? Both events are processed independently; the score
  ticker shows the cumulative result after both.
- What happens if the FCPXML file has no timeline or no clips? The
  processor produces an empty output with no overlays and no errors.
- What happens with extremely long games (4+ hours)? The processor
  handles arbitrary timeline lengths; title durations are computed
  from event-to-event intervals regardless of absolute length.

## Clarifications

### Session 2026-03-08

- Q: How should automated testing run in CI? → A: GitHub Actions on
  macOS runners with full test suite (unit, integration, golden file
  regression, DTD validation) on every PR. Extract golden files to a
  nightly-only run only if CI times become problematic.
- Q: How should the tool be released and distributed? → A: Phase 1
  uses GitHub Releases with a pre-built universal macOS binary
  (arm64 + x86_64), automated from CI on tagged commits. CI builds
  MUST produce the release artifact to validate clean-room
  reproducibility. Long-term trajectory: Homebrew tap + Mac App
  Store distribution in later phases.
- Q: What versioning scheme for releases? → A: Semantic Versioning
  (MAJOR.MINOR.PATCH). MAJOR for breaking FCPXML output format
  changes, MINOR for new projections/features, PATCH for bug fixes.
- Q: How should the CLI report errors and exit? → A: Structured
  exit codes: 0 for clean success, 1 for invalid input file
  (unreadable/not FCPXML), 2 for successful processing with
  validation warnings annotated in output. Human-readable messages
  to stderr.
- Q: What is the CLI invocation pattern? → A:
  `courtstats process <input.fcpxml> -o <output.fcpxml>`.
  Subcommand pattern for future extensibility. Documentation MUST
  include instructions for generating real-world test files from
  Final Cut Pro (File → Export XML workflow with CS: markers placed
  on the timeline).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST parse structured markers in the format
  `CS:<TEAM>:<PLAYER#>:<STAT>` from FCPXML marker elements.
- **FR-002**: System MUST support team codes `T` (home) and `O`
  (opponent) with case-insensitive matching.
- **FR-003**: System MUST support stat codes: PTS2, PTS3, FT, PTS2X,
  PTS3X, FTX, REB, OREB, AST, STL, BLK, TO, PF, SUBON, SUBOFF.
- **FR-004**: System MUST annotate invalid markers with `[CS:INVALID]`
  appended to the marker text in the output FCPXML.
- **FR-005**: System MUST annotate logically inconsistent markers
  with `[CS:WARN]` (e.g., duplicate SUBON).
- **FR-006**: System MUST strip existing `[CS:INVALID]` and
  `[CS:WARN]` annotations before re-parsing (idempotent annotation).
- **FR-007**: System MUST generate score ticker title elements on
  FCPXML lane 99 with the name prefix `[CS]`. Title elements MUST
  reference a named Motion title template (default: "Basic Title").
  The processor sets text content only — all visual styling
  (font, size, colour, position, animation) is owned by the
  template, not the processor.
- **FR-007a**: The CLI MUST accept an optional `--title-template`
  flag to override the default title template name. If omitted,
  "Basic Title" is used.
- **FR-008**: System MUST calculate running cumulative score after
  each scoring event (PTS2=2pts, PTS3=3pts, FT=1pt; missed shots
  add 0 points).
- **FR-009**: Title text format MUST be
  `<HomeTeamName> <HomeScore> — <AwayTeamName> <AwayScore>`.
- **FR-010**: Title duration MUST span from the scoring event to the
  next scoring event. The last title uses a configurable default
  duration.
- **FR-011**: System MUST replace all previously generated `[CS]`
  titles on lane 99 on each run (full replacement, not append).
- **FR-012**: System MUST leave all non-CS markers, user clips, and
  user-created titles untouched.
- **FR-013**: System MUST track substitution state (on-court set)
  per team via SUBON/SUBOFF events.
- **FR-014**: System MUST calculate minutes played per player as the
  sum of all on-court stints.
- **FR-015**: System MUST calculate plus/minus per player based on
  scoring events that occur while the player is on court.
- **FR-016**: System MUST maintain a chronological game log per
  player of all stat events.
- **FR-017**: System MUST produce valid FCPXML output that passes
  Apple DTD validation via `xmllint`.
- **FR-018**: System MUST be idempotent: processing the output of a
  previous run MUST produce structurally identical output.
- **FR-019**: System MUST normalise whitespace and handle
  case-insensitive input for marker parsing.
- **FR-020**: System MUST accept an FCPXML file as input and produce
  a modified FCPXML file as output (CLI tool interface).
- **FR-021**: All unit tests, integration tests, golden file
  regression tests, and DTD validation MUST run via GitHub Actions
  on macOS runners on every pull request. Golden file tests MAY be
  moved to a nightly schedule if PR CI times exceed acceptable
  thresholds.
- **FR-022**: Tagged commits MUST trigger a CI workflow that builds
  a universal macOS binary (arm64 + x86_64) and publishes it as a
  GitHub Release asset.
- **FR-023**: The release binary MUST be self-contained with no
  runtime dependencies beyond macOS system libraries.
- **FR-024**: Releases MUST follow Semantic Versioning
  (MAJOR.MINOR.PATCH). MAJOR increments for breaking changes to
  FCPXML output format, MINOR for new projections or features,
  PATCH for bug fixes. The CLI MUST support a `--version` flag.
- **FR-025**: CLI MUST exit with code 0 on clean success, code 1
  when the input file is unreadable or not valid FCPXML, and code 2
  when processing succeeds but validation warnings/errors were
  annotated in the output.
- **FR-026**: CLI MUST write diagnostic messages (errors, warnings,
  processing summary) to stderr. FCPXML output MUST go to the
  output file only, never to stdout mixed with diagnostics.
- **FR-027**: CLI MUST use subcommand pattern:
  `courtstats process <input.fcpxml> -o <output.fcpxml>`.
  Subcommand structure allows future commands (e.g., `validate`,
  `version`) without breaking the interface.
- **FR-028**: Project documentation MUST include a quickstart guide
  covering: how to export FCPXML from Final Cut Pro (File → Export
  XML), how to place CS: markers on a timeline, how to run the
  processor, and how to import the result back into FCP.

### Key Entities

- **GameEvent**: A single parsed stat event with team, player
  number, stat type, points value, and source timecode.
- **GameState**: Cumulative running state updated after each event:
  team score, opponent score, per-player stat lines, on-court sets.
- **ScoreProjection**: Read model producing a chronological list of
  score snapshots (timecode, home score, away score).
- **SubstitutionProjection**: Read model tracking which players are
  on court at any point and flagging warnings.
- **MinutesPlayedProjection**: Read model calculating total on-court
  time per player.
- **PlusMinusProjection**: Read model calculating cumulative +/−
  per player.
- **PlayerGameLogProjection**: Read model of chronological event
  history per player.
- **ScoreTickerRenderer**: Converts ScoreProjection read model into
  FCPXML title elements on lane 99, referencing a named Motion title
  template. Sets text content only; visual styling is delegated to
  the template.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can process an FCPXML file with scoring markers
  and see correct score ticker overlays in Final Cut Pro within a
  single export-process-import cycle.
- **SC-002**: Processing the same file twice produces identical
  output (zero structural differences after XML normalisation).
- **SC-003**: All generated FCPXML output passes Apple DTD
  validation with zero errors.
- **SC-004**: Invalid markers are annotated in the output so the
  user can find and fix them by searching for `[CS:INVALID]` in
  FCP's Timeline Index.
- **SC-005**: Score calculations are 100% accurate: every scoring
  event produces the correct cumulative score across an entire game.
- **SC-006**: The processor completes in under 5 seconds for a
  typical game file (2-hour timeline, ~100 stat markers).
- **SC-007**: The processor handles edge cases (no markers, partial
  data, malformed markers) without crashing, producing a valid
  FCPXML output in all cases.
- **SC-008**: Minutes played calculations are accurate to within
  1 second of the marker timecodes.
- **SC-009**: Plus/minus calculations correctly attribute scoring
  only to players who are on court at the time of each scoring
  event.
