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

## Build

```bash
swift build                                        # Debug build
swift build -c release --arch x86_64 --arch arm64  # Universal release binary
```

Debug binary: `.build/debug/courtstats`
Release binary: `.build/apple/Products/Release/courtstats`

**Shared filesystem note**: If building on a network/shared volume, use `--scratch-path /tmp/courtstats-build` to avoid index store race conditions.

## Test

```bash
swift test -v                        # Run all tests (unit + integration)
swift test --filter CourtStatsCoreTests  # Unit tests only
swift test --filter IntegrationTests     # Integration tests only
```

Tests require macOS 15+ (Foundation XMLDocument). No Final Cut Pro needed.

## Run

```bash
# Basic processing
courtstats process game.fcpxml -o game-with-overlays.fcpxml

# With team names
courtstats process game.fcpxml -o out.fcpxml --home-name "Wildcats" --away-name "Eagles"

# With custom Motion title template
courtstats process game.fcpxml -o out.fcpxml --title-template "CourtStats Score Ticker"
```

Exit codes: 0 = success, 1 = input error, 2 = success with warnings (`[CS:INVALID]` or `[CS:WARN]` annotations in output).

## Package & Release

Tagged commits trigger `.github/workflows/release.yml` which builds a universal binary and publishes to GitHub Releases.

```bash
git tag v0.1.0
git push origin v0.1.0
```

## Push

```bash
git push origin <branch>             # Push feature branch
gh pr create --title "..." --body "..."  # Open PR against main
```

CI runs `.github/workflows/test.yml` on every PR (macOS runner, full test suite).

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
