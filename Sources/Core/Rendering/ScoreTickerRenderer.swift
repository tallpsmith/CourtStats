import Foundation

#if canImport(FoundationXML)
import FoundationXML
#endif

/// Generates FCPXML title elements that display a running score ticker overlay.
public struct ScoreTickerRenderer {

    public let homeName: String
    public let awayName: String
    public let titleTemplateRef: String

    public init(homeName: String, awayName: String, titleTemplateRef: String) {
        self.homeName = homeName
        self.awayName = awayName
        self.titleTemplateRef = titleTemplateRef
    }

    /// Build title XMLElements from score snapshots, each spanning until the next snapshot (or endTimecode).
    public func renderTitles(from snapshots: [ScoreSnapshot], endTimecode: TimeInterval) -> [XMLElement] {
        guard !snapshots.isEmpty else { return [] }

        return snapshots.enumerated().map { index, snapshot in
            let nextTimecode = nextSnapshotTimecode(after: index, in: snapshots, endTimecode: endTimecode)
            let duration = nextTimecode - snapshot.timecode
            return buildTitleElement(for: snapshot, duration: duration)
        }
    }

    // MARK: - Private

    private func nextSnapshotTimecode(after index: Int, in snapshots: [ScoreSnapshot], endTimecode: TimeInterval) -> TimeInterval {
        let nextIndex = index + 1
        if nextIndex < snapshots.count {
            return snapshots[nextIndex].timecode
        }
        return endTimecode
    }

    private func buildTitleElement(for snapshot: ScoreSnapshot, duration: TimeInterval) -> XMLElement {
        let title = XMLElement(name: "title")

        title.addAttribute(makeAttribute("ref", titleTemplateRef))
        title.addAttribute(makeAttribute("name", "[CS] Score"))
        title.addAttribute(makeAttribute("offset", formatTime(snapshot.timecode)))
        title.addAttribute(makeAttribute("duration", formatTime(duration)))
        title.addAttribute(makeAttribute("lane", "99"))

        let textElement = buildTextElement(for: snapshot)
        title.addChild(textElement)

        return title
    }

    private func buildTextElement(for snapshot: ScoreSnapshot) -> XMLElement {
        let scoreText = "\(homeName) \(snapshot.homeScore) \u{2014} \(awayName) \(snapshot.opponentScore)"

        let textStyle = XMLElement(name: "text-style", stringValue: scoreText)
        textStyle.addAttribute(makeAttribute("ref", "ts1"))

        let textElement = XMLElement(name: "text")
        textElement.addChild(textStyle)
        return textElement
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let intSeconds = Int(seconds)
        if Double(intSeconds) == seconds {
            return "\(intSeconds)s"
        }
        return "\(seconds)s"
    }

    private func makeAttribute(_ name: String, _ value: String) -> XMLNode {
        XMLNode.attribute(withName: name, stringValue: value) as! XMLNode
    }
}
