import XCTest
@testable import CourtStatsCore

final class PlusMinusProjectionTests: XCTestCase {

    private func makeEvent(
        team: Team = .home,
        player: Int = 7,
        stat: StatType = .fieldGoal2pt,
        timecode: TimeInterval = 0,
        index: Int = 0
    ) -> GameEvent {
        GameEvent(team: team, playerNumber: player, statType: stat, timecode: timecode, markerIndex: index)
    }

    // MARK: - On-court players get +/- for scoring

    func testOnCourtPlayersGetPositivePlusMinusForHomeScore() {
        let subProjection = SubstitutionProjection()
        let projection = PlusMinusProjection(substitutionProjection: subProjection)

        subProjection.handle(makeEvent(team: .home, player: 7, stat: .substitutionOn, index: 0))
        subProjection.handle(makeEvent(team: .home, player: 11, stat: .substitutionOn, index: 1))

        let scoringEvent = makeEvent(team: .home, player: 7, stat: .fieldGoal2pt, timecode: 100, index: 2)
        projection.handle(scoringEvent)

        XCTAssertEqual(projection.plusMinus(for: PlayerKey(team: .home, playerNumber: 7)), 2)
        XCTAssertEqual(projection.plusMinus(for: PlayerKey(team: .home, playerNumber: 11)), 2)
    }

    func testOnCourtPlayersGetNegativePlusMinusForOpponentScore() {
        let subProjection = SubstitutionProjection()
        let projection = PlusMinusProjection(substitutionProjection: subProjection)

        subProjection.handle(makeEvent(team: .home, player: 7, stat: .substitutionOn, index: 0))

        let opponentScore = makeEvent(team: .opponent, player: 12, stat: .fieldGoal3pt, timecode: 100, index: 1)
        projection.handle(opponentScore)

        XCTAssertEqual(projection.plusMinus(for: PlayerKey(team: .home, playerNumber: 7)), -3)
    }

    // MARK: - Off-court players unaffected

    func testOffCourtPlayersUnaffected() {
        let subProjection = SubstitutionProjection()
        let projection = PlusMinusProjection(substitutionProjection: subProjection)

        subProjection.handle(makeEvent(team: .home, player: 7, stat: .substitutionOn, index: 0))
        // Player 11 is NOT on court

        let scoringEvent = makeEvent(team: .home, player: 7, stat: .fieldGoal2pt, timecode: 100, index: 1)
        projection.handle(scoringEvent)

        XCTAssertEqual(projection.plusMinus(for: PlayerKey(team: .home, playerNumber: 11)), 0)
    }

    // MARK: - Opponent on-court players

    func testOpponentOnCourtPlayersGetCorrectPlusMinus() {
        let subProjection = SubstitutionProjection()
        let projection = PlusMinusProjection(substitutionProjection: subProjection)

        subProjection.handle(makeEvent(team: .opponent, player: 12, stat: .substitutionOn, index: 0))

        let homeScore = makeEvent(team: .home, player: 7, stat: .fieldGoal2pt, timecode: 100, index: 1)
        projection.handle(homeScore)

        XCTAssertEqual(projection.plusMinus(for: PlayerKey(team: .opponent, playerNumber: 12)), -2)
    }

    // MARK: - Missed shots don't affect +/-

    func testMissedShotsDoNotAffectPlusMinus() {
        let subProjection = SubstitutionProjection()
        let projection = PlusMinusProjection(substitutionProjection: subProjection)

        subProjection.handle(makeEvent(team: .home, player: 7, stat: .substitutionOn, index: 0))

        let miss = makeEvent(team: .home, player: 7, stat: .missedFieldGoal2, timecode: 100, index: 1)
        projection.handle(miss)

        XCTAssertEqual(projection.plusMinus(for: PlayerKey(team: .home, playerNumber: 7)), 0)
    }

    // MARK: - Non-scoring events don't affect +/-

    func testNonScoringEventsDoNotAffectPlusMinus() {
        let subProjection = SubstitutionProjection()
        let projection = PlusMinusProjection(substitutionProjection: subProjection)

        subProjection.handle(makeEvent(team: .home, player: 7, stat: .substitutionOn, index: 0))
        projection.handle(makeEvent(team: .home, player: 7, stat: .rebound, timecode: 100, index: 1))

        XCTAssertEqual(projection.plusMinus(for: PlayerKey(team: .home, playerNumber: 7)), 0)
    }

    // MARK: - Reset

    func testResetClearsState() {
        let subProjection = SubstitutionProjection()
        let projection = PlusMinusProjection(substitutionProjection: subProjection)

        subProjection.handle(makeEvent(team: .home, player: 7, stat: .substitutionOn, index: 0))
        projection.handle(makeEvent(team: .home, player: 7, stat: .fieldGoal2pt, timecode: 100, index: 1))
        projection.reset()

        XCTAssertEqual(projection.plusMinus(for: PlayerKey(team: .home, playerNumber: 7)), 0)
    }
}
