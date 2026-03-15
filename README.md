# SpoofTrap

SpoofTrap is a macOS launcher for Roblox-focused local proxy workflows. It wraps `spoofdpi` in a cleaner terminal/app experience, lets you save reusable profiles, and launches selected macOS apps through the local proxy without requiring a traditional VPN client.

## Features

- Starts a local `spoofdpi` proxy on `127.0.0.1:8080`
- Launches selected `.app` bundles through that proxy
- Supports Roblox-oriented retry guidance during launch
- Saves named profiles with app lists and proxy settings
- Offers preset-based proxy tuning plus custom overrides
- Supports Hydra Split for second-wave app launching
- Can switch between app-scoped proxy launch and system proxy mode
- Packages distributable `.zip` and `.pkg` releases for macOS

## Roblox Notes

- Recommended default setup is the `stable` preset
- If Roblox opens but shows an HTTP or join warning, retry the join flow a few times before resetting the bypass
- Repeated `request blocked` messages can still appear while Roblox is working normally
- System proxy mode is mainly useful for browser-based launch flows

## Run

Open the app
