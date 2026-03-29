import SwiftUI

@main
struct SpoofTrapApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 900, minHeight: 640)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 960, height: 700)
    }
}
