## 2024-05-24 - SSRF and Command Injection through Untrusted Log Data
**Vulnerability:** Extracted application logs containing user-manipulatable input (like placeIds, IPs, and local process IDs extracted via pgrep) were injected directly into URLs (Roblox API, IP-API) and shell processes (/bin/ps, /sbin/ping) without any structural validation.
**Learning:** Even data sourced locally from log files must be treated as hostile input. Processes running parallel or writing to the same logs can easily spoof inputs.
**Prevention:** Strictly validate any log-sourced data against expected formats (e.g., `^[0-9]+$` for PIDs, `^[a-fA-F0-9.:]+$` for IPs) before incorporating it into shell arguments or outbound network requests.
