import Foundation

/// The fundamental unit of data — an immutable stat event parsed from an FCPXML marker.
public struct GameEvent: Equatable, Sendable {
    public let team: Team
    public let playerNumber: Int
    public let statType: StatType
    public let timecode: TimeInterval
    public let markerIndex: Int

    /// Points scored, derived from statType.
    public var pointsValue: Int { statType.pointsValue }

    public init(team: Team, playerNumber: Int, statType: StatType, timecode: TimeInterval, markerIndex: Int) {
        self.team = team
        self.playerNumber = playerNumber
        self.statType = statType
        self.timecode = timecode
        self.markerIndex = markerIndex
    }
}
