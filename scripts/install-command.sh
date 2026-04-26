#!/usr/bin/env bash
# Implements: FR-sc-install, AC-sc-install-global, FR-sr-install, AC-sr-install-global
#
# Installs the /shepherd and /shepherd-review slash commands globally for Claude Code and opencode
# by creating symlinks from ~/.claude/commands/ and ~/.config/opencode/skills/ to this repo's command files.
# Updates propagate automatically via git pull through the symlinks.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Target directories for different agents
# Honor CLAUDE_CONFIG_DIR if set (Claude Code reads commands from this dir).
CLAUDE_CONFIG_BASE="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
CLAUDE_TARGET_DIR="$CLAUDE_CONFIG_BASE/commands"
OPENCODE_TARGET_DIR="$HOME/.config/opencode/skills"

COMMANDS=("shepherd" "shepherd-review" "shepherd-mac")

# Parse flags
FORCE=false
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=true ;;
    --help)
      echo "Usage: ./scripts/install-command.sh [--force]"
      echo ""
      echo "Installs Shepherd tools globally:"
      echo "  - /shepherd and /shepherd-review slash commands for Claude Code and opencode"
      echo "  - git land and git sync subcommands for worktree workflow"
      echo ""
      echo "Options:"
      echo "  --force    Overwrite existing files or symlinks"
      echo "  --help     Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $arg"
      echo "Run with --help for usage."
      exit 1
      ;;
  esac
done

INSTALLED=0
ALREADY=0
ERRORS=0

# Helper function to install a symlink
install_symlink() {
  local source_file="$1"
  local target_file="$2"
  local target_dir="$(dirname "$target_file")"
  
  mkdir -p "$target_dir"
  
  # Verify source exists
  if [ ! -f "$source_file" ]; then
    echo "Warning: Command file not found at $source_file (skipping)"
    ERRORS=$((ERRORS + 1))
    return 1
  fi
  
  # Check for existing file
  if [ -e "$target_file" ] || [ -L "$target_file" ]; then
    # Check if it's already correctly symlinked
    if [ -L "$target_file" ]; then
      local current="$(readlink "$target_file")"
      if [ "$current" = "$source_file" ]; then
        echo "Already installed: $target_file -> $source_file"
        ALREADY=$((ALREADY + 1))
        return 0
      fi
    fi
    
    if [ "$FORCE" = true ]; then
      rm -f "$target_file"
      echo "Removed existing: $target_file"
    else
      echo "Error: $target_file already exists. Run with --force to overwrite."
      ERRORS=$((ERRORS + 1))
      return 1
    fi
  fi
  
  # Create symlink
  ln -s "$source_file" "$target_file"
  echo "Installed: $target_file -> $source_file"
  INSTALLED=$((INSTALLED + 1))
  return 0
}

for CMD in "${COMMANDS[@]}"; do
  # Claude Code installation
  install_symlink "$REPO_ROOT/.claude/commands/$CMD.md" "$CLAUDE_TARGET_DIR/$CMD.md"
  
  # opencode installation
  install_symlink "$REPO_ROOT/.config/opencode/skills/$CMD/SKILL.md" "$OPENCODE_TARGET_DIR/$CMD/SKILL.md"
done

# --- Git subcommands (git land, git sync) ---

GIT_SCRIPTS=("git-land" "git-sync")
BIN_DIR="$HOME/.local/bin"

for SCRIPT in "${GIT_SCRIPTS[@]}"; do
  install_symlink "$REPO_ROOT/scripts/$SCRIPT" "$BIN_DIR/$SCRIPT"
done

# --- macOS app prebuild (FR-sc-mac-prebuild) ---
# Build the ShepherdApp release binary so /shepherd-mac launches instantly.
# Failure here is non-fatal: the web slash command still works without the macOS binary.

MAC_APP_DIR="$REPO_ROOT/engineering/apps/macos"
if [ -d "$MAC_APP_DIR" ]; then
  if command -v swift >/dev/null 2>&1; then
    echo ""
    echo "Building macOS app (release)..."
    if (cd "$MAC_APP_DIR" && swift build -c release) >/dev/null 2>&1; then
      echo "Built: $MAC_APP_DIR/.build/release/ShepherdApp"
    else
      # Non-fatal per FR-sc-mac-prebuild — warn but do not block install.
      echo "Warning: macOS app build failed. /shepherd-mac will not work until rebuilt." >&2
      echo "  Re-run from $MAC_APP_DIR: swift build -c release" >&2
    fi
  else
    echo ""
    echo "Warning: 'swift' not found on PATH. /shepherd-mac will not work until you install Swift and re-run this script." >&2
  fi
fi

echo ""
if [ $INSTALLED -gt 0 ] || [ $ALREADY -gt 0 ]; then
  echo "Installed:"
  echo "  Claude Code/opencode:  /shepherd, /shepherd-review, /shepherd-mac"
  echo "  Git commands: git land, git sync"
  echo ""
  echo "Updates propagate automatically when you git pull this repo."
  if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    echo ""
    echo "Note: $BIN_DIR is not on your PATH."
    echo "Add it with: export PATH=\"\$HOME/.local/bin:\$PATH\""
  fi
fi

if [ $ERRORS -gt 0 ]; then
  exit 1
fi
