import XCTest
@testable import CourtStatsCore

final class PlayerGameLogProjectionTests: XCTestCase {

    private func makeEvent(
        team: Team = .home,
        player: Int = 7,
        stat: StatType = .fieldGoal2pt,
        timecode: TimeInterval = 0,
        index: Int = 0
    ) -> GameEvent {
        GameEvent(team: team, playerNumber: player, statType: stat, timecode: timecode, markerIndex: index)
    }

    // MARK: - Events recorded per player

    func testEventsRecordedForPlayer() {
        let projection = PlayerGameLogProjection()
        let event = makeEvent(player: 7, stat: .fieldGoal2pt, timecode: 100, index: 0)
        projection.handle(event)

        let log = projection.log(for: PlayerKey(team: .home, playerNumber: 7))
        XCTAssertEqual(log.count, 1)
        XCTAssertEqual(log[0], event)
    }

    // MARK: - Chronological order

    func testEventsInChronologicalOrder() {
        let projection = PlayerGameLogProjection()
        projection.handle(makeEvent(player: 7, stat: .fieldGoal2pt, timecode: 100, index: 0))
        projection.handle(makeEvent(player: 7, stat: .rebound, timecode: 200, index: 1))
        projection.handle(makeEvent(player: 7, stat: .assist, timecode: 300, index: 2))

        let log = projection.log(for: PlayerKey(team: .home, playerNumber: 7))
        XCTAssertEqual(log.count, 3)
        XCTAssertEqual(log[0].statType, .fieldGoal2pt)
        XCTAssertEqual(log[1].statType, .rebound)
        XCTAssertEqual(log[2].statType, .assist)
    }

    // MARK: - Players only see their own events

    func testPlayersOnlySeeTheirOwnEvents() {
        let projection = PlayerGameLogProjection()
        projection.handle(makeEvent(player: 7, stat: .fieldGoal2pt, timecode: 100, index: 0))
        projection.handle(makeEvent(player: 11, stat: .rebound, timecode: 200, index: 1))
        projection.handle(makeEvent(player: 7, stat: .assist, timecode: 300, index: 2))

        let log7 = projection.log(for: PlayerKey(team: .home, playerNumber: 7))
        let log11 = projection.log(for: PlayerKey(team: .home, playerNumber: 11))
        XCTAssertEqual(log7.count, 2)
        XCTAssertEqual(log11.count, 1)
    }

    // MARK: - Same number different teams are separate

    func testSameNumberDifferentTeamsAreSeparate() {
        let projection = PlayerGameLogProjection()
        projection.handle(makeEvent(team: .home, player: 7, stat: .fieldGoal2pt, index: 0))
        projection.handle(makeEvent(team: .opponent, player: 7, stat: .fieldGoal3pt, index: 1))

        let homeLog = projection.log(for: PlayerKey(team: .home, playerNumber: 7))
        let oppLog = projection.log(for: PlayerKey(team: .opponent, playerNumber: 7))
        XCTAssertEqual(homeLog.count, 1)
        XCTAssertEqual(oppLog.count, 1)
        XCTAssertEqual(homeLog[0].statType, .fieldGoal2pt)
        XCTAssertEqual(oppLog[0].statType, .fieldGoal3pt)
    }

    // MARK: - Empty log

    func testEmptyLogForUnknownPlayer() {
        let projection = PlayerGameLogProjection()
        let log = projection.log(for: PlayerKey(team: .home, playerNumber: 99))
        XCTAssertTrue(log.isEmpty)
    }

    // MARK: - Reset

    func testResetClearsAllLogs() {
        let projection = PlayerGameLogProjection()
        projection.handle(makeEvent(player: 7, stat: .fieldGoal2pt, index: 0))
        projection.reset()
        let log = projection.log(for: PlayerKey(team: .home, playerNumber: 7))
        XCTAssertTrue(log.isEmpty)
    }
}
