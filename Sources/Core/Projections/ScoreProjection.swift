import Foundation

/// Tracks running score and produces a snapshot after each scoring event.
public final class ScoreProjection: Projection {

    public private(set) var snapshots: [ScoreSnapshot] = []

    private var homeScore: Int = 0
    private var opponentScore: Int = 0

    public init() {}

    public func handle(_ event: GameEvent) {
        guard event.statType.isScoring else { return }

        updateScore(for: event)
        recordSnapshot(at: event.timecode)
    }

    public func reset() {
        snapshots = []
        homeScore = 0
        opponentScore = 0
    }

    // MARK: - Private

    private func updateScore(for event: GameEvent) {
        switch event.team {
        case .home:
            homeScore += event.pointsValue
        case .opponent:
            opponentScore += event.pointsValue
        }
    }

    private func recordSnapshot(at timecode: TimeInterval) {
        let snapshot = ScoreSnapshot(
            timecode: timecode,
            homeScore: homeScore,
            opponentScore: opponentScore
        )
        snapshots.append(snapshot)
    }
}
