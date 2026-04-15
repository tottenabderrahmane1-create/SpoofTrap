
## 2024-04-15 - [Unvalidated Process/Log Inputs Cause Injection Risks]
**Vulnerability:** Extracted IP addresses, Place IDs, and Process IDs from logs and other process outputs were used directly in shell commands (`Process()` arguments) and URLs without validation.
**Learning:** Process outputs (like `pgrep` or parsed logs) must not be trusted implicitly. Command arguments and URL paths built from extracted data can lead to Command Injection (arguments passing) and Server-Side Request Forgery (SSRF) if the log data is manipulated or malformed.
**Prevention:** Always validate extracted data against a strict regular expression (e.g., `^[0-9]+$` for PIDs, `^[a-fA-F0-9.:]+$` for IPs) before incorporating it into `Process()` arguments, shell scripts, or internal/external API requests.
