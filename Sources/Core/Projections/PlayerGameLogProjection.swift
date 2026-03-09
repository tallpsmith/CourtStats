import Foundation

/// Maintains a chronological game log of all events per player.
public final class PlayerGameLogProjection: Projection {

    private var logs: [PlayerKey: [GameEvent]] = [:]

    public init() {}

    public func handle(_ event: GameEvent) {
        let key = PlayerKey(team: event.team, playerNumber: event.playerNumber)
        logs[key, default: []].append(event)
    }

    /// Get the chronological event log for a specific player.
    public func log(for key: PlayerKey) -> [GameEvent] {
        logs[key] ?? []
    }

    public func reset() {
        logs.removeAll()
    }
}
