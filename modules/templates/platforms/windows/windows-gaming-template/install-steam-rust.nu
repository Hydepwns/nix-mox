# Windows Gaming Template: Steam and Rust Installation Script
# This script automates the installation of Steam and Rust on Windows

# Load configuration from JSON
let config = (open config.json
)# CI/CD configuration
let isCI = $env CI=="true"let logLevel = 
if $isCI {"debug"}else
{"info"}# Helper functions

def log [message: string]
{let timestamp = (date now
| format date
"%Y-%m-%d %H:%M:%S"
)
if $logLevel =="debug"{print $"($timestamp ) [DEBUG] ($message )"}else
{print $"($timestamp ) [INFO] ($message )"}}
def check-prerequisites []
{"Checking prerequisites..." # Check if running as administrator
let isAdmin = (whoami | str contains
"Administrator"
)
if not$isAdmin {error make {msg:"Script must be run as Administrator"}}# Check Windows version
let winVer = (systeminfo | findstr /B
/C:"OS Version"
)$"Windows version: ($winVer )"# Check available disk space
let freeSpace = (Get-PSDrive C
| get free
)
if $freeSpace <50GB{error make {msg:"Insufficient disk space. Need at least 50GB free."}}}
def download-steam []
{"Downloading Steam installer..." let steamUrl = $config steamdownloadURLlet steamPath = $"($env TEMP)\\SteamSetup.exe"try {http get
$steamUrl | save --force
$steamPath "Steam installer downloaded successfully"}catch
{error make {msg:"Failed to download Steam installer"}}}
def install-steam []
{"Installing Steam..." let steamPath = $"($env TEMP)\\SteamSetup.exe"let steamInstallPath = $config steaminstallPathtry {
        # Create target directorymkdir $steamInstallPath # Run installer
let args = 
if $config steamsilentInstall{["/S","/D="+$steamInstallPath ]}else
{["/D="+$steamInstallPath ]}Start-Process -FilePath
$steamPath -ArgumentList
$args -Wait
"Steam installed successfully"}catch
{error make {msg:"Failed to install Steam"}}}
def install-rust []
{"Installing Rust..." let steamPath = $"($config steaminstallPath)\\Steam.exe"let rustAppId = $config rustappIdtry {
        # Launch Steam and install RustStart-Process -FilePath
$steamPath -ArgumentList
$"-applaunch ($rustAppId )"-Wait
"Rust installation initiated"}catch
{error make {msg:"Failed to install Rust"}}}
def configure-steam []
{"Configuring Steam..." let steamConfigPath = $"($config steaminstallPath)\\config\\config.vdf"try {
        # Create or update Steam configurationlet configContent = 'InstallConfigStore
{
    "Software"
    {
        "Valve"
        {
            "Steam"
            {
                "AutoUpdateWindowEnabled"    "0"
                "AllowDownloadsDuringAnyApp"    "1"
                "StreamingThrottleEnabled"    "0"
                "AllowDownloadsWhileAnyAppRunning"    "1"
                "DownloadUsageTimestamp"    "0"
            }
        }
    }
}'$configContent | save --force
$steamConfigPath "Steam configuration updated"}catch
{error make {msg:"Failed to configure Steam"}}}
def main []
{"Starting Steam and Rust installation..." $"CI Mode:  ($isCI )"# Run installation steps
# Create a config for the run script
let runConfig = {steam_path:$config steaminstallPath,rust_path:$config rustinstallPath,rust_app_id:$config rustappId}$runConfig | to json
| save run.json
"Installation completed successfully"}# Run the main function
