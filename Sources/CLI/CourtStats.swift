import ArgumentParser

@main
struct CourtStats: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "courtstats",
        abstract: "Basketball stats processing engine for Final Cut Pro FCPXML.",
        version: "0.1.0",
        subcommands: [ProcessCommand.self]
    )
}
