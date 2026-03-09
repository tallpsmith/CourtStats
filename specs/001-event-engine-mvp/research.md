# Research: CourtStats Event Engine MVP

**Branch**: `001-event-engine-mvp` | **Date**: 2026-03-08

## FCPXML Structure & Parsing

### Decision: Use Foundation XMLDocument for FCPXML parsing

**Rationale**: FCPXML is well-structured XML with a published DTD.
Foundation's `XMLDocument` (tree-based) is the right fit because we
need to read markers, modify/add title elements, and write back the
full document. SAX-style parsing would be awkward for round-trip
modification. No third-party XML dependency needed.

**Alternatives considered**:
- Pipeline Neo (Swift 6 FCPXML framework) — too heavy for our needs,
  adds dependency risk, and we only need marker extraction + title
  insertion, not full FCPXML modelling.
- swift-daw-file-tools — read-only, doesn't support writing back.
- Python xml.etree — product spec mentions this as an option but
  Swift keeps the project single-language for Phase 2+ integration.

### FCPXML Marker Structure

Markers are child elements of clip containers (`asset-clip`, `clip`,
etc.) within a `spine`:

```xml
<fcpxml version="1.11">
  <resources>
    <effect id="r2" name="Basic Title"
      uid=".../Titles.localized/Bumper:Opener.localized/Basic Title.localized/Basic Title.moti"/>
  </resources>
  <library>
    <event>
      <project>
        <sequence>
          <spine>
            <asset-clip ref="r1" offset="0s" duration="3600s">
              <marker start="90s" duration="1s" value="CS:T:7:PTS2"/>
              <marker start="165s" duration="1s" value="CS:O:12:PTS3"/>
            </asset-clip>
          </spine>
        </sequence>
      </project>
    </event>
  </library>
</fcpxml>
```

Key attributes:
- `start` — rational time format (e.g., `90s`, `43703/29s`)
- `duration` — always present, typically `1s` for point markers
- `value` — the marker text (this is where `CS:T:7:PTS2` lives)

### FCPXML Timecode Format

All timing uses **rational time**: `numerator/denominators` where
the unit is seconds. Examples:
- `15s` — 15 seconds
- `1001/30000s` — one frame at 29.97 fps
- `3600/1s` — one hour

Parsing strategy: extract numerator and denominator, compute
`TimeInterval` as `Double(numerator) / Double(denominator)`.

### Basic Title Element Structure

Generated score ticker titles will look like:

```xml
<title ref="r2" name="[CS] Score" offset="90s" duration="75s" lane="99">
  <text>
    <text-style ref="ts1">Wildcats 2 — Eagles 0</text-style>
  </text>
</title>
```

- `ref` references the title template effect in `<resources>`
- `lane="99"` places it on our dedicated lane
- `name` prefix `[CS]` identifies generated titles for replacement
- Title is a child of `<spine>` as a connected element

### Design Decision: Template-Driven Titles

The processor sets **text content only** — no inline styling
(font, size, colour, position). All visual presentation is owned
by the referenced Motion title template.

**Rationale**: Separation of concerns. The processor owns the data
(what the score is), the template owns the presentation (what it
looks like). Users can customise appearance by creating a custom
Motion template without re-processing. This also simplifies the
renderer (fewer FCPXML params to generate) and makes idempotency
comparisons cleaner.

**Default**: "Basic Title" (Apple built-in, always available).
**Override**: `--title-template "Custom Template Name"` CLI flag.

The `<effect>` resource in `<resources>` references the template
by name. If the template doesn't exist on the user's machine, FCP
handles the fallback gracefully (renders with default styling).

### DTD Validation

Apple publishes DTD files per FCPXML version. CommandPost repo
bundles them. Validation command:

```bash
xmllint --noout --dtdvalid FCPXMLv1_11.dtd output.fcpxml
```

The DTD file should be bundled in the test fixtures directory.

## Swift CLI Tool Architecture

### Decision: Swift 5.9+ with ArgumentParser, SPM executable + library

**Rationale**: Swift is the natural choice for a tool that will
integrate into a Final Cut Pro Workflow Extension in Phase 2.
ArgumentParser provides built-in subcommand support, `--version`,
and `--help` for free. Separating core logic into a library target
enables reuse in the Workflow Extension without code duplication.

**Alternatives considered**:
- Python CLI — faster prototyping but creates a language boundary
  for Phase 2 integration. Product spec mentions this as an option
  but recommends Swift for the long game.
- Rust CLI — great performance but no path to Workflow Extension
  integration.

### Package.swift Structure

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CourtStats",
    platforms: [.macOS(.v15)],
    products: [
        .executable(name: "courtstats", targets: ["CourtStatsCLI"]),
        .library(name: "CourtStatsCore", targets: ["CourtStatsCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git",
                 from: "1.3.0")
    ],
    targets: [
        .target(name: "CourtStatsCore", path: "Sources/Core"),
        .executableTarget(
            name: "CourtStatsCLI",
            dependencies: [
                "CourtStatsCore",
                .product(name: "ArgumentParser",
                         package: "swift-argument-parser")
            ],
            path: "Sources/CLI"
        ),
        .testTarget(name: "CourtStatsCoreTests",
                     dependencies: ["CourtStatsCore"],
                     path: "Tests/CourtStatsCoreTests"),
        .testTarget(name: "IntegrationTests",
                     dependencies: ["CourtStatsCore"],
                     path: "Tests/IntegrationTests",
                     resources: [.copy("Fixtures")])
    ]
)
```

### macOS Version Target

macOS 15 (Sequoia) minimum. Final Cut Pro dictates the floor — even
though Phase 1 is CLI-only, there's no value supporting a macOS
version that can't run FCP when Phases 2-3 integrate directly.
This also gives us the latest Foundation APIs and Swift concurrency
features.

## GitHub Actions CI/CD

### Decision: macOS runners, full test suite on PR, tagged release workflow

**Rationale**: macOS runner is required for `xmllint` DTD validation
and matches the target platform. `swift test` runs natively.
Universal binary build uses `swift build -c release --arch x86_64
--arch arm64`.

### PR Test Workflow

```yaml
name: Tests
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - run: swift test -v
```

### Release Workflow

```yaml
name: Release
on:
  push:
    tags: ['v*']
jobs:
  build:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - run: swift build -c release --arch x86_64 --arch arm64
      - run: |
          BUILD_PATH=$(swift build -c release --arch x86_64 \
            --arch arm64 --show-bin-path)
          cp "$BUILD_PATH/courtstats" courtstats-macos
      - uses: softprops/action-gh-release@v2
        with:
          files: courtstats-macos
```

## Sources

- Apple FCPXML Reference Documentation
- Apple Developer: Building a Workflow Extension
- FCP Cafe: Demystifying Final Cut Pro XMLs
- FCP Cafe: FCPXML Developer Reference
- CommandPost FCPXML DTD files (GitHub)
- Apple swift-argument-parser repository
- GitHub Docs: Building and Testing Swift
- SwiftToolkit: Releasing Swift Binaries with GitHub Actions
