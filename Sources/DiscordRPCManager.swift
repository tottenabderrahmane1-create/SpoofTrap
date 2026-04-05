import Foundation
import Combine

@MainActor
final class DiscordRPCManager: ObservableObject {
    @Published var isConnected = false
    @Published var isEnabled = true

    private var socket: Int32 = -1
    private var updateTask: Task<Void, Never>?
    private var nonce = 0
    private let clientId = "1192124994039697408"
    private let socketLock = NSLock()

    func connect() {
        guard isEnabled else { return }
        let cid = clientId
        Task.detached { [weak self] in
            guard let self else { return }
            let fd = await self.tryConnect()
            guard fd >= 0 else { return }

            await MainActor.run {
                self.socket = fd
            }

            let ok = self.performHandshake(fd: fd, clientId: cid)
            await MainActor.run {
                self.isConnected = ok
                if !ok {
                    Darwin.close(fd)
                    self.socket = -1
                }
            }
        }
    }

    func disconnect() {
        updateTask?.cancel()
        updateTask = nil
        if socket >= 0 {
            Darwin.close(socket)
            socket = -1
        }
        isConnected = false
    }

    func updatePresence(gameName: String?, placeId: String?, elapsed: TimeInterval) {
        guard isConnected, isEnabled else { return }
        let details = gameName ?? "In Lobby"
        let state = "via SpoofTrap"

        var activity: [String: Any] = [
            "details": details,
            "state": state,
            "timestamps": ["start": Int(Date().timeIntervalSince1970 - elapsed)]
        ]

        if let placeId {
            activity["buttons"] = [
                ["label": "Join Game", "url": "https://www.roblox.com/games/\(placeId)"]
            ]
        }

        activity["assets"] = [
            "large_image": "spooftrap_icon",
            "large_text": "SpoofTrap",
            "small_image": "roblox_icon",
            "small_text": gameName ?? "Roblox"
        ]

        let payload: [String: Any] = [
            "cmd": "SET_ACTIVITY",
            "args": ["pid": ProcessInfo.processInfo.processIdentifier, "activity": activity],
            "nonce": "\(nextNonce())"
        ]

        let fd = socket
        Task.detached { [weak self] in
            self?.sendFrameSync(fd: fd, opcode: 1, payload: payload)
        }
    }

    func clearPresence() {
        guard isConnected else { return }
        let payload: [String: Any] = [
            "cmd": "SET_ACTIVITY",
            "args": ["pid": ProcessInfo.processInfo.processIdentifier],
            "nonce": "\(nextNonce())"
        ]
        let fd = socket
        Task.detached { [weak self] in
            self?.sendFrameSync(fd: fd, opcode: 1, payload: payload)
        }
    }

    // MARK: - IPC (runs off MainActor)

    private nonisolated func tryConnect() async -> Int32 {
        for i in 0..<10 {
            let path = ipcPath(i)
            let fd = Darwin.socket(AF_UNIX, SOCK_STREAM, 0)
            guard fd >= 0 else { continue }

            var addr = sockaddr_un()
            addr.sun_family = sa_family_t(AF_UNIX)
            let pathBytes = path.utf8CString
            withUnsafeMutablePointer(to: &addr.sun_path) { ptr in
                ptr.withMemoryRebound(to: CChar.self, capacity: Int(104)) { dest in
                    for (idx, byte) in pathBytes.enumerated() where idx < 104 {
                        dest[idx] = byte
                    }
                }
            }

            let addrLen = socklen_t(MemoryLayout<sockaddr_un>.size)
            let result = withUnsafePointer(to: &addr) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    Darwin.connect(fd, $0, addrLen)
                }
            }

            if result == 0 {
                return fd
            } else {
                Darwin.close(fd)
            }
        }
        return -1
    }

    private nonisolated func performHandshake(fd: Int32, clientId: String) -> Bool {
        let payload: [String: Any] = ["v": 1, "client_id": clientId]
        sendFrameSync(fd: fd, opcode: 0, payload: payload)

        var buffer = [UInt8](repeating: 0, count: 4096)
        let bytesRead = read(fd, &buffer, buffer.count)
        return bytesRead > 8
    }

    private nonisolated func sendFrameSync(fd: Int32, opcode: UInt32, payload: [String: Any]) {
        guard fd >= 0,
              let jsonData = try? JSONSerialization.data(withJSONObject: payload) else { return }

        var header = [UInt8](repeating: 0, count: 8)
        header.withUnsafeMutableBufferPointer { ptr in
            guard let base = ptr.baseAddress else { return }
            base.withMemoryRebound(to: UInt32.self, capacity: 2) { intPtr in
                intPtr[0] = opcode.littleEndian
                intPtr[1] = UInt32(jsonData.count).littleEndian
            }
        }

        var frame = Data(header)
        frame.append(jsonData)
        socketLock.lock()
        frame.withUnsafeBytes { ptr in
            guard let base = ptr.baseAddress else { return }
            _ = Darwin.write(fd, base, frame.count)
        }
        socketLock.unlock()
    }

    private nonisolated func ipcPath(_ index: Int) -> String {
        let tmpDir = ProcessInfo.processInfo.environment["XDG_RUNTIME_DIR"]
            ?? ProcessInfo.processInfo.environment["TMPDIR"]
            ?? NSTemporaryDirectory()
        let base = tmpDir.hasSuffix("/") ? tmpDir : tmpDir + "/"
        return "\(base)discord-ipc-\(index)"
    }

    private func nextNonce() -> Int {
        nonce += 1
        return nonce
    }
}
