import XCTest
@testable import CourtStatsCore

final class TeamTests: XCTestCase {

    // MARK: - Cases

    func testHomeAndOpponentCasesExist() {
        let home = Team.home
        let opponent = Team.opponent
        XCTAssertNotEqual(home, opponent)
    }

    // MARK: - Init from marker code

    func testInitFromMarkerCodeT() {
        XCTAssertEqual(Team(markerCode: "T"), .home)
    }

    func testInitFromMarkerCodeO() {
        XCTAssertEqual(Team(markerCode: "O"), .opponent)
    }

    func testInitFromMarkerCodeIsCaseInsensitive() {
        XCTAssertEqual(Team(markerCode: "t"), .home)
        XCTAssertEqual(Team(markerCode: "o"), .opponent)
    }

    func testInitFromInvalidMarkerCodeReturnsNil() {
        XCTAssertNil(Team(markerCode: "X"))
        XCTAssertNil(Team(markerCode: ""))
        XCTAssertNil(Team(markerCode: "HOME"))
    }
}
