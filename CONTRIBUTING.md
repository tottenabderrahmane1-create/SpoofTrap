# Contributing to SpoofTrap

SpoofTrap is built and maintained by inqweqwe, a developer based in Qatar where Roblox has been blocked since August 2025. Contributions are welcome but please read this whole document first — there are some specific things this project does and doesn't accept.

## Reporting bugs

Open a GitHub issue with:

- Your operating system and version (e.g., macOS 14.4)
- SpoofTrap version
- What you were trying to do
- What actually happened
- Any relevant log output (you can find logs in the app's Settings > Logs panel)

The issue tracker is the right place for bugs — not Discord. Discord is for support questions and community chat.

## Suggesting features

Open a GitHub issue with the "feature request" label. Be specific about what you want and why.

Note: not all suggestions will be implemented. SpoofTrap has a deliberate scope (Roblox launcher for blocked countries) and feature requests outside that scope will usually be declined politely.

## Submitting code

1. Fork the repo
2. Create a feature branch off main
3. Make your change small and focused
4. Open a pull request with a clear description of what you changed and why
5. Be patient — I read every PR but I don't always have time to review immediately

For larger changes (anything touching the bypass engine, the license system, or the UI architecture), open an issue first to discuss the approach before writing code. This saves everyone time.

## Code style

Follow the existing style in the file you're editing. Don't reformat unrelated code. Don't introduce new third-party dependencies without discussing it in an issue first.

## What kinds of contributions are welcome

- Bug fixes
- Translations of UI strings into Turkish, Arabic, Russian, or any other language relevant to blocked-country audiences
- Documentation improvements
- New presets or FastFlag combinations that work in specific countries (please include which country/ISP you tested on)
- Small UX improvements

## What kinds of contributions are NOT welcome

- Anything that removes, weakens, or works around the license check
- Anything that adds telemetry or external network calls without disclosure
- Anything that turns SpoofTrap into a general VPN or proxy tool
- New bundled third-party binaries beyond the existing SpoofDPI
- Cosmetic refactors that don't change behavior
- AI-generated code submitted without human review

## Code of Conduct

By contributing to SpoofTrap you agree to the [Code of Conduct](CODE_OF_CONDUCT.md). Read it before participating.

## Questions

If you have a question that doesn't fit anywhere above, ask in Discord: https://discord.gg/62A4PejJXR
