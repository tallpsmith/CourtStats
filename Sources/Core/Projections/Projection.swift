/// A projection consumes GameEvents to build a read model.
/// Each projection is independent and maintains its own state.
public protocol Projection: AnyObject {
    /// Process a single game event.
    func handle(_ event: GameEvent)

    /// Reset all state for a fresh processing run.
    func reset()
}
