import AppKit
import SwiftUI
import Combine

@MainActor
final class MenuBarManager: ObservableObject {
    @Published var isEnabled = false

    private var statusItem: NSStatusItem?
    private var cancellables = Set<AnyCancellable>()

    func setup(viewModel: BypassViewModel) {
        viewModel.$state.sink { [weak self] state in
            self?.updateIcon(running: state == .running)
        }.store(in: &cancellables)

        if isEnabled {
            createStatusItem(viewModel: viewModel)
        }
    }

    func setEnabled(_ enabled: Bool, viewModel: BypassViewModel) {
        isEnabled = enabled
        if enabled {
            createStatusItem(viewModel: viewModel)
        } else {
            removeStatusItem()
            NSApp.setActivationPolicy(.regular)
        }
    }

    func handleWindowClose() -> Bool {
        guard isEnabled else { return false }
        NSApp.setActivationPolicy(.accessory)
        return true
    }

    func restoreWindow() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first(where: { $0.canBecomeMain }) {
            window.makeKeyAndOrderFront(nil)
        }
    }

    private func createStatusItem(viewModel: BypassViewModel) {
        guard statusItem == nil else { return }
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        updateIcon(running: viewModel.state == .running)

        let menu = NSMenu()

        let statusMenuItem = NSMenuItem(title: "SpoofTrap", action: nil, keyEquivalent: "")
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)
        menu.addItem(.separator())

        let showItem = NSMenuItem(title: "Show Window", action: #selector(MenuBarTarget.showWindow), keyEquivalent: "s")
        showItem.target = MenuBarTarget.shared
        menu.addItem(showItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit SpoofTrap", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)

        statusItem?.menu = menu

        MenuBarTarget.shared.restoreAction = { [weak self] in
            self?.restoreWindow()
        }
    }

    private func removeStatusItem() {
        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
            statusItem = nil
        }
    }

    private func updateIcon(running: Bool) {
        guard let button = statusItem?.button else { return }
        let name = running ? "shield.checkered" : "shield.slash"
        let image = NSImage(systemSymbolName: name, accessibilityDescription: "SpoofTrap")
        let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        button.image = image?.withSymbolConfiguration(config)
        button.image?.isTemplate = true
    }
}

@objc final class MenuBarTarget: NSObject {
    static let shared = MenuBarTarget()
    var restoreAction: (() -> Void)?

    @objc func showWindow() {
        restoreAction?()
    }
}
