
## 2024-05-15 - Unvalidated inputs from logs passing to processes and HTTP requests
**Vulnerability:** Extracted IP addresses and PIDs from local application logs were passed directly to `Process()` arguments (like `/sbin/ping` and `/bin/ps`) and URLs (like `ip-api.com`) without strict format validation, exposing the application to command/argument injection and Server-Side Request Forgery (SSRF).
**Learning:** Data parsed from local files (even logs produced by other processes) should always be treated as untrusted input. Maliciously crafted data in the log source could potentially exploit downstream execution paths.
**Prevention:** Strictly validate extracted data against a safe pattern format (e.g., `^[0-9]+$` for PIDs, `^[0-9.]+$` for IPv4 addresses) before use in sensitive operations like `Process` arguments or external API queries.
