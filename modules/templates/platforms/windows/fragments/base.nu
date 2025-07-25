# Windows Template Fragment System - Base Configuration
# Main entry point that imports all essential fragments

# Load configuration from environment or use defaults
let config = {hostname:($env HOSTNAME| default "windows-pc"
),user:($env USER| default "admin"
),password:($env PASSWORD| default "secure-password"
),installPath:($env INSTALL_PATH| default "C:\\Program Files"
),gamesPath:($env GAMES_PATH| default "D:\\Games"
),features:($env FEATURES| default "base"
| split row
","
),securityLevel:($env SECURITY_LEVEL| default "medium"
),performanceProfile:($env PERFORMANCE_PROFILE| default "balanced"
),ci:($env CI| default "false"
),dryRun:($env DRY_RUN| default "false"
)}# CI/CD configuration
let isCI = $config ci=="true"let isDryRun = $config dryRun=="true"let logLevel = 
if $isCI {"debug"}else
{"info"}# Helper functions

def log [message: string]
{let timestamp = (date now
| format date
"%Y-%m-%d %H:%M:%S"
)
if $logLevel =="debug"{print $"($timestamp ) [DEBUG] ($message )"}else
{print $"($timestamp ) [INFO] ($message )"}}
def log-error [message: string]
{let timestamp = (date now
| format date
"%Y-%m-%d %H:%M:%S"
)print $"($timestamp ) [ERROR] ($message )"}
def check-admin-privileges []
{"Checking administrator privileges..." # Check if running as administrator
let isAdmin = (whoami | str contains
"Administrator"
)
if not$isAdmin {"Script must be run as Administrator"exit 1
}"Administrator privileges confirmed"}
def check-windows-version []
{"Checking Windows version..." let winVer = (systeminfo | findstr /B
/C:"OS Version"
)$"Windows version: ($winVer )"# Check if Windows 10 or later
let majorVersion = (systeminfo | findstr /B
/C:"OS Version"
| parse "{*Version *}"
| get Version.0
| split row
"."
| get 0
)
if ($majorVersion | into int
)<10{"Windows 10 or later is required"exit 1
}"Windows version is compatible"}
def check-disk-space []
{"Checking available disk space..." # Check C: drive space
let freeSpace = (Get-PSDrive C
| get free
)let requiredSpace = 50GB
if $freeSpace <$requiredSpace {$"Insufficient disk space. Need at least ($requiredSpace ) free, have ($freeSpace )"exit 1
}$"Available disk space: ($freeSpace )"}
def setup-hostname []
{
if $isDryRun {"DRY RUN: Would set hostname to ($config.hostname)"return }$"Setting hostname to ($config hostname)..."try {wmic computersystem
where
name="%computername%"
call
rename
name=($config hostname)"Hostname updated successfully"}catch
{"Failed to update hostname"}}
def setup-user-account []
{
if $isDryRun {"DRY RUN: Would create user account ($config.user)"return }$"Setting up user account ($config user)..."try {
        # Create user accountnet user
$config user$config password/add
net localgroup
administrators
$config user/add
# Disable default admin account for security
net user
administrator
/active:no
"User account created successfully"}catch
{"Failed to create user account"}}
def setup-directories []
{
if $isDryRun {"DRY RUN: Would create installation directories"return }"Creating installation directories..."try {
        # Create main installation directory
if not($config installPath| path exists
){mkdir $config installPath}# Create games directory

if not($config gamesPath| path exists
){mkdir $config gamesPath}"Installation directories created"}catch
{"Failed to create directories"}}# Import essential fragments

def import-fragments []
{"Importing essential fragments..." # Always import these base fragments
source ./prerequisites.nu
source ./networking.nu
source ./security.nu
source ./performance.nu
source ./maintenance.nu
# Import feature-specific fragments based on configuration

if "gaming"in$config features{"Importing gaming fragment..."source ./gaming.nu
}
if "development"in$config features{"Importing development fragment..."source ./development.nu
}
if "multimedia"in$config features{"Importing multimedia fragment..."source ./multimedia.nu
}
if "productivity"in$config features{"Importing productivity fragment..."source ./productivity.nu
}
if "virtualization"in$config features{"Importing virtualization fragment..."source ./virtualization.nu
}}# Main setup function

def main []
{"Starting Windows configuration setup..." $"CI Mode:  ($isCI )"$"Dry Run Mode:  ($isDryRun )"$"Configuration:  ($config | to json
)"# Run base setup steps
# Import and run fragments
"Windows configuration setup completed successfully" }# Export main function and configuration

export def setup-windows []
{}export-env {
    $env.WINDOWS_CONFIG =  ($config | to json
)
} 
# Script execution is handled by the exported function
