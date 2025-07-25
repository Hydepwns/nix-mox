# Windows Template Fragment - Virtualization
# VM platforms, containers, and virtualization tools

def log [message: string]
{let timestamp = (date now
| format date
"%Y-%m-%d %H:%M:%S"
)print $"($timestamp ) [INFO] ($message )"}
def install-hyper-v []
{"Installing Hyper-V..." "Hyper-V installation completed" }
def install-virtualbox []
{"Installing VirtualBox..." "VirtualBox installation completed" }
def install-vmware []
{"Installing VMware..." "VMware installation completed" }
def install-wsl []
{"Installing Windows Subsystem for Linux..." "WSL installation completed" }
export def setup-virtualization []
{"Setting up virtualization environment..." "Virtualization environment setup completed" }
