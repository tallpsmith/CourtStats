import Foundation

/// Tracks which players are on court via SUBON/SUBOFF events.
/// Generates warnings for logical inconsistencies like duplicate SUBON or orphaned SUBOFF.
public final class SubstitutionProjection: Projection {

    public struct Warning: Equatable, Sendable {
        public let markerIndex: Int
        public let message: String
    }

    public private(set) var homeOnCourt: Set<Int> = []
    public private(set) var opponentOnCourt: Set<Int> = []
    public private(set) var warnings: [Warning] = []

    private var homeSubOnTimecodes: [Int: TimeInterval] = [:]
    private var opponentSubOnTimecodes: [Int: TimeInterval] = [:]

    public init() {}

    public func handle(_ event: GameEvent) {
        guard event.statType.isSubstitution else { return }

        switch (event.team, event.statType) {
        case (.home, .substitutionOn):
            handleSubOn(player: event.playerNumber, onCourt: &homeOnCourt,
                        timecodes: &homeSubOnTimecodes, event: event)
        case (.home, .substitutionOff):
            handleSubOff(player: event.playerNumber, onCourt: &homeOnCourt,
                         timecodes: &homeSubOnTimecodes, event: event)
        case (.opponent, .substitutionOn):
            handleSubOn(player: event.playerNumber, onCourt: &opponentOnCourt,
                        timecodes: &opponentSubOnTimecodes, event: event)
        case (.opponent, .substitutionOff):
            handleSubOff(player: event.playerNumber, onCourt: &opponentOnCourt,
                         timecodes: &opponentSubOnTimecodes, event: event)
        default:
            break
        }
    }

    /// Auto-close all open stints at end of processing.
    public func finalise(atTimecode endTimecode: TimeInterval) {
        homeOnCourt.removeAll()
        opponentOnCourt.removeAll()
        homeSubOnTimecodes.removeAll()
        opponentSubOnTimecodes.removeAll()
    }

    public func reset() {
        homeOnCourt.removeAll()
        opponentOnCourt.removeAll()
        warnings.removeAll()
        homeSubOnTimecodes.removeAll()
        opponentSubOnTimecodes.removeAll()
    }

    private func handleSubOn(player: Int, onCourt: inout Set<Int>,
                              timecodes: inout [Int: TimeInterval], event: GameEvent) {
        if onCourt.contains(player) {
            warnings.append(Warning(
                markerIndex: event.markerIndex,
                message: "Player \(player) already on court"
            ))
        }
        onCourt.insert(player)
        timecodes[player] = event.timecode
    }

    private func handleSubOff(player: Int, onCourt: inout Set<Int>,
                               timecodes: inout [Int: TimeInterval], event: GameEvent) {
        if !onCourt.contains(player) {
            warnings.append(Warning(
                markerIndex: event.markerIndex,
                message: "Player \(player) not on court"
            ))
        }
        onCourt.remove(player)
        timecodes.removeValue(forKey: player)
    }
}
