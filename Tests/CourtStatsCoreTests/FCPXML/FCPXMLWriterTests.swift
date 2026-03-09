import XCTest
@testable import CourtStatsCore

#if canImport(FoundationXML)
import FoundationXML
#endif

final class FCPXMLWriterTests: XCTestCase {

    // MARK: - Strip Existing CS Titles

    func testStripsExistingCSTitlesOnLane99() throws {
        let xml = fcpxmlWithExistingTitle()
        let document = try XMLDocument(data: Data(xml.utf8))

        let outputData = try FCPXMLWriter.write(
            document: document,
            titles: [],
            markerAnnotations: [],
            effectName: "Basic Title",
            effectRef: "r2"
        )

        let outputXML = String(data: outputData, encoding: .utf8)!
        XCTAssertFalse(outputXML.contains("[CS] Score"),
                        "Existing CS titles should be stripped")
    }

    func testPreservesNonCSTitles() throws {
        let xml = fcpxmlWithMixedTitles()
        let document = try XMLDocument(data: Data(xml.utf8))

        let outputData = try FCPXMLWriter.write(
            document: document,
            titles: [],
            markerAnnotations: [],
            effectName: "Basic Title",
            effectRef: "r2"
        )

        let outputXML = String(data: outputData, encoding: .utf8)!
        XCTAssertTrue(outputXML.contains("My Custom Title"),
                       "Non-CS titles should be preserved")
    }

    // MARK: - Insert New Titles

    func testInsertsTitleElementsIntoSpine() throws {
        let xml = minimalFCPXML()
        let document = try XMLDocument(data: Data(xml.utf8))

        let title = makeTitleElement(text: "Home 2 \u{2014} Away 0", offset: "90s", duration: "75s")

        let outputData = try FCPXMLWriter.write(
            document: document,
            titles: [title],
            markerAnnotations: [],
            effectName: "Basic Title",
            effectRef: "r2"
        )

        let outputXML = String(data: outputData, encoding: .utf8)!
        XCTAssertTrue(outputXML.contains("Home 2 \u{2014} Away 0"))
    }

    // MARK: - Effect Resource

    func testAddsEffectResourceIfNotPresent() throws {
        let xml = minimalFCPXML()
        let document = try XMLDocument(data: Data(xml.utf8))

        let outputData = try FCPXMLWriter.write(
            document: document,
            titles: [],
            markerAnnotations: [],
            effectName: "Basic Title",
            effectRef: "r2"
        )

        let outputDoc = try XMLDocument(data: outputData)
        let effects = try outputDoc.nodes(forXPath: "//effect[@id='r2']")
        XCTAssertEqual(effects.count, 1)
    }

    func testDoesNotDuplicateExistingEffectResource() throws {
        let xml = fcpxmlWithEffect()
        let document = try XMLDocument(data: Data(xml.utf8))

        let outputData = try FCPXMLWriter.write(
            document: document,
            titles: [],
            markerAnnotations: [],
            effectName: "Basic Title",
            effectRef: "r2"
        )

        let outputDoc = try XMLDocument(data: outputData)
        let effects = try outputDoc.nodes(forXPath: "//effect[@id='r2']")
        XCTAssertEqual(effects.count, 1, "Should not duplicate existing effect")
    }

    // MARK: - Marker Annotations

    func testAnnotatesMarkerWithInvalid() throws {
        let xml = fcpxmlWithMarkers()
        let document = try XMLDocument(data: Data(xml.utf8))

        let annotations: [(markerIndex: Int, annotation: MarkerAnnotation)] = [
            (markerIndex: 0, annotation: .invalid),
        ]

        let outputData = try FCPXMLWriter.write(
            document: document,
            titles: [],
            markerAnnotations: annotations,
            effectName: "Basic Title",
            effectRef: "r2"
        )

        let outputDoc = try XMLDocument(data: outputData)
        let markers = try outputDoc.nodes(forXPath: "//marker")
        let firstValue = (markers[0] as? XMLElement)?.attribute(forName: "value")?.stringValue
        XCTAssertEqual(firstValue, "CS:T:7:PTS2 [CS:INVALID]")
    }

    func testAnnotatesMarkerWithWarn() throws {
        let xml = fcpxmlWithMarkers()
        let document = try XMLDocument(data: Data(xml.utf8))

        let annotations: [(markerIndex: Int, annotation: MarkerAnnotation)] = [
            (markerIndex: 1, annotation: .warn),
        ]

        let outputData = try FCPXMLWriter.write(
            document: document,
            titles: [],
            markerAnnotations: annotations,
            effectName: "Basic Title",
            effectRef: "r2"
        )

        let outputDoc = try XMLDocument(data: outputData)
        let markers = try outputDoc.nodes(forXPath: "//marker")
        let secondValue = (markers[1] as? XMLElement)?.attribute(forName: "value")?.stringValue
        XCTAssertEqual(secondValue, "CS:O:12:PTS3 [CS:WARN]")
    }

    func testValidAndIgnoredAnnotationsLeaveMarkerUnchanged() throws {
        let xml = fcpxmlWithMarkers()
        let document = try XMLDocument(data: Data(xml.utf8))

        let annotations: [(markerIndex: Int, annotation: MarkerAnnotation)] = [
            (markerIndex: 0, annotation: .valid),
            (markerIndex: 1, annotation: .ignored),
        ]

        let outputData = try FCPXMLWriter.write(
            document: document,
            titles: [],
            markerAnnotations: annotations,
            effectName: "Basic Title",
            effectRef: "r2"
        )

        let outputDoc = try XMLDocument(data: outputData)
        let markers = try outputDoc.nodes(forXPath: "//marker")
        let firstValue = (markers[0] as? XMLElement)?.attribute(forName: "value")?.stringValue
        let secondValue = (markers[1] as? XMLElement)?.attribute(forName: "value")?.stringValue
        XCTAssertEqual(firstValue, "CS:T:7:PTS2")
        XCTAssertEqual(secondValue, "CS:O:12:PTS3")
    }

    // MARK: - Preserves Content

    func testPreservesClipsAndMarkers() throws {
        let xml = fcpxmlWithMarkers()
        let document = try XMLDocument(data: Data(xml.utf8))

        let outputData = try FCPXMLWriter.write(
            document: document,
            titles: [],
            markerAnnotations: [],
            effectName: "Basic Title",
            effectRef: "r2"
        )

        let outputDoc = try XMLDocument(data: outputData)
        let clips = try outputDoc.nodes(forXPath: "//asset-clip")
        XCTAssertEqual(clips.count, 1)

        let markers = try outputDoc.nodes(forXPath: "//marker")
        XCTAssertEqual(markers.count, 2)
    }

    // MARK: - Valid XML Output

    func testOutputIsValidXMLData() throws {
        let xml = minimalFCPXML()
        let document = try XMLDocument(data: Data(xml.utf8))

        let outputData = try FCPXMLWriter.write(
            document: document,
            titles: [],
            markerAnnotations: [],
            effectName: "Basic Title",
            effectRef: "r2"
        )

        XCTAssertFalse(outputData.isEmpty)
        // Verify it parses back as valid XML
        XCTAssertNoThrow(try XMLDocument(data: outputData))
    }

    // MARK: - Helpers

    private func minimalFCPXML() -> String {
        """
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
    }

    private func fcpxmlWithExistingTitle() -> String {
        """
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
                                <title ref="r2" name="[CS] Score" offset="90s" duration="75s" lane="99">
                                    <text><text-style ref="ts1">Home 2 — Away 0</text-style></text>
                                </title>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """
    }

    private func fcpxmlWithMixedTitles() -> String {
        """
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
                                <title ref="r2" name="[CS] Score" offset="90s" duration="75s" lane="99">
                                    <text><text-style ref="ts1">Home 2 — Away 0</text-style></text>
                                </title>
                                <title ref="r3" name="My Custom Title" offset="0s" duration="100s" lane="1">
                                    <text><text-style ref="ts2">Hello</text-style></text>
                                </title>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """
    }

    private func fcpxmlWithEffect() -> String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources>
                <effect id="r2" name="Basic Title" uid="test-uid"/>
            </resources>
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
    }

    private func fcpxmlWithMarkers() -> String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>
        <fcpxml version="1.11">
            <resources/>
            <library>
                <event>
                    <project>
                        <sequence>
                            <spine>
                                <asset-clip ref="r1" offset="0s" duration="3600s">
                                    <marker start="90s" duration="1s" value="CS:T:7:PTS2"/>
                                    <marker start="165s" duration="1s" value="CS:O:12:PTS3"/>
                                </asset-clip>
                            </spine>
                        </sequence>
                    </project>
                </event>
            </library>
        </fcpxml>
        """
    }

    private func makeTitleElement(text: String, offset: String, duration: String) -> XMLElement {
        let title = XMLElement(name: "title")
        title.addAttribute(XMLNode.attribute(withName: "ref", stringValue: "r2") as! XMLNode)
        title.addAttribute(XMLNode.attribute(withName: "name", stringValue: "[CS] Score") as! XMLNode)
        title.addAttribute(XMLNode.attribute(withName: "offset", stringValue: offset) as! XMLNode)
        title.addAttribute(XMLNode.attribute(withName: "duration", stringValue: duration) as! XMLNode)
        title.addAttribute(XMLNode.attribute(withName: "lane", stringValue: "99") as! XMLNode)

        let textElement = XMLElement(name: "text")
        let textStyle = XMLElement(name: "text-style", stringValue: text)
        textStyle.addAttribute(XMLNode.attribute(withName: "ref", stringValue: "ts1") as! XMLNode)
        textElement.addChild(textStyle)
        title.addChild(textElement)

        return title
    }
}
