import Foundation

/// A point-in-time capture of the score after a scoring event.
public struct ScoreSnapshot: Equatable, Sendable {
    public let timecode: TimeInterval
    public let homeScore: Int
    public let opponentScore: Int

    public init(timecode: TimeInterval, homeScore: Int, opponentScore: Int) {
        self.timecode = timecode
        self.homeScore = homeScore
        self.opponentScore = opponentScore
    }
}
