# CLI Contract: courtstats

**Version**: 0.1.0 (initial MVP)

## Executable

Name: `courtstats`

## Subcommands

### `courtstats process`

Process an FCPXML file: parse stat markers, compute projections,
generate score ticker overlays, write output.

**Arguments**:

| Argument       | Type   | Required | Description                    |
|----------------|--------|----------|--------------------------------|
| `<input>`      | Path   | Yes      | Input FCPXML file path         |
| `-o, --output` | Path   | Yes      | Output FCPXML file path        |
| `--home-name`  | String | No       | Home team name (default: "Home")|
| `--away-name`  | String | No       | Away team name (default: "Away")|
| `--title-template` | String | No  | Motion title template name (default: "Basic Title")|

**Exit Codes**:

| Code | Meaning                                              |
|------|------------------------------------------------------|
| 0    | Success — output produced, no validation issues      |
| 1    | Input error — file unreadable or not valid FCPXML    |
| 2    | Success with warnings — output produced, but markers |
|      | annotated with `[CS:INVALID]` or `[CS:WARN]`        |

**Stderr Output**:

On success (exit 0):
```
Processing: input.fcpxml
Parsed 47 markers (42 valid, 5 non-CS ignored)
Generated 18 score ticker overlays
Output written to: output.fcpxml
```

On success with warnings (exit 2):
```
Processing: input.fcpxml
Parsed 47 markers (38 valid, 3 invalid, 1 warning, 5 non-CS ignored)
  WARNING: Marker at 01:23:45 — CS:T:7 — invalid segment count
  WARNING: Marker at 02:10:30 — CS:X:7:PTS2 — invalid team code
  WARNING: Marker at 03:15:00 — CS:T:7:SUBON — player already on court
Generated 16 score ticker overlays
Output written to: output.fcpxml
```

On input error (exit 1):
```
Error: Cannot read file 'missing.fcpxml': No such file or directory
```
```
Error: File 'notes.txt' is not valid FCPXML
```

### `courtstats version`

Print version and exit.

**Output** (stdout):
```
courtstats 0.1.0
```

### `courtstats --version`

Built-in ArgumentParser flag. Same as `courtstats version`.

### `courtstats --help`

Built-in ArgumentParser help. Lists available subcommands.

## FCPXML I/O Contract

### Input

- FCPXML version 1.9+ (single `.fcpxml` file format)
- Must contain a valid `<fcpxml>` root element
- Markers are `<marker>` elements within clip containers
- Only markers with `value` starting with `CS:` are processed
- All other content passes through unmodified

### Output

- Valid FCPXML that passes Apple DTD validation
- All original content preserved (markers, clips, titles, etc.)
- CS markers may have annotations appended: `[CS:INVALID]`, `[CS:WARN]`
- Existing annotations stripped before re-parsing
- Score ticker titles added on lane 99 with name prefix `[CS]`
- Title elements reference a named Motion title template (default:
  "Basic Title", overridable via `--title-template`)
- Processor sets text content only — visual styling (font, size,
  colour, position, animation) is owned by the referenced template
- Previously generated `[CS]` titles on lane 99 fully replaced
- Title template effect resource added to `<resources>` if not present

### Idempotency Contract

```
process(input) = output₁
process(output₁) = output₂
normalize(output₁) == normalize(output₂)  // MUST be true
```

Where `normalize` means: sort XML attributes, normalise whitespace.
