
## $(date +%Y-%m-%d) - Command Injection and SSRF via Unvalidated Log Extraction
**Vulnerability:** Extracted variables from log files (e.g. IPs and PIDs) were being passed directly into `Process()` command arguments (`ping`, `ps`) and HTTP requests without prior format validation, opening the door to command injection and Server-Side Request Forgery if a malicious actor controls the log contents.
**Learning:** Even internal log files should be treated as untrusted data sources when their contents can be influenced by external inputs (such as user events or server responses).
**Prevention:** Strictly validate extracted variables using format-specific regular expressions (e.g., `^[a-zA-Z0-9.:-]+$` for IPs, `^[0-9]+$` for PIDs) before using them in sensitive contexts like external process arguments or URL construction.
