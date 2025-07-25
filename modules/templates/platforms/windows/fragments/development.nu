# Windows Template Fragment - Development
# Development tools, IDEs, and programming languages

def log [message: string]
{let timestamp = (date now
| format date
"%Y-%m-%d %H:%M:%S"
)print $"($timestamp ) [INFO] ($message )"}
def install-vscode []
{"Installing Visual Studio Code..." "VS Code installation completed" }
def install-git []
{"Installing Git..." "Git installation completed" }
def install-docker []
{"Installing Docker..." "Docker installation completed" }
def install-nodejs []
{"Installing Node.js..." "Node.js installation completed" }
def install-python []
{"Installing Python..." "Python installation completed" }
export def setup-development []
{"Setting up development environment..." "Development environment setup completed" }
