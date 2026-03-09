import Foundation

/// Tracks playing time per player via SUBON/SUBOFF timecodes.
public final class MinutesPlayedProjection: Projection {

    public struct Stint: Equatable, Sendable {
        public let startTimecode: TimeInterval
        public let endTimecode: TimeInterval

        public var durationMinutes: Double {
            (endTimecode - startTimecode) / 60.0
        }
    }

    private var completedStints: [PlayerKey: [Stint]] = [:]
    private var openStintStarts: [PlayerKey: TimeInterval] = [:]

    public init() {}

    public func handle(_ event: GameEvent) {
        guard event.statType.isSubstitution else { return }
        let key = PlayerKey(team: event.team, playerNumber: event.playerNumber)

        switch event.statType {
        case .substitutionOn:
            openStintStarts[key] = event.timecode
        case .substitutionOff:
            closeStint(for: key, atTimecode: event.timecode)
        default:
            break
        }
    }

    /// Auto-close all open stints at the end of processing.
    public func finalise(atTimecode endTimecode: TimeInterval) {
        for (key, _) in openStintStarts {
            closeStint(for: key, atTimecode: endTimecode)
        }
    }

    /// Total minutes played for a given player.
    public func minutesPlayed(for key: PlayerKey) -> Double {
        guard let stints = completedStints[key] else { return 0.0 }
        return stints.reduce(0.0) { $0 + $1.durationMinutes }
    }

    /// All completed stints for a given player.
    public func stints(for key: PlayerKey) -> [Stint] {
        completedStints[key] ?? []
    }

    public func reset() {
        completedStints.removeAll()
        openStintStarts.removeAll()
    }

    private func closeStint(for key: PlayerKey, atTimecode endTimecode: TimeInterval) {
        guard let start = openStintStarts.removeValue(forKey: key) else { return }
        let stint = Stint(startTimecode: start, endTimecode: endTimecode)
        completedStints[key, default: []].append(stint)
    }
}
