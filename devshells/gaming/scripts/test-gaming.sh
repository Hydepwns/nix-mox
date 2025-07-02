#!/usr/bin/env bash
# Gaming shell test script
# Tests the availability and functionality of gaming tools

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to test command availability
test_command() {
  local cmd="$1"
  local description="$2"

  if command -v "$cmd" &> /dev/null; then
    echo -e "${GREEN}✓${NC} $description ($cmd)"
    return 0
  else
    echo -e "${RED}✗${NC} $description ($cmd) - NOT FOUND"
    return 1
  fi
}

# Function to test version
test_version() {
  local cmd="$1"
  local description="$2"

  if command -v "$cmd" &> /dev/null; then
    local version
    version=$($cmd --version 2> /dev/null | head -n1 || echo "version unknown")
    echo -e "${GREEN}✓${NC} $description: $version"
    return 0
  else
    echo -e "${RED}✗${NC} $description ($cmd) - NOT FOUND"
    return 1
  fi
}

# Function to test Wine functionality
test_wine() {
  echo -e "${BLUE}Testing Wine functionality...${NC}"

  if command -v wine &> /dev/null; then
    echo -e "${GREEN}✓${NC} Wine is available"

    # Test Wine version
    local wine_version
    wine_version=$(wine --version 2> /dev/null || echo "version unknown")
    echo -e "${GREEN}✓${NC} Wine version: $wine_version"

    # Test if Wine can run basic commands
    if wine cmd /c echo "Wine test successful" &> /dev/null; then
      echo -e "${GREEN}✓${NC} Wine can execute basic commands"
    else
      echo -e "${YELLOW}⚠${NC} Wine basic command test failed"
    fi
  else
    echo -e "${RED}✗${NC} Wine is not available"
    return 1
  fi
}

# Function to test graphics capabilities
test_graphics() {
  echo -e "${BLUE}Testing graphics capabilities...${NC}"

  # Test OpenGL
  if command -v glxinfo &> /dev/null; then
    local opengl_version
    opengl_version=$(glxinfo | grep "OpenGL version" | head -n1 || echo "OpenGL version unknown")
    echo -e "${GREEN}✓${NC} $opengl_version"
  else
    echo -e "${RED}✗${NC} glxinfo not available"
  fi

  # Test Vulkan
  if command -v vulkaninfo &> /dev/null; then
    echo -e "${GREEN}✓${NC} Vulkan support available"
  else
    echo -e "${YELLOW}⚠${NC} vulkaninfo not available"
  fi

  # Test OpenGL benchmark
  if command -v glmark2 &> /dev/null; then
    echo -e "${GREEN}✓${NC} OpenGL benchmark (glmark2) available"
  else
    echo -e "${YELLOW}⚠${NC} glmark2 not available"
  fi
}

# Function to test system monitoring
test_monitoring() {
  echo -e "${BLUE}Testing system monitoring tools...${NC}"

  test_command "htop" "Process monitoring (htop)"
  test_command "nvtop" "GPU monitoring (nvtop)"

  # Test if nvtop works (NVIDIA GPU)
  if command -v nvtop &> /dev/null; then
    if timeout 2s nvtop --version &> /dev/null; then
      echo -e "${GREEN}✓${NC} nvtop is functional"
    else
      echo -e "${YELLOW}⚠${NC} nvtop may not work (no NVIDIA GPU or driver issues)"
    fi
  fi
}

# Function to test performance tools
test_performance() {
  echo -e "${BLUE}Testing performance optimization tools...${NC}"

  test_command "gamemode" "GameMode"
  test_command "mangohud" "MangoHud"

  # Test GameMode
  if command -v gamemode &> /dev/null; then
    if gamemode --version &> /dev/null; then
      echo -e "${GREEN}✓${NC} GameMode is functional"
    else
      echo -e "${YELLOW}⚠${NC} GameMode may not be properly configured"
    fi
  fi

  # Test MangoHud
  if command -v mangohud &> /dev/null; then
    if mangohud --help &> /dev/null; then
      echo -e "${GREEN}✓${NC} MangoHud is functional"
    else
      echo -e "${YELLOW}⚠${NC} MangoHud may not be properly configured"
    fi
  fi
}

# Function to test environment variables
test_environment() {
  echo -e "${BLUE}Testing environment variables...${NC}"

  local env_vars=(
    "DXVK_HUD"
    "DXVK_STATE_CACHE"
    "DXVK_STATE_CACHE_PATH"
    "__GL_SHADER_DISK_CACHE"
    "__GL_SHADER_DISK_CACHE_PATH"
    "__GL_SYNC_TO_VBLANK"
    "__GL_THREADED_OPTIMIZATIONS"
    "MESA_GL_VERSION_OVERRIDE"
    "MESA_GLSL_VERSION_OVERRIDE"
  )

  for var in "${env_vars[@]}"; do
    if [ -n "${!var}" ]; then
      echo -e "${GREEN}✓${NC} $var is set: ${!var}"
    else
      echo -e "${YELLOW}⚠${NC} $var is not set"
    fi
  done
}

# Function to test cache directories
test_cache_dirs() {
  echo -e "${BLUE}Testing cache directories...${NC}"

  local cache_dirs=(
    "$HOME/.cache/dxvk"
    "$HOME/.cache/gl-shaders"
  )

  for dir in "${cache_dirs[@]}"; do
    if [ -d "$dir" ]; then
      echo -e "${GREEN}✓${NC} Cache directory exists: $dir"
    else
      echo -e "${YELLOW}⚠${NC} Cache directory missing: $dir"
    fi
  done
}

# Function to test League of Legends setup
test_league_setup() {
  echo -e "${BLUE}Testing League of Legends setup...${NC}"

  # Check if League Wine prefix exists
  if [ -d "$HOME/.wine-league" ]; then
    echo -e "${GREEN}✓${NC} League Wine prefix exists: $HOME/.wine-league"
  else
    echo -e "${YELLOW}⚠${NC} League Wine prefix not found. Run 'league-setup' to create it."
  fi

  # Check if League environment file exists
  if [ -f "$HOME/.config/league-env" ]; then
    echo -e "${GREEN}✓${NC} League environment file exists: $HOME/.config/league-env"
  else
    echo -e "${YELLOW}⚠${NC} League environment file not found. Run 'league-setup' to create it."
  fi

  # Check if League launch script exists
  if [ -f "$HOME/.local/bin/league-launch" ]; then
    echo -e "${GREEN}✓${NC} League launch script exists: $HOME/.local/bin/league-launch"
  else
    echo -e "${YELLOW}⚠${NC} League launch script not found. Run 'league-setup' to create it."
  fi
}

# Main test function
main() {
  echo -e "${BLUE}🎮 Gaming Shell Test Suite${NC}"
  echo "================================"
  echo ""

  local tests_passed=0
  local tests_total=0

  # Test gaming platforms
  echo -e "${BLUE}Testing gaming platforms...${NC}"
  test_command "steam" "Steam" && ((tests_passed++))
  ((tests_total++))
  test_command "lutris" "Lutris" && ((tests_passed++))
  ((tests_total++))
  test_command "heroic" "Heroic Games Launcher" && ((tests_passed++))
  ((tests_total++))
  echo ""

  # Test Wine and compatibility
  echo -e "${BLUE}Testing Wine and compatibility...${NC}"
  test_command "wine" "Wine" && ((tests_passed++))
  ((tests_total++))
  test_command "winetricks" "Winetricks" && ((tests_passed++))
  ((tests_total++))
  test_command "protontricks" "Protontricks" && ((tests_passed++))
  ((tests_total++))
  echo ""

  # Test Wine functionality
  test_wine
  echo ""

  # Test graphics
  test_graphics
  echo ""

  # Test performance tools
  test_performance
  echo ""

  # Test system monitoring
  test_monitoring
  echo ""

  # Test environment
  test_environment
  echo ""

  # Test cache directories
  test_cache_dirs
  echo ""

  # Test League of Legends setup
  test_league_setup
  echo ""

  # Summary
  echo -e "${BLUE}Test Summary${NC}"
  echo "============"
  echo -e "Tests passed: ${GREEN}$tests_passed${NC}/$tests_total"

  if [ $tests_passed -eq $tests_total ]; then
    echo -e "${GREEN}🎉 All tests passed! Gaming shell is ready to use.${NC}"
  else
    echo -e "${YELLOW}⚠ Some tests failed. Check the output above for details.${NC}"
  fi

  echo ""
  echo -e "${BLUE}Next Steps:${NC}"
  echo "1. If League setup tests failed, run: league-setup"
  echo "2. If Wine tests failed, ensure you're in the gaming shell"
  echo "3. If graphics tests failed, check your graphics drivers"
  echo "4. For help, run: gaming-help"
}

# Run main function
main "$@"
