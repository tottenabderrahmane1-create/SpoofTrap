
## 2026-04-19 - Strict Validation of Extracted Data
**Vulnerability:** Extracted strings from logs and shell commands (like IPs or PIDs) were used directly in `Process()` arguments and `URLSession` URLs, exposing the application to Command/Argument Injection and SSRF if the parsed output or remote endpoint gets manipulated.
**Learning:** Even if data is sourced from seemingly benign regex captures or command outputs (e.g., `pgrep`), it must be strictly validated against an expected format (e.g., `^[0-9]+$` for PIDs) before being used in sensitive operations. This is a crucial defense-in-depth measure.
**Prevention:** Always implement strict regex validation immediately before passing any dynamically sourced input into `Process()`, file paths, or network requests.
