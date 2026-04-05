import AppKit
import Foundation

struct ModCategory: Identifiable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let relativePaths: [String]
    let allowedExtensions: [String]
    let requiresPro: Bool
}

struct InstalledMod: Identifiable, Codable, Equatable {
    let id: String
    var categoryId: String
    var name: String
    var isEnabled: Bool
    var isBuiltIn: Bool
    var customFilePath: String?
    var originalBackedUp: Bool
}

@MainActor
final class ModsManager: ObservableObject {
    @Published var installedMods: [InstalledMod] = []
    @Published var isEnabled: Bool = false {
        didSet { saveSettings() }
    }

    private let fileManager: FileManager

    static let categories: [ModCategory] = [
        ModCategory(
            id: "death_sound",
            name: "Death Sound",
            description: "Replace the classic 'oof' sound",
            icon: "speaker.wave.2.fill",
            relativePaths: ["content/sounds/ouch.ogg"],
            allowedExtensions: ["ogg"],
            requiresPro: false
        ),
        ModCategory(
            id: "cursor",
            name: "Custom Cursor",
            description: "Replace in-game cursor textures",
            icon: "cursorarrow",
            relativePaths: [
                "content/textures/Cursors/KeyboardMouse/ArrowCursor.png",
                "content/textures/Cursors/KeyboardMouse/ArrowFarCursor.png"
            ],
            allowedExtensions: ["png"],
            requiresPro: false
        ),
        ModCategory(
            id: "app_icon",
            name: "App Icon",
            description: "Replace the Roblox icon (Dock + in-game)",
            icon: "app.badge.fill",
            relativePaths: [
                "content/textures/ui/icon_app-512.png"
            ],
            allowedExtensions: ["png", "icns"],
            requiresPro: true
        ),
        ModCategory(
            id: "fonts",
            name: "Custom Fonts",
            description: "Replace default Roblox UI fonts",
            icon: "textformat",
            relativePaths: [
                "content/fonts/BuilderSans-Regular.otf",
                "content/fonts/BuilderSans-Medium.otf",
                "content/fonts/BuilderSans-Bold.otf",
                "content/fonts/BuilderSans-ExtraBold.otf"
            ],
            allowedExtensions: ["otf", "ttf"],
            requiresPro: true
        ),
        ModCategory(
            id: "avatar_bg",
            name: "Avatar Background",
            description: "Change the avatar editor background",
            icon: "person.crop.rectangle.fill",
            relativePaths: [
                "ExtraContent/places/Mobile.rbxl"
            ],
            allowedExtensions: ["rbxl"],
            requiresPro: true
        ),
        ModCategory(
            id: "loading_screen",
            name: "Loading Screen",
            description: "Replace the Roblox loading background textures",
            icon: "photo.fill",
            relativePaths: [
                "content/textures/loading/darkLoadingTexture.png",
                "content/textures/loading/loadingTexture.png"
            ],
            allowedExtensions: ["png", "jpg"],
            requiresPro: true
        )
    ]

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        loadSettings()
    }

    var enabledCount: Int {
        installedMods.filter { $0.isEnabled }.count
    }

    func category(for id: String) -> ModCategory? {
        Self.categories.first { $0.id == id }
    }

    func mods(for categoryId: String) -> [InstalledMod] {
        installedMods.filter { $0.categoryId == categoryId }
    }

    func activeMod(for categoryId: String) -> InstalledMod? {
        installedMods.first { $0.categoryId == categoryId && $0.isEnabled }
    }

    // MARK: - Import custom mod file (PRO)

    func importCustomMod(for categoryId: String) {
        guard let cat = category(for: categoryId) else { return }

        let panel = NSOpenPanel()
        panel.title = "Choose \(cat.name) file"
        panel.prompt = "Import"
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false

        panel.allowedFileTypes = cat.allowedExtensions

        guard panel.runModal() == .OK, let url = panel.url else { return }

        let destDir = modsStorageDir.appendingPathComponent(categoryId)
        try? fileManager.createDirectory(at: destDir, withIntermediateDirectories: true)

        let destURL = destDir.appendingPathComponent(url.lastPathComponent)
        try? fileManager.removeItem(at: destURL)

        do {
            try fileManager.copyItem(at: url, to: destURL)
        } catch {
            return
        }

        let newMod = InstalledMod(
            id: UUID().uuidString,
            categoryId: categoryId,
            name: url.deletingPathExtension().lastPathComponent,
            isEnabled: false,
            isBuiltIn: false,
            customFilePath: destURL.path,
            originalBackedUp: false
        )

        installedMods.append(newMod)
        saveSettings()
    }

    func toggleMod(_ mod: InstalledMod) {
        guard let index = installedMods.firstIndex(where: { $0.id == mod.id }) else { return }

        if !mod.isEnabled {
            for i in installedMods.indices where installedMods[i].categoryId == mod.categoryId {
                installedMods[i].isEnabled = false
            }
        }

        installedMods[index].isEnabled.toggle()
        saveSettings()
    }

    func removeMod(_ mod: InstalledMod) {
        guard !mod.isBuiltIn else { return }

        if let path = mod.customFilePath {
            try? fileManager.removeItem(atPath: path)
        }

        installedMods.removeAll { $0.id == mod.id }
        saveSettings()
    }

    // MARK: - Apply mods before Roblox launch

    func applyMods(robloxAppPath: String, isProUser: Bool = false) -> (applied: Int, failed: Int) {
        guard isEnabled else { return (0, 0) }

        let resourcesBase = (robloxAppPath as NSString).appendingPathComponent("Contents/Resources")
        let macosBase = (robloxAppPath as NSString).appendingPathComponent("Contents/MacOS")
        var applied = 0
        var failed = 0

        for mod in installedMods where mod.isEnabled {
            guard let cat = category(for: mod.categoryId) else { continue }
            if cat.requiresPro && !isProUser { continue }

            let sourceFile: String
            if let custom = mod.customFilePath {
                sourceFile = custom
            } else if mod.isBuiltIn {
                guard let bundled = bundledModPath(for: mod) else {
                    failed += 1
                    continue
                }
                sourceFile = bundled
            } else {
                continue
            }

            guard fileManager.fileExists(atPath: sourceFile) else {
                failed += 1
                continue
            }

            for relPath in cat.relativePaths {
                let base = cat.id == "app_icon" ? macosBase : resourcesBase
                let targetPath = (base as NSString).appendingPathComponent(relPath)
                let backupPath = backupPathFor(target: targetPath)

                if fileManager.fileExists(atPath: targetPath) {
                    if !fileManager.fileExists(atPath: backupPath) {
                        let backupDir = (backupPath as NSString).deletingLastPathComponent
                        try? fileManager.createDirectory(atPath: backupDir, withIntermediateDirectories: true)
                        try? fileManager.copyItem(atPath: targetPath, toPath: backupPath)
                    }
                    if let idx = installedMods.firstIndex(where: { $0.id == mod.id }) {
                        installedMods[idx].originalBackedUp = true
                    }
                }

                let targetDir = (targetPath as NSString).deletingLastPathComponent
                try? fileManager.createDirectory(atPath: targetDir, withIntermediateDirectories: true)

                do {
                    if fileManager.fileExists(atPath: targetPath) {
                        try fileManager.removeItem(atPath: targetPath)
                    }
                    try fileManager.copyItem(atPath: sourceFile, toPath: targetPath)
                    applied += 1
                } catch {
                    failed += 1
                }
            }

            if cat.id == "app_icon" {
                if applyDockIcon(sourceFile: sourceFile, robloxAppPath: robloxAppPath) {
                    applied += 1
                }
                clearIconCache()
            }
        }

        if applied > 0 {
            resignBundle(robloxAppPath)
        }

        saveSettings()
        return (applied, failed)
    }

    private func applyDockIcon(sourceFile: String, robloxAppPath: String) -> Bool {
        let icnsPath = (robloxAppPath as NSString)
            .appendingPathComponent("Contents/Resources/AppIcon.icns")
        let backupPath = backupPathFor(target: icnsPath)

        if fileManager.fileExists(atPath: icnsPath) && !fileManager.fileExists(atPath: backupPath) {
            let backupDir = (backupPath as NSString).deletingLastPathComponent
            try? fileManager.createDirectory(atPath: backupDir, withIntermediateDirectories: true)
            try? fileManager.copyItem(atPath: icnsPath, toPath: backupPath)
        }

        if sourceFile.hasSuffix(".icns") {
            try? fileManager.removeItem(atPath: icnsPath)
            return (try? fileManager.copyItem(atPath: sourceFile, toPath: icnsPath)) != nil
        }

        let tempIconset = NSTemporaryDirectory() + "SpoofTrap_icon.iconset"
        try? fileManager.removeItem(atPath: tempIconset)
        try? fileManager.createDirectory(atPath: tempIconset, withIntermediateDirectories: true)

        let baseSizes = [16, 32, 128, 256, 512]
        for base in baseSizes {
            for scale in [1, 2] {
                let px = base * scale
                let name = scale == 1
                    ? "icon_\(base)x\(base).png"
                    : "icon_\(base)x\(base)@2x.png"
                let dest = "\(tempIconset)/\(name)"
                let proc = Process()
                proc.executableURL = URL(fileURLWithPath: "/usr/bin/sips")
                proc.arguments = ["-z", "\(px)", "\(px)", sourceFile, "--out", dest]
                proc.standardOutput = FileHandle.nullDevice
                proc.standardError = FileHandle.nullDevice
                try? proc.run()
                proc.waitUntilExit()
            }
        }

        let tempIcns = NSTemporaryDirectory() + "SpoofTrap_AppIcon.icns"
        try? fileManager.removeItem(atPath: tempIcns)
        let iconutil = Process()
        iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
        iconutil.arguments = ["-c", "icns", tempIconset, "-o", tempIcns]
        iconutil.standardOutput = FileHandle.nullDevice
        iconutil.standardError = FileHandle.nullDevice
        try? iconutil.run()
        iconutil.waitUntilExit()

        guard fileManager.fileExists(atPath: tempIcns) else { return false }

        do {
            try fileManager.removeItem(atPath: icnsPath)
            try fileManager.copyItem(atPath: tempIcns, toPath: icnsPath)
            try? fileManager.removeItem(atPath: tempIconset)
            try? fileManager.removeItem(atPath: tempIcns)
            return true
        } catch {
            return false
        }
    }

    private func resignBundle(_ appPath: String) {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
        proc.arguments = ["--force", "--deep", "--sign", "-", appPath]
        proc.standardOutput = FileHandle.nullDevice
        proc.standardError = FileHandle.nullDevice
        try? proc.run()
        proc.waitUntilExit()
    }

    private func clearIconCache() {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        proc.arguments = ["Dock"]
        proc.standardOutput = FileHandle.nullDevice
        proc.standardError = FileHandle.nullDevice
        try? proc.run()
        proc.waitUntilExit()
    }

    func restoreOriginals(robloxAppPath: String) {
        let resourcesBase = (robloxAppPath as NSString).appendingPathComponent("Contents/Resources")
        let macosBase = (robloxAppPath as NSString).appendingPathComponent("Contents/MacOS")
        var restoredIcon = false

        for cat in Self.categories {
            for relPath in cat.relativePaths {
                let base = cat.id == "app_icon" ? macosBase : resourcesBase
                let targetPath = (base as NSString).appendingPathComponent(relPath)
                let backupPath = backupPathFor(target: targetPath)

                if fileManager.fileExists(atPath: backupPath) {
                    try? fileManager.removeItem(atPath: targetPath)
                    try? fileManager.copyItem(atPath: backupPath, toPath: targetPath)
                    try? fileManager.removeItem(atPath: backupPath)
                }
            }

            if cat.id == "app_icon" {
                let icnsPath = (robloxAppPath as NSString)
                    .appendingPathComponent("Contents/Resources/AppIcon.icns")
                let icnsBackup = backupPathFor(target: icnsPath)
                if fileManager.fileExists(atPath: icnsBackup) {
                    try? fileManager.removeItem(atPath: icnsPath)
                    try? fileManager.copyItem(atPath: icnsBackup, toPath: icnsPath)
                    try? fileManager.removeItem(atPath: icnsBackup)
                    restoredIcon = true
                }
            }
        }

        if restoredIcon {
            resignBundle(robloxAppPath)
            clearIconCache()
        }

        for i in installedMods.indices {
            installedMods[i].originalBackedUp = false
        }
        saveSettings()
    }

    // MARK: - Storage

    private var modsStorageDir: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("SpoofTrap/Mods")
    }

    private var backupsDir: URL {
        modsStorageDir.appendingPathComponent("Backups")
    }

    private var settingsURL: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("SpoofTrap/mods_settings.json")
    }

    private func backupPathFor(target: String) -> String {
        let hash = target.data(using: .utf8)!.base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
            .prefix(40)
        let ext = (target as NSString).pathExtension
        return backupsDir.appendingPathComponent("\(hash).\(ext)").path
    }

    private func bundledModPath(for mod: InstalledMod) -> String? {
        guard mod.isBuiltIn else { return nil }
        let path = modsStorageDir
            .appendingPathComponent("defaults")
            .appendingPathComponent(mod.categoryId)
            .appendingPathComponent(mod.name)
        return fileManager.fileExists(atPath: path.path) ? path.path : nil
    }

    private func loadSettings() {
        guard let data = try? Data(contentsOf: settingsURL),
              let saved = try? JSONDecoder().decode(SavedModsSettings.self, from: data) else {
            return
        }

        isEnabled = saved.isEnabled
        installedMods = saved.mods
    }

    private func saveSettings() {
        let saved = SavedModsSettings(
            isEnabled: isEnabled,
            mods: installedMods
        )

        do {
            try fileManager.createDirectory(
                at: settingsURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(saved)
            try data.write(to: settingsURL, options: .atomic)
        } catch {
            print("Failed to save mods settings: \(error)")
        }
    }
}

private struct SavedModsSettings: Codable {
    let isEnabled: Bool
    let mods: [InstalledMod]
}
