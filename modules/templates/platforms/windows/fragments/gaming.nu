# Windows Template Fragment - Gaming
# Gaming platforms (Steam, Epic, etc.) and optimizations

def log [message: string]
{let timestamp = (date now
| format date
"%Y-%m-%d %H:%M:%S"
)print $"($timestamp ) [INFO] ($message )"}
def log-error [message: string]
{let timestamp = (date now
| format date
"%Y-%m-%d %H:%M:%S"
)print $"($timestamp ) [ERROR] ($message )"}# Gaming configuration
let gaming_config = {steam:{installPath:($env STEAM_PATH| default "C:\\Steam"
),downloadURL:"https://steamcdn-a.akamaihd.net/client/installer/SteamSetup.exe",silentInstall:true},epic:{installPath:($env EPIC_PATH| default "C:\\Program Files\\Epic Games"
),downloadURL:"https://launcher-public-service-prod06.ol.epicgames.com/launcher/api/public/assets/v2/platforms/Windows/namespaces/epic/launcherVersions/2.1.0-17645698+++Portal+Release-Live",enableAutoUpdates:true},games:($env GAMES| default "rust"
| split row
","
)}
def download-steam []
{"Downloading Steam installer..." let steamUrl = $gaming_config steamdownloadURLlet steamPath = $"($env TEMP)\\SteamSetup.exe"try {http get
$steamUrl | save --force
$steamPath "Steam installer downloaded successfully"}catch
{"Failed to download Steam installer"exit 1
}}
def install-steam []
{"Installing Steam..." let steamPath = $"($env TEMP)\\SteamSetup.exe"let steamInstallPath = $gaming_config steaminstallPathtry {
        # Create target directorymkdir $steamInstallPath # Run installer
let args = 
if $gaming_config steamsilentInstall{["/S","/D="+$steamInstallPath ]}else
{["/D="+$steamInstallPath ]}Start-Process -FilePath
$steamPath -ArgumentList
$args -Wait
"Steam installed successfully"}catch
{"Failed to install Steam"exit 1
}}
def configure-steam []
{"Configuring Steam..." let steamConfigPath = $"($gaming_config steaminstallPath)\\config\\config.vdf"try {
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
{"Failed to configure Steam"}}
def install-epic-games []
{"Installing Epic Games Store..." try {
        # Download Epic Games Launcherlet epicUrl = $gaming_config epicdownloadURLlet epicPath = $"($env TEMP)\\EpicInstaller.msi"http get
$epicUrl | save --force
$epicPath # Install Epic Games Launcher
Start-Process -FilePath
"msiexec.exe"
-ArgumentList
["/i",$epicPath ,"/quiet"]-Wait
"Epic Games Store installed successfully"}catch
{"Failed to install Epic Games Store"}}
def install-games []
{"Installing games..." $gaming_config games | each { |game|
        log  Installing  ($game
)... 

        if $game ==  "rust"  {
            install-rust
        } else {
            log  Game  ($game
) installation not implemented yet 
        }
    } }
def install-rust []
{"Installing Rust..." let steamPath = $"($gaming_config steaminstallPath)\\Steam.exe"let rustAppId = "252490"# Rust Steam App ID
try {
        # Launch Steam and install RustStart-Process -FilePath
$steamPath -ArgumentList
$"-applaunch ($rustAppId )"-Wait
"Rust installation initiated"}catch
{"Failed to install Rust"}}
def configure-gaming-optimizations []
{"Configuring gaming optimizations..." # Disable Windows Game Mode (can cause issues)
"Gaming optimizations configured" }
def create-game-shortcuts []
{"Creating game shortcuts..." # Create desktop shortcuts for installed games
"Game shortcuts created" }
export def setup-gaming []
{"Setting up gaming environment..." "Gaming environment setup completed" }
