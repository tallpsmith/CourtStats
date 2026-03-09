import Foundation

/// Composite key to uniquely identify a player across teams.
public struct PlayerKey: Hashable, Sendable {
    public let team: Team
    public let playerNumber: Int

    public init(team: Team, playerNumber: Int) {
        self.team = team
        self.playerNumber = playerNumber
    }
}

/// Per-player cumulative stat totals.
public struct PlayerStatLine: Equatable, Sendable {
    public var statCounts: [StatType: Int] = [:]

    public init() {}

    public mutating func record(_ statType: StatType) {
        statCounts[statType, default: 0] += 1
    }
}

/// Cumulative running game state, updated after each GameEvent.
public struct GameState: Sendable {
    public var homeScore: Int = 0
    public var opponentScore: Int = 0
    public var playerStats: [PlayerKey: PlayerStatLine] = [:]
    public var homeOnCourt: Set<Int> = []
    public var opponentOnCourt: Set<Int> = []

    public init() {}

    /// Apply a game event to update running state.
    public mutating func apply(_ event: GameEvent) {
        applyScore(event)
        applySubstitution(event)
        recordPlayerStat(event)
    }

    private mutating func applyScore(_ event: GameEvent) {
        let points = event.pointsValue
        guard points > 0 else { return }

        switch event.team {
        case .home: homeScore += points
        case .opponent: opponentScore += points
        }
    }

    private mutating func applySubstitution(_ event: GameEvent) {
        guard event.statType.isSubstitution else { return }

        switch (event.team, event.statType) {
        case (.home, .substitutionOn):
            homeOnCourt.insert(event.playerNumber)
        case (.home, .substitutionOff):
            homeOnCourt.remove(event.playerNumber)
        case (.opponent, .substitutionOn):
            opponentOnCourt.insert(event.playerNumber)
        case (.opponent, .substitutionOff):
            opponentOnCourt.remove(event.playerNumber)
        default:
            break
        }
    }

    private mutating func recordPlayerStat(_ event: GameEvent) {
        let key = PlayerKey(team: event.team, playerNumber: event.playerNumber)
        playerStats[key, default: PlayerStatLine()].record(event.statType)
    }
}
