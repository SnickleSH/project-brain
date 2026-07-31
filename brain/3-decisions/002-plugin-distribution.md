---
status: accepted
created: 2026-07-31
links: []
---

# 002. Distribute the framework as a Claude Code plugin, not per-repo copies

**Context** — `install.sh` copied commands, templates, and lint into each
consumer repo with `cp -n`, and appended the contract to `CLAUDE.md` blind.
Because `cp -n` never overwrites, a framework improvement could never reach a
repo that already had one: every repo froze at its install date and drifted.
The considered alternative was an "update-capable installer" — an explicit
framework manifest, always overwritten. That fails on two counts. Overwriting
safely requires detecting whether the consumer edited a file, which requires
storing a checksum of the last install: a state file, which rule 4 forbids.
And it stays pull-based, so with 5+ repos the drift merely changes shape from
clobber to staleness.

**Decision** — We will ship the framework as a plugin (`plugins/brain/`,
distributed via `.claude-plugin/marketplace.json`). Commands live outside the
consumer's working tree and are never copied into it. `/brain:init` scaffolds
only the content tree; `/brain:sync` refreshes the two framework files that
must be repo-local — the `CLAUDE.md` managed block and `tools/brain-lint.sh`.

**Consequences** — Commands become physically immutable per repo, so
consistency is structural rather than restored at update time, and one plugin
update reaches every repo. Divergence detection shrinks to exactly one
legitimately-editable file class (`brain/_templates/`), handled by showing a
diff and asking rather than by a lockfile. Costs: commands are namespaced, so
`/plan` becomes `/brain:plan`; the git pre-commit hook cannot reference the
plugin, because `${CLAUDE_PLUGIN_ROOT}` moves on every update and is unset in
a git hook's environment — hence lint remains a repo-local copy that sync
overwrites. Repos installed by the old `install.sh` need a one-time
reconciliation, which `/brain:init` performs with a diff.
