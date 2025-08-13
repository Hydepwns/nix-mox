# Development-related Makefile targets
# Include this file in the main Makefile

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
	@echo "🎨 Formatting Nix files..."
	nixpkgs-fmt **/*.nix

fmt: check-nushell
	@echo "🎨 Formatting all code..."
	treefmt

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