#!/usr/bin/env bash
# Implements: FR-sc-install, AC-sc-install-global
#
# Installs the /shepherd slash command globally for Claude Code by creating
# a symlink from ~/.claude/commands/shepherd.md to this repo's command file.
# Updates propagate automatically via git pull through the symlink.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SOURCE="$REPO_ROOT/.claude/commands/shepherd.md"
TARGET_DIR="$HOME/.claude/commands"
TARGET="$TARGET_DIR/shepherd.md"

# Parse flags
FORCE=false
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=true ;;
    --help)
      echo "Usage: ./scripts/install-command.sh [--force]"
      echo ""
      echo "Installs the /shepherd slash command globally for Claude Code."
      echo "Creates a symlink at ~/.claude/commands/shepherd.md"
      echo ""
      echo "Options:"
      echo "  --force    Overwrite existing file or symlink"
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

# Verify source exists
if [ ! -f "$SOURCE" ]; then
  echo "Error: Command file not found at $SOURCE"
  echo "Are you running this from the Shepherd repository?"
  exit 1
fi

# Create target directory
mkdir -p "$TARGET_DIR"

# Check for existing file
if [ -e "$TARGET" ] || [ -L "$TARGET" ]; then
  # Check if it's already correctly symlinked
  if [ -L "$TARGET" ]; then
    CURRENT="$(readlink "$TARGET")"
    if [ "$CURRENT" = "$SOURCE" ]; then
      echo "Already installed: $TARGET -> $SOURCE"
      echo "The /shepherd command is available globally in Claude Code."
      exit 0
    fi
  fi

  if [ "$FORCE" = true ]; then
    rm -f "$TARGET"
    echo "Removed existing: $TARGET"
  else
    echo "Error: $TARGET already exists."
    echo "Run with --force to overwrite, or remove it manually."
    exit 1
  fi
fi

# Create symlink
ln -s "$SOURCE" "$TARGET"

echo "Installed: $TARGET -> $SOURCE"
echo ""
echo "The /shepherd command is now available globally in Claude Code."
echo "Type '/shepherd <filepath>' in any project to launch the Code Review Prompt Generator."
echo ""
echo "Updates will propagate automatically when you git pull this repo."
