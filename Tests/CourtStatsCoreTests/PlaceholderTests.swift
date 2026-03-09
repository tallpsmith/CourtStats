import XCTest
@testable import CourtStatsCore

final class PlaceholderTests: XCTestCase {
    func testCoreModuleLoads() {
        XCTAssertEqual(CourtStatsCore.version, "0.1.0")
    }
}
