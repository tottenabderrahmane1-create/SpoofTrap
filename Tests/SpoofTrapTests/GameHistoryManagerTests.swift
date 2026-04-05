import XCTest
@testable import SpoofTrap

@MainActor
final class GameHistoryManagerTests: XCTestCase {

    var sut: GameHistoryManager!

    override func setUp() {
        super.setUp()
        sut = GameHistoryManager()
        // Ensure starting from a clean state
        sut.clearHistory()
    }

    override func tearDown() {
        sut.clearHistory()
        sut = nil
        super.tearDown()
    }

    func testClearHistoryWithMultipleSessions() {
        // Arrange
        sut.recordSession(gameName: "Game 1", placeId: "123", serverRegion: "US", preset: "Preset 1", duration: 10)
        sut.recordSession(gameName: "Game 2", placeId: "456", serverRegion: "EU", preset: "Preset 2", duration: 20)

        XCTAssertEqual(sut.sessions.count, 2, "Sessions should have been recorded")

        // Act
        sut.clearHistory()

        // Assert
        XCTAssertTrue(sut.sessions.isEmpty, "clearHistory should remove all sessions")
    }

    func testClearHistoryWhenAlreadyEmpty() {
        // Arrange (Ensure it is empty)
        sut.clearHistory()
        XCTAssertTrue(sut.sessions.isEmpty, "Initial state should be empty")

        // Act
        sut.clearHistory()

        // Assert
        XCTAssertTrue(sut.sessions.isEmpty, "clearHistory on an empty manager should maintain an empty state")
    }

    func testClearHistoryPersistsState() {
        // Arrange
        sut.recordSession(gameName: "Persistent Game", placeId: "789", serverRegion: "Asia", preset: "Preset 3", duration: 30)
        XCTAssertEqual(sut.sessions.count, 1, "Session should be recorded")

        // Act
        sut.clearHistory()

        // Assert
        XCTAssertTrue(sut.sessions.isEmpty, "Memory state should be empty")

        // Verify Persistence
        // Assuming GameHistoryManager loads from persistence on init
        let newInstance = GameHistoryManager()
        XCTAssertTrue(newInstance.sessions.isEmpty, "Persistent storage should reflect the empty state after clearHistory is called")
    }
}
