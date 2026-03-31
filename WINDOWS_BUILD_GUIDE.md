# SpoofTrap Windows Build Guide

Create a Windows version of SpoofTrap - a Roblox bypass launcher app.

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

### 2. License Key System (IMPORTANT)

Connect to existing Supabase backend for license validation.

#### Supabase Details

| Setting | Value |
|---------|-------|
| URL | `https://xucsfvyijnjkwdiiquwy.supabase.co` |
| Anon Key | `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh1Y3Nmdnlpam5qa3dkaWlxdXd5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ5NzY0NDksImV4cCI6MjA5MDU1MjQ0OX0.hfeGgWqqWdIym6Y4BqlW8nlIZ8y7MDmtWynS3bWQ0BM` |

#### API Endpoint

**POST** `/rest/v1/rpc/validate_license`

**Headers:**
```
apikey: <anon_key>
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
{"valid": false, "error": "expired", "message": "License has expired"}
{"valid": false, "error": "max_activations", "message": "Maximum devices reached", "max": 2, "current": 2}
```

#### Other API Endpoints

**Deactivate Device:** POST `/rest/v1/rpc/deactivate_device`
```json
{
  "p_license_key": "STXXX-XXXXX-XXXXX-XXXXX-XXXXX",
  "p_device_id": "<hardware_hash>"
}
```

**Heartbeat:** POST `/rest/v1/rpc/license_heartbeat`
```json
{
  "p_license_key": "STXXX-XXXXX-XXXXX-XXXXX-XXXXX",
  "p_device_id": "<hardware_hash>"
}
```

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

### 3. Pro Features (require valid license)

**Pro Only:**
- Fast & Custom presets
- Full FastFlags editor
- Advanced settings
- Detailed session stats

**Free Users Get:**
- Stable & Balanced presets
- Basic FastFlags presets (read-only)
- Core bypass functionality

### 4. FastFlags

Write flags to: `%LOCALAPPDATA%\Roblox\ClientSettings\ClientAppSettings.json`

```json
{
  "FFlagDebugGraphicsPreferVulkan": "true",
  "DFIntTaskSchedulerTargetFps": 9999,
  "FFlagHandleAltEnterFullscreenManually": "false"
}
```

**Preset Examples:**

| Preset | Flags |
|--------|-------|
| Stable | Minimal changes, safest |
| Balanced | Some optimizations |
| Fast | Max FPS, reduced quality (PRO) |
| Custom | User-defined (PRO) |

### 5. UI Design

Modern dark theme matching macOS version:

- Glassmorphism/acrylic effects (Mica)
- Purple/cyan accent colors
- Two-column layout
- Animated elements
- PRO badge for licensed users

**Color Palette:**
```
Background: #1a1a2e
Card: rgba(255,255,255,0.05)
Accent Primary: #9333ea (purple)
Accent Secondary: #06b6d4 (cyan)
Text: #ffffff
Text Muted: rgba(255,255,255,0.6)
```

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
│   │   ├── BypassViewModel.cs
│   │   └── ViewModelBase.cs
│   ├── Services/
│   │   ├── LicenseManager.cs
│   │   ├── ProxyService.cs
│   │   ├── FastFlagsManager.cs
│   │   └── RobloxLauncher.cs
│   ├── Models/
│   │   ├── LicenseInfo.cs
│   │   ├── FastFlag.cs
│   │   └── ConfigPreset.cs
│   ├── Views/
│   │   ├── SettingsCard.xaml
│   │   ├── LogCard.xaml
│   │   ├── FastFlagsCard.xaml
│   │   └── UpgradeCard.xaml
│   ├── Assets/
│   │   └── icon.ico
│   └── Package.appxmanifest
├── spoofdpi.exe (bundled binary)
└── README.md
```

---

## Key Classes to Create

### LicenseManager.cs

Handles all license operations:

```csharp
public class LicenseManager : INotifyPropertyChanged
{
    private const string SupabaseUrl = "https://xucsfvyijnjkwdiiquwy.supabase.co";
    private const string SupabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...";
    
    public bool IsValidated { get; private set; }
    public LicenseInfo? CurrentLicense { get; private set; }
    public string? ValidationError { get; private set; }
    
    public async Task<bool> ActivateAsync(string licenseKey);
    public async Task<bool> DeactivateAsync();
    public async Task ValidateStoredLicenseAsync();
    
    private string GetDeviceId();
    private void StartHeartbeat();
    private void SaveLicenseLocally(LicenseInfo license);
    private LicenseInfo? LoadStoredLicense();
}
```

### BypassViewModel.cs

Main view model for the app:

```csharp
public class BypassViewModel : ViewModelBase
{
    public LicenseManager LicenseManager { get; }
    public FastFlagsManager FastFlagsManager { get; }
    
    public bool IsRunning { get; set; }
    public string SelectedPreset { get; set; } = "stable";
    public string ProxyScope { get; set; } = "system"; // or "app"
    public ObservableCollection<string> Logs { get; }
    
    public string RobloxPath { get; set; }
    public string SpoofdpiPath { get; set; }
    
    public ICommand StartCommand { get; }
    public ICommand StopCommand { get; }
    public ICommand ChooseRobloxPathCommand { get; }
    
    private Process? _spoofdpiProcess;
    
    public async Task StartBypassAsync();
    public async Task StopBypassAsync();
    private void LaunchRoblox();
    private void SetSystemProxy(bool enable);
}
```

### ProxyService.cs

Manages system proxy settings:

```csharp
public class ProxyService
{
    public void EnableSystemProxy(string address, int port)
    {
        // Use netsh or registry
        // netsh winhttp set proxy 127.0.0.1:8080
    }
    
    public void DisableSystemProxy()
    {
        // netsh winhttp reset proxy
    }
    
    public Process StartSpoofdpi(string path, string[] args);
}
```

### FastFlagsManager.cs

Manages Roblox FastFlags:

```csharp
public class FastFlagsManager
{
    private static readonly string FlagsPath = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
        "Roblox", "ClientSettings", "ClientAppSettings.json"
    );
    
    public List<FastFlag> AllowedFlags { get; }
    public Dictionary<string, object> CurrentFlags { get; }
    
    public void ApplyPreset(string preset);
    public void SetFlag(string name, object value);
    public void RemoveFlag(string name);
    public void SaveToRoblox();
    public void LoadFromRoblox();
}
```

---

## Implementation Order

1. **Project Setup** - Create WinUI 3 project with proper dependencies
2. **LicenseManager** - Critical for Pro features
3. **Basic UI** - Main window with two-column layout
4. **BypassViewModel** - Core functionality
5. **ProxyService** - spoofdpi management
6. **FastFlagsManager** - Flag editing
7. **Pro Feature Gating** - Lock features based on license
8. **Polish** - Animations, error handling, packaging

---

## Dependencies (NuGet)

```xml
<PackageReference Include="Microsoft.WindowsAppSDK" Version="1.4.*" />
<PackageReference Include="CommunityToolkit.Mvvm" Version="8.*" />
<PackageReference Include="System.Management" Version="8.*" />
```

---

## spoofdpi Arguments

Same as macOS version:

```
spoofdpi.exe -addr 127.0.0.1 -port 8080 -dns-addr 8.8.8.8 -enable-doh -doh-url https://1.1.1.1/dns-query
```

Download Windows binary from: https://github.com/xvzc/SpoofDPI/releases

---

## Testing License

Use this test key (already in database):
```
STYGC-LR6HG-X6FPU-46ZHT-NDQF9
```

Or create new ones via Discord bot `/license create` command.

---

## Notes

- The macOS version source is in this same repo under `Sources/` for reference
- License system is shared - same database, same keys work on both platforms
- Device activations are tracked per-platform (user can have 1 Mac + 1 Windows)
- Keep UI consistent between platforms for brand recognition
