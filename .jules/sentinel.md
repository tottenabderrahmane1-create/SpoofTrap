## 2024-04-27 - [Command Injection and SSRF Risks in Log Parsing]
**Vulnerability:** Extracted strings from application logs (like IPs and PIDs) were being passed directly to Process arguments and network requests without strict format validation, leading to potential command injection and SSRF vulnerabilities if the logs were manipulated.
**Learning:** Even internal tool outputs like pgrep or parsed log strings must be treated as untrusted input. Malicious log entries can inject unexpected payloads.
**Prevention:** Always validate extracted log data against strict regular expressions (e.g., ^[0-9]+$ for PIDs, ^[a-fA-F0-9.:]+$ for IPs) before using them in sensitive operations.
