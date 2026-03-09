import Foundation

#if canImport(FoundationXML)
import FoundationXML
#endif

/// Writes modified FCPXML with score ticker titles and marker annotations.
public struct FCPXMLWriter {

    /// Modify an FCPXML document: strip old CS titles, insert new ones, annotate markers, ensure effect resource exists.
    public static func write(
        document: XMLDocument,
        titles: [XMLElement],
        markerAnnotations: [(markerIndex: Int, annotation: MarkerAnnotation)],
        effectName: String,
        effectRef: String
    ) throws -> Data {
        stripExistingCSTitles(from: document)
        insertTitles(titles, into: document)
        ensureEffectResource(in: document, effectRef: effectRef, effectName: effectName)
        applyMarkerAnnotations(markerAnnotations, to: document)
        return document.xmlData(options: [.nodePrettyPrint])
    }

    // MARK: - Private

    /// Remove any <title> on lane 99 whose name starts with "[CS]".
    private static func stripExistingCSTitles(from document: XMLDocument) {
        guard let spines = try? document.nodes(forXPath: "//spine") else { return }

        for spine in spines {
            guard let spineElement = spine as? XMLElement else { continue }
            removeCSTitleChildren(from: spineElement)
        }
    }

    private static func removeCSTitleChildren(from spine: XMLElement) {
        // Collect indices in reverse so removal doesn't shift remaining indices
        var indicesToRemove: [Int] = []

        for i in 0..<(spine.childCount) {
            guard let child = spine.children?[i] as? XMLElement,
                  child.name == "title",
                  isCSTitleOnLane99(child) else {
                continue
            }
            indicesToRemove.append(i)
        }

        for index in indicesToRemove.reversed() {
            spine.removeChild(at: index)
        }
    }

    private static func isCSTitleOnLane99(_ element: XMLElement) -> Bool {
        let name = element.attribute(forName: "name")?.stringValue ?? ""
        let lane = element.attribute(forName: "lane")?.stringValue ?? ""
        return name.hasPrefix("[CS]") && lane == "99"
    }

    /// Append new title elements to the first spine found.
    private static func insertTitles(_ titles: [XMLElement], into document: XMLDocument) {
        guard !titles.isEmpty,
              let spine = (try? document.nodes(forXPath: "//spine"))?.first as? XMLElement else {
            return
        }

        for title in titles {
            spine.addChild(title)
        }
    }

    /// Add an <effect> element to <resources> if one with the given ID doesn't already exist.
    private static func ensureEffectResource(in document: XMLDocument, effectRef: String, effectName: String) {
        let existingEffects = try? document.nodes(forXPath: "//effect[@id='\(effectRef)']")
        if let existing = existingEffects, !existing.isEmpty { return }

        guard let resources = (try? document.nodes(forXPath: "//resources"))?.first as? XMLElement else {
            return
        }

        let effect = XMLElement(name: "effect")
        effect.addAttribute(XMLNode.attribute(withName: "id", stringValue: effectRef) as! XMLNode)
        effect.addAttribute(XMLNode.attribute(withName: "name", stringValue: effectName) as! XMLNode)
        resources.addChild(effect)
    }

    /// Update marker values with annotation suffixes where appropriate.
    private static func applyMarkerAnnotations(
        _ annotations: [(markerIndex: Int, annotation: MarkerAnnotation)],
        to document: XMLDocument
    ) {
        guard !annotations.isEmpty else { return }
        guard let markerNodes = try? document.nodes(forXPath: "//marker") else { return }

        for (markerIndex, annotation) in annotations {
            guard markerIndex < markerNodes.count,
                  let element = markerNodes[markerIndex] as? XMLElement else {
                continue
            }
            applyAnnotationSuffix(annotation, to: element)
        }
    }

    private static func applyAnnotationSuffix(_ annotation: MarkerAnnotation, to marker: XMLElement) {
        guard let suffix = annotationSuffix(for: annotation) else { return }

        let currentValue = marker.attribute(forName: "value")?.stringValue ?? ""
        let strippedValue = MarkerParser.stripAnnotations(currentValue)
        let newValue = "\(strippedValue) \(suffix)"

        if let attr = marker.attribute(forName: "value") {
            attr.stringValue = newValue
        }
    }

    private static func annotationSuffix(for annotation: MarkerAnnotation) -> String? {
        switch annotation {
        case .invalid: return "[CS:INVALID]"
        case .warn: return "[CS:WARN]"
        case .valid, .ignored: return nil
        }
    }
}
