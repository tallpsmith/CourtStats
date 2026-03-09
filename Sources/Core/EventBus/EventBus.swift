/// Dispatches GameEvents to registered projections in order.
public final class EventBus {
    private let projections: [Projection]

    public init(projections: [Projection]) {
        self.projections = projections
    }

    /// Dispatch a single event to all registered projections.
    public func dispatch(_ event: GameEvent) {
        for projection in projections {
            projection.handle(event)
        }
    }

    /// Dispatch a sequence of events in order.
    public func dispatchAll(_ events: [GameEvent]) {
        for event in events {
            dispatch(event)
        }
    }

    /// Reset all projections for a fresh run.
    public func resetAll() {
        for projection in projections {
            projection.reset()
        }
    }
}
