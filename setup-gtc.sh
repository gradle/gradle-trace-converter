#!/bin/bash

# Gradle Trace Converter - Install Alias Script
# Runs ./gradlew install (step 3) and automatically adds the gtc alias to the appropriate shell rc file (step 4)

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
echo -e "${BLUE}Step 4: Adding alias to shell startup file...${NC}"

# Create the alias command based on shell
if [ "$CURRENT_SHELL" = "fish" ]; then
  ALIAS_CMD="alias gtc '$FINAL_DIST_PATH'"
else
  ALIAS_CMD="alias gtc=\"$FINAL_DIST_PATH\""
fi

# Check if alias already exists
if grep -q "alias gtc=" "$RC_FILE" 2>/dev/null; then
  echo -e "${YELLOW}Alias already exists in $RC_FILE${NC}"
  echo "Current alias:"
  grep "alias gtc=" "$RC_FILE"

  read -p "Do you want to replace it? (y/n) " -n 1 -r
  echo

  if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Remove old alias
    if [ "$CURRENT_SHELL" = "fish" ]; then
      sed -i '' "/^alias gtc=/d" "$RC_FILE"
    else
      sed -i '' "/^alias gtc=/d" "$RC_FILE"
    fi
  else
    echo "Installation cancelled."
    exit 0
  fi
fi

# Add the alias to the rc file
echo "$ALIAS_CMD" >> "$RC_FILE"

echo ""
echo -e "${GREEN}✓ Installation complete!${NC}"
echo ""
echo "Summary:"
if [ -n "$DIST_INSTALL_DIR" ]; then
  echo "  • Step 3: Built and installed to $DIST_INSTALL_DIR"
else
  echo "  • Step 3: Built and installed to $(pwd)/distribution"
fi
echo "  • Step 4: Added alias to $RC_FILE"
echo ""
echo "To activate the alias in your current session, run:"
echo -e "${YELLOW}source $RC_FILE${NC}"
echo ""
echo "Then you can use the command: ${YELLOW}gtc${NC}"
