---
status: raw          # raw | processed
created: 2026-06-13
links: []
---

# Brain distribution mechanism

<!-- Raw capture. Don't polish. The /plan command consumes this. -->

Distribution mechanism for the brain framework itself — how to install brain into other projects and push updates from this repo.

CORE INSIGHT: the repo is two layers wearing one coat. (1) Framework = shared, authored here, OVERWRITTEN on update: .claude/commands/*.md, tools/brain-lint.sh, the CLAUDE.md operating contract, brain/_templates/, the pre-commit hook. (2) Content = per-project, authored by the consumer, NEVER touched on update: brain/0-inbox..4-reference, _archive, and any /distill'd skills in .claude/skills/. Every distribution decision flows from keeping these two from contaminating each other. The trap: a naive copy-in clobbers a project's distilled skills and CLAUDE.md customizations on every update.

RECOMMENDED APPROACH: ship brain as a Claude Code plugin. The reusable surface is already plugin-shaped (mostly .claude/commands + a script). Plugins are the native install-once/update-with-one-command mechanism, versioned and distributed from a git repo ("marketplace"). Mapping: commands/ -> the 7 commands (read-only in plugin); skills/ -> framework skills only; bundled copy of brain-lint.sh; agents/ + hooks/ if added later. Because the plugin lives OUTSIDE the project working tree, it physically cannot overwrite brain/ content or distilled skills — solves the clobber problem for free.

THREE THINGS A PLUGIN ALONE CAN'T DO + fixes:
1. Scaffold the content tree — ship a /brain-init command that creates brain/0-inbox..4-reference, drops _templates/, appends brain/_archive/ to .gitignore. Idempotent.
2. The project's own CLAUDE.md — use a managed-block marker (<!-- BRAIN:START vX --> ... <!-- BRAIN:END -->). /brain-init injects it; a /brain-sync command replaces only between the markers and bumps the version stamp, preserving project additions.
3. The git pre-commit hook — plugin hooks are Claude Code hooks, not git hooks. /brain-init installs .git/hooks/pre-commit calling the plugin's bundled brain-lint.sh via the plugin-root env var.

DISTILLED-SKILLS SAFETY: /distill must write to the PROJECT's .claude/skills/, never the plugin's — separate trees never collide.

UPDATE FLOW: edit command here -> tag release -> consumer runs plugin update + /brain-sync. Commands/lint refresh atomically; CLAUDE.md managed block re-syncs; brain/ and distilled skills untouched.

FALLBACK (zero plugin coupling): git subtree the framework into vendor/brain/, symlink commands into .claude/, update via git subtree pull. More portable but reintroduces merge conflicts when projects edit vendored files. Only if brain must work in non-Claude-Code repos.

OPEN QUESTIONS / TO VERIFY: confirm exact current plugin + marketplace command names against live Claude Code docs before writing the architecture doc. Decide whether brain-lint runs as a git pre-commit hook, a Claude Code Stop/PreToolUse hook, or both. Decide skills namespace convention (framework vs project-distilled).

Related:
