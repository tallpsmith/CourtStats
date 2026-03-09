import Foundation

#if canImport(FoundationXML)
import FoundationXML
#endif

/// Orchestrates the full processing pipeline:
/// read FCPXML → parse markers → dispatch events → project → render → write output.
public struct ProcessingPipeline {

    public struct Result: Sendable {
        public let outputData: Data
        public let totalMarkers: Int
        public let validMarkers: Int
        public let invalidMarkers: Int
        public let warningMarkers: Int
        public let ignoredMarkers: Int
        public let overlaysGenerated: Int
        public let hasWarnings: Bool
    }

    public struct Configuration: Sendable {
        public let homeName: String
        public let awayName: String
        public let titleTemplateName: String

        public init(
            homeName: String = "Home",
            awayName: String = "Away",
            titleTemplateName: String = "Basic Title"
        ) {
            self.homeName = homeName
            self.awayName = awayName
            self.titleTemplateName = titleTemplateName
        }
    }

    private let configuration: Configuration

    public init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
    }

    /// Process FCPXML data through the full pipeline.
    public func process(_ inputData: Data) throws -> Result {
        let document = try XMLDocument(data: inputData)
        let rawMarkers = try FCPXMLReader.readMarkers(from: inputData)

        let parseResults = parseAllMarkers(rawMarkers)
        let events = extractValidEvents(from: parseResults)

        let scoreProjection = buildScoreProjection(from: events)
        let substitutionProjection = buildSubstitutionProjection(from: events)
        let endTimecode = determineEndTimecode(from: rawMarkers)

        let titles = renderScoreTitles(from: scoreProjection.snapshots, endTimecode: endTimecode)
        let markerAnnotations = buildAnnotations(from: parseResults, substitutionWarnings: substitutionProjection.warnings)

        let effectRef = "r_courtstats_title"
        let outputData = try FCPXMLWriter.write(
            document: document,
            titles: titles,
            markerAnnotations: markerAnnotations,
            effectName: configuration.titleTemplateName,
            effectRef: effectRef
        )

        let counts = countAnnotations(parseResults)

        return Result(
            outputData: outputData,
            totalMarkers: rawMarkers.count,
            validMarkers: counts.valid,
            invalidMarkers: counts.invalid,
            warningMarkers: counts.warn + substitutionProjection.warnings.count,
            ignoredMarkers: counts.ignored,
            overlaysGenerated: titles.count,
            hasWarnings: counts.invalid > 0 || counts.warn > 0 || !substitutionProjection.warnings.isEmpty
        )
    }

    // MARK: - Pipeline stages

    private func parseAllMarkers(_ rawMarkers: [RawMarker]) -> [(rawMarker: RawMarker, parseResult: MarkerParser.ParseResult)] {
        rawMarkers.map { marker in
            let result = MarkerParser.parse(
                markerValue: marker.value,
                timecode: marker.timecode,
                markerIndex: marker.markerIndex
            )
            return (marker, result)
        }
    }

    private func extractValidEvents(from parseResults: [(rawMarker: RawMarker, parseResult: MarkerParser.ParseResult)]) -> [GameEvent] {
        parseResults.compactMap { $0.parseResult.event }
    }

    private func buildScoreProjection(from events: [GameEvent]) -> ScoreProjection {
        let projection = ScoreProjection()
        for event in events {
            projection.handle(event)
        }
        return projection
    }

    private func buildSubstitutionProjection(from events: [GameEvent]) -> SubstitutionProjection {
        let projection = SubstitutionProjection()
        for event in events {
            projection.handle(event)
        }
        if let lastTimecode = events.last?.timecode {
            projection.finalise(atTimecode: lastTimecode)
        }
        return projection
    }

    private func renderScoreTitles(from snapshots: [ScoreSnapshot], endTimecode: TimeInterval) -> [XMLElement] {
        let renderer = ScoreTickerRenderer(
            homeName: configuration.homeName,
            awayName: configuration.awayName,
            titleTemplateRef: "r_courtstats_title"
        )
        return renderer.renderTitles(from: snapshots, endTimecode: endTimecode)
    }

    private func determineEndTimecode(from rawMarkers: [RawMarker]) -> TimeInterval {
        rawMarkers.map { $0.timecode }.max() ?? 0.0
    }

    private func buildAnnotations(
        from parseResults: [(rawMarker: RawMarker, parseResult: MarkerParser.ParseResult)],
        substitutionWarnings: [SubstitutionProjection.Warning]
    ) -> [(markerIndex: Int, annotation: MarkerAnnotation)] {
        var annotations: [(markerIndex: Int, annotation: MarkerAnnotation)] = []

        for (rawMarker, parseResult) in parseResults {
            if parseResult.annotation == .invalid {
                annotations.append((rawMarker.markerIndex, .invalid))
            }
        }

        for warning in substitutionWarnings {
            annotations.append((warning.markerIndex, .warn))
        }

        return annotations
    }

    private func countAnnotations(_ parseResults: [(rawMarker: RawMarker, parseResult: MarkerParser.ParseResult)]) -> (valid: Int, invalid: Int, warn: Int, ignored: Int) {
        var valid = 0, invalid = 0, warn = 0, ignored = 0
        for (_, result) in parseResults {
            switch result.annotation {
            case .valid: valid += 1
            case .invalid: invalid += 1
            case .warn: warn += 1
            case .ignored: ignored += 1
            }
        }
        return (valid, invalid, warn, ignored)
    }
}
