/// Identifies which team a stat event belongs to.
public enum Team: Equatable, Hashable, Sendable {
    case home
    case opponent

    /// Parse from FCPXML marker code: "T" → home, "O" → opponent.
    public init?(markerCode: String) {
        switch markerCode.uppercased() {
        case "T": self = .home
        case "O": self = .opponent
        default: return nil
        }
    }
}
