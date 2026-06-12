#!/usr/bin/env bash
# install.sh — drop the brain pipeline into an existing project repo.
# Usage: ./install.sh /path/to/your/repo
# Idempotent: never overwrites existing notes, commands, or CLAUDE.md content.
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:?Usage: ./install.sh /path/to/repo}"
TARGET="$(cd "$TARGET" && pwd)"

if [[ "$TARGET" == /mnt/* ]]; then
  echo "⚠  Target is on a Windows-mounted path ($TARGET)."
  echo "   Use a native WSL path (e.g. ~/projects/...) to avoid permission/inotify issues."
  exit 1
fi

echo "Installing brain into: $TARGET"

# 1. Folder structure + templates + README (no clobber)
mkdir -p "$TARGET/brain"/{0-inbox,1-architecture,2-checklists,3-decisions,4-reference,_templates,_archive}
cp -n "$SRC/brain/_templates/"*.md "$TARGET/brain/_templates/" 2>/dev/null || true
cp -n "$SRC/brain/README.md" "$TARGET/brain/README.md" 2>/dev/null || true
# .gitkeep so empty stages survive cloning
for d in 0-inbox 1-architecture 2-checklists 3-decisions 4-reference; do
  touch "$TARGET/brain/$d/.gitkeep"
done

# 2. claude-code slash commands (no clobber)
mkdir -p "$TARGET/.claude/commands"
cp -n "$SRC/.claude/commands/"*.md "$TARGET/.claude/commands/" 2>/dev/null || true

# 2b. Skills + lint + pre-commit hook
mkdir -p "$TARGET/.claude/skills" "$TARGET/tools"
cp -rn "$SRC/.claude/skills/." "$TARGET/.claude/skills/" 2>/dev/null || true
cp -n "$SRC/tools/brain-lint.sh" "$TARGET/tools/" 2>/dev/null || true
chmod +x "$TARGET/tools/brain-lint.sh" 2>/dev/null || true
if [[ -d "$TARGET/.git" ]]; then
  HOOK="$TARGET/.git/hooks/pre-commit"
  if [[ ! -f "$HOOK" ]]; then
    printf '#!/usr/bin/env bash\nexec tools/brain-lint.sh\n' > "$HOOK" && chmod +x "$HOOK"
    echo "  Installed pre-commit hook -> tools/brain-lint.sh"
  elif ! grep -q brain-lint "$HOOK"; then
    echo "  ⚠ Existing pre-commit hook found — add 'tools/brain-lint.sh' to it manually."
  fi
fi

# 3. CLAUDE.md — append contract if not already present
if [[ -f "$TARGET/CLAUDE.md" ]] && grep -q "Project Brain — Operating Contract" "$TARGET/CLAUDE.md"; then
  echo "  CLAUDE.md already contains the brain contract — skipping."
else
  { [[ -f "$TARGET/CLAUDE.md" ]] && printf '\n\n'; cat "$SRC/CLAUDE.md"; } >> "$TARGET/CLAUDE.md"
  echo "  Appended brain contract to CLAUDE.md."
fi

# 4. .gitignore — archive (local-only) + Obsidian machine-local state
GI="$TARGET/.gitignore"
touch "$GI"
for line in "brain/_archive/" "brain/.obsidian/workspace*" "brain/.obsidian/cache" ".obsidian/workspace*"; do
  grep -qxF "$line" "$GI" || echo "$line" >> "$GI"
done

echo "Done. Next:"
echo "  cd $TARGET && claude"
echo "  /capture your first raw note..."
