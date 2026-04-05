import XCTest
@testable import SpoofTrap

@MainActor
final class ModsManagerTests: XCTestCase {

    var manager: ModsManager!

    override func setUp() {
        super.setUp()
        manager = ModsManager()

        // Reset installed mods for test predictability.
        manager.installedMods = [
            InstalledMod(id: "1", categoryId: "death_sound", name: "Oof 1", isEnabled: false, isBuiltIn: true, originalBackedUp: false),
            InstalledMod(id: "2", categoryId: "death_sound", name: "Oof 2", isEnabled: false, isBuiltIn: true, originalBackedUp: false),
            InstalledMod(id: "3", categoryId: "cursor", name: "Cursor 1", isEnabled: true, isBuiltIn: true, originalBackedUp: false)
        ]
    }

    override func tearDown() {
        manager = nil
        super.tearDown()
    }

    func testToggleModEnablesModAndDisablesOthersInCategory() {
        // Arrange
        let modToEnable = manager.installedMods[0]

        // Ensure initial state
        XCTAssertFalse(manager.installedMods[0].isEnabled)
        XCTAssertFalse(manager.installedMods[1].isEnabled)
        XCTAssertTrue(manager.installedMods[2].isEnabled)

        // Act
        manager.toggleMod(modToEnable)

        // Assert
        XCTAssertTrue(manager.installedMods[0].isEnabled, "The mod should be enabled")
        XCTAssertFalse(manager.installedMods[1].isEnabled, "Other mods in the same category should be disabled")
        XCTAssertTrue(manager.installedMods[2].isEnabled, "Mods in other categories should not be affected")

        // Act again to enable the other mod in the same category
        let otherModToEnable = manager.installedMods[1]
        manager.toggleMod(otherModToEnable)

        // Assert
        XCTAssertFalse(manager.installedMods[0].isEnabled, "The first mod should now be disabled")
        XCTAssertTrue(manager.installedMods[1].isEnabled, "The second mod should be enabled")
        XCTAssertTrue(manager.installedMods[2].isEnabled, "Mods in other categories should not be affected")
    }

    func testToggleModDisablesAlreadyEnabledMod() {
        // Arrange
        let modToDisable = manager.installedMods[2]
        XCTAssertTrue(manager.installedMods[2].isEnabled)

        // Act
        manager.toggleMod(modToDisable)

        // Assert
        XCTAssertFalse(manager.installedMods[2].isEnabled, "The mod should be disabled")
    }

    func testToggleModWithNonExistentModDoesNothing() {
        // Arrange
        let nonExistentMod = InstalledMod(id: "999", categoryId: "death_sound", name: "Ghost Mod", isEnabled: false, isBuiltIn: true, originalBackedUp: false)
        let initialModCount = manager.installedMods.count

        // Act
        manager.toggleMod(nonExistentMod)

        // Assert
        XCTAssertEqual(manager.installedMods.count, initialModCount, "Installed mods count should not change")
        XCTAssertFalse(manager.installedMods[0].isEnabled)
        XCTAssertFalse(manager.installedMods[1].isEnabled)
        XCTAssertTrue(manager.installedMods[2].isEnabled)
    }
}
