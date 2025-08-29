# Development-related Makefile targets
# Include this file in the main Makefile

# Editor extension targets
build-zed-extension:
	@echo "🛠️  Building Zed extension..."
	cd extensions/zed && cargo build --release

build-vscode-extension:
	@echo "🛠️  Building VSCode extension..."
	cd extensions/vscode && npm install && npm run compile

install-synthwave84-zed:
	@echo "🌈 Installing Synthwave84 theme for Zed..."
	@if [ ! -d ~/.config/zed/themes ]; then mkdir -p ~/.config/zed/themes; fi
	@if [ ! -d ~/.config/zed/themes/synthwave84 ]; then \
		git clone https://github.com/Hydepwns/synthwave84-zed ~/.config/zed/themes/synthwave84; \
		echo "✅ Synthwave84 theme installed for Zed"; \
	else \
		echo "🔄 Updating Synthwave84 theme for Zed..."; \
		cd ~/.config/zed/themes/synthwave84 && git pull; \
	fi

# DRY dashboard pattern
dashboard: check-nushell
	@echo "📊 Launching overview dashboard..."
	$(NUSHELL) scripts/dashboard.nu overview

# Parameterized dashboard targets
dashboard-%: check-nushell
	@echo "📊 Launching $* dashboard..."
	$(NUSHELL) scripts/dashboard.nu $*

# DRY validation pattern
validate: check-nushell
	@echo "✅ Running basic validation..."
	$(NUSHELL) scripts/validate.nu basic

# Parameterized validation targets
validate-%: check-nushell
	@echo "✅ Running $* validation..."
	$(NUSHELL) scripts/validate.nu $*
	$(NUSHELL) scripts/validate.nu gaming

validate-storage: check-nushell
	@echo "💾 Running storage validation..."
	$(NUSHELL) scripts/validate.nu storage

validate-pre-rebuild: check-nushell
	@echo "🛡️  Running pre-rebuild validation..."
	$(NUSHELL) scripts/validate.nu pre-rebuild

# Storage operations
storage-guard: check-nushell
	@echo "💾 Running storage safety guard..."
	$(NUSHELL) scripts/storage.nu guard

storage-fix: check-nushell
	@echo "🔧 Fixing storage configuration..."
	$(NUSHELL) scripts/storage.nu fix

storage-health: check-nushell
	@echo "🏥 Checking storage health..."
	$(NUSHELL) scripts/storage.nu health-check

# Display troubleshooting
display-troubleshoot: check-nushell
	@echo "🖥️  Running display troubleshooting..."
	$(NUSHELL) scripts/testing/display/kde-display-troubleshoot.nu --verbose

display-fix: check-nushell
	@echo "🔧 Applying display fixes..."
	$(NUSHELL) scripts/testing/display/kde-display-troubleshoot.nu --fix --verbose

emergency-display-recovery: check-nushell
	@echo "🚨 Running emergency display recovery..."
	$(NUSHELL) scripts/emergency-display-recovery.nu --auto

# Coverage operations
coverage: check-nushell
	@echo "📊 Generating LCOV coverage report..."
	$(NUSHELL) scripts/coverage.nu lcov

coverage-all: check-nushell
	@echo "📊 Generating all coverage formats..."
	$(NUSHELL) scripts/coverage.nu all

coverage-html: check-nushell
	@echo "📊 Generating HTML coverage report..."
	$(NUSHELL) scripts/coverage.nu html

coverage-watch: check-nushell
	@echo "👀 Starting coverage watch mode..."
	$(NUSHELL) scripts/coverage.nu watch

# Development targets
dev: check-nushell
	@echo "💻 Entering development shell..."
	nix develop

test-shell: check-nushell
	@echo "💻 Entering testing shell..."
	nix develop .#testing

gaming-shell: check-nushell
	@echo "💻 Entering gaming shell..."
	nix develop .#gaming

macos-shell: check-nushell
	@echo "💻 Entering macOS shell..."
	nix develop .#macos

services-shell: check-nushell
	@echo "💻 Entering services shell..."
	nix develop .#services

monitoring-shell: check-nushell
	@echo "💻 Entering monitoring shell..."
	nix develop .#monitoring

zfs-shell: check-nushell
	@echo "💻 Entering ZFS shell..."
	nix develop .#zfs

# Build targets
build: check-nushell
	@echo "🔨 Building default package..."
	nix --extra-experimental-features "nix-command flakes" build

build-all: check-nushell
	@echo "🔨 Building all packages..."
	nix --extra-experimental-features "nix-command flakes" build

build-packages: check-nushell
	@echo "📦 Building all packages..."
	@for package in $(PACKAGES); do \
		echo "Building $$package..."; \
		nix build .#"$$package" || echo "Failed to build $$package"; \
	done

# Format and check targets
format: check-nushell
	@echo "🎨 Formatting all code..."
	nix --extra-experimental-features "nix-command flakes" develop --command treefmt

fmt: check-nushell
	@echo "🎨 Formatting all code..."
	nix --extra-experimental-features "nix-command flakes" develop --command treefmt

check: check-nushell
	@echo "🔍 Running nix flake check..."
	nix --extra-experimental-features "nix-command flakes" flake check

check-flake: check-nushell
	@echo "🔍 Running flake check..."
	nix flake check

# Update targets
update: check-nushell
	@echo "🔄 Updating flake inputs..."
	nix flake update

update-flake: check-nushell
	@echo "🔄 Updating flake inputs with flake..."
	nix flake update

lock: check-nushell
	@echo "🔒 Updating flake.lock..."
	nix flake lock 