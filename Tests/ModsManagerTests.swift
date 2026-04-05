import XCTest
@testable import SpoofTrap

final class MockFileManager: FileManager {
    var removedPaths: [String] = []

    // We mock applicationSupportDirectory so saveSettings() doesn't overwrite real user files
    var mockAppSupportDir: URL

    init(mockAppSupportDir: URL) {
        self.mockAppSupportDir = mockAppSupportDir
        super.init()
    }

    override func urls(for directory: FileManager.SearchPathDirectory, in domainMask: FileManager.SearchPathDomainMask) -> [URL] {
        if directory == .applicationSupportDirectory {
            return [mockAppSupportDir]
        }
        return super.urls(for: directory, in: domainMask)
    }

    override func removeItem(atPath path: String) throws {
        removedPaths.append(path)
    }

    // We override these so we can safely fake directory creation and encoding
    override func createDirectory(at url: URL, withIntermediateDirectories createIntermediates: Bool, attributes: [FileAttributeKey : Any]? = nil) throws {
        // do nothing
    }
}

@MainActor
final class ModsManagerTests: XCTestCase {
    var modsManager: ModsManager!
    var mockFileManager: MockFileManager!
    var tempDir: URL!

    override func setUpWithError() throws {
        tempDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        mockFileManager = MockFileManager(mockAppSupportDir: tempDir)
        modsManager = ModsManager(fileManager: mockFileManager)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDir)
        modsManager = nil
        mockFileManager = nil
    }

    func testRemoveMod_CustomMod_DeletesFileAndRemovesFromList() throws {
        // Arrange
        let customPath = "/fake/path/to/mod.png"
        let mod = InstalledMod(
            id: "test-id-1",
            categoryId: "cursor",
            name: "Test Cursor",
            isEnabled: false,
            isBuiltIn: false,
            customFilePath: customPath,
            originalBackedUp: false
        )
        modsManager.installedMods = [mod]

        // Act
        modsManager.removeMod(mod)

        // Assert
        XCTAssertTrue(mockFileManager.removedPaths.contains(customPath), "The custom mod file should be deleted via FileManager.")
        XCTAssertTrue(modsManager.installedMods.isEmpty, "The mod should be removed from the installedMods list.")
    }

    func testRemoveMod_BuiltInMod_DoesNothing() throws {
        // Arrange
        let mod = InstalledMod(
            id: "test-id-2",
            categoryId: "cursor",
            name: "Built-in Cursor",
            isEnabled: false,
            isBuiltIn: true,
            customFilePath: nil,
            originalBackedUp: false
        )
        modsManager.installedMods = [mod]

        // Act
        modsManager.removeMod(mod)

        // Assert
        XCTAssertTrue(mockFileManager.removedPaths.isEmpty, "No files should be deleted for a built-in mod.")
        XCTAssertEqual(modsManager.installedMods.count, 1, "The built-in mod should not be removed from the list.")
    }
}
