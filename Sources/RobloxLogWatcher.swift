import Foundation
import Combine

@MainActor
final class RobloxLogWatcher: ObservableObject {
    @Published var currentPlaceId: String?
    @Published var currentJobId: String?
    @Published var currentGameName: String?
    @Published var currentServerIP: String?
    @Published var currentRegion: String?
    @Published var currentPing: String?
    @Published var isInGame: Bool = false
    @Published var disconnected: Bool = false
    @Published var currentFPS: String?
    @Published var currentMemory: String?
    @Published var watcherStatus: String = "idle"
    @Published var robloxLogLines: [String] = []
    @Published var playerEvents: [PlayerEvent] = []

    struct PlayerEvent: Identifiable {
        let id = UUID()
        let timestamp: Date
        let playerName: String
        let action: Action
        enum Action: String { case joined, left }
    }

    private var watchTask: Task<Void, Never>?
    private var lastFileOffset: UInt64 = 0
    private var logFileURL: URL?
    private var lastLogFileName: String?
    private let maxRobloxLogLines = 500

    private static var logDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Logs/Roblox")
    }

    func startWatching() {
        stopWatching()

        let found = Self.findLatestLog()
        logFileURL = found
        lastLogFileName = found?.lastPathComponent

        if let url = found {
            watcherStatus = "scanning \(url.lastPathComponent)"
            scanExistingContent(url)
        } else {
            watcherStatus = "no log found"
        }

        watchTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                self?.pollLog()
                self?.pollProcessStatsAsync()
            }
        }
    }

    func stopWatching() {
        watchTask?.cancel()
        watchTask = nil
        watcherStatus = "stopped"
    }

    private func scanExistingContent(_ url: URL) {
        guard let handle = try? FileHandle(forReadingFrom: url) else {
            watcherStatus = "cannot open log"
            return
        }
        defer { try? handle.close() }

        let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
        let fileSize = (attrs?[.size] as? UInt64) ?? 0

        let scanSize: UInt64 = min(fileSize, 128 * 1024)
        let startOffset = fileSize - scanSize
        handle.seek(toFileOffset: startOffset)

        guard let data = try? handle.readToEnd() else {
            lastFileOffset = fileSize
            return
        }

        guard let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) else {
            lastFileOffset = fileSize
            return
        }

        var foundJoin = false
        for line in text.components(separatedBy: .newlines) {
            parseLine(line)
            if line.contains("Joining game") { foundJoin = true }
        }

        lastFileOffset = fileSize
        watcherStatus = foundJoin ? "active (game detected)" : "watching"
    }

    private func pollLog() {
        let latestLog = Self.findLatestLog()

        if let latest = latestLog {
            let latestName = latest.lastPathComponent
            if latestName != lastLogFileName {
                logFileURL = latest
                lastLogFileName = latestName
                lastFileOffset = 0
                watcherStatus = "switched to \(latestName)"
            }
        }

        if logFileURL == nil {
            logFileURL = latestLog
            lastLogFileName = latestLog?.lastPathComponent
        }

        guard let url = logFileURL else { return }
        guard let handle = try? FileHandle(forReadingFrom: url) else { return }
        defer { try? handle.close() }

        handle.seek(toFileOffset: lastFileOffset)
        guard let data = try? handle.readToEnd(), !data.isEmpty else { return }

        guard let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) else {
            lastFileOffset += UInt64(data.count)
            return
        }

        lastFileOffset += UInt64(data.count)

        for line in text.components(separatedBy: .newlines) {
            parseLine(line)
        }
    }

    private func pollProcessStatsAsync() {
        let serverIP = currentServerIP
        Task.detached {
            let memStr = Self.readProcessMemory()
            let pingMs = Self.measurePing(ip: serverIP)
            await MainActor.run { @Sendable [weak self] in
                if let mem = memStr { self?.currentMemory = mem }
                if let ping = pingMs { self?.currentPing = "\(ping) ms" }
                else if serverIP == nil { self?.currentPing = nil }
            }
        }
    }

    private nonisolated static func readProcessMemory() -> String? {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
        process.arguments = ["-x", "RobloxPlayer"]
        process.standardOutput = pipe
        process.standardError = pipe
        do {
            try process.run()
            process.waitUntilExit()
        } catch { return nil }

        let pidData = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let pidStr = String(data: pidData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
              let pid = pidStr.components(separatedBy: .newlines).first,
              !pid.isEmpty else {
            return nil
        }

        let psProcess = Process()
        let psPipe = Pipe()
        psProcess.executableURL = URL(fileURLWithPath: "/bin/ps")
        psProcess.arguments = ["-p", pid, "-o", "rss="]
        psProcess.standardOutput = psPipe
        psProcess.standardError = psPipe
        do {
            try psProcess.run()
            psProcess.waitUntilExit()
        } catch { return nil }

        let data = psPipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
              let rssKB = Int(output) else { return nil }

        let mb = rssKB / 1024
        return "\(mb) MB"
    }

    private func parseLine(_ line: String) {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if robloxLogLines.count >= maxRobloxLogLines {
            robloxLogLines.removeFirst(robloxLogLines.count - maxRobloxLogLines + 1)
        }
        robloxLogLines.append(trimmed)

        if line.contains("Joining game") || line.contains("joining game") {
            if let range = line.range(of: "place (\\d+)", options: .regularExpression) {
                let placeStr = line[range].replacingOccurrences(of: "place ", with: "")
                currentPlaceId = placeStr
                isInGame = true
                disconnected = false
                resolveGameName(placeId: placeStr)
            }
            if let range = line.range(of: "'([0-9a-fA-F\\-]+)'", options: .regularExpression) {
                let raw = String(line[range])
                currentJobId = raw.trimmingCharacters(in: CharacterSet(charactersIn: "'"))
            }
        }

        if line.contains("UDMUX") || line.contains("udmux") {
            if let range = line.range(of: "(\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3})", options: .regularExpression) {
                let ip = String(line[range])
                currentServerIP = ip
                resolveRegion(ip: ip)
            }
        }

        if line.contains("Destroying MegaReplicator") {
            isInGame = false
            disconnected = true
            currentServerIP = nil
        }

        if line.contains("Kicked") && line.contains("from server") {
            isInGame = false
            disconnected = true
        }

        if line.contains("Teleport") && line.contains("Started") {
            disconnected = false
        }

        if line.contains("AppMemUsageStatus") {
            if let range = line.range(of: #"\]\s+([\d.]+)"#, options: .regularExpression) {
                let matched = String(line[range])
                if let numRange = matched.range(of: #"[\d.]+"#, options: .regularExpression) {
                    let numStr = String(matched[numRange])
                    if let val = Double(numStr), val > 1_000_000 {
                        let mb = Int(val / (1024 * 1024))
                        if mb > 0 && mb < 100_000 {
                            currentMemory = "\(mb) MB"
                        }
                    }
                }
            }
        }

        if let range = line.range(of: #"FPS:\s*([\d.]+)"#, options: .regularExpression) {
            let matched = String(line[range])
            if let numRange = matched.range(of: #"[\d.]+"#, options: .regularExpression) {
                let fpsStr = String(matched[numRange])
                if let fps = Double(fpsStr), fps > 0, fps < 10000 {
                    currentFPS = "\(Int(fps.rounded()))"
                }
            }
        } else if line.contains("GraphicsFrameRateManager") || line.contains("FrameRate") {
            if let range = line.range(of: #"(\d{1,4})\s*fps"#, options: [.regularExpression, .caseInsensitive]) {
                let matched = String(line[range])
                if let numRange = matched.range(of: #"\d+"#, options: .regularExpression) {
                    let fpsStr = String(matched[numRange])
                    if let fps = Int(fpsStr), fps > 0, fps < 10000 {
                        currentFPS = "\(fps)"
                    }
                }
            }
        }

        // Player join/leave detection
        if let joinRange = trimmed.range(of: #"([\w\d_]+) has joined"#, options: .regularExpression) {
            let joinMatch = String(trimmed[joinRange])
            let playerName = joinMatch.replacingOccurrences(of: " has joined", with: "")
            if !playerName.isEmpty && playerName.count < 30 {
                let event = PlayerEvent(timestamp: Date(), playerName: playerName, action: .joined)
                playerEvents.append(event)
                if playerEvents.count > 200 { playerEvents.removeFirst(playerEvents.count - 200) }
            }
        }

        if let leftRange = trimmed.range(of: #"([\w\d_]+) has left"#, options: .regularExpression) {
            let leftMatch = String(trimmed[leftRange])
            let playerName = leftMatch.replacingOccurrences(of: " has left", with: "")
            if !playerName.isEmpty && playerName.count < 30 {
                let event = PlayerEvent(timestamp: Date(), playerName: playerName, action: .left)
                playerEvents.append(event)
                if playerEvents.count > 200 { playerEvents.removeFirst(playerEvents.count - 200) }
            }
        }

        if trimmed.contains("removing player") {
            if let rmRange = trimmed.range(of: #"removing player (\d+)"#, options: .regularExpression) {
                let rmMatch = String(trimmed[rmRange]).replacingOccurrences(of: "removing player ", with: "Player#")
                let event = PlayerEvent(timestamp: Date(), playerName: rmMatch, action: .left)
                playerEvents.append(event)
                if playerEvents.count > 200 { playerEvents.removeFirst(playerEvents.count - 200) }
            }
        }
    }

    var currentLogFilePath: String? {
        logFileURL?.path
    }

    private func resolveGameName(placeId: String) {
        Task.detached {
            guard let url = URL(string: "https://games.roblox.com/v1/games/multiget-place-details?placeIds=\(placeId)") else { return }
            guard let (data, _) = try? await URLSession.shared.data(from: url),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                  let first = json.first,
                  let name = first["name"] as? String else { return }
            await MainActor.run { [weak self] in
                self?.currentGameName = name
            }
        }
    }

    private func resolveRegion(ip: String) {
        Task.detached {
            guard let url = URL(string: "http://ip-api.com/json/\(ip)?fields=country,regionName,city,query,lat,lon") else { return }
            guard let (data, _) = try? await URLSession.shared.data(from: url),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }

            let region = json["regionName"] as? String ?? ""
            let city = json["city"] as? String ?? ""
            let country = json["country"] as? String ?? ""

            let display = [city, region, country].filter { !$0.isEmpty }.joined(separator: ", ")
            await MainActor.run { [weak self] in
                self?.currentRegion = display.isEmpty ? "Unknown" : display
            }
        }
    }

    private nonisolated static func measurePing(ip: String?) -> Int? {
        guard let ip, !ip.isEmpty else { return nil }
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/sbin/ping")
        process.arguments = ["-c", "1", "-W", "2000", ip]
        process.standardOutput = pipe
        process.standardError = pipe
        do {
            try process.run()
            process.waitUntilExit()
        } catch { return nil }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else { return nil }

        if let range = output.range(of: #"time[=<]([\d.]+)"#, options: .regularExpression) {
            let matched = String(output[range])
            if let numRange = matched.range(of: #"[\d.]+"#, options: .regularExpression) {
                if let ms = Double(String(matched[numRange])) {
                    return Int(ms.rounded())
                }
            }
        }
        return nil
    }

    private static func findLatestLog() -> URL? {
        let dir = logDirectory
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: dir, includingPropertiesForKeys: [.contentModificationDateKey],
            options: .skipsHiddenFiles
        ) else { return nil }

        return files
            .filter { $0.pathExtension == "log" }
            .sorted {
                let d1 = (try? $0.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
                let d2 = (try? $1.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
                return d1 > d2
            }
            .first
    }
}
