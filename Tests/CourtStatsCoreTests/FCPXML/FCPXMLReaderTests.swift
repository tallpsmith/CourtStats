import XCTest
@testable import CourtStatsCore

final class FCPXMLReaderTests: XCTestCase {

    // MARK: - Rational Time Parsing

    func testParseWholeSecondsTimecode() {
        let result = FCPXMLReader.parseRationalTime("90s")
        XCTAssertEqual(result!, 90.0, accuracy: 0.001)
    }

    func testParseFractionalTimecode() {
        let result = FCPXMLReader.parseRationalTime("43703/29s")
        XCTAssertEqual(result!, 43703.0 / 29.0, accuracy: 0.0001)
    }

    func testParseZeroTimecode() {
        let result = FCPXMLReader.parseRationalTime("0s")
        XCTAssertEqual(result!, 0.0, accuracy: 0.001)
    }

    func testParseInvalidTimecodeReturnsNil() {
        XCTAssertNil(FCPXMLReader.parseRationalTime("garbage"))
        XCTAssertNil(FCPXMLReader.parseRationalTime(""))
    }

    // MARK: - Marker Extraction

    func testExtractMarkersFromMinimalFCPXML() throws {
        let xml = minimalFCPXML(markers: [
            (start: "90s", duration: "1s", value: "CS:T:7:PTS2"),
            (start: "165s", duration: "1s", value: "CS:O:12:PTS3"),
        ], clipOffset: "0s")

        let markers = try FCPXMLReader.readMarkers(from: Data(xml.utf8))

        XCTAssertEqual(markers.count, 2)
        XCTAssertEqual(markers[0].value, "CS:T:7:PTS2")
        XCTAssertEqual(markers[0].timecode, 90.0, accuracy: 0.001)
        XCTAssertEqual(markers[1].value, "CS:O:12:PTS3")
        XCTAssertEqual(markers[1].timecode, 165.0, accuracy: 0.001)
    }

    func testMarkerDurationParsedCorrectly() throws {
        let xml = minimalFCPXML(markers: [
            (start: "90s", duration: "2s", value: "CS:T:7:PTS2"),
        ], clipOffset: "0s")

        let markers = try FCPXMLReader.readMarkers(from: Data(xml.utf8))

        XCTAssertEqual(markers[0].duration, 2.0, accuracy: 0.001)
    }

    func testSequentialMarkerIndices() throws {
        let xml = minimalFCPXML(markers: [
            (start: "10s", duration: "1s", value: "CS:T:1:PTS2"),
            (start: "20s", duration: "1s", value: "CS:T:2:PTS3"),
            (start: "30s", duration: "1s", value: "CS:O:5:REB"),
        ], clipOffset: "0s")

        let markers = try FCPXMLReader.readMarkers(from: Data(xml.utf8))

        XCTAssertEqual(markers[0].markerIndex, 0)
        XCTAssertEqual(markers[1].markerIndex, 1)
        XCTAssertEqual(markers[2].markerIndex, 2)
    }

    func testClipOffsetCaptured() throws {
        let xml = minimalFCPXML(markers: [
            (start: "90s", duration: "1s", value: "CS:T:7:PTS2"),
        ], clipOffset: "3600/30s")

        let markers = try FCPXMLReader.readMarkers(from: Data(xml.utf8))

        XCTAssertEqual(markers[0].clipOffset, 3600.0 / 30.0, accuracy: 0.001)
    }

    func testEmptyFCPXMLReturnsNoMarkers() throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources/>
            <library>
                <event>
                    <project>
                        <sequence>
                            <spine>
                                <asset-clip ref="r1" offset="0s" duration="3600s"/>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """

        let markers = try FCPXMLReader.readMarkers(from: Data(xml.utf8))
        XCTAssertTrue(markers.isEmpty)
    }

    func testMultipleAssetClipsEachWithMarkers() throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources/>
            <library>
                <event>
                    <project>
                        <sequence>
                            <spine>
                                <asset-clip ref="r1" offset="0s" duration="1800s">
                                    <marker start="10s" duration="1s" value="CS:T:1:PTS2"/>
                                </asset-clip>
                                <asset-clip ref="r2" offset="1800s" duration="1800s">
                                    <marker start="5s" duration="1s" value="CS:O:3:PTS3"/>
                                </asset-clip>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """

        let markers = try FCPXMLReader.readMarkers(from: Data(xml.utf8))

        XCTAssertEqual(markers.count, 2)
        XCTAssertEqual(markers[0].clipOffset, 0.0)
        XCTAssertEqual(markers[1].clipOffset, 1800.0)
        XCTAssertEqual(markers[0].markerIndex, 0)
        XCTAssertEqual(markers[1].markerIndex, 1)
    }

    func testRationalTimecodesInMarkers() throws {
        let xml = minimalFCPXML(markers: [
            (start: "43703/29s", duration: "100/29s", value: "CS:T:7:FT"),
        ], clipOffset: "0s")

        let markers = try FCPXMLReader.readMarkers(from: Data(xml.utf8))

        XCTAssertEqual(markers[0].timecode, 43703.0 / 29.0, accuracy: 0.0001)
        XCTAssertEqual(markers[0].duration, 100.0 / 29.0, accuracy: 0.0001)
    }

    func testInvalidXMLThrows() {
        let badXML = Data("this is not xml".utf8)
        XCTAssertThrowsError(try FCPXMLReader.readMarkers(from: badXML))
    }

    // MARK: - Helpers

    private func minimalFCPXML(
        markers: [(start: String, duration: String, value: String)],
        clipOffset: String
    ) -> String {
        let markerElements = markers.map { marker in
            """
                                    <marker start="\(marker.start)" duration="\(marker.duration)" value="\(marker.value)"/>
            """
        }.joined(separator: "\n")

        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources/>
            <library>
                <event>
                    <project>
                        <sequence>
                            <spine>
                                <asset-clip ref="r1" offset="\(clipOffset)" duration="3600s">
        \(markerElements)
                                </asset-clip>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """
    }
}
