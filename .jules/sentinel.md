## 2024-05-24 - Fix Command Injection and SSRF vulnerabilities in RobloxLogWatcher

**Vulnerability:** Untrusted variables extracted from raw log files (`pid`, `ip`, and `placeId`) were passed directly to `Process()` shell arguments or interpolated into `URL(string:)` initializers without validation. A maliciously crafted log file could trigger arbitrary command execution or SSRF.
**Learning:** Even when parsing local files, if the content is partially or completely untrusted (like a third-party app log), any extracted data must be strictly validated before being used in sensitive sinks like shell execution or network requests.
**Prevention:** Always validate extracted variables using strict regex filters (e.g., `^[0-9]+$` for IDs/PIDs, `^[a-fA-F0-9.:]+$` for IPs) before utilizing them in functions that touch the network or the operating system shell.
