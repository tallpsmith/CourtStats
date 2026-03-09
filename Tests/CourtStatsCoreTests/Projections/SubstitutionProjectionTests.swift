import XCTest
@testable import CourtStatsCore

final class SubstitutionProjectionTests: XCTestCase {

    private func makeEvent(
        team: Team = .home,
        player: Int = 7,
        stat: StatType = .substitutionOn,
        timecode: TimeInterval = 0,
        index: Int = 0
    ) -> GameEvent {
        GameEvent(team: team, playerNumber: player, statType: stat, timecode: timecode, markerIndex: index)
    }

    // MARK: - On-court tracking

    func testSubOnAddsPlayerToOnCourt() {
        let projection = SubstitutionProjection()
        projection.handle(makeEvent(team: .home, player: 7, stat: .substitutionOn))
        XCTAssertTrue(projection.homeOnCourt.contains(7))
    }

    func testSubOffRemovesPlayerFromOnCourt() {
        let projection = SubstitutionProjection()
        projection.handle(makeEvent(team: .home, player: 7, stat: .substitutionOn, timecode: 0, index: 0))
        projection.handle(makeEvent(team: .home, player: 7, stat: .substitutionOff, timecode: 300, index: 1))
        XCTAssertFalse(projection.homeOnCourt.contains(7))
    }

    func testOpponentOnCourtTrackedSeparately() {
        let projection = SubstitutionProjection()
        projection.handle(makeEvent(team: .home, player: 7, stat: .substitutionOn, index: 0))
        projection.handle(makeEvent(team: .opponent, player: 7, stat: .substitutionOn, index: 1))
        XCTAssertTrue(projection.homeOnCourt.contains(7))
        XCTAssertTrue(projection.opponentOnCourt.contains(7))
    }

    func testMultiplePlayersTracked() {
        let projection = SubstitutionProjection()
        projection.handle(makeEvent(team: .home, player: 7, stat: .substitutionOn, index: 0))
        projection.handle(makeEvent(team: .home, player: 11, stat: .substitutionOn, index: 1))
        projection.handle(makeEvent(team: .home, player: 23, stat: .substitutionOn, index: 2))
        XCTAssertEqual(projection.homeOnCourt, Set([7, 11, 23]))
    }

    // MARK: - Warning: duplicate SUBON

    func testDuplicateSubOnGeneratesWarning() {
        let projection = SubstitutionProjection()
        projection.handle(makeEvent(team: .home, player: 7, stat: .substitutionOn, index: 0))
        projection.handle(makeEvent(team: .home, player: 7, stat: .substitutionOn, index: 1))
        XCTAssertEqual(projection.warnings.count, 1)
        XCTAssertTrue(projection.warnings[0].message.contains("already on court"))
        XCTAssertEqual(projection.warnings[0].markerIndex, 1)
    }

    // MARK: - Warning: orphaned SUBOFF

    func testOrphanedSubOffGeneratesWarning() {
        let projection = SubstitutionProjection()
        projection.handle(makeEvent(team: .home, player: 7, stat: .substitutionOff, index: 0))
        XCTAssertEqual(projection.warnings.count, 1)
        XCTAssertTrue(projection.warnings[0].message.contains("not on court"))
        XCTAssertEqual(projection.warnings[0].markerIndex, 0)
    }

    // MARK: - Non-substitution events ignored

    func testNonSubstitutionEventsIgnored() {
        let projection = SubstitutionProjection()
        projection.handle(makeEvent(stat: .fieldGoal2pt))
        projection.handle(makeEvent(stat: .rebound))
        XCTAssertTrue(projection.homeOnCourt.isEmpty)
        XCTAssertTrue(projection.warnings.isEmpty)
    }

    // MARK: - Auto-close open stints

    func testFinaliseAutoClosesOpenStints() {
        let projection = SubstitutionProjection()
        projection.handle(makeEvent(team: .home, player: 7, stat: .substitutionOn, timecode: 100, index: 0))
        projection.finalise(atTimecode: 3600)
        XCTAssertFalse(projection.homeOnCourt.contains(7))
    }

    // MARK: - Reset

    func testResetClearsAllState() {
        let projection = SubstitutionProjection()
        projection.handle(makeEvent(team: .home, player: 7, stat: .substitutionOn, index: 0))
        projection.handle(makeEvent(team: .home, player: 7, stat: .substitutionOn, index: 1))
        projection.reset()
        XCTAssertTrue(projection.homeOnCourt.isEmpty)
        XCTAssertTrue(projection.opponentOnCourt.isEmpty)
        XCTAssertTrue(projection.warnings.isEmpty)
    }
}
