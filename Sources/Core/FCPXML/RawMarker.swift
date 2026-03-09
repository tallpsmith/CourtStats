import Foundation

/// A marker extracted from FCPXML before parsing into a GameEvent.
public struct RawMarker: Equatable, Sendable {
    public let value: String
    public let timecode: TimeInterval
    public let duration: TimeInterval
    public let markerIndex: Int
    public let clipOffset: TimeInterval

    public init(value: String, timecode: TimeInterval, duration: TimeInterval, markerIndex: Int, clipOffset: TimeInterval) {
        self.value = value
        self.timecode = timecode
        self.duration = duration
        self.markerIndex = markerIndex
        self.clipOffset = clipOffset
    }
}
