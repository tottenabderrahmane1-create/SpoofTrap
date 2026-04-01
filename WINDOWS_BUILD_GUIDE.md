# SpoofTrap Windows Build Guide

Complete guide to build the Windows version of SpoofTrap - a Roblox bypass launcher app.

---

## What the app does

SpoofTrap runs a local proxy (spoofdpi) that helps bypass Roblox network restrictions. It launches Roblox with proxy settings configured.

---

## Tech Stack

- **Language:** C# / .NET 8
- **UI Framework:** WinUI 3 (Windows App SDK)
- **Packaging:** MSIX for distribution

---

## Core Features

### 1. Main Bypass Functionality

- Start/stop a local spoofdpi proxy on `127.0.0.1:8080`
- Set system proxy or app-specific proxy for Roblox
- Launch Roblox with proxy environment variables
- Configuration presets: Stable, Balanced, Fast, Custom
- Bundle spoofdpi.exe with the app

### 2. License Key System (CRITICAL)

**IMPORTANT: License must be validated with server on EVERY app launch. No offline grace period.**

Connect to existing Supabase backend for license validation.

#### Supabase Details

| Setting | Value |
|---------|-------|
| URL | `https://xucsfvyijnjkwdiiquwy.supabase.co` |
| Anon Key | `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh1Y3Nmdnlpam5qa3dkaWlxdXd5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ5NzY0NDksImV4cCI6MjA5MDU1MjQ0OX0.hfeGgWqqWdIym6Y4BqlW8nlIZ8y7MDmtWynS3bWQ0BM` |

#### License Key Format

Keys follow this pattern: `ST[A-Z0-9]{3}-[A-Z0-9]{5}-[A-Z0-9]{5}-[A-Z0-9]{5}-[A-Z0-9]{5}`

Example: `STYGC-LR6HG-X6FPU-46ZHT-NDQF9`

Regex validation:
```csharp
var pattern = @"^ST[A-Z0-9]{3}-[A-Z0-9]{5}-[A-Z0-9]{5}-[A-Z0-9]{5}-[A-Z0-9]{5}$";
bool isValid = Regex.IsMatch(key.ToUpper().Trim(), pattern);
```

#### API Endpoints

**1. Validate/Activate License**

POST `https://xucsfvyijnjkwdiiquwy.supabase.co/rest/v1/rpc/validate_license`

**Headers:**
```
apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh1Y3Nmdnlpam5qa3dkaWlxdXd5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ5NzY0NDksImV4cCI6MjA5MDU1MjQ0OX0.hfeGgWqqWdIym6Y4BqlW8nlIZ8y7MDmtWynS3bWQ0BM
Content-Type: application/json
```

**Request Body:**
```json
{
  "p_license_key": "STXXX-XXXXX-XXXXX-XXXXX-XXXXX",
  "p_device_id": "<hardware_hash>",
  "p_device_name": "Windows PC",
  "p_platform": "windows",
  "p_app_version": "1.0.0",
  "p_os_version": "Windows 11"
}
```

**Success Response:**
```json
{
  "valid": true,
  "plan": "lifetime",
  "expires_at": null,
  "activation_id": "uuid",
  "newly_activated": true
}
```

**Error Responses:**
```json
{"valid": false, "error": "invalid_key", "message": "License key not found"}
{"valid": false, "error": "revoked", "message": "License has been revoked"}
{"valid": false, "error": "inactive", "message": "License is not active"}
{"valid": false, "error": "expired", "message": "License has expired"}
{"valid": false, "error": "max_activations", "message": "Maximum devices reached", "max": 2, "current": 2}
```

**2. Deactivate Device**

POST `https://xucsfvyijnjkwdiiquwy.supabase.co/rest/v1/rpc/deactivate_device`

```json
{
  "p_license_key": "STXXX-XXXXX-XXXXX-XXXXX-XXXXX",
  "p_device_id": "<hardware_hash>"
}
```

**3. Heartbeat (send every hour while app is running)**

POST `https://xucsfvyijnjkwdiiquwy.supabase.co/rest/v1/rpc/license_heartbeat`

```json
{
  "p_license_key": "STXXX-XXXXX-XXXXX-XXXXX-XXXXX",
  "p_device_id": "<hardware_hash>"
}
```

Response: `{"valid": true/false}` - if false, revoke Pro status immediately

#### Device ID Generation (Windows)

Use WMI to get hardware identifiers and SHA256 hash them:

```csharp
using System.Management;
using System.Security.Cryptography;
using System.Text;

public static string GetDeviceId()
{
    var sb = new StringBuilder();
    
    // CPU ID
    using (var searcher = new ManagementObjectSearcher("SELECT ProcessorId FROM Win32_Processor"))
    {
        foreach (var obj in searcher.Get())
            sb.Append(obj["ProcessorId"]?.ToString() ?? "");
    }
    
    // Motherboard Serial
    using (var searcher = new ManagementObjectSearcher("SELECT SerialNumber FROM Win32_BaseBoard"))
    {
        foreach (var obj in searcher.Get())
            sb.Append(obj["SerialNumber"]?.ToString() ?? "");
    }
    
    // BIOS Serial
    using (var searcher = new ManagementObjectSearcher("SELECT SerialNumber FROM Win32_BIOS"))
    {
        foreach (var obj in searcher.Get())
            sb.Append(obj["SerialNumber"]?.ToString() ?? "");
    }
    
    // Hash
    var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(sb.ToString()));
    return Convert.ToHexString(bytes).ToLower();
}
```

#### License Validation Flow

**On App Launch:**
1. Load stored license from `%APPDATA%\SpoofTrap\license.json`
2. If stored license exists:
   - Set `IsValidated = false` (don't trust stored data)
   - Call `validate_license` API with stored key
   - If valid: set `IsValidated = true`, start heartbeat timer
   - If invalid: clear stored license, show error
3. If no stored license: show upgrade card with license input field

**NO GRACE PERIOD** - If network fails, Pro features are locked.

#### License Storage (local)

Store in `%APPDATA%\SpoofTrap\license.json`:

```json
{
  "licenseKey": "STXXX-XXXXX-XXXXX-XXXXX-XXXXX",
  "plan": "lifetime",
  "expiresAt": null,
  "activatedAt": "2026-03-29T12:00:00Z",
  "deviceId": "abc123..."
}
```

### 3. Pro Features (require valid license)

**Pro Only:**
- Fast & Custom presets
- Full FastFlags editor (add/edit/remove flags)
- Advanced settings (Chunk Size, Disorder toggle)
- Detailed session stats

**Free Users Get:**
- Stable & Balanced presets
- Basic FastFlags ON/OFF toggle
- FastFlags presets (Performance, Graphics, etc.) - read-only apply
- Core bypass functionality
- Choose spoofdpi binary location

### 4. FastFlags

Write flags to: `%LOCALAPPDATA%\Roblox\ClientSettings\ClientAppSettings.json`

**Create directory if it doesn't exist!**

```csharp
var flagsDir = Path.Combine(
    Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
    "Roblox", "ClientSettings"
);
Directory.CreateDirectory(flagsDir);
var flagsPath = Path.Combine(flagsDir, "ClientAppSettings.json");
```

**Example flags file:**
```json
{
  "FFlagDebugGraphicsPreferVulkan": "true",
  "DFIntTaskSchedulerTargetFps": 9999,
  "FFlagHandleAltEnterFullscreenManually": "false"
}
```

**Presets:**

| Preset | Description | Free |
|--------|-------------|------|
| Stable | Minimal changes, safest | Yes |
| Balanced | Some optimizations | Yes |
| Performance | Max FPS focus | Yes |
| Graphics | Visual quality | Yes |
| Fast | Aggressive optimizations | PRO |
| Custom | User-defined | PRO |

**Show green "ON" badge next to "FastFlags" title when enabled.**

### 5. Proxy Settings

**Proxy Modes:**
- **App** (recommended): Sets `http_proxy` and `https_proxy` environment variables when launching Roblox
- **System**: Uses `netsh winhttp set proxy 127.0.0.1:8080`

**spoofdpi launch arguments:**
```
spoofdpi.exe -addr 127.0.0.1 -port 8080 -dns-addr 8.8.8.8 -enable-doh -doh-url https://1.1.1.1/dns-query -chunk-size 1 -disorder
```

Advanced settings (PRO only):
- Chunk Size: 1-16 (default 1)
- Disorder: true/false (default true)

### 6. UI Design

Modern dark theme matching macOS version:

- Mica backdrop (Windows 11) or Acrylic (Windows 10)
- Purple/cyan accent colors
- Two-column layout
- PRO badge for licensed users
- Green "ON" badge for FastFlags status
- Session log with colored lines (green=success, red=error)

**Color Palette:**
```
Background: #0f1219 (dark blue-gray)
Card Background: rgba(255,255,255,0.05)
Card Border: rgba(255,255,255,0.08)
Accent Primary: #72d5f5 (cyan)
Accent Secondary: #9333ea (purple)
Success: #4ade80 (green)
Error: #f87171 (red)
Warning: #fbbf24 (yellow)
Text Primary: #ffffff
Text Secondary: rgba(255,255,255,0.7)
Text Muted: rgba(255,255,255,0.4)
```

**Main Button States:**
- Stopped: Cyan gradient, "Start Session"
- Running: Green tint, "Stop Session"
- Starting: Yellow tint, "Starting..."

---

## Project Structure

```
SpoofTrapWindows/
├── SpoofTrapWindows.sln
├── SpoofTrapWindows/
│   ├── App.xaml
│   ├── App.xaml.cs
│   ├── MainWindow.xaml
│   ├── MainWindow.xaml.cs
│   ├── ViewModels/
│   │   ├── MainViewModel.cs
│   │   └── ViewModelBase.cs
│   ├── Services/
│   │   ├── LicenseManager.cs
│   │   ├── ProManager.cs
│   │   ├── ProxyService.cs
│   │   ├── FastFlagsManager.cs
│   │   └── SettingsService.cs
│   ├── Models/
│   │   ├── LicenseInfo.cs
│   │   ├── FastFlag.cs
│   │   ├── ProxyPreset.cs
│   │   └── SessionStats.cs
│   ├── Controls/
│   │   ├── GlassCard.xaml
│   │   ├── SettingRow.xaml
│   │   └── StatusPill.xaml
│   ├── Assets/
│   │   ├── icon.ico
│   │   └── spooftrap-icon.png
│   ├── Resources/
│   │   └── spoofdpi.exe
│   └── Package.appxmanifest
└── README.md
```

---

## Key Classes

### LicenseManager.cs

```csharp
public class LicenseManager : INotifyPropertyChanged
{
    private const string SupabaseUrl = "https://xucsfvyijnjkwdiiquwy.supabase.co";
    private const string SupabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh1Y3Nmdnlpam5qa3dkaWlxdXd5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ5NzY0NDksImV4cCI6MjA5MDU1MjQ0OX0.hfeGgWqqWdIym6Y4BqlW8nlIZ8y7MDmtWynS3bWQ0BM";
    
    public bool IsValidated { get; private set; }
    public bool IsValidating { get; private set; }
    public LicenseInfo? CurrentLicense { get; private set; }
    public string? ValidationError { get; private set; }
    
    public string DeviceId => GetDeviceId();
    public string DeviceName => Environment.MachineName;
    public string AppVersion => "1.0.0";
    public string OsVersion => Environment.OSVersion.VersionString;
    
    // Call on app startup
    public async Task InitializeAsync()
    {
        var stored = LoadStoredLicense();
        if (stored != null)
        {
            IsValidated = false; // Don't trust stored data
            await ValidateOnLaunchAsync(stored);
        }
    }
    
    private async Task ValidateOnLaunchAsync(LicenseInfo stored)
    {
        IsValidating = true;
        var success = await ActivateAsync(stored.LicenseKey);
        if (!success)
        {
            ClearLicense();
            ValidationError ??= "License validation failed. Please check your connection.";
        }
        IsValidating = false;
    }
    
    public async Task<bool> ActivateAsync(string licenseKey);
    public async Task<bool> DeactivateAsync();
    
    private void StartHeartbeat(); // Timer every 3600 seconds
    private void StopHeartbeat();
    private async Task SendHeartbeatAsync();
    
    private void SaveLicense(LicenseInfo license);
    private LicenseInfo? LoadStoredLicense();
    private void ClearLicense();
    
    private static string GetDeviceId();
    private static bool IsValidKeyFormat(string key);
}
```

### ProManager.cs

```csharp
public class ProManager : INotifyPropertyChanged
{
    private readonly LicenseManager _licenseManager;
    
    public bool IsPro => _licenseManager.IsValidated;
    
    // Feature checks
    public bool CanUsePreset(string preset) => 
        preset is "stable" or "balanced" || IsPro;
    
    public bool CanEditFastFlags => IsPro;
    public bool CanAccessAdvanced => IsPro;
    public bool CanViewStats => IsPro;
}
```

### MainViewModel.cs

```csharp
public class MainViewModel : ViewModelBase
{
    public LicenseManager LicenseManager { get; }
    public ProManager ProManager { get; }
    public FastFlagsManager FastFlagsManager { get; }
    
    // State
    public enum BypassState { Stopped, Starting, Running, Stopping }
    public BypassState State { get; set; }
    public bool IsRunning => State == BypassState.Running;
    
    // Settings
    public string Preset { get; set; } = "stable"; // stable, balanced, fast, custom
    public string ProxyScope { get; set; } = "app"; // app, system
    public int ChunkSize { get; set; } = 1;
    public bool Disorder { get; set; } = true;
    public bool HybridLaunch { get; set; } = false;
    public int LaunchDelay { get; set; } = 0;
    
    // Paths
    public string RobloxPath { get; set; }
    public string SpoofdpiPath { get; set; }
    public bool RobloxInstalled => !string.IsNullOrEmpty(RobloxPath) && File.Exists(RobloxPath);
    public bool BinaryAvailable => !string.IsNullOrEmpty(SpoofdpiPath) && File.Exists(SpoofdpiPath);
    
    // Logs
    public ObservableCollection<string> Logs { get; }
    
    // Commands
    public ICommand ToggleBypassCommand { get; }
    public ICommand ChooseRobloxCommand { get; }
    public ICommand ChooseSpoofdpiCommand { get; }
    public ICommand CopyLogsCommand { get; }
    
    public async Task StartSessionAsync();
    public async Task StopSessionAsync();
}
```

---

## Settings Persistence

Store in `%APPDATA%\SpoofTrap\settings.json`:

```json
{
  "robloxPath": "C:\\Users\\...\\Roblox\\...",
  "spoofdpiPath": "C:\\...",
  "preset": "stable",
  "proxyScope": "app",
  "chunkSize": 1,
  "disorder": true,
  "hybridLaunch": false,
  "launchDelay": 0,
  "reducedMotion": false
}
```

---

## Dependencies (NuGet)

```xml
<PackageReference Include="Microsoft.WindowsAppSDK" Version="1.5.*" />
<PackageReference Include="CommunityToolkit.Mvvm" Version="8.*" />
<PackageReference Include="CommunityToolkit.WinUI.UI.Controls" Version="7.*" />
<PackageReference Include="System.Management" Version="8.*" />
```

---

## Implementation Order

1. **Project Setup** - Create WinUI 3 project
2. **Settings Service** - Load/save settings
3. **LicenseManager** - Critical for Pro features
4. **ProManager** - Feature gating
5. **Basic UI** - Main window layout
6. **MainViewModel** - Core state
7. **ProxyService** - spoofdpi management
8. **FastFlagsManager** - Flag editing
9. **Polish** - Error handling, packaging

---

## Testing

**Test License Key:**
```
STVQ8-M597T-NQRYF-HZZAD-XH7HH
```

Or create new via Discord `/license create` command.

---

## Distribution

Download spoofdpi Windows binary from: https://github.com/xvzc/SpoofDPI/releases

Bundle it with the app in the Resources folder.

---

## Notes

- License system is shared - same database, same keys work on both platforms
- Device activations are tracked per-platform (user can have 1 Mac + 1 Windows active)
- The macOS Swift source is in `Sources/` for reference
- Keep UI consistent between platforms for brand recognition
- No offline grace period - must validate with server every launch
