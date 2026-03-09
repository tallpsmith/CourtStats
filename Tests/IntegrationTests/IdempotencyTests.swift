import XCTest
@testable import CourtStatsCore

final class IdempotencyTests: XCTestCase {

    private func loadFixture(_ name: String) throws -> Data {
        let bundle = Bundle.module
        guard let url = bundle.url(forResource: name, withExtension: nil, subdirectory: "Fixtures") else {
            XCTFail("Missing fixture: \(name)")
            return Data()
        }
        return try Data(contentsOf: url)
    }

    func testProcessingOutputTwiceProducesIdenticalResult() throws {
        let inputData = try loadFixture("basic-scoring.fcpxml")
        let pipeline = ProcessingPipeline(configuration: .init(
            homeName: "Wildcats",
            awayName: "Eagles"
        ))

        let firstResult = try pipeline.process(inputData)
        let secondResult = try pipeline.process(firstResult.outputData)

        let firstOutput = normalizeXML(String(data: firstResult.outputData, encoding: .utf8) ?? "")
        let secondOutput = normalizeXML(String(data: secondResult.outputData, encoding: .utf8) ?? "")

        XCTAssertEqual(firstOutput, secondOutput, "Processing output twice should produce identical results")
        XCTAssertEqual(firstResult.overlaysGenerated, secondResult.overlaysGenerated,
                       "Same number of overlays on second pass")
    }

    /// Normalize XML whitespace for comparison — strip leading/trailing whitespace per line.
    private func normalizeXML(_ xml: String) -> String {
        xml.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }
}
