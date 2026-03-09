import XCTest
@testable import CourtStatsCore

#if canImport(FoundationXML)
import FoundationXML
#endif

final class ScoreTickerRendererTests: XCTestCase {

    private let defaultRenderer = ScoreTickerRenderer(
        homeName: "Home",
        awayName: "Away",
        titleTemplateRef: "r2"
    )

    // MARK: - Single Snapshot

    func testSingleSnapshotProducesTitleElement() {
        let snapshots = [ScoreSnapshot(timecode: 90.0, homeScore: 2, opponentScore: 0)]
        let titles = defaultRenderer.renderTitles(from: snapshots, endTimecode: 180.0)

        XCTAssertEqual(titles.count, 1)
        XCTAssertEqual(titles[0].name, "title")
    }

    func testTitleHasLane99() {
        let snapshots = [ScoreSnapshot(timecode: 90.0, homeScore: 2, opponentScore: 0)]
        let titles = defaultRenderer.renderTitles(from: snapshots, endTimecode: 180.0)

        let lane = titles[0].attribute(forName: "lane")?.stringValue
        XCTAssertEqual(lane, "99")
    }

    func testTitleHasCSPrefixInName() {
        let snapshots = [ScoreSnapshot(timecode: 90.0, homeScore: 2, opponentScore: 0)]
        let titles = defaultRenderer.renderTitles(from: snapshots, endTimecode: 180.0)

        let name = titles[0].attribute(forName: "name")?.stringValue
        XCTAssertEqual(name, "[CS] Score")
    }

    func testTitleTextFormatWithEmDash() throws {
        let snapshots = [ScoreSnapshot(timecode: 90.0, homeScore: 2, opponentScore: 0)]
        let titles = defaultRenderer.renderTitles(from: snapshots, endTimecode: 180.0)

        let xmlString = titles[0].xmlString
        XCTAssertTrue(xmlString.contains("Home 2 \u{2014} Away 0"),
                       "Expected em dash separator in: \(xmlString)")
    }

    func testCustomTeamNames() throws {
        let renderer = ScoreTickerRenderer(
            homeName: "Wildcats",
            awayName: "Eagles",
            titleTemplateRef: "r2"
        )
        let snapshots = [ScoreSnapshot(timecode: 90.0, homeScore: 2, opponentScore: 0)]
        let titles = renderer.renderTitles(from: snapshots, endTimecode: 180.0)

        let xmlString = titles[0].xmlString
        XCTAssertTrue(xmlString.contains("Wildcats 2 \u{2014} Eagles 0"),
                       "Expected custom team names in: \(xmlString)")
    }

    // MARK: - Duration Calculation

    func testDurationSpansBetweenConsecutiveSnapshots() {
        let snapshots = [
            ScoreSnapshot(timecode: 90.0, homeScore: 2, opponentScore: 0),
            ScoreSnapshot(timecode: 165.0, homeScore: 2, opponentScore: 3),
        ]
        let titles = defaultRenderer.renderTitles(from: snapshots, endTimecode: 300.0)

        XCTAssertEqual(titles.count, 2)

        // First title: 90s to 165s = 75s duration
        let firstDuration = titles[0].attribute(forName: "duration")?.stringValue
        XCTAssertEqual(firstDuration, "75s")

        // Second title: 165s to 300s = 135s duration
        let secondDuration = titles[1].attribute(forName: "duration")?.stringValue
        XCTAssertEqual(secondDuration, "135s")
    }

    func testLastSnapshotExtendsToEndTimecode() {
        let snapshots = [ScoreSnapshot(timecode: 90.0, homeScore: 2, opponentScore: 0)]
        let titles = defaultRenderer.renderTitles(from: snapshots, endTimecode: 500.0)

        let duration = titles[0].attribute(forName: "duration")?.stringValue
        XCTAssertEqual(duration, "410s")
    }

    // MARK: - Title Offset

    func testTitleOffsetMatchesSnapshotTimecode() {
        let snapshots = [ScoreSnapshot(timecode: 90.0, homeScore: 2, opponentScore: 0)]
        let titles = defaultRenderer.renderTitles(from: snapshots, endTimecode: 180.0)

        let offset = titles[0].attribute(forName: "offset")?.stringValue
        XCTAssertEqual(offset, "90s")
    }

    // MARK: - Effect Reference

    func testTitleReferencesConfiguredEffectRef() {
        let renderer = ScoreTickerRenderer(
            homeName: "Home",
            awayName: "Away",
            titleTemplateRef: "r5"
        )
        let snapshots = [ScoreSnapshot(timecode: 90.0, homeScore: 2, opponentScore: 0)]
        let titles = renderer.renderTitles(from: snapshots, endTimecode: 180.0)

        let ref = titles[0].attribute(forName: "ref")?.stringValue
        XCTAssertEqual(ref, "r5")
    }

    // MARK: - Empty Input

    func testEmptySnapshotsProducesEmptyOutput() {
        let titles = defaultRenderer.renderTitles(from: [], endTimecode: 300.0)
        XCTAssertTrue(titles.isEmpty)
    }
}
