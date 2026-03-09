# CourtStats

A command-line tool that transforms basketball stat markers in Final Cut Pro timelines into score ticker overlays. Place structured markers while editing, run the processor, and import the result back into FCP with running score titles on a dedicated lane.

## How It Works

```
FCPXML Export  -->  courtstats process  -->  FCPXML Import
 (with markers)     (parse, compute,        (with score ticker
                     render overlays)         titles on lane 99)
```

### The Workflow

1. **Edit your game footage** in Final Cut Pro
2. **Place markers** at scoring events using the format `CS:<TEAM>:<PLAYER#>:<STAT>`
3. **Export FCPXML** from Final Cut Pro
4. **Run the processor** to generate score ticker overlays
5. **Import the result** back into FCP -- titles appear on lane 99

### Marker Format

```
CS:T:7:PTS2     Home team, player #7, 2-point field goal
CS:O:12:PTS3    Opponent, player #12, 3-pointer
CS:T:5:FT       Home team, player #5, free throw made
CS:T:7:SUBON    Home team, player #7 enters the game
CS:T:7:SUBOFF   Home team, player #7 leaves the game
```

**Team codes:** `T` = home, `O` = opponent

**All stat codes:** PTS2, PTS3, FT, PTS2X, PTS3X, FTX, REB, OREB, AST, STL, BLK, TO, PF, SUBON, SUBOFF

### What the Processor Computes

| Projection | Description |
|------------|-------------|
| **Score Ticker** | Running score overlay titles (Home 2 -- Away 3) |
| **Substitution Tracking** | Who's on court, with warnings for duplicate/orphaned subs |
| **Minutes Played** | Per-player playing time from SUBON/SUBOFF stints |
| **Plus/Minus** | +/- rating based on scoring while a player is on court |
| **Player Game Log** | Chronological event history per player |

## Installation

### From GitHub Releases

```bash
curl -L -o courtstats \
  https://github.com/tallpsmith/CourtStats/releases/latest/download/courtstats-macos
chmod +x courtstats
```

### Build from Source

Requires macOS 15+ and Swift 5.9+ (Xcode 15+).

```bash
git clone git@github.com:tallpsmith/CourtStats.git
cd CourtStats
swift build
```

## Usage

### Basic

```bash
courtstats process game.fcpxml -o game-with-overlays.fcpxml
```

### With Team Names

```bash
courtstats process game.fcpxml -o game-with-overlays.fcpxml \
  --home-name "Wildcats" --away-name "Eagles"
```

### With Custom Title Template

```bash
courtstats process game.fcpxml -o game-with-overlays.fcpxml \
  --title-template "CourtStats Score Ticker"
```

The default template is "Basic Title" (Apple built-in). Create a custom template in Motion with your preferred font, size, colour, and animation -- the processor sets text content only, all visual styling comes from the template.

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Input error (file not found, invalid FCPXML) |
| 2 | Success with warnings (output produced, but some markers annotated as `[CS:INVALID]` or `[CS:WARN]`) |

### Idempotency

The processor is idempotent. Running it on its own output replaces all generated overlays cleanly -- no duplication, no drift.

## Architecture

Event-sourced pipeline with independent projections:

```
FCPXML Input
  -> FCPXMLReader        Extract markers with rational timecodes
  -> MarkerParser        Parse CS:TEAM:PLAYER#:STAT into typed GameEvents
  -> EventBus            Dispatch events to registered projections
  -> Projections         Each projection builds its own read model independently
  -> ScoreTickerRenderer Convert score snapshots to FCPXML title elements
  -> FCPXMLWriter        Strip old overlays, insert new titles, annotate markers
  -> FCPXML Output
```

Projections are pure functions of GameEvent sequences. Adding a new stat or metric is purely additive -- implement the `Projection` protocol, register it, done. No changes to existing code.

## Project Structure

```
Sources/Core/           CourtStatsCore library (all domain logic)
  Models/               Team, StatType, GameEvent, GameState, ScoreSnapshot
  Parsing/              MarkerParser (CS: format -> GameEvent)
  EventBus/             Dispatches events to projections
  Projections/          Score, Substitution, MinutesPlayed, PlusMinus, GameLog
  Rendering/            ScoreTickerRenderer (snapshots -> FCPXML titles)
  FCPXML/               FCPXMLReader, FCPXMLWriter (XML round-trip)
  Pipeline/             ProcessingPipeline (orchestrates everything)

Sources/CLI/            CourtStatsCLI executable (thin ArgumentParser shell)

Tests/CourtStatsCoreTests/    Unit tests (138 tests)
Tests/IntegrationTests/       Pipeline, idempotency, DTD validation tests
```

## Development

```bash
swift build                                        # Debug build
swift test -v                                      # Run all tests
swift build -c release --arch x86_64 --arch arm64  # Universal release binary
```

## License

See [LICENSE](LICENSE).
