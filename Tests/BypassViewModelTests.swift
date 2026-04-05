import XCTest
@testable import SpoofTrap

@MainActor
final class BypassViewModelTests: XCTestCase {

    var viewModel: BypassViewModel!

    override func setUp() {
        super.setUp()
        viewModel = BypassViewModel()
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    func testApplyPresetStable() {
        viewModel.applyPreset(.stable)

        XCTAssertEqual(viewModel.preset, .stable)
        XCTAssertEqual(viewModel.dnsHttpsURL, "https://1.1.1.1/dns-query")
        XCTAssertEqual(viewModel.httpsChunkSize, 1)
        XCTAssertTrue(viewModel.httpsDisorder)
        XCTAssertEqual(viewModel.appLaunchDelay, 0)
    }

    func testApplyPresetBalanced() {
        viewModel.applyPreset(.balanced)

        XCTAssertEqual(viewModel.preset, .balanced)
        XCTAssertEqual(viewModel.dnsHttpsURL, "https://1.1.1.1/dns-query")
        XCTAssertEqual(viewModel.httpsChunkSize, 2)
        XCTAssertTrue(viewModel.httpsDisorder)
        XCTAssertEqual(viewModel.appLaunchDelay, 0)
    }

    func testApplyPresetFast() {
        viewModel.applyPreset(.fast)

        XCTAssertEqual(viewModel.preset, .fast)
        XCTAssertEqual(viewModel.dnsHttpsURL, "https://1.1.1.1/dns-query")
        XCTAssertEqual(viewModel.httpsChunkSize, 4)
        XCTAssertFalse(viewModel.httpsDisorder)
        XCTAssertEqual(viewModel.appLaunchDelay, 0)
    }

    func testApplyPresetCustomDoesNotChangeOtherSettings() {
        // Set up some initial state
        viewModel.applyPreset(.fast)

        // Apply custom
        viewModel.applyPreset(.custom)

        // Preset should change to custom
        XCTAssertEqual(viewModel.preset, .custom)

        // Other settings should remain the same as the previous state (fast)
        XCTAssertEqual(viewModel.dnsHttpsURL, "https://1.1.1.1/dns-query")
        XCTAssertEqual(viewModel.httpsChunkSize, 4)
        XCTAssertFalse(viewModel.httpsDisorder)
        XCTAssertEqual(viewModel.appLaunchDelay, 0)
    }
}
