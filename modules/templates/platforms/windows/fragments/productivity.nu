# Windows Template Fragment - Productivity
# Office suites, collaboration tools, and utilities

def log [message: string]
{let timestamp = (date now
| format date
"%Y-%m-%d %H:%M:%S"
)print $"($timestamp ) [INFO] ($message )"}
def install-office-suite []
{"Installing office suite..." "Office suite installation completed" }
def install-collaboration-tools []
{"Installing collaboration tools..." "Collaboration tools installation completed" }
def install-utilities []
{"Installing productivity utilities..." "Productivity utilities installation completed" }
export def setup-productivity []
{"Setting up productivity environment..." "Productivity environment setup completed" }
