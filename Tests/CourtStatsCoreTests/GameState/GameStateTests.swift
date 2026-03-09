import XCTest
@testable import CourtStatsCore

final class GameStateTests: XCTestCase {

    // MARK: - Initial state

    func testInitialScoresAreZero() {
        let state = GameState()
        XCTAssertEqual(state.homeScore, 0)
        XCTAssertEqual(state.opponentScore, 0)
    }

    func testInitialOnCourtSetsAreEmpty() {
        let state = GameState()
        XCTAssertTrue(state.homeOnCourt.isEmpty)
        XCTAssertTrue(state.opponentOnCourt.isEmpty)
    }

    // MARK: - Scoring events update score

    func testApplyHomeScoringEventUpdatesHomeScore() {
        var state = GameState()
        let event = GameEvent(team: .home, playerNumber: 7, statType: .fieldGoal2pt, timecode: 90.0, markerIndex: 0)
        state.apply(event)
        XCTAssertEqual(state.homeScore, 2)
        XCTAssertEqual(state.opponentScore, 0)
    }

    func testApplyOpponentScoringEventUpdatesOpponentScore() {
        var state = GameState()
        let event = GameEvent(team: .opponent, playerNumber: 12, statType: .fieldGoal3pt, timecode: 120.0, markerIndex: 0)
        state.apply(event)
        XCTAssertEqual(state.homeScore, 0)
        XCTAssertEqual(state.opponentScore, 3)
    }

    func testApplyMultipleScoringEventsAccumulates() {
        var state = GameState()
        state.apply(GameEvent(team: .home, playerNumber: 7, statType: .fieldGoal2pt, timecode: 90.0, markerIndex: 0))
        state.apply(GameEvent(team: .opponent, playerNumber: 12, statType: .fieldGoal3pt, timecode: 120.0, markerIndex: 1))
        state.apply(GameEvent(team: .home, playerNumber: 5, statType: .freeThrow, timecode: 150.0, markerIndex: 2))
        XCTAssertEqual(state.homeScore, 3)
        XCTAssertEqual(state.opponentScore, 3)
    }

    func testApplyMissedShotDoesNotChangeScore() {
        var state = GameState()
        state.apply(GameEvent(team: .home, playerNumber: 7, statType: .missedFieldGoal2, timecode: 90.0, markerIndex: 0))
        XCTAssertEqual(state.homeScore, 0)
        XCTAssertEqual(state.opponentScore, 0)
    }

    // MARK: - Substitution events update on-court sets

    func testApplySubOnAddsPlayerToOnCourt() {
        var state = GameState()
        state.apply(GameEvent(team: .home, playerNumber: 7, statType: .substitutionOn, timecode: 90.0, markerIndex: 0))
        XCTAssertTrue(state.homeOnCourt.contains(7))
    }

    func testApplySubOffRemovesPlayerFromOnCourt() {
        var state = GameState()
        state.apply(GameEvent(team: .home, playerNumber: 7, statType: .substitutionOn, timecode: 90.0, markerIndex: 0))
        state.apply(GameEvent(team: .home, playerNumber: 7, statType: .substitutionOff, timecode: 300.0, markerIndex: 1))
        XCTAssertFalse(state.homeOnCourt.contains(7))
    }

    func testSubstitutionAffectsCorrectTeam() {
        var state = GameState()
        state.apply(GameEvent(team: .home, playerNumber: 7, statType: .substitutionOn, timecode: 90.0, markerIndex: 0))
        state.apply(GameEvent(team: .opponent, playerNumber: 7, statType: .substitutionOn, timecode: 90.0, markerIndex: 1))
        XCTAssertTrue(state.homeOnCourt.contains(7))
        XCTAssertTrue(state.opponentOnCourt.contains(7))
    }

    // MARK: - Player stats

    func testApplyEventUpdatesPlayerStats() {
        var state = GameState()
        state.apply(GameEvent(team: .home, playerNumber: 7, statType: .fieldGoal2pt, timecode: 90.0, markerIndex: 0))
        state.apply(GameEvent(team: .home, playerNumber: 7, statType: .rebound, timecode: 95.0, markerIndex: 1))

        let key = PlayerKey(team: .home, playerNumber: 7)
        let stats = state.playerStats[key]
        XCTAssertNotNil(stats)
        XCTAssertEqual(stats?.statCounts[.fieldGoal2pt], 1)
        XCTAssertEqual(stats?.statCounts[.rebound], 1)
    }
}
