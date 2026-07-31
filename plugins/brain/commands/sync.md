---
description: Refresh this repo's brain framework files from the installed plugin, leaving all content untouched
---

You are updating the **framework** in this repo after the plugin itself has
been updated. Plugin files are at `${CLAUDE_PLUGIN_ROOT}` — read every source
from there, never from a guessed relative path.

The dividing line is absolute:

| Layer | Files | On sync |
|---|---|---|
| Framework | the contract block in `CLAUDE.md`, `tools/brain-lint.sh` | **replaced** |
| Editable | `brain/_templates/*.md` | **offered**, never silently replaced |
| Content | `brain/0-inbox` … `4-reference`, `brain/log/`, `brain/_archive/`, `.claude/skills/` | **never touched** |

If you find yourself about to write to anything in the Content row, stop —
that is a bug in this command, not a decision to make.

1. Read `version` from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json` and
   the stamp in the repo's `<!-- BRAIN:START v... -->` marker. Report both.
   Do not decide "already current" from the version alone — versions lie when
   someone edits a file by hand. Decide it by **comparing file content**: if
   the contract block already matches the plugin's contract and
   `tools/brain-lint.sh` already matches the plugin's copy, say "already
   current" and stop.

2. **Contract block.** Replace everything between `<!-- BRAIN:START v... -->`
   and `<!-- BRAIN:END -->` with
   `${CLAUDE_PLUGIN_ROOT}/contract/brain-contract.md`, and restamp the marker
   with the plugin version. Text outside the markers is the project's own and
   must survive byte-for-byte.
   If the markers are missing entirely, this repo was never `/brain:init`'d (or
   was installed by the legacy `install.sh`) — stop and tell me to run
   `/brain:init`, which handles that reconciliation with a diff.
   If exactly one marker is present, stop and show me the file; a half-marked
   file means someone edited across the boundary and guessing would destroy work.

3. **Lint.** Diff **before** overwriting, never after — once the file is
   replaced the local delta is unrecoverable. Show `diff tools/brain-lint.sh
   ${CLAUDE_PLUGIN_ROOT}/tools/brain-lint.sh`; if there is any local change,
   show it and get confirmation. If the working tree is dirty for that file,
   stop and ask for a commit or an explicit go-ahead first. Then overwrite and
   keep it executable.

4. **Templates.** For each `${CLAUDE_PLUGIN_ROOT}/templates/*.md`, compare with
   `brain/_templates/`. Templates are documented as editable, so:
   - Missing in the repo → copy it in.
   - Identical → nothing.
   - Different → show a diff and ask, one file at a time. Default to keeping
     the repo's version. Never batch-approve these.

5. **Structural drift.** Sync replaces files; it does not create directories or
   `.gitignore` lines. So compare the stage list and the `.gitignore` entries
   the new contract requires against what this repo actually has. If anything
   is missing — a new stage, a new ignore line — stop and tell me to run
   `/brain:init`, which is idempotent and exists for exactly this.

6. Run `tools/brain-lint.sh` and show its output. A newer lint usually brings
   new checks and surfacing them is the point — but **report them, fix none of
   them**. Contract rule 7's "redact, then retry" does not apply during a sync;
   hand the findings back as a to-do list and let me decide.

7. Report: version moved from → to, which framework files actually changed,
   which template diffs are still outstanding, whether `/brain:init` is needed
   for structural drift, and any lint findings the new version introduced.

Never create, move, or delete anything under `brain/0-inbox`, `1-architecture`,
`2-checklists`, `3-decisions`, `4-reference`, `log`, or `_archive`. Never touch
`.claude/skills/` — that is `/brain:distill` output and belongs to the project.
