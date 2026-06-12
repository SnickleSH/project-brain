#!/usr/bin/env bash
# brain-lint — mechanical enforcement of the brain contract.
# FAILS on: secrets in committed brain files, index<->filesystem drift.
# WARNS on: broken wikilinks, missing frontmatter, stale inbox notes.
# Set BRAIN_LINT_STRICT=1 to fail on warnings too. Run manually or via pre-commit.
set -uo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)"
[ -d brain ] || exit 0
FAIL=0; WARN=0
err()  { echo "✗ $1"; FAIL=1; }
warn() { echo "⚠ $1"; WARN=1; }

# 1. Secret scan (committed areas only — _archive is gitignored/local)
PAT='AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{20,}|sk-[A-Za-z0-9]{20,}|xox[bap]-|-----BEGIN [A-Z ]*PRIVATE KEY|[Aa][Pp][Ii][_-]?[Kk][Ee][Yy]["'"'"']?\s*[:=]\s*["'"'"']?[A-Za-z0-9_\-]{16,}|[Pp]assword\s*[:=]\s*\S{8,}'
HITS=$(grep -RInE "$PAT" brain --exclude-dir=_archive 2>/dev/null)
[ -n "$HITS" ] && err "possible secrets in committed brain files:"$'\n'"$HITS"

# 2. Index <-> filesystem consistency
IDX=brain/1-architecture/_index.md
if [ -f "$IDX" ]; then
  while IFS= read -r f; do
    slug=$(basename "$f" .md)
    grep -q "\[\[$slug\]\]" "$IDX" || err "index drift: $f missing from _index.md"
  done < <(find brain/1-architecture -name '*.md' ! -name '_index.md')
  while IFS= read -r slug; do
    find brain/1-architecture -name "$slug.md" | grep -q . || err "index drift: [[${slug}]] in _index.md has no file"
  done < <(grep -o '\[\[[^]|]*\]\]' "$IDX" | tr -d '[]')
fi

# 3. Broken wikilinks (archive targets exempt: local breadcrumbs by design)
while IFS= read -r slug; do
  find brain -name "$slug.md" | grep -q . || warn "broken wikilink: [[${slug}]]"
done < <(grep -RhoE '\[\[[^]|#]+' brain --exclude-dir=_archive --exclude-dir=_templates --exclude=README.md 2>/dev/null | sed 's/\[\[//' | sort -u)

# 4. Frontmatter present on every doc
while IFS= read -r f; do
  head -1 "$f" | grep -q '^---$' || warn "missing frontmatter: $f"
done < <(find brain -name '*.md' ! -path '*_archive*' ! -path '*_templates*' ! -name 'README.md')

# 5. Stale inbox (unprocessed > 14 days)
find brain/0-inbox -name '*.md' -mtime +14 2>/dev/null | while read -r f; do
  warn "inbox note older than 14 days (plan it or drop it): $f"; done

[ "${BRAIN_LINT_STRICT:-0}" = "1" ] && [ "$WARN" = 1 ] && FAIL=1
[ "$FAIL" = 0 ] && echo "brain-lint: OK"
exit $FAIL
