import XCTest
@testable import CourtStatsCore

final class GameEventTests: XCTestCase {

    // MARK: - Construction

    func testGameEventStoresAllProperties() {
        let event = GameEvent(
            team: .home,
            playerNumber: 7,
            statType: .fieldGoal2pt,
            timecode: 90.0,
            markerIndex: 0
        )

        XCTAssertEqual(event.team, .home)
        XCTAssertEqual(event.playerNumber, 7)
        XCTAssertEqual(event.statType, .fieldGoal2pt)
        XCTAssertEqual(event.timecode, 90.0)
        XCTAssertEqual(event.markerIndex, 0)
    }

    // MARK: - Points value derived from statType

    func testPointsValueDerivedFromStatType() {
        let twoPointer = GameEvent(team: .home, playerNumber: 7, statType: .fieldGoal2pt, timecode: 90.0, markerIndex: 0)
        XCTAssertEqual(twoPointer.pointsValue, 2)

        let threePointer = GameEvent(team: .opponent, playerNumber: 12, statType: .fieldGoal3pt, timecode: 120.0, markerIndex: 1)
        XCTAssertEqual(threePointer.pointsValue, 3)

        let freeThrow = GameEvent(team: .home, playerNumber: 5, statType: .freeThrow, timecode: 150.0, markerIndex: 2)
        XCTAssertEqual(freeThrow.pointsValue, 1)

        let miss = GameEvent(team: .home, playerNumber: 7, statType: .missedFieldGoal2, timecode: 180.0, markerIndex: 3)
        XCTAssertEqual(miss.pointsValue, 0)

        let rebound = GameEvent(team: .home, playerNumber: 10, statType: .rebound, timecode: 200.0, markerIndex: 4)
        XCTAssertEqual(rebound.pointsValue, 0)
    }

    // MARK: - Marker index identity

    func testMarkerIndexServesAsIdentity() {
        let event1 = GameEvent(team: .home, playerNumber: 7, statType: .fieldGoal2pt, timecode: 90.0, markerIndex: 0)
        let event2 = GameEvent(team: .home, playerNumber: 7, statType: .fieldGoal2pt, timecode: 90.0, markerIndex: 1)

        XCTAssertNotEqual(event1.markerIndex, event2.markerIndex)
    }
}
