#!/bin/bash
# Context Guard — Installer
# Usage: ./install.sh [target-directory]
# If no target directory given, uses current working directory.

set -e

# 1. SECTION: Configuration
TARGET="${1:-.}"

# Resolve to absolute path
TARGET="$(cd "$TARGET" && pwd)"

# Get the directory where this script lives (the Context Guard repo)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# end of 1

# 2. SECTION: Welcome banner
echo ""
echo "  Context Guard — Installer"
echo "  ================================="
echo ""
echo "  Installing into: $TARGET"
echo ""
# end of 2

# 3. SECTION: Pre-flight checks
# 3.1 Check if .claude/ already exists
if [ -d "$TARGET/.claude" ]; then
    echo "  WARNING: $TARGET/.claude/ already exists."
    echo "  Context Guard files will be merged into your existing .claude/ folder."
    echo ""
    read -p "  Continue? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "  Aborted."
        exit 1
    fi
    echo ""
fi
# end of 3.1

# 3.2 Detect parent directory with .claude/ (working directory mismatch)
# Claude Code looks for slash commands in its working directory's .claude/commands/.
# If the user opens Claude Code in a parent folder (e.g. /Software/) but
# installs CCG into a subfolder (e.g. /Software/MyProject/), the commands
# won't be found. Detect this and offer to install commands at the parent level.
PARENT_CLAUDE_DIR=""
CHECK_DIR="$(dirname "$TARGET")"
while [ "$CHECK_DIR" != "/" ] && [ "$CHECK_DIR" != "." ]; do
    if [ -d "$CHECK_DIR/.claude" ]; then
        PARENT_CLAUDE_DIR="$CHECK_DIR"
        break
    fi
    CHECK_DIR="$(dirname "$CHECK_DIR")"
done

if [ -n "$PARENT_CLAUDE_DIR" ]; then
    echo "  NOTICE: Found .claude/ in a parent directory:"
    echo "    $PARENT_CLAUDE_DIR/.claude/"
    echo ""
    echo "  If you open Claude Code from that parent directory, it will look"
    echo "  for commands there — not in $TARGET/.claude/commands/."
    echo "  CCG commands and hooks need to exist at the working directory level"
    echo "  to be discovered by Claude Code."
    echo ""
    echo "  Options:"
    echo "    1) Install commands and hooks to BOTH locations (recommended)"
    echo "    2) Install to target directory only (skip parent)"
    echo "    3) Abort"
    echo ""
    read -p "  Choose (1/2/3): " -n 1 -r
    echo ""
    echo ""

    case "$REPLY" in
        1)
            INSTALL_TO_PARENT=true
            ;;
        2)
            INSTALL_TO_PARENT=false
            ;;
        *)
            echo "  Aborted."
            exit 1
            ;;
    esac
fi
# end of 3.2
# end of 3

# 4. SECTION: File installation
# 4.1 Copy slash commands
# Copy commands
echo "  Copying commands..."
mkdir -p "$TARGET/.claude/commands"
cp "$SCRIPT_DIR/.claude/commands/start.md" "$TARGET/.claude/commands/"
cp "$SCRIPT_DIR/.claude/commands/end.md" "$TARGET/.claude/commands/"
cp "$SCRIPT_DIR/.claude/commands/audit.md" "$TARGET/.claude/commands/"
cp "$SCRIPT_DIR/.claude/commands/itemise.md" "$TARGET/.claude/commands/"
cp "$SCRIPT_DIR/.claude/commands/save.md" "$TARGET/.claude/commands/"
# end of 4.1

# 4.2 Copy hooks
# Copy hooks
echo "  Copying hooks..."
mkdir -p "$TARGET/.claude/hooks"
cp "$SCRIPT_DIR/.claude/hooks/pre-commit-check.sh" "$TARGET/.claude/hooks/"
cp "$SCRIPT_DIR/.claude/hooks/pre-compact-save.sh" "$TARGET/.claude/hooks/"
# end of 4.2

# 4.3 Copy settings (conditional)
# Copy settings.json only if it doesn't already exist
if [ ! -f "$TARGET/.claude/settings.json" ]; then
    echo "  Copying settings.json..."
    cp "$SCRIPT_DIR/.claude/settings.json" "$TARGET/.claude/settings.json"
else
    echo "  Skipping settings.json (already exists)"
fi
# end of 4.3

# 4.4 Copy templates (includes LEARNED_BEHAVIOUR.md and RESUME_STATE.md)
# Copy templates
echo "  Copying templates..."
mkdir -p "$TARGET/templates"
cp "$SCRIPT_DIR/templates/"* "$TARGET/templates/"
# end of 4.4

# 4.5 Copy commands and hooks to parent directory (if selected)
if [ "${INSTALL_TO_PARENT:-false}" = true ] && [ -n "$PARENT_CLAUDE_DIR" ]; then
    echo "  Copying commands to parent: $PARENT_CLAUDE_DIR/.claude/commands/"
    mkdir -p "$PARENT_CLAUDE_DIR/.claude/commands"
    cp "$SCRIPT_DIR/.claude/commands/start.md" "$PARENT_CLAUDE_DIR/.claude/commands/"
    cp "$SCRIPT_DIR/.claude/commands/end.md" "$PARENT_CLAUDE_DIR/.claude/commands/"
    cp "$SCRIPT_DIR/.claude/commands/audit.md" "$PARENT_CLAUDE_DIR/.claude/commands/"
    cp "$SCRIPT_DIR/.claude/commands/itemise.md" "$PARENT_CLAUDE_DIR/.claude/commands/"
    cp "$SCRIPT_DIR/.claude/commands/save.md" "$PARENT_CLAUDE_DIR/.claude/commands/"

    echo "  Copying hooks to parent: $PARENT_CLAUDE_DIR/.claude/hooks/"
    mkdir -p "$PARENT_CLAUDE_DIR/.claude/hooks"
    cp "$SCRIPT_DIR/.claude/hooks/pre-commit-check.sh" "$PARENT_CLAUDE_DIR/.claude/hooks/"
    cp "$SCRIPT_DIR/.claude/hooks/pre-compact-save.sh" "$PARENT_CLAUDE_DIR/.claude/hooks/"

    if [ ! -f "$PARENT_CLAUDE_DIR/.claude/settings.json" ]; then
        echo "  Copying settings.json to parent..."
        cp "$SCRIPT_DIR/.claude/settings.json" "$PARENT_CLAUDE_DIR/.claude/settings.json"
    else
        echo "  Skipping parent settings.json (already exists)"
    fi
fi
# end of 4.5
# end of 4

# 5. SECTION: Success output
echo ""
echo "  ✓ Context Guard installed successfully."
echo ""
echo "  Next step: Open Claude Code in your project and type /start"
echo "  On first run, /start will set up your safeguard files and offer to"
echo "  itemise your existing codebase."
echo ""
# end of 5
