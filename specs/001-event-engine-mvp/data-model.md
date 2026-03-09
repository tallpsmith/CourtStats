# Data Model: CourtStats Event Engine MVP

**Branch**: `001-event-engine-mvp` | **Date**: 2026-03-08

## Core Types

### Team

Identifies which team a stat event belongs to.

- Values: `home`, `opponent`
- Parsed from marker codes: `T` → home, `O` → opponent
- Case-insensitive matching

### StatType

Enumeration of all supported basketball stat codes.

| Code    | StatType          | Points | Category     |
|---------|-------------------|--------|--------------|
| PTS2    | fieldGoal2pt      | 2      | scoring      |
| PTS3    | fieldGoal3pt      | 3      | scoring      |
| FT      | freeThrow         | 1      | scoring      |
| PTS2X   | missedFieldGoal2  | 0      | scoring      |
| PTS3X   | missedFieldGoal3  | 0      | scoring      |
| FTX     | missedFreeThrow   | 0      | scoring      |
| REB     | rebound           | 0      | box stat     |
| OREB    | offensiveRebound  | 0      | box stat     |
| AST     | assist            | 0      | box stat     |
| STL     | steal             | 0      | box stat     |
| BLK     | block             | 0      | box stat     |
| TO      | turnover          | 0      | box stat     |
| PF      | personalFoul      | 0      | box stat     |
| SUBON   | substitutionOn    | 0      | substitution |
| SUBOFF  | substitutionOff   | 0      | substitution |

Properties:
- `pointsValue: Int` — points scored (0 for non-scoring events)
- `isScoring: Bool` — true for PTS2, PTS3, FT (not misses)
- `isSubstitution: Bool` — true for SUBON, SUBOFF

### GameEvent

The fundamental unit of data in the system. Immutable value type.

| Field        | Type        | Description                          |
|--------------|-------------|--------------------------------------|
| team         | Team        | Which team this event belongs to     |
| playerNumber | Int         | Jersey number of the player          |
| statType     | StatType    | What happened                        |
| pointsValue  | Int         | Points scored (derived from statType)|
| timecode     | TimeInterval| Source timecode in seconds           |
| markerIndex  | Int         | Position in original marker sequence |

Identity: Events are identified by markerIndex (their position in
the source FCPXML). No two events share the same markerIndex.

Ordering: Events are processed in markerIndex order, which
corresponds to their timeline position.

### GameState

Cumulative running state, updated after each GameEvent. Mutable.

| Field           | Type                       | Description                    |
|-----------------|----------------------------|--------------------------------|
| homeScore       | Int                        | Running home team score        |
| opponentScore   | Int                        | Running opponent score         |
| playerStats     | [PlayerKey: PlayerStatLine]| Per-player cumulative stats    |
| homeOnCourt     | Set\<Int\>                 | Home player numbers on court   |
| opponentOnCourt | Set\<Int\>                 | Opponent player numbers on court|

**PlayerKey**: Composite of (Team, playerNumber) to uniquely
identify a player across teams (player 7 on home is different from
player 7 on opponent).

**PlayerStatLine**: Per-player cumulative totals for all stat types.

### MarkerAnnotation

Represents the validation result for a parsed marker.

| Value   | Meaning                                        |
|---------|------------------------------------------------|
| valid   | Marker parsed successfully into a GameEvent    |
| invalid | Marker has structural errors (bad syntax)      |
| warn    | Marker parsed but has logical inconsistency    |
| ignored | Not a CS marker — left untouched               |

## Projection Read Models

Each projection produces its own read model, independent of other
projections.

### ScoreSnapshot (ScoreProjection output)

| Field         | Type         | Description                     |
|---------------|--------------|---------------------------------|
| timecode      | TimeInterval | When this score state begins    |
| homeScore     | Int          | Home score at this point        |
| opponentScore | Int          | Opponent score at this point    |

Output: `[ScoreSnapshot]` — chronological list, one entry per
scoring event.

### SubstitutionState (SubstitutionProjection output)

| Field        | Type        | Description                      |
|--------------|-------------|----------------------------------|
| homeOnCourt  | Set\<Int\>  | Home players currently on court  |
| oppOnCourt   | Set\<Int\>  | Opponent players on court        |
| warnings     | [Warning]   | Logical inconsistencies found    |

Warning contains: markerIndex, message (e.g., "Player 7 already
on court").

### PlayerMinutes (MinutesPlayedProjection output)

| Field         | Type         | Description                    |
|---------------|--------------|--------------------------------|
| team          | Team         | Which team                     |
| playerNumber  | Int          | Jersey number                  |
| minutesPlayed | Double       | Total on-court minutes         |
| stints        | [Stint]      | Individual on/off intervals    |

Stint: (startTimecode: TimeInterval, endTimecode: TimeInterval)

### PlayerPlusMinus (PlusMinusProjection output)

| Field         | Type | Description                         |
|---------------|------|-------------------------------------|
| team          | Team | Which team                          |
| playerNumber  | Int  | Jersey number                       |
| plusMinus     | Int  | Cumulative +/− rating               |

### PlayerLog (PlayerGameLogProjection output)

| Field        | Type         | Description                     |
|--------------|--------------|---------------------------------|
| team         | Team         | Which team                      |
| playerNumber | Int          | Jersey number                   |
| events       | [GameEvent]  | Chronological event history     |

## State Transitions

### GameEvent Processing Flow

```
FCPXML Input
  → MarkerParser.parse(markerValue) → GameEvent? + MarkerAnnotation
  → EventBus.dispatch(event) → each registered Projection.handle(event)
  → GameState.apply(event) — cumulative update
```

### Substitution State Machine (per player)

```
[Off Court] --SUBON--> [On Court]
[On Court]  --SUBOFF-> [Off Court]
[On Court]  --SUBON--> [On Court] + WARN (duplicate)
[Off Court] --SUBOFF-> [Off Court] + WARN (orphaned)
[On Court]  --finalise-> [Off Court] (auto-close open stint)
```

### Score State Machine

```
[Score(h, o)] --PTS2(home)--> [Score(h+2, o)]
[Score(h, o)] --PTS3(home)--> [Score(h+3, o)]
[Score(h, o)] --FT(home)----> [Score(h+1, o)]
[Score(h, o)] --PTS2X-------> [Score(h, o)]  (no change)
[Score(h, o)] --PTS2(opp)---> [Score(h, o+2)]
```

## Relationships

```
GameEvent ←──parses── MarkerParser ←──reads── FCPXML Marker
    │
    ├──dispatched to── EventBus
    │                    │
    │                    ├── ScoreProjection ──→ [ScoreSnapshot]
    │                    ├── SubstitutionProjection ──→ SubstitutionState
    │                    ├── MinutesPlayedProjection ──→ [PlayerMinutes]
    │                    ├── PlusMinusProjection ──→ [PlayerPlusMinus]
    │                    └── PlayerGameLogProjection ──→ [PlayerLog]
    │
    └──updates── GameState (cumulative)

[ScoreSnapshot] ──→ ScoreTickerRenderer ──→ FCPXML Title Elements
                                            │
                                            └── references named Motion
                                                template (text only,
                                                styling from template)
```
