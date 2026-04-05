import Foundation

@MainActor
final class CacheCleanerManager: ObservableObject {
    struct CacheInfo {
        var logsSize: Int64 = 0
        var cacheSize: Int64 = 0
        var tempSize: Int64 = 0
        var totalSize: Int64 { logsSize + cacheSize + tempSize }
        var logsCount: Int = 0
        var cacheCount: Int = 0
        var tempCount: Int = 0
        var totalCount: Int { logsCount + cacheCount + tempCount }
    }

    @Published var cacheInfo = CacheInfo()
    @Published var lastCleaned: Date?
    @Published var isCleaning = false
    @Published var lastFreedBytes: Int64 = 0

    private let fm = FileManager.default

    private var logsDir: URL {
        fm.homeDirectoryForCurrentUser.appendingPathComponent("Library/Logs/Roblox")
    }

    private var cacheDir: URL {
        fm.homeDirectoryForCurrentUser.appendingPathComponent("Library/Caches/com.roblox.RobloxPlayer")
    }

    private var tempDir: URL {
        fm.temporaryDirectory
    }

    func scan() {
        var info = CacheInfo()

        if let (size, count) = sizeOfDirectory(logsDir) {
            info.logsSize = size
            info.logsCount = count
        }

        if let (size, count) = sizeOfDirectory(cacheDir) {
            info.cacheSize = size
            info.cacheCount = count
        }

        let robloxTempFiles = robloxTempItems()
        info.tempSize = robloxTempFiles.reduce(0) { total, url in
            total + (fileSize(url) ?? 0)
        }
        info.tempCount = robloxTempFiles.count

        cacheInfo = info
    }

    func cleanAll() -> (freed: Int64, files: Int) {
        isCleaning = true
        defer { isCleaning = false }

        let before = cacheInfo.totalSize
        var deletedFiles = 0

        deletedFiles += cleanDirectory(logsDir, keepRecent: 1)
        deletedFiles += cleanDirectory(cacheDir, keepRecent: 0)

        for url in robloxTempItems() {
            try? fm.removeItem(at: url)
            deletedFiles += 1
        }

        scan()
        let freed = max(0, before - cacheInfo.totalSize)
        lastFreedBytes = freed
        lastCleaned = Date()
        return (freed, deletedFiles)
    }

    func cleanLogs() -> Int {
        let count = cleanDirectory(logsDir, keepRecent: 1)
        scan()
        return count
    }

    func cleanCache() -> Int {
        let count = cleanDirectory(cacheDir, keepRecent: 0)
        scan()
        return count
    }

    private func cleanDirectory(_ dir: URL, keepRecent: Int) -> Int {
        guard let items = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.contentModificationDateKey], options: .skipsHiddenFiles) else { return 0 }

        let sorted = items.sorted {
            let d1 = (try? $0.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
            let d2 = (try? $1.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
            return d1 > d2
        }

        var deleted = 0
        for (i, item) in sorted.enumerated() {
            if i < keepRecent { continue }
            try? fm.removeItem(at: item)
            deleted += 1
        }
        return deleted
    }

    private func robloxTempItems() -> [URL] {
        guard let items = try? fm.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) else { return [] }
        return items.filter { $0.lastPathComponent.lowercased().contains("roblox") }
    }

    private func sizeOfDirectory(_ dir: URL) -> (Int64, Int)? {
        guard let items = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.fileSizeKey], options: .skipsHiddenFiles) else { return nil }
        var total: Int64 = 0
        for item in items {
            total += fileSize(item) ?? 0
        }
        return (total, items.count)
    }

    private func fileSize(_ url: URL) -> Int64? {
        guard let vals = try? url.resourceValues(forKeys: [.fileSizeKey]) else { return nil }
        return Int64(vals.fileSize ?? 0)
    }

    static func formatBytes(_ bytes: Int64) -> String {
        if bytes < 1024 { return "\(bytes) B" }
        if bytes < 1024 * 1024 { return String(format: "%.1f KB", Double(bytes) / 1024) }
        return String(format: "%.1f MB", Double(bytes) / (1024 * 1024))
    }
}
