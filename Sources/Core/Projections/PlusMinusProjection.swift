import Foundation

/// Calculates cumulative +/- for each player based on scoring events
/// that occur while they are on court.
public final class PlusMinusProjection: Projection {

    private let substitutionProjection: SubstitutionProjection
    private var ratings: [PlayerKey: Int] = [:]

    public init(substitutionProjection: SubstitutionProjection) {
        self.substitutionProjection = substitutionProjection
    }

    public func handle(_ event: GameEvent) {
        guard event.statType.isScoring else { return }

        let points = event.pointsValue
        applyToOnCourtPlayers(team: .home, scoringTeam: event.team, points: points)
        applyToOnCourtPlayers(team: .opponent, scoringTeam: event.team, points: points)
    }

    /// Get the +/- rating for a specific player.
    public func plusMinus(for key: PlayerKey) -> Int {
        ratings[key] ?? 0
    }

    public func reset() {
        ratings.removeAll()
    }

    private func applyToOnCourtPlayers(team: Team, scoringTeam: Team, points: Int) {
        let onCourt = team == .home
            ? substitutionProjection.homeOnCourt
            : substitutionProjection.opponentOnCourt

        let delta = team == scoringTeam ? points : -points

        for playerNumber in onCourt {
            let key = PlayerKey(team: team, playerNumber: playerNumber)
            ratings[key, default: 0] += delta
        }
    }
}
