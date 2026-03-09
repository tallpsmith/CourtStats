/// All supported basketball stat codes.
public enum StatType: Equatable, Hashable, Sendable {
    // Scoring
    case fieldGoal2pt
    case fieldGoal3pt
    case freeThrow
    case missedFieldGoal2
    case missedFieldGoal3
    case missedFreeThrow

    // Box stats
    case rebound
    case offensiveRebound
    case assist
    case steal
    case block
    case turnover
    case personalFoul

    // Substitution
    case substitutionOn
    case substitutionOff

    /// Points scored for this stat type (0 for non-scoring and misses).
    public var pointsValue: Int {
        switch self {
        case .fieldGoal2pt: return 2
        case .fieldGoal3pt: return 3
        case .freeThrow: return 1
        default: return 0
        }
    }

    /// Whether this is a made scoring event (not misses).
    public var isScoring: Bool {
        switch self {
        case .fieldGoal2pt, .fieldGoal3pt, .freeThrow: return true
        default: return false
        }
    }

    /// Whether this is a substitution event.
    public var isSubstitution: Bool {
        switch self {
        case .substitutionOn, .substitutionOff: return true
        default: return false
        }
    }

    /// Parse from FCPXML marker code. Case-insensitive.
    public init?(markerCode: String) {
        switch markerCode.uppercased() {
        case "PTS2": self = .fieldGoal2pt
        case "PTS3": self = .fieldGoal3pt
        case "FT": self = .freeThrow
        case "PTS2X": self = .missedFieldGoal2
        case "PTS3X": self = .missedFieldGoal3
        case "FTX": self = .missedFreeThrow
        case "REB": self = .rebound
        case "OREB": self = .offensiveRebound
        case "AST": self = .assist
        case "STL": self = .steal
        case "BLK": self = .block
        case "TO": self = .turnover
        case "PF": self = .personalFoul
        case "SUBON": self = .substitutionOn
        case "SUBOFF": self = .substitutionOff
        default: return nil
        }
    }
}
