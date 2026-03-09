/// Validation result for a parsed marker.
public enum MarkerAnnotation: Equatable, Sendable {
    /// Marker parsed successfully into a GameEvent.
    case valid
    /// Marker has structural errors (bad syntax).
    case invalid
    /// Marker parsed but has a logical inconsistency.
    case warn
    /// Not a CS marker — left untouched.
    case ignored
}
