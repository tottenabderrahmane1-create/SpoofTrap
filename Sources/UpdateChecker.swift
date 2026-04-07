import AppKit
import Foundation

@MainActor
final class UpdateChecker: ObservableObject {
    @Published var updateAvailable = false
    @Published var latestVersion: String?
    @Published var changelog: [String] = []
    @Published var dismissed = false {
        didSet {
            if dismissed, let ver = latestVersion {
                UserDefaults.standard.set(ver, forKey: "SpoofTrap.dismissedUpdateVersion")
            }
        }
    }
    @Published var isDownloading = false
    @Published var downloadProgress: Double = 0
    @Published var downloadError: String?

    private let remoteURLs = [
        "https://spooftrap.port0.org/dist/latest.json",
        "https://raw.githubusercontent.com/spooftrap-app/SpoofTrap-site/main/docs/dist/latest.json"
    ]

    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    private var latestJSON: [String: Any]?

    func check() {
        Task {
            for remote in remoteURLs {
                guard let url = URL(string: remote) else { continue }
                guard let (data, _) = try? await URLSession.shared.data(from: url),
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let version = json["version"] as? String else { continue }

                let log = json["changelog"] as? [String] ?? []
                let dismissedVer = UserDefaults.standard.string(forKey: "SpoofTrap.dismissedUpdateVersion")

                latestJSON = json
                latestVersion = version
                changelog = log
                updateAvailable = isNewer(remote: version, current: currentVersion)
                dismissed = (dismissedVer == version)
                return
            }
        }
    }

    var manualDownloadURL: URL? {
        guard let ver = latestVersion else { return nil }
        return URL(string: "https://github.com/spooftrap-app/SpoofTrap-site/releases/tag/v\(ver)")
    }

    func downloadAndInstall() {
        guard let json = latestJSON,
              let artifacts = json["artifacts"] as? [String: Any],
              let zipInfo = artifacts["zip"] as? [String: Any],
              let zipFile = zipInfo["file"] as? String else {
            downloadError = "No download URL available"
            return
        }

        let candidates = [
            "https://github.com/spooftrap-app/SpoofTrap-site/releases/download/v\(latestVersion ?? "")/\(zipFile)",
            "https://spooftrap.port0.org/dist/\(zipFile)"
        ]

        guard let url = candidates.compactMap({ URL(string: $0) }).first else {
            downloadError = "Invalid download URL"
            return
        }

        isDownloading = true
        downloadProgress = 0
        downloadError = nil

        Task {
            do {
                let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("SpoofTrap-Update-\(UUID().uuidString.prefix(8))")
                try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

                let (localURL, _) = try await URLSession.shared.download(from: url)

                let zipPath = tempDir.appendingPathComponent("update.zip")
                try? FileManager.default.removeItem(at: zipPath)
                try FileManager.default.moveItem(at: localURL, to: zipPath)

                downloadProgress = 0.5

                let extractDir = tempDir.appendingPathComponent("extracted")
                try FileManager.default.createDirectory(at: extractDir, withIntermediateDirectories: true)

                let unzip = Process()
                unzip.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
                unzip.arguments = ["-xk", zipPath.path, extractDir.path]
                try unzip.run()
                unzip.waitUntilExit()

                guard unzip.terminationStatus == 0 else {
                    downloadError = "Failed to extract update"
                    isDownloading = false
                    return
                }

                downloadProgress = 0.8

                let extractedApp = extractDir.appendingPathComponent("SpoofTrap.app")
                guard FileManager.default.fileExists(atPath: extractedApp.path) else {
                    downloadError = "SpoofTrap.app not found in download"
                    isDownloading = false
                    return
                }

                let currentApp = Bundle.main.bundleURL
                let backupURL = currentApp.deletingLastPathComponent().appendingPathComponent("SpoofTrap-backup.app")

                try? FileManager.default.removeItem(at: backupURL)
                try FileManager.default.moveItem(at: currentApp, to: backupURL)
                try FileManager.default.copyItem(at: extractedApp, to: currentApp)

                let codesign = Process()
                codesign.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
                codesign.arguments = ["--force", "--deep", "--sign", "-", currentApp.path]
                codesign.standardOutput = FileHandle.nullDevice
                codesign.standardError = FileHandle.nullDevice
                try? codesign.run()
                codesign.waitUntilExit()

                let xattr = Process()
                xattr.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
                xattr.arguments = ["-cr", currentApp.path]
                xattr.standardOutput = FileHandle.nullDevice
                xattr.standardError = FileHandle.nullDevice
                try? xattr.run()
                xattr.waitUntilExit()

                downloadProgress = 1.0

                try? FileManager.default.removeItem(at: tempDir)
                try? FileManager.default.removeItem(at: backupURL)

                relaunchApp()
            } catch {
                downloadError = "Update failed: \(error.localizedDescription)"
                isDownloading = false
            }
        }
    }

    private func relaunchApp() {
        let appPath = Bundle.main.bundleURL.path
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/sh")
        task.arguments = ["-c", "sleep 1 && open \"$0\"", appPath]
        try? task.run()
        NSApplication.shared.terminate(nil)
    }

    private func isNewer(remote: String, current: String) -> Bool {
        let r = remote.split(separator: ".").compactMap { Int($0) }
        let c = current.split(separator: ".").compactMap { Int($0) }
        for i in 0..<max(r.count, c.count) {
            let rv = i < r.count ? r[i] : 0
            let cv = i < c.count ? c[i] : 0
            if rv > cv { return true }
            if rv < cv { return false }
        }
        return false
    }
}
