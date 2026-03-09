import Foundation

#if canImport(FoundationXML)
import FoundationXML
#endif

/// Reads FCPXML data and extracts raw marker information.
public struct FCPXMLReader {

    /// Extract all markers from FCPXML data, ordered by document position.
    public static func readMarkers(from xmlData: Data) throws -> [RawMarker] {
        let document = try XMLDocument(data: xmlData)
        let markerNodes = try document.nodes(forXPath: "//marker")

        var markers: [RawMarker] = []

        for (index, node) in markerNodes.enumerated() {
            guard let element = node as? XMLElement else { continue }

            guard let marker = extractMarker(from: element, atIndex: index) else {
                continue
            }
            markers.append(marker)
        }

        return markers
    }

    /// Parse a rational time string like "90s" or "43703/29s" into seconds.
    public static func parseRationalTime(_ value: String) -> TimeInterval? {
        guard value.hasSuffix("s") else { return nil }

        let numericPart = String(value.dropLast())
        guard !numericPart.isEmpty else { return nil }

        if let slashIndex = numericPart.firstIndex(of: "/") {
            let numeratorStr = String(numericPart[numericPart.startIndex..<slashIndex])
            let denominatorStr = String(numericPart[numericPart.index(after: slashIndex)...])

            guard let numerator = Double(numeratorStr),
                  let denominator = Double(denominatorStr),
                  denominator != 0 else {
                return nil
            }
            return numerator / denominator
        }

        return Double(numericPart)
    }

    // MARK: - Private

    private static func extractMarker(from element: XMLElement, atIndex index: Int) -> RawMarker? {
        guard let value = element.attribute(forName: "value")?.stringValue,
              let startStr = element.attribute(forName: "start")?.stringValue,
              let durationStr = element.attribute(forName: "duration")?.stringValue,
              let timecode = parseRationalTime(startStr),
              let duration = parseRationalTime(durationStr) else {
            return nil
        }

        let clipOffset = resolveClipOffset(for: element)

        return RawMarker(
            value: value,
            timecode: timecode,
            duration: duration,
            markerIndex: index,
            clipOffset: clipOffset
        )
    }

    /// Walk up to the parent clip element and read its offset attribute.
    private static func resolveClipOffset(for markerElement: XMLElement) -> TimeInterval {
        guard let parent = markerElement.parent as? XMLElement,
              let offsetStr = parent.attribute(forName: "offset")?.stringValue,
              let offset = parseRationalTime(offsetStr) else {
            return 0.0
        }
        return offset
    }
}
