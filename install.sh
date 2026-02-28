#!/usr/bin/env bash
# ╭──────────────────────────────────────────╮
# │  proj installer                          │
# │  Project Hub in your Terminal            │
# ╰──────────────────────────────────────────╯

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$SCRIPT_DIR/src"
PROJ_CONFIG="$HOME/.config/proj"
PROJ_DATA="$PROJ_CONFIG/projects"
ZSHRC="$HOME/.zshrc"
SOURCE_LINE="source \"$SRC_DIR/proj.zsh\""

echo ""
echo "  🚀 proj · Project Hub in your Terminal"
echo "  ──────────────────────────────────────"
echo ""

# 1. Create data directory
if [[ ! -d "$PROJ_DATA" ]]; then
  mkdir -p "$PROJ_DATA"
  echo "  ✓ Created $PROJ_DATA"
else
  echo "  · Data directory exists"
fi

# 2. Make Python helper executable
chmod +x "$SRC_DIR/proj_helper.py"
echo "  ✓ Made proj_helper.py executable"

# 3. Check for python3
if ! command -v python3 &>/dev/null; then
  echo "  ✗ python3 not found — required for JSON operations"
  exit 1
fi
echo "  ✓ python3 found"

# 4. Update .zshrc
# Remove old source line if present
OLD_SOURCE='source "$HOME/.config/proj/proj.zsh"'
if grep -qF "$OLD_SOURCE" "$ZSHRC" 2>/dev/null; then
  # Comment out old line
  sed -i '' "s|^source \"\$HOME/.config/proj/proj.zsh\"|# OLD: &  # replaced by proj|" "$ZSHRC"
  echo "  ✓ Commented out old proj source line"
fi

# Add new source line if not present
if grep -qF "$SOURCE_LINE" "$ZSHRC" 2>/dev/null; then
  echo "  · Already in .zshrc"
else
  echo "" >> "$ZSHRC"
  echo "# proj — Project Hub in your Terminal" >> "$ZSHRC"
  echo "$SOURCE_LINE" >> "$ZSHRC"
  echo "  ✓ Added to .zshrc"
fi

# 5. Migrate existing .conf files
CONF_COUNT=$(ls -1 "$PROJ_DATA"/*.conf 2>/dev/null | wc -l | tr -d ' ')
if (( CONF_COUNT > 0 )); then
  echo ""
  echo "  Found $CONF_COUNT .conf files to migrate → JSON"
  echo "  Run 'proj migrate' after reloading your shell"
fi

# 6. Done
echo ""
echo "  ──────────────────────────────────────"
echo "  ✓ Installation complete!"
echo ""
echo "  Next steps:"
echo "    1. source ~/.zshrc    (or open new terminal)"
echo "    2. proj               (interactive menu)"
echo "    3. proj demo          (load demo projects)"
echo "    4. proj help          (all commands)"
echo ""
