# SpoofTrap

Launch Roblox on networks that usually block it.

SpoofTrap is a macOS Roblox launcher built for restrictive networks, cleaner setup, and faster recovery when the normal launch flow fails.

<p align="center">
  <a href="https://www.youtube.com/watch?v=qZ7aV8kBDgY">
    <img src="docs/assets/hero-network.jpeg" alt="Watch the SpoofTrap promo video" width="820" />
  </a>
</p>

<p align="center">
  <a href="https://spooftrap.port0.org"><strong>Main site</strong></a>
  ·
  <a href="dist/SpoofTrap-macOS-2026.03.10.5.dmg"><strong>Download for macOS</strong></a>
  ·
  <a href="https://spooftrap.port0.org/windows.html"><strong>Windows beta</strong></a>
</p>

<p align="center">
  <img src="docs/assets/app-screenshot.jpeg" alt="SpoofTrap app screenshot" width="900" />
</p>

## Download

| Platform | Status | Link |
| --- | --- | --- |
| macOS | Available now | [DMG](dist/SpoofTrap-macOS-2026.03.10.5.dmg) |
| macOS alternate builds | Available now | [PKG](dist/SpoofTrap-macOS-2026.03.10.5.pkg) · [ZIP](dist/SpoofTrap-macOS-2026.03.10.5.zip) |
| Windows beta | Public beta | [Windows page](https://spooftrap.port0.org/windows.html) · [Download](https://bit.ly/4bY0AZj) · [Discord](https://discord.gg/32UmsRfVha) |

DMG is the easiest install. PKG and ZIP stay available if you need a different format.

## Quick Read

- macOS launcher for restrictive networks
- local bypass flow with a simpler launch workspace
- faster retries when the normal Roblox launch path fails
- Windows is available as a public beta with rough edges, limited polish, and direct download through the Windows page and Discord

## Updates

- Main site: [spooftrap.port0.org](https://spooftrap.port0.org)
- macOS page: [spooftrap.port0.org/macos.html](https://spooftrap.port0.org/macos.html)
- Windows page: [spooftrap.port0.org/windows.html](https://spooftrap.port0.org/windows.html)
- Socials: [spooftrap.port0.org/socials.html](https://spooftrap.port0.org/socials.html)

## macOS packaging (developers)

SpoofTrap **bundles** the `spoofdpi` binary so users do not download it separately. Source of truth:

- Put or replace the macOS `spoofdpi` at **`Sources/Resources/bin/spoofdpi`** (tracked in git).
- Run **`scripts/package_macos_app.sh`** — it builds the app, copies the executable into `dist/SpoofTrap.app`, copies **`Resources/bin/spoofdpi`** into the bundle, syncs the SwiftPM resource bundle, then **`codesign --force --deep --sign -`** and **`xattr -cr`**.

Then run **`scripts/build_installers.sh`** — it builds **ZIP / DMG / PKG** in `dist/`, copies them into **`docs/dist/`** (what GitHub Pages serves), and prints **SHA-256** lines for `docs/dist/latest.json`.

## Notes

- macOS builds are available through the release files in `dist/` and on the website.
- Windows is available as a public beta. Expect unfinished behavior, bugs, and changes without notice.

## Disclaimer

Use SpoofTrap only on systems and networks where you are authorized to do so. You are responsible for compliance with Roblox rules, local policy, and any network restrictions that apply to your environment.

Windows beta notice: the Windows build is pre-release software provided on an "AS IS" and "AS AVAILABLE" basis, without warranties of any kind to the maximum extent permitted by applicable law. By downloading, installing, or using it, you accept the risks associated with beta software, including instability, incomplete features, and possible disruption or data loss.
