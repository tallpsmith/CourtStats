# Quickstart: CourtStats Event Engine

## Prerequisites

- macOS 15 (Sequoia) or later
- Xcode 15+ or Swift 5.9+ toolchain
- Final Cut Pro (for generating real-world test files)

## Build from Source

```bash
git clone git@github.com:tallpsmith/CourtStats.git
cd CourtStats
swift build
```

The binary is at `.build/debug/courtstats`.

## Build Release Binary

```bash
swift build -c release --arch x86_64 --arch arm64
```

Universal binary at `.build/apple/Products/Release/courtstats`.

## Run Tests

```bash
swift test -v
```

This runs all unit tests, integration tests, golden file regression
tests, and FCPXML DTD validation. No Final Cut Pro required.

## Creating Test Files from Final Cut Pro

1. **Open Final Cut Pro** and create a new project with any clip.

2. **Place markers** on the timeline at points where stat events
   occur. To add a marker: position the playhead and press `M`,
   then edit the marker text.

3. **Use the marker format**: `CS:<TEAM>:<PLAYER#>:<STAT>`

   Examples:
   - `CS:T:7:PTS2` — Home team, player 7, 2-point field goal
   - `CS:O:12:PTS3` — Opponent, player 12, 3-pointer
   - `CS:T:5:FT` — Home team, player 5, free throw made
   - `CS:T:7:SUBON` — Home team, player 7 enters game
   - `CS:T:7:SUBOFF` — Home team, player 7 leaves game
   - `CS:T:10:REB` — Home team, player 10, rebound

   Team codes: `T` = home team, `O` = opponent.

   Full stat code list: PTS2, PTS3, FT, PTS2X, PTS3X, FTX, REB,
   OREB, AST, STL, BLK, TO, PF, SUBON, SUBOFF.

4. **Export FCPXML**: File → Export XML → choose a destination.

5. **Run the processor**:

   ```bash
   courtstats process game-export.fcpxml -o game-with-overlays.fcpxml
   ```

   Optional: specify team names for the score ticker:

   ```bash
   courtstats process game-export.fcpxml -o game-with-overlays.fcpxml \
     --home-name "Wildcats" --away-name "Eagles"
   ```

   Optional: use a custom Motion title template for styling:

   ```bash
   courtstats process game-export.fcpxml -o game-with-overlays.fcpxml \
     --title-template "CourtStats Score Ticker"
   ```

   The default template is "Basic Title" (Apple's built-in). If you
   create a custom template in Motion with your preferred font, size,
   colour, and animation, pass its name here. The processor sets only
   the text content — all visual styling comes from the template.

6. **Import the result**: In Final Cut Pro, File → Import → XML.
   Score ticker titles appear on lane 99 of your timeline.

7. **Re-process anytime**: The processor is idempotent. Running it
   again on the output replaces all generated overlays cleanly.

## Check for Errors

If the processor exits with code 2, some markers had issues.
Look at the stderr output for details, then search for
`[CS:INVALID]` or `[CS:WARN]` in FCP's Timeline Index to find
the problematic markers.

## Install from GitHub Release

Download the latest universal binary from
[GitHub Releases](https://github.com/tallpsmith/CourtStats/releases):

```bash
curl -L -o courtstats \
  https://github.com/tallpsmith/CourtStats/releases/latest/download/courtstats-macos
chmod +x courtstats
./courtstats process game.fcpxml -o game-processed.fcpxml
```
