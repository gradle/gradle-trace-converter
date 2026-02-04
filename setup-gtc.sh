#!/usr/bin/env bash

# Gradle Trace Converter - Setup Script
# Runs ./gradlew install (step 3) and automatically adds gtc and cct aliases to the appropriate shell rc file (step 4)

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the current shell
CURRENT_SHELL=$(basename "$SHELL")

# Determine the rc file based on the shell
case "$CURRENT_SHELL" in
  bash)
    RC_FILE="$HOME/.bashrc"
    ;;
  zsh)
    RC_FILE="$HOME/.zshrc"
    ;;
  ksh)
    RC_FILE="$HOME/.kshrc"
    ;;
  fish)
    RC_FILE="$HOME/.config/fish/config.fish"
    ;;
  *)
    echo -e "${RED}Error: Unsupported shell '$CURRENT_SHELL'${NC}"
    echo "Supported shells: bash, zsh, ksh, fish"
    exit 1
    ;;
esac

# Default to current directory if not specified
PROJECT_DIR="${1:-.}"

# Installation directory (optional, defaults to PROJECT_DIR/distribution)
DIST_INSTALL_DIR="${2:-}"

# Verify the directory exists and contains gradlew
if [ ! -f "$PROJECT_DIR/gradlew" ]; then
  echo -e "${RED}Error: gradlew not found in $PROJECT_DIR${NC}"
  echo "Please run this script from the gradle-trace-converter directory or specify the project directory"
  exit 1
fi

# Step 3: Run gradlew install
echo -e "${BLUE}Step 3: Running ./gradlew install...${NC}"
cd "$PROJECT_DIR"

if [ -n "$DIST_INSTALL_DIR" ]; then
  echo "Installing to: $DIST_INSTALL_DIR"
  ./gradlew install -Pgtc.install.dir="$DIST_INSTALL_DIR"
  FINAL_DIST_PATH="$DIST_INSTALL_DIR/gtc"
else
  ./gradlew install
  FINAL_DIST_PATH="$(pwd)/distribution/bin/gtc"
fi

echo ""
echo -e "${GREEN}✓ Build completed successfully!${NC}"

# Verify the binary exists
if [ ! -f "$FINAL_DIST_PATH" ]; then
  echo -e "${RED}Error: gtc binary not found at $FINAL_DIST_PATH${NC}"
  exit 1
fi

echo ""
echo -e "${BLUE}Step 4: Adding aliases to shell startup file...${NC}"

# Get the project directory absolute path for collect-trace.sh
PROJECT_ABS_PATH="$PROJECT_DIR"
if [ "$PROJECT_DIR" = "." ]; then
  PROJECT_ABS_PATH="$(pwd)"
fi

COLLECT_TRACE_PATH="$PROJECT_ABS_PATH/collect-trace.sh"

# Create the alias commands based on shell
if [ "$CURRENT_SHELL" = "fish" ]; then
  GTC_ALIAS="alias gtc '$FINAL_DIST_PATH'"
  CCT_ALIAS="alias cct '$COLLECT_TRACE_PATH'"
else
  GTC_ALIAS="alias gtc=\"$FINAL_DIST_PATH\""
  CCT_ALIAS="alias cct=\"$COLLECT_TRACE_PATH\""
fi

# Check if aliases already exist
GTC_EXISTS=false
CCT_EXISTS=false

if grep -q "alias gtc=" "$RC_FILE" 2>/dev/null; then
  GTC_EXISTS=true
fi

if grep -q "alias cct=" "$RC_FILE" 2>/dev/null; then
  CCT_EXISTS=true
fi

if [ "$GTC_EXISTS" = true ] || [ "$CCT_EXISTS" = true ]; then
  echo -e "${YELLOW}Some aliases already exist in $RC_FILE${NC}"
  [ "$GTC_EXISTS" = true ] && echo "  - gtc: $(grep 'alias gtc=' "$RC_FILE")"
  [ "$CCT_EXISTS" = true ] && echo "  - cct: $(grep 'alias cct=' "$RC_FILE")"

  read -p "Do you want to replace them? (y/n) " -n 1 -r
  echo

  if [[ $REPLY =~ ^[Yy]$ ]]; then
    sed -i '' "/^alias gtc=/d" "$RC_FILE"
    sed -i '' "/^alias cct=/d" "$RC_FILE"
  else
    echo "Installation cancelled."
    exit 0
  fi
fi

# Add the aliases to the rc file
echo "$GTC_ALIAS" >> "$RC_FILE"
echo "$CCT_ALIAS" >> "$RC_FILE"

echo ""
echo -e "${GREEN}✓ Installation complete!${NC}"
echo ""
echo "Summary:"
if [ -n "$DIST_INSTALL_DIR" ]; then
  echo "  • Step 3: Built and installed to $DIST_INSTALL_DIR"
else
  echo "  • Step 3: Built and installed to $(pwd)/distribution"
fi
echo "  • Step 4: Added aliases to $RC_FILE"
echo ""
echo "To activate the aliases in your current session, run:"
echo -e "${YELLOW}source $RC_FILE${NC}"
echo ""
echo "Then you can use these commands:"
echo "  • ${YELLOW}gtc${NC} - Convert build traces"
echo "  • ${YELLOW}cct${NC} - Collect clean traces (CollectCleanTrace)"
