import SwiftUI

@main
struct SpoofTrapApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 900, minHeight: 640)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 960, height: 700)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    static var menuBarManager: MenuBarManager?

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        if let mgr = Self.menuBarManager, mgr.isEnabled {
            _ = mgr.handleWindowClose()
            return false
        }
        return true
    }
}
