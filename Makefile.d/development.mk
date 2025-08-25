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

# Consolidated script targets
dashboard: check-nushell
	@echo "📊 Launching system dashboard..."
	$(NUSHELL) scripts/dashboard.nu overview

dashboard-system: check-nushell  
	@echo "🖥️  Launching system dashboard..."
	$(NUSHELL) scripts/dashboard.nu system

dashboard-performance: check-nushell
	@echo "⚡ Launching performance dashboard..."
	$(NUSHELL) scripts/dashboard.nu performance

dashboard-gaming: check-nushell
	@echo "🎮 Launching gaming dashboard..."
	$(NUSHELL) scripts/dashboard.nu gaming

validate: check-nushell
	@echo "✅ Running basic validation..."
	$(NUSHELL) scripts/validate.nu basic

validate-config: check-nushell
	@echo "🔧 Running configuration validation..."
	$(NUSHELL) scripts/validate.nu config

validate-gaming: check-nushell
	@echo "🎮 Running gaming validation..."
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
	nix build

build-all: check-nushell
	@echo "🔨 Building all packages..."
	nix build

build-packages: check-nushell
	@echo "📦 Building all packages..."
	@for package in $(PACKAGES); do \
		echo "Building $$package..."; \
		nix build .#"$$package" || echo "Failed to build $$package"; \
	done

# Format and check targets
format: check-nushell
	@echo "🎨 Formatting all code..."
	nix develop --command treefmt

fmt: check-nushell
	@echo "🎨 Formatting all code..."
	nix develop --command treefmt

check: check-nushell
	@echo "🔍 Running nix flake check..."
	nix flake check

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