import XCTest
@testable import CourtStatsCore

final class PipelineTests: XCTestCase {

    // MARK: - Helpers

    private func loadFixture(_ name: String) throws -> Data {
        let bundle = Bundle.module
        guard let url = bundle.url(forResource: name, withExtension: nil, subdirectory: "Fixtures") else {
            XCTFail("Missing fixture: \(name)")
            return Data()
        }
        return try Data(contentsOf: url)
    }

    // MARK: - T036: Basic scoring pipeline test

    func testBasicScoringPipelineProducesScoreTickerTitles() throws {
        let inputData = try loadFixture("basic-scoring.fcpxml")
        let pipeline = ProcessingPipeline(configuration: .init(
            homeName: "Wildcats",
            awayName: "Eagles"
        ))

        let result = try pipeline.process(inputData)

        XCTAssertEqual(result.validMarkers, 4, "4 valid CS markers")
        XCTAssertEqual(result.ignoredMarkers, 1, "1 non-CS marker (Chapter 1)")
        XCTAssertEqual(result.overlaysGenerated, 4, "4 scoring events = 4 overlays")
        XCTAssertFalse(result.hasWarnings)

        let outputString = String(data: result.outputData, encoding: .utf8) ?? ""
        XCTAssertTrue(outputString.contains("[CS] Score"), "Output should contain score ticker titles")
        XCTAssertTrue(outputString.contains("lane=\"99\""), "Titles should be on lane 99")
        XCTAssertTrue(outputString.contains("Wildcats"), "Output should use home team name")
        XCTAssertTrue(outputString.contains("Eagles"), "Output should use away team name")
    }

    func testBasicScoringProducesCorrectRunningScores() throws {
        let inputData = try loadFixture("basic-scoring.fcpxml")
        let pipeline = ProcessingPipeline(configuration: .init(
            homeName: "Home",
            awayName: "Away"
        ))

        let result = try pipeline.process(inputData)
        let outputString = String(data: result.outputData, encoding: .utf8) ?? ""

        // Marker 1: CS:T:7:PTS2 at 90s → Home 2 — Away 0
        XCTAssertTrue(outputString.contains("Home 2 \u{2014} Away 0"), "First score should be Home 2 — Away 0")
        // Marker 2: CS:O:12:PTS3 at 165s → Home 2 — Away 3
        XCTAssertTrue(outputString.contains("Home 2 \u{2014} Away 3"), "Second score should be Home 2 — Away 3")
        // Marker 3: CS:T:5:FT at 240s → Home 3 — Away 3
        XCTAssertTrue(outputString.contains("Home 3 \u{2014} Away 3"), "Third score should be Home 3 — Away 3")
        // Marker 4: CS:T:7:PTS3 at 300s → Home 6 — Away 3
        XCTAssertTrue(outputString.contains("Home 6 \u{2014} Away 3"), "Fourth score should be Home 6 — Away 3")
    }

    func testBasicScoringPreservesOriginalContent() throws {
        let inputData = try loadFixture("basic-scoring.fcpxml")
        let pipeline = ProcessingPipeline()

        let result = try pipeline.process(inputData)
        let outputString = String(data: result.outputData, encoding: .utf8) ?? ""

        XCTAssertTrue(outputString.contains("CS:T:7:PTS2"), "Original markers preserved")
        XCTAssertTrue(outputString.contains("Chapter 1"), "Non-CS markers preserved")
        XCTAssertTrue(outputString.contains("Game Footage"), "Clip names preserved")
    }

    // MARK: - T038: Malformed markers test

    func testMalformedMarkersProduceAnnotations() throws {
        let inputData = try loadFixture("malformed-markers.fcpxml")
        let pipeline = ProcessingPipeline()

        let result = try pipeline.process(inputData)

        XCTAssertEqual(result.validMarkers, 1, "Only first marker is valid")
        XCTAssertEqual(result.invalidMarkers, 4, "4 malformed markers")
        XCTAssertTrue(result.hasWarnings, "Should have warnings for invalid markers")
        XCTAssertEqual(result.overlaysGenerated, 1, "Only 1 scoring overlay from valid marker")

        let outputString = String(data: result.outputData, encoding: .utf8) ?? ""
        XCTAssertTrue(outputString.contains("[CS:INVALID]"), "Invalid markers should be annotated")
    }

    // MARK: - T051: Scoring-only input (no substitutions)

    func testScoringOnlyInputProducesOverlaysWithoutErrors() throws {
        let inputData = try loadFixture("mixed-markers.fcpxml")
        let pipeline = ProcessingPipeline()

        let result = try pipeline.process(inputData)

        XCTAssertEqual(result.validMarkers, 3, "3 valid CS scoring markers")
        XCTAssertEqual(result.ignoredMarkers, 2, "2 non-CS markers")
        XCTAssertEqual(result.overlaysGenerated, 3, "3 score overlays generated")
        XCTAssertFalse(result.hasWarnings, "No warnings for scoring-only input")
    }

    // MARK: - T052: Empty input (no CS markers)

    func testEmptyInputProducesCleanOutputWithNoOverlays() throws {
        let inputData = try loadFixture("empty-timeline.fcpxml")
        let pipeline = ProcessingPipeline()

        let result = try pipeline.process(inputData)

        XCTAssertEqual(result.totalMarkers, 0)
        XCTAssertEqual(result.overlaysGenerated, 0)
        XCTAssertFalse(result.hasWarnings)

        let outputString = String(data: result.outputData, encoding: .utf8) ?? ""
        XCTAssertFalse(outputString.contains("[CS] Score"), "No score titles in empty output")
        XCTAssertTrue(outputString.contains("Game Footage"), "Original content preserved")
    }

    // MARK: - T053: Edge case — scoring before SUBON

    func testScoringBeforeSubOnDoesNotCrash() throws {
        let inputData = try loadFixture("basic-scoring.fcpxml")
        let pipeline = ProcessingPipeline()

        let result = try pipeline.process(inputData)
        XCTAssertGreaterThan(result.overlaysGenerated, 0, "Scoring without SUBON still produces overlays")
    }
}
