import AppKit
import SwiftUI
import Combine

@MainActor
final class PerformanceOverlayManager: ObservableObject {
    @Published var isVisible = false

    private var panel: NSPanel?
    private var cancellables = Set<AnyCancellable>()

    func toggle(logWatcher: RobloxLogWatcher) {
        isVisible.toggle()
        if isVisible {
            showPanel(logWatcher: logWatcher)
        } else {
            hidePanel()
        }
    }

    func hide() {
        isVisible = false
        hidePanel()
    }

    private func showPanel(logWatcher: RobloxLogWatcher) {
        guard panel == nil else {
            panel?.orderFront(nil)
            return
        }

        let content = OverlayContentView(logWatcher: logWatcher)
        let hostingView = NSHostingView(rootView: content)
        hostingView.frame = NSRect(x: 0, y: 0, width: 140, height: 70)

        let p = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 140, height: 70),
            styleMask: [.nonactivatingPanel, .hudWindow, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        p.isFloatingPanel = true
        p.level = .floating
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        p.isOpaque = false
        p.backgroundColor = .clear
        p.hasShadow = true
        p.contentView = hostingView
        p.isMovableByWindowBackground = true
        p.titleVisibility = .hidden
        p.titlebarAppearsTransparent = true

        if let screen = NSScreen.main {
            let x = screen.frame.maxX - 160
            let y = screen.frame.maxY - 100
            p.setFrameOrigin(NSPoint(x: x, y: y))
        }

        p.orderFront(nil)
        panel = p
    }

    private func hidePanel() {
        panel?.close()
        panel = nil
    }
}

private struct OverlayContentView: View {
    @ObservedObject var logWatcher: RobloxLogWatcher

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let fps = logWatcher.currentFPS {
                HStack(spacing: 6) {
                    Image(systemName: "gauge.high")
                        .font(.system(size: 10))
                        .foregroundStyle(fpsColor(fps))
                    Text("\(fps) FPS")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(fpsColor(fps))
                }
            }
            if let ping = logWatcher.currentPing {
                HStack(spacing: 6) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 10))
                        .foregroundStyle(pingColor(ping))
                    Text(ping)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(pingColor(ping))
                }
            }
            if let region = logWatcher.currentRegion {
                HStack(spacing: 6) {
                    Image(systemName: "globe")
                        .font(.system(size: 10))
                        .foregroundStyle(.cyan)
                    Text(region)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
            }
            HStack(spacing: 6) {
                Image(systemName: "memorychip")
                    .font(.system(size: 10))
                    .foregroundStyle(.orange)
                Text(logWatcher.currentMemory ?? "-- MB")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
            }
            if logWatcher.isInGame {
                HStack(spacing: 6) {
                    Circle()
                        .fill(.green)
                        .frame(width: 6, height: 6)
                    Text("In Game")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.black.opacity(0.75))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
    }

    private func fpsColor(_ fps: String) -> Color {
        guard let val = Int(fps) else { return .white }
        if val >= 55 { return .green }
        if val >= 30 { return .yellow }
        return .red
    }

    private func pingColor(_ ping: String) -> Color {
        let digits = ping.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        guard let val = Int(digits) else { return .white }
        if val <= 60 { return .green }
        if val <= 120 { return .yellow }
        if val <= 200 { return .orange }
        return .red
    }
}
