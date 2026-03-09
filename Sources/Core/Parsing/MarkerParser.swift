import Foundation

/// Parses FCPXML marker values in CS:TEAM:PLAYER#:STAT format into GameEvents.
public enum MarkerParser {

    public struct ParseResult: Sendable {
        public let event: GameEvent?
        public let annotation: MarkerAnnotation
    }

    /// Parse a raw marker value string into a GameEvent and annotation.
    ///
    /// Handles whitespace normalisation, case-insensitive matching,
    /// and stripping of existing [CS:INVALID] / [CS:WARN] annotations.
    public static func parse(markerValue: String, timecode: TimeInterval, markerIndex: Int) -> ParseResult {
        let cleaned = stripAnnotations(markerValue).trimmingCharacters(in: .whitespaces)

        guard isCSMarker(cleaned) else {
            return ParseResult(event: nil, annotation: .ignored)
        }

        let segments = cleaned.split(separator: ":", maxSplits: .max, omittingEmptySubsequences: false)
            .map(String.init)

        guard segments.count == 4 else {
            return ParseResult(event: nil, annotation: .invalid)
        }

        let teamCode = segments[1]
        let playerString = segments[2]
        let statCode = segments[3]

        guard let team = Team(markerCode: teamCode) else {
            return ParseResult(event: nil, annotation: .invalid)
        }

        guard let playerNumber = Int(playerString) else {
            return ParseResult(event: nil, annotation: .invalid)
        }

        guard let statType = StatType(markerCode: statCode) else {
            return ParseResult(event: nil, annotation: .invalid)
        }

        let event = GameEvent(
            team: team,
            playerNumber: playerNumber,
            statType: statType,
            timecode: timecode,
            markerIndex: markerIndex
        )
        return ParseResult(event: event, annotation: .valid)
    }

    /// Strip existing [CS:INVALID] and [CS:WARN] annotation suffixes.
    public static func stripAnnotations(_ value: String) -> String {
        var result = value
        result = result.replacingOccurrences(of: " [CS:INVALID]", with: "")
        result = result.replacingOccurrences(of: " [CS:WARN]", with: "")
        return result
    }

    private static func isCSMarker(_ cleaned: String) -> Bool {
        let upper = cleaned.uppercased()
        return upper.hasPrefix("CS:")
    }
}
