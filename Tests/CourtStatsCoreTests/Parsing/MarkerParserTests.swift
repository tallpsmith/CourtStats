import XCTest
@testable import CourtStatsCore

final class MarkerParserTests: XCTestCase {

    // MARK: - T016: Valid marker parsing

    func testValidTwoPointMarker() {
        let result = MarkerParser.parse(markerValue: "CS:T:7:PTS2", timecode: 90.0, markerIndex: 0)
        XCTAssertEqual(result.annotation, .valid)
        XCTAssertNotNil(result.event)
        XCTAssertEqual(result.event?.team, .home)
        XCTAssertEqual(result.event?.playerNumber, 7)
        XCTAssertEqual(result.event?.statType, .fieldGoal2pt)
        XCTAssertEqual(result.event?.timecode, 90.0)
        XCTAssertEqual(result.event?.markerIndex, 0)
    }

    func testValidThreePointMarkerOpponent() {
        let result = MarkerParser.parse(markerValue: "CS:O:12:PTS3", timecode: 120.0, markerIndex: 1)
        XCTAssertEqual(result.annotation, .valid)
        XCTAssertEqual(result.event?.team, .opponent)
        XCTAssertEqual(result.event?.playerNumber, 12)
        XCTAssertEqual(result.event?.statType, .fieldGoal3pt)
    }

    func testValidFreeThrow() {
        let result = MarkerParser.parse(markerValue: "CS:T:5:FT", timecode: 150.0, markerIndex: 2)
        XCTAssertEqual(result.event?.statType, .freeThrow)
        XCTAssertEqual(result.event?.pointsValue, 1)
    }

    func testAllStatCodesParseCorrectly() {
        let codes: [(String, StatType)] = [
            ("PTS2", .fieldGoal2pt), ("PTS3", .fieldGoal3pt),
            ("FT", .freeThrow), ("PTS2X", .missedFieldGoal2),
            ("PTS3X", .missedFieldGoal3), ("FTX", .missedFreeThrow),
            ("REB", .rebound), ("OREB", .offensiveRebound),
            ("AST", .assist), ("STL", .steal),
            ("BLK", .block), ("TO", .turnover),
            ("PF", .personalFoul),
            ("SUBON", .substitutionOn), ("SUBOFF", .substitutionOff)
        ]
        for (index, (code, expectedType)) in codes.enumerated() {
            let result = MarkerParser.parse(markerValue: "CS:T:1:\(code)", timecode: 0, markerIndex: index)
            XCTAssertEqual(result.event?.statType, expectedType, "Code '\(code)' should parse to \(expectedType)")
            XCTAssertEqual(result.annotation, .valid, "Code '\(code)' should be valid")
        }
    }

    func testBothTeamCodesParse() {
        let home = MarkerParser.parse(markerValue: "CS:T:1:PTS2", timecode: 0, markerIndex: 0)
        let opp = MarkerParser.parse(markerValue: "CS:O:1:PTS2", timecode: 0, markerIndex: 1)
        XCTAssertEqual(home.event?.team, .home)
        XCTAssertEqual(opp.event?.team, .opponent)
    }

    // MARK: - T017: Invalid marker rejection

    func testTooFewSegmentsReturnsInvalid() {
        let result = MarkerParser.parse(markerValue: "CS:T:7", timecode: 0, markerIndex: 0)
        XCTAssertNil(result.event)
        XCTAssertEqual(result.annotation, .invalid)
    }

    func testInvalidTeamCodeReturnsInvalid() {
        let result = MarkerParser.parse(markerValue: "CS:X:7:PTS2", timecode: 0, markerIndex: 0)
        XCTAssertNil(result.event)
        XCTAssertEqual(result.annotation, .invalid)
    }

    func testInvalidStatCodeReturnsInvalid() {
        let result = MarkerParser.parse(markerValue: "CS:T:7:DUNK", timecode: 0, markerIndex: 0)
        XCTAssertNil(result.event)
        XCTAssertEqual(result.annotation, .invalid)
    }

    func testNonNumericPlayerNumberReturnsInvalid() {
        let result = MarkerParser.parse(markerValue: "CS:T:ABC:PTS2", timecode: 0, markerIndex: 0)
        XCTAssertNil(result.event)
        XCTAssertEqual(result.annotation, .invalid)
    }

    func testEmptySegmentsReturnsInvalid() {
        let result = MarkerParser.parse(markerValue: "CS:::", timecode: 0, markerIndex: 0)
        XCTAssertNil(result.event)
        XCTAssertEqual(result.annotation, .invalid)
    }

    // MARK: - T018: Whitespace and case insensitivity

    func testLeadingTrailingWhitespaceNormalised() {
        let result = MarkerParser.parse(markerValue: "  CS:T:7:PTS2  ", timecode: 0, markerIndex: 0)
        XCTAssertEqual(result.annotation, .valid)
        XCTAssertEqual(result.event?.statType, .fieldGoal2pt)
    }

    func testCaseInsensitiveParsing() {
        let result = MarkerParser.parse(markerValue: "cs:t:7:pts2", timecode: 0, markerIndex: 0)
        XCTAssertEqual(result.annotation, .valid)
        XCTAssertEqual(result.event?.team, .home)
        XCTAssertEqual(result.event?.statType, .fieldGoal2pt)
    }

    func testMixedCaseParsing() {
        let result = MarkerParser.parse(markerValue: "Cs:t:7:Pts3", timecode: 0, markerIndex: 0)
        XCTAssertEqual(result.annotation, .valid)
        XCTAssertEqual(result.event?.statType, .fieldGoal3pt)
    }

    // MARK: - T019: Annotation stripping

    func testExistingInvalidAnnotationStrippedBeforeReparse() {
        let result = MarkerParser.parse(markerValue: "CS:T:7:PTS2 [CS:INVALID]", timecode: 0, markerIndex: 0)
        XCTAssertEqual(result.annotation, .valid)
        XCTAssertEqual(result.event?.statType, .fieldGoal2pt)
    }

    func testExistingWarnAnnotationStrippedBeforeReparse() {
        let result = MarkerParser.parse(markerValue: "CS:T:7:SUBON [CS:WARN]", timecode: 0, markerIndex: 0)
        XCTAssertEqual(result.annotation, .valid)
        XCTAssertEqual(result.event?.statType, .substitutionOn)
    }

    func testMultipleAnnotationsStripped() {
        let result = MarkerParser.parse(markerValue: "CS:T:7:PTS2 [CS:INVALID] [CS:WARN]", timecode: 0, markerIndex: 0)
        XCTAssertEqual(result.annotation, .valid)
    }

    // MARK: - T020: Non-CS marker detection

    func testNonCSMarkerReturnsIgnored() {
        let result = MarkerParser.parse(markerValue: "Chapter 1", timecode: 0, markerIndex: 0)
        XCTAssertNil(result.event)
        XCTAssertEqual(result.annotation, .ignored)
    }

    func testEmptyMarkerReturnsIgnored() {
        let result = MarkerParser.parse(markerValue: "", timecode: 0, markerIndex: 0)
        XCTAssertNil(result.event)
        XCTAssertEqual(result.annotation, .ignored)
    }

    func testMarkerStartingWithCSButNotColonReturnsIgnored() {
        let result = MarkerParser.parse(markerValue: "CSomething else", timecode: 0, markerIndex: 0)
        XCTAssertNil(result.event)
        XCTAssertEqual(result.annotation, .ignored)
    }
}
