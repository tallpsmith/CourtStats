import XCTest
@testable import CourtStatsCore

final class PlaceholderIntegrationTests: XCTestCase {
    func testIntegrationTargetLoads() {
        XCTAssertEqual(CourtStatsCore.version, "0.1.0")
    }
}
