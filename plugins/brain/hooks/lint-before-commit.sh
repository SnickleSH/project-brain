#!/usr/bin/env bash
# PreToolUse(Bash) — run brain-lint before an agent-issued `git commit`.
#
# WHY THIS EXISTS: the git pre-commit hook is the real gate, but git hooks do
# not travel. A fresh clone runs nothing until someone sets core.hooksPath by
# hand, so the enforcement silently isn't there — and nobody notices, because
# absence of a failure looks exactly like passing.
#
# This hook ships with the PLUGIN, so it applies in every repo and every clone
# with no per-repo setup. It covers agent-issued commits, which is the dominant
# path. The git hook still covers commits typed in a terminal.
#
# Blocking protocol: exit 2 blocks the tool call and stderr becomes the reason.
# Exit 0 lets it through. Any other code is a non-blocking error.
set -uo pipefail

input=$(cat)

# Cheap bail-out first: this runs on EVERY Bash call, so do one grep before
# spending a process on JSON parsing.
printf '%s' "$input" | grep -q 'git commit' || exit 0

read -r -d '' PY <<'PYEOF' || true
import json,sys
try: d = json.load(sys.stdin)
except Exception: sys.exit(1)
print(d.get("tool_input", {}).get("command", ""))
print(d.get("cwd", ""))
PYEOF
parsed=$(printf '%s' "$input" | python3 -c "$PY" 2>/dev/null) || exit 0
cmd=$(printf '%s\n' "$parsed" | sed -n '1p')
cwd=$(printf '%s\n' "$parsed" | sed -n '2p')

# Confirm it really is a commit, not merely a string mentioning one.
printf '%s' "$cmd" | grep -qE '(^|[;&|[:space:]])git([[:space:]]+-[^[:space:]]+)*[[:space:]]+commit([[:space:]]|$)' || exit 0

# Respect the documented escape hatch. Without this there is no way out, and a
# gate with no bypass gets disabled wholesale rather than bypassed once.
printf '%s' "$cmd" | grep -q -- '--no-verify' && exit 0

[ -n "$cwd" ] && cd "$cwd" 2>/dev/null || exit 0

# Locate the linter: nearest ancestor of cwd carrying tools/brain-lint.sh,
# which also handles a brain nested in a monorepo service.
dir=$PWD; lint=
while [ "$dir" != "/" ]; do
  if [ -f "$dir/tools/brain-lint.sh" ] && [ -d "$dir/brain" ]; then lint="$dir/tools/brain-lint.sh"; break; fi
  dir=$(dirname "$dir")
done
[ -n "$lint" ] || exit 0   # not a brain repo — nothing to say

out=$(cd "$(dirname "$(dirname "$lint")")" && bash "$lint" 2>&1)
status=$?
[ "$status" -eq 0 ] && exit 0

{
  echo "brain-lint failed, so this commit was blocked before it ran:"
  echo
  printf '%s\n' "$out" | grep '^✗' || printf '%s\n' "$out"
  echo
  echo "Fix the cause rather than working around it. If the failure is genuinely"
  echo "not yours (another session's half-finished edit), 'git commit --no-verify'"
  echo "is the documented bypass and this hook honours it."
} >&2
exit 2
