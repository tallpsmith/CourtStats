import XCTest
@testable import CourtStatsCore

final class MinutesPlayedProjectionTests: XCTestCase {

    private func makeEvent(
        team: Team = .home,
        player: Int = 7,
        stat: StatType = .substitutionOn,
        timecode: TimeInterval = 0,
        index: Int = 0
    ) -> GameEvent {
        GameEvent(team: team, playerNumber: player, statType: stat, timecode: timecode, markerIndex: index)
    }

    // MARK: - Single stint

    func testSingleCompletedStint() {
        let projection = MinutesPlayedProjection()
        projection.handle(makeEvent(player: 7, stat: .substitutionOn, timecode: 60, index: 0))
        projection.handle(makeEvent(player: 7, stat: .substitutionOff, timecode: 660, index: 1))

        let minutes = projection.minutesPlayed(for: PlayerKey(team: .home, playerNumber: 7))
        XCTAssertEqual(minutes, 10.0, accuracy: 0.01)
    }

    // MARK: - Multiple stints

    func testMultipleStintsAccumulate() {
        let projection = MinutesPlayedProjection()
        projection.handle(makeEvent(player: 7, stat: .substitutionOn, timecode: 0, index: 0))
        projection.handle(makeEvent(player: 7, stat: .substitutionOff, timecode: 300, index: 1))
        projection.handle(makeEvent(player: 7, stat: .substitutionOn, timecode: 600, index: 2))
        projection.handle(makeEvent(player: 7, stat: .substitutionOff, timecode: 900, index: 3))

        let minutes = projection.minutesPlayed(for: PlayerKey(team: .home, playerNumber: 7))
        XCTAssertEqual(minutes, 10.0, accuracy: 0.01)
    }

    // MARK: - Auto-close at finalise

    func testAutoCloseOpenStintAtFinalise() {
        let projection = MinutesPlayedProjection()
        projection.handle(makeEvent(player: 7, stat: .substitutionOn, timecode: 0, index: 0))
        projection.finalise(atTimecode: 600)

        let minutes = projection.minutesPlayed(for: PlayerKey(team: .home, playerNumber: 7))
        XCTAssertEqual(minutes, 10.0, accuracy: 0.01)
    }

    // MARK: - Player with no stints

    func testPlayerWithNoStintsReturnsZero() {
        let projection = MinutesPlayedProjection()
        let minutes = projection.minutesPlayed(for: PlayerKey(team: .home, playerNumber: 99))
        XCTAssertEqual(minutes, 0.0)
    }

    // MARK: - Non-substitution events ignored

    func testNonSubstitutionEventsIgnored() {
        let projection = MinutesPlayedProjection()
        projection.handle(makeEvent(player: 7, stat: .fieldGoal2pt, timecode: 100, index: 0))
        let minutes = projection.minutesPlayed(for: PlayerKey(team: .home, playerNumber: 7))
        XCTAssertEqual(minutes, 0.0)
    }

    // MARK: - Multiple players independent

    func testMultiplePlayersTrackedIndependently() {
        let projection = MinutesPlayedProjection()
        projection.handle(makeEvent(player: 7, stat: .substitutionOn, timecode: 0, index: 0))
        projection.handle(makeEvent(player: 11, stat: .substitutionOn, timecode: 120, index: 1))
        projection.handle(makeEvent(player: 7, stat: .substitutionOff, timecode: 600, index: 2))
        projection.handle(makeEvent(player: 11, stat: .substitutionOff, timecode: 600, index: 3))

        let minutes7 = projection.minutesPlayed(for: PlayerKey(team: .home, playerNumber: 7))
        let minutes11 = projection.minutesPlayed(for: PlayerKey(team: .home, playerNumber: 11))
        XCTAssertEqual(minutes7, 10.0, accuracy: 0.01)
        XCTAssertEqual(minutes11, 8.0, accuracy: 0.01)
    }

    // MARK: - Stints list

    func testStintsListReturnsAllStints() {
        let projection = MinutesPlayedProjection()
        projection.handle(makeEvent(player: 7, stat: .substitutionOn, timecode: 0, index: 0))
        projection.handle(makeEvent(player: 7, stat: .substitutionOff, timecode: 300, index: 1))
        projection.handle(makeEvent(player: 7, stat: .substitutionOn, timecode: 600, index: 2))
        projection.handle(makeEvent(player: 7, stat: .substitutionOff, timecode: 900, index: 3))

        let stints = projection.stints(for: PlayerKey(team: .home, playerNumber: 7))
        XCTAssertEqual(stints.count, 2)
        XCTAssertEqual(stints[0].startTimecode, 0)
        XCTAssertEqual(stints[0].endTimecode, 300)
        XCTAssertEqual(stints[1].startTimecode, 600)
        XCTAssertEqual(stints[1].endTimecode, 900)
    }

    // MARK: - Reset

    func testResetClearsAllState() {
        let projection = MinutesPlayedProjection()
        projection.handle(makeEvent(player: 7, stat: .substitutionOn, timecode: 0, index: 0))
        projection.handle(makeEvent(player: 7, stat: .substitutionOff, timecode: 300, index: 1))
        projection.reset()
        let minutes = projection.minutesPlayed(for: PlayerKey(team: .home, playerNumber: 7))
        XCTAssertEqual(minutes, 0.0)
    }
}
