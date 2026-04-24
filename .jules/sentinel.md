## 2026-04-24 - Command Injection in App Relaunch Flow
**Vulnerability:** Command injection in `UpdateChecker.swift` via `Process` execution of `/bin/sh -c` with unescaped string interpolation containing an application bundle path.
**Learning:** Constructing shell commands with string interpolation using potentially user-controlled or dynamically resolved paths (like `Bundle.main.bundleURL.path`) allows an attacker to execute arbitrary commands if the application is stored in a directory with shell metacharacters (e.g. `SpoofTrap; rm -rf /`).
**Prevention:** Avoid using external shell invocation (via `Process` running `/bin/sh`) whenever a native API is available. Use `NSWorkspace.shared.openApplication(at:configuration:completionHandler:)` to relaunch an application safely.
