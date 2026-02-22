#!/usr/bin/env bash
# Implements: FR-sc-install, AC-sc-install-global, FR-sr-install, AC-sr-install-global
#
# Installs the /shepherd and /shepherd-review slash commands globally for Claude Code
# by creating symlinks from ~/.claude/commands/ to this repo's command files.
# Updates propagate automatically via git pull through the symlinks.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TARGET_DIR="$HOME/.claude/commands"
COMMANDS=("shepherd.md" "shepherd-review.md")

# Parse flags
FORCE=false
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=true ;;
    --help)
      echo "Usage: ./scripts/install-command.sh [--force]"
      echo ""
      echo "Installs the /shepherd and /shepherd-review slash commands globally for Claude Code."
      echo "Creates symlinks at ~/.claude/commands/ pointing to this repo's command files."
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

# Create target directory
mkdir -p "$TARGET_DIR"

INSTALLED=0
ALREADY=0
ERRORS=0

for CMD in "${COMMANDS[@]}"; do
  SOURCE="$REPO_ROOT/.claude/commands/$CMD"
  TARGET="$TARGET_DIR/$CMD"

  # Verify source exists
  if [ ! -f "$SOURCE" ]; then
    echo "Warning: Command file not found at $SOURCE (skipping)"
    ERRORS=$((ERRORS + 1))
    continue
  fi

  # Check for existing file
  if [ -e "$TARGET" ] || [ -L "$TARGET" ]; then
    # Check if it's already correctly symlinked
    if [ -L "$TARGET" ]; then
      CURRENT="$(readlink "$TARGET")"
      if [ "$CURRENT" = "$SOURCE" ]; then
        echo "Already installed: $TARGET -> $SOURCE"
        ALREADY=$((ALREADY + 1))
        continue
      fi
    fi

    if [ "$FORCE" = true ]; then
      rm -f "$TARGET"
      echo "Removed existing: $TARGET"
    else
      echo "Error: $TARGET already exists. Run with --force to overwrite."
      ERRORS=$((ERRORS + 1))
      continue
    fi
  fi

  # Create symlink
  ln -s "$SOURCE" "$TARGET"
  echo "Installed: $TARGET -> $SOURCE"
  INSTALLED=$((INSTALLED + 1))
done

echo ""
if [ $INSTALLED -gt 0 ] || [ $ALREADY -gt 0 ]; then
  echo "The /shepherd and /shepherd-review commands are now available globally in Claude Code."
  echo "Updates will propagate automatically when you git pull this repo."
fi

if [ $ERRORS -gt 0 ]; then
  exit 1
fi
