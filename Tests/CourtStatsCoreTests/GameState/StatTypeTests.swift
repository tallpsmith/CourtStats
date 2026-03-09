import XCTest
@testable import CourtStatsCore

final class StatTypeTests: XCTestCase {

    // MARK: - All 15 cases exist

    func testAllFifteenCasesExist() {
        let allCases: [StatType] = [
            .fieldGoal2pt, .fieldGoal3pt, .freeThrow,
            .missedFieldGoal2, .missedFieldGoal3, .missedFreeThrow,
            .rebound, .offensiveRebound, .assist, .steal,
            .block, .turnover, .personalFoul,
            .substitutionOn, .substitutionOff
        ]
        XCTAssertEqual(allCases.count, 15)
    }

    // MARK: - Points value

    func testPointsValueForScoringTypes() {
        XCTAssertEqual(StatType.fieldGoal2pt.pointsValue, 2)
        XCTAssertEqual(StatType.fieldGoal3pt.pointsValue, 3)
        XCTAssertEqual(StatType.freeThrow.pointsValue, 1)
    }

    func testPointsValueForMisses() {
        XCTAssertEqual(StatType.missedFieldGoal2.pointsValue, 0)
        XCTAssertEqual(StatType.missedFieldGoal3.pointsValue, 0)
        XCTAssertEqual(StatType.missedFreeThrow.pointsValue, 0)
    }

    func testPointsValueForNonScoringTypes() {
        let nonScoring: [StatType] = [
            .rebound, .offensiveRebound, .assist, .steal,
            .block, .turnover, .personalFoul,
            .substitutionOn, .substitutionOff
        ]
        for stat in nonScoring {
            XCTAssertEqual(stat.pointsValue, 0, "\(stat) should have 0 points")
        }
    }

    // MARK: - isScoring

    func testIsScoringTrueForMadeShots() {
        XCTAssertTrue(StatType.fieldGoal2pt.isScoring)
        XCTAssertTrue(StatType.fieldGoal3pt.isScoring)
        XCTAssertTrue(StatType.freeThrow.isScoring)
    }

    func testIsScoringFalseForMisses() {
        XCTAssertFalse(StatType.missedFieldGoal2.isScoring)
        XCTAssertFalse(StatType.missedFieldGoal3.isScoring)
        XCTAssertFalse(StatType.missedFreeThrow.isScoring)
    }

    func testIsScoringFalseForOtherTypes() {
        XCTAssertFalse(StatType.rebound.isScoring)
        XCTAssertFalse(StatType.assist.isScoring)
        XCTAssertFalse(StatType.substitutionOn.isScoring)
    }

    // MARK: - isSubstitution

    func testIsSubstitutionTrueForSubEvents() {
        XCTAssertTrue(StatType.substitutionOn.isSubstitution)
        XCTAssertTrue(StatType.substitutionOff.isSubstitution)
    }

    func testIsSubstitutionFalseForOtherTypes() {
        XCTAssertFalse(StatType.fieldGoal2pt.isSubstitution)
        XCTAssertFalse(StatType.rebound.isSubstitution)
    }

    // MARK: - Init from marker code

    func testInitFromMarkerCodeAllCodes() {
        let mapping: [(String, StatType)] = [
            ("PTS2", .fieldGoal2pt),
            ("PTS3", .fieldGoal3pt),
            ("FT", .freeThrow),
            ("PTS2X", .missedFieldGoal2),
            ("PTS3X", .missedFieldGoal3),
            ("FTX", .missedFreeThrow),
            ("REB", .rebound),
            ("OREB", .offensiveRebound),
            ("AST", .assist),
            ("STL", .steal),
            ("BLK", .block),
            ("TO", .turnover),
            ("PF", .personalFoul),
            ("SUBON", .substitutionOn),
            ("SUBOFF", .substitutionOff)
        ]
        for (code, expected) in mapping {
            XCTAssertEqual(StatType(markerCode: code), expected, "Code '\(code)' should map to \(expected)")
        }
    }

    func testInitFromMarkerCodeIsCaseInsensitive() {
        XCTAssertEqual(StatType(markerCode: "pts2"), .fieldGoal2pt)
        XCTAssertEqual(StatType(markerCode: "Pts3"), .fieldGoal3pt)
        XCTAssertEqual(StatType(markerCode: "ft"), .freeThrow)
        XCTAssertEqual(StatType(markerCode: "subon"), .substitutionOn)
    }

    func testInitFromInvalidMarkerCodeReturnsNil() {
        XCTAssertNil(StatType(markerCode: "INVALID"))
        XCTAssertNil(StatType(markerCode: ""))
        XCTAssertNil(StatType(markerCode: "SCORE"))
    }
}
