import XCTest
@testable import SpoofTrap

@MainActor
final class GameHistoryManagerTests: XCTestCase {

    var sut: GameHistoryManager!

    override func setUpWithError() throws {
        // Run before each test
        sut = GameHistoryManager()
        sut.clearHistory()
    }

    override func tearDownWithError() throws {
        // Run after each test
        sut.clearHistory()
        sut = nil
    }

    func testRecordSession_LimitsTo100Sessions() {
        // Arrange
        let initialCount = sut.sessions.count
        XCTAssertEqual(initialCount, 0, "Initial sessions count should be 0")

        // Act: insert 105 sessions
        let totalSessionsToInsert = 105
        for i in 1...totalSessionsToInsert {
            sut.recordSession(
                gameName: "Game \(i)",
                placeId: "Place \(i)",
                serverRegion: "Region \(i)",
                preset: "Preset \(i)",
                duration: TimeInterval(i)
            )
        }

        // Assert: count should be limited to 100
        XCTAssertEqual(sut.sessions.count, 100, "Sessions count should not exceed 100")

        // Assert: newest items are kept (e.g. Game 105 should be the first item)
        // Since new items are inserted at 0, the first item should be the 105th inserted.
        XCTAssertEqual(sut.sessions.first?.gameName, "Game 105", "The most recently inserted session should be at index 0")

        // The last item (index 99) should be the 6th inserted item (Game 6) because 1-5 have been discarded.
        XCTAssertEqual(sut.sessions.last?.gameName, "Game 6", "The oldest session should be discarded and the 100th newest kept at the end of the list")
    }

}
