import XCTest
@testable import CourtStatsCore

final class ScoreProjectionTests: XCTestCase {

    private var projection: ScoreProjection!

    override func setUp() {
        super.setUp()
        projection = ScoreProjection()
    }

    override func tearDown() {
        projection = nil
        super.tearDown()
    }

    // MARK: - Helper

    private func makeEvent(
        team: Team = .home,
        playerNumber: Int = 7,
        statType: StatType,
        timecode: TimeInterval = 10.0,
        markerIndex: Int = 0
    ) -> GameEvent {
        GameEvent(
            team: team,
            playerNumber: playerNumber,
            statType: statType,
            timecode: timecode,
            markerIndex: markerIndex
        )
    }

    // MARK: - Initial State

    func testInitialStateHasNoSnapshots() {
        XCTAssertTrue(projection.snapshots.isEmpty)
    }

    // MARK: - Home Scoring

    func testHomeTwoPointerProducesCorrectSnapshot() {
        let event = makeEvent(team: .home, statType: .fieldGoal2pt, timecode: 5.0)

        projection.handle(event)

        XCTAssertEqual(projection.snapshots.count, 1)
        XCTAssertEqual(projection.snapshots[0], ScoreSnapshot(timecode: 5.0, homeScore: 2, opponentScore: 0))
    }

    // MARK: - Opponent Scoring

    func testOpponentThreePointerProducesCorrectSnapshot() {
        let event = makeEvent(team: .opponent, statType: .fieldGoal3pt, timecode: 12.0)

        projection.handle(event)

        XCTAssertEqual(projection.snapshots.count, 1)
        XCTAssertEqual(projection.snapshots[0], ScoreSnapshot(timecode: 12.0, homeScore: 0, opponentScore: 3))
    }

    // MARK: - Cumulative Scoring

    func testCumulativeScoringProducesRunningTotals() {
        projection.handle(makeEvent(team: .home, statType: .fieldGoal2pt, timecode: 1.0, markerIndex: 0))
        projection.handle(makeEvent(team: .opponent, statType: .fieldGoal3pt, timecode: 2.0, markerIndex: 1))
        projection.handle(makeEvent(team: .home, statType: .freeThrow, timecode: 3.0, markerIndex: 2))
        projection.handle(makeEvent(team: .opponent, statType: .fieldGoal2pt, timecode: 4.0, markerIndex: 3))

        XCTAssertEqual(projection.snapshots.count, 4)
        XCTAssertEqual(projection.snapshots[0], ScoreSnapshot(timecode: 1.0, homeScore: 2, opponentScore: 0))
        XCTAssertEqual(projection.snapshots[1], ScoreSnapshot(timecode: 2.0, homeScore: 2, opponentScore: 3))
        XCTAssertEqual(projection.snapshots[2], ScoreSnapshot(timecode: 3.0, homeScore: 3, opponentScore: 3))
        XCTAssertEqual(projection.snapshots[3], ScoreSnapshot(timecode: 4.0, homeScore: 3, opponentScore: 5))
    }

    // MARK: - Missed Shots Do Not Produce Snapshots

    func testMissedTwoPointerDoesNotProduceSnapshot() {
        projection.handle(makeEvent(statType: .missedFieldGoal2))
        XCTAssertTrue(projection.snapshots.isEmpty)
    }

    func testMissedThreePointerDoesNotProduceSnapshot() {
        projection.handle(makeEvent(statType: .missedFieldGoal3))
        XCTAssertTrue(projection.snapshots.isEmpty)
    }

    func testMissedFreeThrowDoesNotProduceSnapshot() {
        projection.handle(makeEvent(statType: .missedFreeThrow))
        XCTAssertTrue(projection.snapshots.isEmpty)
    }

    // MARK: - Non-Scoring Events Do Not Produce Snapshots

    func testReboundDoesNotProduceSnapshot() {
        projection.handle(makeEvent(statType: .rebound))
        XCTAssertTrue(projection.snapshots.isEmpty)
    }

    func testAssistDoesNotProduceSnapshot() {
        projection.handle(makeEvent(statType: .assist))
        XCTAssertTrue(projection.snapshots.isEmpty)
    }

    func testStealDoesNotProduceSnapshot() {
        projection.handle(makeEvent(statType: .steal))
        XCTAssertTrue(projection.snapshots.isEmpty)
    }

    func testBlockDoesNotProduceSnapshot() {
        projection.handle(makeEvent(statType: .block))
        XCTAssertTrue(projection.snapshots.isEmpty)
    }

    func testTurnoverDoesNotProduceSnapshot() {
        projection.handle(makeEvent(statType: .turnover))
        XCTAssertTrue(projection.snapshots.isEmpty)
    }

    func testPersonalFoulDoesNotProduceSnapshot() {
        projection.handle(makeEvent(statType: .personalFoul))
        XCTAssertTrue(projection.snapshots.isEmpty)
    }

    // MARK: - Free Throws

    func testFreeThrowProducesOnePointSnapshot() {
        projection.handle(makeEvent(team: .home, statType: .freeThrow, timecode: 20.0))

        XCTAssertEqual(projection.snapshots.count, 1)
        XCTAssertEqual(projection.snapshots[0], ScoreSnapshot(timecode: 20.0, homeScore: 1, opponentScore: 0))
    }

    // MARK: - Reset

    func testResetClearsAllSnapshotsAndScores() {
        projection.handle(makeEvent(team: .home, statType: .fieldGoal2pt, timecode: 1.0))
        projection.handle(makeEvent(team: .opponent, statType: .fieldGoal3pt, timecode: 2.0))

        projection.reset()

        XCTAssertTrue(projection.snapshots.isEmpty)

        // After reset, scoring should start fresh
        projection.handle(makeEvent(team: .home, statType: .freeThrow, timecode: 10.0))
        XCTAssertEqual(projection.snapshots[0], ScoreSnapshot(timecode: 10.0, homeScore: 1, opponentScore: 0))
    }

    // MARK: - Timecodes

    func testSnapshotsPreserveTimecodesFromSourceEvents() {
        projection.handle(makeEvent(team: .home, statType: .fieldGoal2pt, timecode: 42.5))
        projection.handle(makeEvent(team: .opponent, statType: .fieldGoal3pt, timecode: 99.9))

        XCTAssertEqual(projection.snapshots[0].timecode, 42.5)
        XCTAssertEqual(projection.snapshots[1].timecode, 99.9)
    }
}
