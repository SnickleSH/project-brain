#!/usr/bin/env bash
# SessionStart — tell the session when a repo's git hooks are present but inert.
#
# core.hooksPath is local config and does not travel with a clone, so a repo can
# carry a perfectly good .githooks/pre-commit that has never once run. This
# reports the condition and the one-line fix. It deliberately does NOT run
# `git config` itself: a plugin silently rewriting your repo's configuration is
# the wrong trade, and a repo may point hooksPath elsewhere on purpose.
#
# SessionStart cannot block; additionalContext is its only output.
set -uo pipefail

input=$(cat)
cwd=$(printf '%s' "$input" | python3 -c 'import json,sys
try: print(json.load(sys.stdin).get("cwd",""))
except Exception: print("")' 2>/dev/null) || exit 0

[ -n "$cwd" ] && cd "$cwd" 2>/dev/null || exit 0
root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$root" || exit 0

# Only speak up in repos that actually use this framework.
[ -d brain ] || [ -n "$(find . -maxdepth 3 -type d -name brain -not -path './.git/*' -print -quit 2>/dev/null)" ] || exit 0

configured=$(git config core.hooksPath 2>/dev/null || true)
hookdir=$(git rev-parse --git-path hooks 2>/dev/null)

msg=
if [ -d .githooks ] && [ -z "$configured" ]; then
  msg="This repo has a .githooks/ directory but core.hooksPath is unset, so its git hooks have never run in this clone. brain-lint still gates agent-issued commits via the plugin, but terminal commits are ungated until: git config core.hooksPath .githooks"
elif [ ! -e "$hookdir/pre-commit" ] && [ ! -d .githooks ]; then
  msg="This repo has a brain/ graph but no git pre-commit hook, so brain-lint does not gate commits typed in a terminal. Agent-issued commits are still checked by the plugin. Run /brain:init to install the hook."
elif [ -e "$hookdir/pre-commit" ] && [ ! -x "$hookdir/pre-commit" ]; then
  msg="This repo's pre-commit hook exists but is NOT executable, so git silently skips it — every check it performs is currently inert. Fix with: chmod +x '$hookdir/pre-commit'"
fi

[ -n "$msg" ] || exit 0
python3 -c 'import json,sys
print(json.dumps({"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":sys.argv[1]}}))' "$msg"
