#!/usr/bin/env bash
# brain-lint — mechanical enforcement of the brain contract.
# FAILS on: secrets in committed brain files, index<->filesystem drift,
#           non-markdown or oversized bulk under brain/, a backlog without
#           status: standing, Evidence links that only resolve into _archive.
# WARNS on: broken wikilinks, missing frontmatter, stale inbox notes,
#           stale/unswept standing-backlog lines, oversized docs and logs.
# Set BRAIN_LINT_STRICT=1 to fail on warnings too. Run manually or via pre-commit.
#
# Installed as a repo-local copy by /brain:init, refreshed by /brain:sync.
# It cannot be referenced inside the plugin: ${CLAUDE_PLUGIN_ROOT} moves on
# every plugin update and is not set at all in a git hook's environment.
set -uo pipefail

# Locate the brain. It is NOT always at the git root: a monorepo can carry one
# per service (services/intelligence/brain/). Resolving only to the git root
# made a nested brain silently unlinted — `[ -d brain ] || exit 0` returned
# success having checked nothing, which is the worst possible failure for a
# tool whose job is to fail loudly.
# Order: explicit override, then the script's own parent (installed at
# <root>/tools/brain-lint.sh), then the git root.
SELF=$(cd "$(dirname "$0")" 2>/dev/null && pwd) || SELF=
if [ -n "${BRAIN_ROOT:-}" ] && [ -d "$BRAIN_ROOT/brain" ]; then
  cd "$BRAIN_ROOT"
elif [ -n "$SELF" ] && [ -d "$SELF/../brain" ]; then
  cd "$SELF/.."
else
  cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)"
fi
[ -d brain ] || exit 0
FAIL=0; WARN=0
err()  { echo "✗ $1"; FAIL=1; }
warn() { echo "⚠ $1"; WARN=1; }

# Cap repeated warnings so one bad day cannot train you to ignore the output.
CAP=3
declare -A CAPCOUNT=()
warncap() { # warncap <category> <message>
  local c=$1; shift
  CAPCOUNT[$c]=$(( ${CAPCOUNT[$c]:-0} + 1 ))
  if [ "${CAPCOUNT[$c]}" -le "$CAP" ]; then warn "$1"; else WARN=1; fi
}
capsummary() {
  local c
  for c in "${!CAPCOUNT[@]}"; do
    [ "${CAPCOUNT[$c]}" -gt "$CAP" ] && echo "⚠ $(( ${CAPCOUNT[$c]} - CAP )) more: $c"
  done
  return 0
}

# The set of files that would actually reach a commit: tracked plus untracked
# but not gitignored. Checking the raw working tree instead would hard-FAIL on
# editor droppings and WSL Zone.Identifier files that git never sees.
if git rev-parse --git-dir >/dev/null 2>&1; then
  brain_files() { git ls-files -z --cached --others --exclude-standard -- brain 2>/dev/null | tr '\0' '\n'; }
else
  brain_files() { find brain -type f 2>/dev/null; }
fi
committed() { brain_files | grep -v '_archive/' | grep -v '\.obsidian/'; }

date -d 2020-01-01 +%s >/dev/null 2>&1 && HAVE_DATE=1 || HAVE_DATE=0
[ "$HAVE_DATE" = 0 ] && warn "GNU 'date -d' unavailable — every staleness check is DISABLED on this platform"
NOW=$(date +%s)
days_since() { # YYYY-MM-DD -> whole days; non-zero exit if unparseable
  [ "$HAVE_DATE" = 1 ] || return 1
  local t; t=$(date -d "$1" +%s 2>/dev/null) || return 1
  echo $(( (NOW - t) / 86400 ))
}
# Resolve a wikilink slug to a real file, excluding the gitignored archive.
# -print -quit avoids `find | grep -q`, which raises SIGPIPE and — under
# `set -o pipefail` — turns a SUCCESSFUL match into a non-zero pipeline.
resolve() { # <slug> [extra find args...]
  local slug=$1; shift
  case "$slug" in
    */*) find brain -path "*/$slug.md" ! -path '*_archive*' "$@" -print -quit 2>/dev/null ;;
      *) find brain -name "$slug.md" ! -path '*_archive*' "$@" -print -quit 2>/dev/null ;;
  esac
}

# 1. Secret scan (committed areas only — _archive is gitignored/local).
#    POSIX classes rather than \s/\S so this behaves identically everywhere.
PAT='AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{20,}|sk-[A-Za-z0-9]{20,}|xox[bap]-|-----BEGIN [A-Z ]*PRIVATE KEY|[Aa][Pp][Ii][_-]?[Kk][Ee][Yy]["'"'"']?[[:space:]]*[:=][[:space:]]*["'"'"']?[A-Za-z0-9_\-]{16,}|[Pp]assword[[:space:]]*[:=][[:space:]]*[^[:space:]]{8,}'
HITS=$(grep -RInE "$PAT" brain --exclude-dir=_archive --exclude-dir=.obsidian 2>/dev/null)
[ -n "$HITS" ] && err "possible secrets in committed brain files:"$'\n'"$HITS"

# 2. Index <-> filesystem consistency. Keyed on the path relative to
#    1-architecture/ so the documented subfolder splitting convention stays
#    checkable, and matched with grep -F so aliases ([[doc|Label]]), anchors
#    ([[doc#Section]]) and regex metacharacters in filenames all behave.
IDX=brain/1-architecture/_index.md
if [ -f "$IDX" ]; then
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    rel=${f#brain/1-architecture/}; rel=${rel%.md}
    base=$(basename "$f" .md)
    # `[[doc|Alias]]` must be written `[[doc\|Alias]]` inside a markdown table,
    # and _index.md IS a table — so the escaped form has to match too.
    for s in "$rel" "$base"; do
      grep -qF -e "[[$s]]" -e "[[$s|" -e "[[$s\\|" -e "[[$s#" "$IDX" && continue 2
    done
    err "index drift: $f missing from _index.md"
  done < <(find brain/1-architecture -name '*.md' ! -name '_index.md' 2>/dev/null)
  # An index entry must RESOLVE, but it need not be an architecture doc — a
  # routing table that also points at ADRs or reference topics is useful, not
  # broken. Only the forward direction above is scoped to 1-architecture.
  while IFS= read -r slug; do
    [ -n "$slug" ] || continue
    [ -n "$(resolve "$slug")" ] || err "index drift: [[${slug}]] in _index.md has no file"
  done < <(grep -ohE '\[\[[^]|#]+' "$IDX" 2>/dev/null | sed 's/\[\[//' | sort -u)
  # Basenames must stay globally unique or [[wikilinks]] become ambiguous.
  DUPES=$(find brain/1-architecture -name '*.md' ! -name '_index.md' -exec basename {} \; 2>/dev/null | sort | uniq -d)
  [ -n "$DUPES" ] && err "duplicate architecture basenames (wikilinks resolve by filename):"$'\n'"$DUPES"
fi

# 3. Wikilinks. A link that resolves ONLY into the gitignored archive passes
#    for the author and breaks on every clone — that is precisely the failure
#    rule 6 exists to prevent, so it gets its own message.
while IFS= read -r slug; do
  [ -n "$slug" ] || continue
  [ -n "$(resolve "$slug")" ] && continue
  if [ -n "$(find brain -name "$(basename "$slug").md" -path '*_archive*' -print -quit 2>/dev/null)" ]; then
    warn "wikilink [[${slug}]] resolves only into gitignored _archive — unreachable from a clone; promote the fact to 4-reference/"
  else
    warncap "broken wikilinks" "broken wikilink: [[${slug}]]"
  fi
done < <(grep -RhoE '\[\[[^]|#]+' brain --exclude-dir=_archive --exclude-dir=_templates --exclude-dir=.obsidian --exclude=README.md 2>/dev/null | sed 's/\[\[//' | sort -u)

# 3b. Rule 6, the one mechanically checkable form: an ## Evidence link in an
#     architecture doc MUST resolve to a committed file.
while IFS= read -r f; do
  while IFS= read -r slug; do
    [ -n "$slug" ] || continue
    [ -n "$(resolve "$slug")" ] || err "$f: ## Evidence links [[${slug}]], which does not resolve to a committed brain file (rule 6)"
  done < <(sed -n '/^## Evidence/,/^## /p' "$f" 2>/dev/null | grep -ohE '\[\[[^]|#]+' | sed 's/\[\[//' | sort -u)
done < <(find brain/1-architecture -name '*.md' ! -name '_index.md' 2>/dev/null)

# 4. Frontmatter present on every doc. Log streams are exempt by design: they
#    are append-only observation, not nodes in the graph. `tr -d '\r'` so a
#    CRLF checkout does not report every single file.
while IFS= read -r f; do
  head -1 "$f" | tr -d '\r' | grep -q '^---$' || warncap "missing frontmatter" "missing frontmatter: $f"
done < <(find brain -name '*.md' ! -path '*_archive*' ! -path '*_templates*' ! -path 'brain/log/*' ! -path '*.obsidian*' ! -name 'README.md' 2>/dev/null)

# 5. Stale inbox — age from the FILENAME date, never mtime. mtime is rewritten
#    by a fresh clone, so real staleness would vanish exactly when someone new
#    picks the repo up. A note that triage has already mined restarts its clock
#    from its newest "## Extracted YYYY-MM-DD" heading.
while IFS= read -r f; do
  d=$(basename "$f" | grep -oE '^[0-9]{4}-[0-9]{2}-[0-9]{2}')
  [ -n "$d" ] || continue
  ex=$(grep -ohE '^## Extracted ([0-9]{4}-[0-9]{2}-[0-9]{2})' "$f" 2>/dev/null | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | sort | tail -1)
  [ -n "$ex" ] && [[ "$ex" > "$d" ]] && d=$ex
  age=$(days_since "$d") || { [ "$HAVE_DATE" = 1 ] && warn "unparseable date '$d' in $f"; continue; }
  [ "$age" -gt 14 ] && warncap "stale inbox notes" "inbox note ${age}d old (triage it or plan it): $f"
done < <(find brain/0-inbox -name '*.md' 2>/dev/null)

# 6. No machine-generated bulk under brain/. The brain holds intent, procedure
#    and judgment; regenerable or externally-authoritative data belongs in
#    data/ (gitignored). This is the one mechanical backstop for a rule that is
#    otherwise only prose — so it is scoped to what git would actually commit.
while IFS= read -r f; do
  case "$f" in */.gitkeep|*.md) continue ;; esac
  [ -L "$f" ] && continue   # symlinks get their own, more useful message below
  err "non-markdown file under brain/ (bulk belongs in data/): $f"
done < <(committed)
while IFS= read -r f; do
  case "$f" in *.md) ;; *) continue ;; esac   # non-md already reported above
  [ -f "$f" ] && [ "$(wc -c < "$f")" -gt 102400 ] && err "markdown file over 100KB under brain/ (bulk belongs in data/): $f"
done < <(committed)
while IFS= read -r f; do
  err "symlink under brain/ (link to data/ in prose, not on the filesystem): $f"
done < <(find brain -type l ! -path '*_archive*' 2>/dev/null)

# 7. Oversized architecture docs — WARN only, never fail. This hook runs on
#    every commit against the working tree; a hard gate would block an
#    unrelated code commit until someone performed a doc split. /brain:tidy
#    owns that judgment — this is only the reminder.
while IFS= read -r f; do
  n=$(wc -l < "$f")
  [ "$n" -gt 150 ] && warn "architecture doc ${n} lines (>150 — /brain:tidy proposes the split): $f"
done < <(find brain/1-architecture -name '*.md' ! -name '_index.md' 2>/dev/null)

# 8. Standing backlogs. The `status: standing` line gates both /brain:execute's
#    parallel fan-out and every check below it, so a backlog missing it fails
#    OPEN — dangerously. Both directions of the naming/status pair are errors.
while IFS= read -r f; do
  fm=$(sed -n '2,/^---$/p' "$f" 2>/dev/null | tr -d '\r')
  standing=0; grep -qE '^status:[[:space:]]*standing' <<<"$fm" && standing=1
  case "$(basename "$f")" in
    *-backlog.md|*backlog*.md)
      [ "$standing" = 1 ] || { err "$f is named as a backlog but lacks 'status: standing' — /brain:execute would take ALL its items in parallel"; continue; } ;;
    *)
      [ "$standing" = 1 ] && err "$f has 'status: standing' but is not named *-backlog.md (one standing backlog per repo or domain)" ;;
  esac
  [ "$standing" = 1 ] || continue
  grep -qE '^[[:space:]]*- \[[xX]\]' "$f" && warn "standing backlog has done items — sweep them (delete the line; log it if the record matters): $f"
  while IFS= read -r line; do
    d=$(grep -oE '^[[:space:]]*- \[[ xX]\] ([0-9]{4}-[0-9]{2}-[0-9]{2})' <<<"$line" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}')
    if [ -z "$d" ]; then
      warncap "undated backlog lines" "undated backlog line in $f (triage dates every line): ${line:0:60}"
      continue
    fi
    age=$(days_since "$d") || { [ "$HAVE_DATE" = 1 ] && warn "unparseable backlog date '$d' in $f"; continue; }
    [ "$age" -lt 0 ] && warn "backlog line dated in the future ($d) in $f"
    [ "$age" -gt 30 ] && warncap "stale backlog lines" "backlog line ${age}d old (do it, shrink it, or delete it): ${line:0:60}"
  done < <(grep -E '^[[:space:]]*- \[[ xX]\]' "$f" 2>/dev/null | grep -v '{{')
done < <(find brain/2-checklists -name '*.md' 2>/dev/null)

# 9. Log streams: size only. Their content is judgment and is not lintable.
while IFS= read -r f; do
  n=$(wc -l < "$f")
  [ "$n" -gt 500 ] && warn "log stream ${n} lines (>500 — split by year, e.g. workout-2026.md): $f"
done < <(find brain/log -name '*.md' 2>/dev/null)

# 10. Plugin-source repos only: the consumer copies must match what is shipped,
#     or this repo stops being a test of its own distribution. Inert elsewhere.
if [ -d plugins/brain ]; then
  [ -f tools/brain-lint.sh ] && ! cmp -s tools/brain-lint.sh plugins/brain/tools/brain-lint.sh \
    && err "tools/brain-lint.sh differs from plugins/brain/tools/brain-lint.sh — run /brain:sync"
  if [ -f CLAUDE.md ] && [ -f plugins/brain/contract/brain-contract.md ]; then
    sed -n '/<!-- BRAIN:START/,/<!-- BRAIN:END/p' CLAUDE.md | sed '1d;$d' > /tmp/.brain-block.$$ 2>/dev/null
    cmp -s /tmp/.brain-block.$$ plugins/brain/contract/brain-contract.md \
      || err "CLAUDE.md's BRAIN block differs from plugins/brain/contract/brain-contract.md — run /brain:sync"
    rm -f /tmp/.brain-block.$$
  fi
fi

capsummary
[ "${BRAIN_LINT_STRICT:-0}" = "1" ] && [ "$WARN" = 1 ] && FAIL=1
[ "$FAIL" = 0 ] && echo "brain-lint: OK"
exit $FAIL
