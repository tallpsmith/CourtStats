import ArgumentParser
import CourtStatsCore
import Foundation

struct ProcessCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "process",
        abstract: "Process an FCPXML file: parse stat markers, compute projections, generate score ticker overlays."
    )

    @Argument(help: "Input FCPXML file path.")
    var input: String

    @Option(name: .shortAndLong, help: "Output FCPXML file path.")
    var output: String

    @Option(name: .long, help: "Home team name for score ticker.")
    var homeName: String = "Home"

    @Option(name: .long, help: "Away team name for score ticker.")
    var awayName: String = "Away"

    @Option(name: .long, help: "Motion title template name.")
    var titleTemplate: String = "Basic Title"

    mutating func run() throws {
        let inputURL = URL(fileURLWithPath: input)
        let outputURL = URL(fileURLWithPath: output)

        guard FileManager.default.fileExists(atPath: inputURL.path) else {
            printDiagnostic("Error: Cannot read file '\(input)': No such file or directory")
            throw ExitCode(1)
        }

        let inputData: Data
        do {
            inputData = try Data(contentsOf: inputURL)
        } catch {
            printDiagnostic("Error: Cannot read file '\(input)': \(error.localizedDescription)")
            throw ExitCode(1)
        }

        printDiagnostic("Processing: \(input)")

        let configuration = ProcessingPipeline.Configuration(
            homeName: homeName,
            awayName: awayName,
            titleTemplateName: titleTemplate
        )
        let pipeline = ProcessingPipeline(configuration: configuration)

        let result: ProcessingPipeline.Result
        do {
            result = try pipeline.process(inputData)
        } catch {
            printDiagnostic("Error: File '\(input)' is not valid FCPXML")
            throw ExitCode(1)
        }

        printDiagnostic("Parsed \(result.totalMarkers) markers (\(result.validMarkers) valid, \(result.invalidMarkers) invalid, \(result.warningMarkers) warning, \(result.ignoredMarkers) non-CS ignored)")
        printDiagnostic("Generated \(result.overlaysGenerated) score ticker overlays")

        try result.outputData.write(to: outputURL)
        printDiagnostic("Output written to: \(output)")

        if result.hasWarnings {
            throw ExitCode(2)
        }
    }

    private func printDiagnostic(_ message: String) {
        FileHandle.standardError.write(Data((message + "\n").utf8))
    }
}
