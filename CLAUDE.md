# CourtStats Development Guidelines

## Active Technologies

- Swift 5.9+ with Swift Package Manager
- swift-argument-parser 1.3+ (CLI subcommands)
- Foundation XMLDocument (FCPXML parsing/writing)
- XCTest (unit + integration tests)
- xmllint (FCPXML DTD validation)

## Project Structure

```text
Sources/Core/       — Library target (CourtStatsCore)
Sources/CLI/        — Executable target (CourtStatsCLI)
Tests/CourtStatsCoreTests/  — Unit tests
Tests/IntegrationTests/     — Pipeline + fixture tests
```

## Commands

```bash
swift build                          # Debug build
swift build -c release --arch x86_64 --arch arm64  # Universal release
swift test -v                        # Run all tests
courtstats process <in> -o <out>     # Process FCPXML
```

## Code Style

- Swift standard conventions
- Descriptive method/variable names — no abbreviations
- One projection per file, one renderer per file
- Comments for "why" only, never "what"
- Constitution: `.specify/memory/constitution.md`

## Architecture

Event-sourced pipeline:
FCPXML → MarkerParser → EventBus → Projections → Renderers → FCPXML

Projections are pure functions of GameEvent sequences.
Adding new projections is purely additive — no core changes.

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
