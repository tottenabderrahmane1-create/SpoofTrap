import Foundation

@MainActor
final class UpdateChecker: ObservableObject {
    @Published var updateAvailable = false
    @Published var latestVersion: String?
    @Published var downloadURL: String?
    @Published var changelog: [String] = []
    @Published var dismissed = false {
        didSet {
            if dismissed, let ver = latestVersion {
                UserDefaults.standard.set(ver, forKey: "SpoofTrap.dismissedUpdateVersion")
            }
        }
    }

    private let remoteURL = "https://raw.githubusercontent.com/spooftrap-app/SpoofTrap-site/main/docs/dist/latest.json"

    private var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    func check() {
        Task {
            guard let url = URL(string: remoteURL),
                  let (data, _) = try? await URLSession.shared.data(from: url),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let remote = json["version"] as? String else { return }

            let dmgURL = (json["downloads"] as? [String: Any])?["dmg"] as? [String: Any]
            let dl = dmgURL?["url"] as? String
            let log = json["changelog"] as? [String] ?? []

            let dismissedVer = UserDefaults.standard.string(forKey: "SpoofTrap.dismissedUpdateVersion")
            await MainActor.run {
                self.latestVersion = remote
                self.downloadURL = dl
                self.changelog = log
                self.updateAvailable = self.isNewer(remote: remote, current: self.currentVersion)
                self.dismissed = (dismissedVer == remote)
            }
        }
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
