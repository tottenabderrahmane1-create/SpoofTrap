import AppKit
import Carbon.HIToolbox

@MainActor
final class GlobalHotkeyManager {
    enum Hotkey: Int, CaseIterable {
        case toggleSession = 1
        case serverHop = 2
        case toggleOverlay = 3
        case exportLog = 4
    }

    private var eventHandlerRef: EventHandlerRef?
    private weak var viewModel: BypassViewModel?

    private static var sharedInstance: GlobalHotkeyManager?

    init() {
        Self.sharedInstance = self
    }

    func setup(viewModel: BypassViewModel) {
        self.viewModel = viewModel
        unregisterAll()
        registerHotkeys()
    }

    func teardown() {
        unregisterAll()
    }

    private func registerHotkeys() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let callback: EventHandlerUPP = { _, event, _ -> OSStatus in
            var hotkeyID = EventHotKeyID()
            GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotkeyID
            )

            Task { @MainActor in
                GlobalHotkeyManager.sharedInstance?.handleHotkey(id: Int(hotkeyID.id))
            }
            return noErr
        }

        InstallEventHandler(
            GetApplicationEventTarget(),
            callback,
            1,
            &eventType,
            nil,
            &eventHandlerRef
        )

        // Cmd+Shift+S = Toggle session
        registerKey(id: Hotkey.toggleSession.rawValue, keyCode: UInt32(kVK_ANSI_S), modifiers: UInt32(cmdKey | shiftKey))
        // Cmd+Shift+H = Server hop
        registerKey(id: Hotkey.serverHop.rawValue, keyCode: UInt32(kVK_ANSI_H), modifiers: UInt32(cmdKey | shiftKey))
        // Cmd+Shift+O = Toggle overlay
        registerKey(id: Hotkey.toggleOverlay.rawValue, keyCode: UInt32(kVK_ANSI_O), modifiers: UInt32(cmdKey | shiftKey))
        // Cmd+Shift+E = Export log
        registerKey(id: Hotkey.exportLog.rawValue, keyCode: UInt32(kVK_ANSI_E), modifiers: UInt32(cmdKey | shiftKey))
    }

    private var hotkeyRefs: [EventHotKeyRef?] = []

    private func registerKey(id: Int, keyCode: UInt32, modifiers: UInt32) {
        let hotkeyID = EventHotKeyID(signature: OSType(0x5354_4B59), id: UInt32(id))
        var ref: EventHotKeyRef?
        RegisterEventHotKey(keyCode, modifiers, hotkeyID, GetApplicationEventTarget(), 0, &ref)
        hotkeyRefs.append(ref)
    }

    private func unregisterAll() {
        for ref in hotkeyRefs {
            if let ref { UnregisterEventHotKey(ref) }
        }
        hotkeyRefs.removeAll()
        if let handler = eventHandlerRef {
            RemoveEventHandler(handler)
            eventHandlerRef = nil
        }
    }

    private func handleHotkey(id: Int) {
        guard let vm = viewModel, let hotkey = Hotkey(rawValue: id) else { return }

        switch hotkey {
        case .toggleSession:
            vm.toggleBypass()
        case .serverHop:
            vm.serverHop()
        case .toggleOverlay:
            if vm.proManager.canUsePerformanceOverlay {
                vm.perfOverlay.toggle(logWatcher: vm.logWatcher)
            }
        case .exportLog:
            vm.exportLogs()
        }
    }
}
