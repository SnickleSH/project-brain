---
description: Scaffold the brain content tree into this repo and install the contract, lint, and pre-commit hook
---

Target: the current repository. Optional argument — a domain list for a
multi-domain personal repo (e.g. `health investing university`): $ARGUMENTS

You are installing the brain **content tree**. The commands themselves live in
the plugin and are never copied into a repo — that is the whole point of the
plugin, and copying them would recreate the per-repo drift this replaces.

Throughout, the plugin's own files are at `${CLAUDE_PLUGIN_ROOT}` (an absolute
path Claude Code sets while this command runs). Read every source file from
there — `${CLAUDE_PLUGIN_ROOT}/templates/`,
`${CLAUDE_PLUGIN_ROOT}/tools/brain-lint.sh`,
`${CLAUDE_PLUGIN_ROOT}/contract/brain-contract.md`,
`${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`. Never assume the plugin
sits at a relative path from the repo; usually it does not.

This command is idempotent. Run it on a fresh repo, or re-run it safely on one
that already has a brain. It NEVER overwrites existing notes, docs, logs, or
distilled skills.

## 1. Detect what is already here

Report before you change anything:
- Does `brain/` exist, and which stages?
- Does `CLAUDE.md` exist? Does it contain `<!-- BRAIN:START` markers? Does it
  contain the contract text WITHOUT markers (a legacy `install.sh` install)?
- **Is `.claude/commands` a symlink** (`[ -L .claude/commands ]`), or does any
  file under it resolve outside the repo's `.claude/`? If so this repo sources
  commands from a plugin checkout on purpose. Report that and **skip step 2
  entirely** — following the legacy branch would delete the plugin's own source
  files through the link.
- Otherwise: do regular files (`-type f`) exist at `.claude/commands/<name>.md`
  for any name in `${CLAUDE_PLUGIN_ROOT}/commands/`? Derive that list by
  listing the directory rather than hardcoding it, so it stays correct as
  commands are added. Those are legacy per-repo copies that now shadow the
  plugin under un-namespaced names.
- Does `tools/brain-lint.sh` exist?

## 2. Legacy migration (only if step 1 found real legacy copies)

A repo installed by the old `install.sh` carries local copies of the commands
and an unmarked contract. Both must be reconciled or you run two versions of
the framework side by side: the plugin's `/brain:plan` and a stale local
`/plan`.

Present this as a plan and get confirmation for each part:
- **Legacy command copies** → delete only regular files under
  `.claude/commands/` whose names match the plugin's command set. Never follow
  a symlink. Leave any command the project wrote itself, and leave
  `.claude/skills/` completely alone (that is `/brain:distill` output and
  belongs to the project).
- **Unmarked contract in `CLAUDE.md`** → this needs a human decision, because
  the project may have edited it. Show a diff between the repo's contract text
  and `${CLAUDE_PLUGIN_ROOT}/contract/brain-contract.md`. Then either wrap the
  existing text in markers as-is (preserving local edits; say plainly that the
  next `/brain:sync` will replace it), or replace it with the current contract.
  Ask which. Never guess.

## 3. Scaffold the content tree

Create, without clobbering anything that exists:

```
brain/0-inbox/        brain/1-architecture/   brain/2-checklists/
brain/3-decisions/    brain/4-reference/      brain/log/
brain/_archive/       brain/_templates/
```

- `.gitkeep` in each committed stage so empty stages survive a clone.
- `brain/1-architecture/_index.md` with an empty routing table if absent.
- Copy `${CLAUDE_PLUGIN_ROOT}/templates/*.md` into `brain/_templates/` **only
  if the file does not already exist**. Templates are explicitly editable per
  repo, and every content command reads them from `brain/_templates/`.
- Copy `${CLAUDE_PLUGIN_ROOT}/templates/skill-example/SKILL.md` to
  `.claude/skills/_example-repo-conventions/SKILL.md` only if `.claude/skills/`
  is empty.
- If domain arguments were given, create matching subfolders under
  `1-architecture/`, `2-checklists/` and `log/`, and note in `_index.md` that
  this repo is domain-partitioned. Do NOT create per-domain inboxes: capture
  must stay zero-decision, so there is exactly one `0-inbox/` and
  `/brain:triage` is what routes.

## 4. Install lint and the pre-commit hook

Copy `${CLAUDE_PLUGIN_ROOT}/tools/brain-lint.sh` to `tools/brain-lint.sh` and
`chmod +x` it. It must be a repo-local copy rather than a reference into the
plugin, for two reasons: `${CLAUDE_PLUGIN_ROOT}` points at a new directory
after every plugin update, and it is not set at all in a git hook's
environment, which is where this script does its most important work.
`/brain:sync` is what keeps the copy current.

Then, if this is a git repo — resolve the hooks directory with
`git rev-parse --git-path hooks` rather than assuming `.git/hooks`, since
`core.hooksPath` and worktrees both move it:

- No `pre-commit` hook → write exactly:

  ```sh
  #!/usr/bin/env sh
  exec bash tools/brain-lint.sh
  ```

  then `chmod +x` the hook. **The chmod is not optional**: git silently skips a
  non-executable hook, printing only a `hint:` line, so the commit succeeds and
  every mechanical guarantee in this contract quietly becomes advisory.
  Note the hook invokes the linter via `bash` rather than executing it: git
  stores file modes, and a rebase or stash cycle can drop the linter's own exec
  bit. Invoking it explicitly makes the check independent of that.
- Chaining into an existing hook → guard on `-f`, never `-x`. An `-x` guard
  turns a lost exec bit into a silently skipped check, which is strictly worse
  than a noisy failure.
- A `pre-commit` hook exists and already mentions `brain-lint` → leave it, but
  still verify it is executable.
- A `pre-commit` hook exists without it → do not edit it silently. Print the
  exact line to add and tell me to add it.

## 5. Patch `.gitignore`

Append any of these that are missing (never remove existing lines):

```
brain/_archive/
data/
*:Zone.Identifier
brain/.obsidian/workspace*
brain/.obsidian/cache
.obsidian/workspace*
```

`data/` is ignored because bulk and machine-regenerable material must never
enter git through the brain. If the repo already commits a `data/` directory
for another purpose, skip that line and tell me.

## 6. Inject the contract

Read `${CLAUDE_PLUGIN_ROOT}/contract/brain-contract.md` and the `version` field
from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`. In the repo's
`CLAUDE.md`:
- Markers present → replace everything between them and restamp the marker with
  the plugin version. (That is `/brain:sync`'s job; doing it here keeps init
  idempotent.)
- No markers → append the contract wrapped in
  `<!-- BRAIN:START v<version> -->` … `<!-- BRAIN:END -->`, preceded by a blank
  line. Everything outside the markers is the project's and is never touched.

The block must end up byte-identical to the plugin's contract file — lint
compares them in plugin-source repos.

## 7. Report and verify

Print: what was created, what was skipped as already-present, and what needs my
manual action. Then verify rather than assume:

- Confirm the pre-commit hook exists AND is executable. Say so explicitly.
- Run `tools/brain-lint.sh` once and show its output, so the repo starts in a
  known-clean state.

Finally, note that these commands come from a plugin installed **per machine,
not per repo**. Anyone cloning this repo needs, once:

```
/plugin marketplace add <marketplace-repo>
/plugin install brain@project-brain
```

Print those two lines in the report, with the marketplace this plugin came
from, so the instruction lands somewhere the next person will find it.
