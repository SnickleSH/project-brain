# Project Brain — Operating Contract

This repository contains a markdown knowledge graph in `brain/`. It is the single
source of truth for planning. Treat it as part of the codebase: read it before
planning, update it after acting, commit it with code.

## Pipeline

Raw thought flows through four stages. Never skip a stage silently.

```
brain/0-inbox/        raw notes, ideas, meeting dumps, pasted links (unprocessed ONLY)
brain/1-architecture/ synthesized design docs (one per feature/domain)
brain/2-checklists/   actionable technical checklists derived from architecture
brain/3-decisions/    short ADRs — why we chose X over Y
brain/_archive/       processed inbox notes — GITIGNORED, local-only, never committed
```

Commands (defined in `.claude/commands/`):

- `/plan <topic>` — synthesize inbox notes into an architecture doc
- `/breakdown <architecture-doc>` — derive a technical checklist from a design
- `/execute <checklist>` — implement the next unchecked items as code
- `/capture <text>` — append a quick note to the inbox

## Rules

1. **Links over duplication.** Reference other docs with `[[wikilinks]]`
   (Obsidian-style). Never copy content between stages — link to it.
2. **Checklists are the execution interface.** When writing code, work from a
   checklist in `brain/2-checklists/`. Mark items `[x]` as you complete them,
   in the same commit as the code.
3. **Architecture docs are stable; checklists are disposable.** If
   implementation reveals the design was wrong, update the architecture doc
   and note it in `brain/3-decisions/` — don't patch around it in the checklist.
4. **No state files.** Progress lives in checkbox state and git history.
   Do not create status JSON, manifests, or progress trackers.
5. **Processed input gets archived automatically.** When `/plan` consumes
   inbox notes, it moves them to `brain/_archive/` (creating it if needed),
   sets `status: processed`, and adds a link to the doc that absorbed them.
   The inbox therefore contains only unprocessed material — its file count IS
   the backlog. Never delete notes; archive them. Never commit the archive.
6. **Architecture docs must stand alone.** `brain/_archive/` is gitignored,
   so archived notes exist only on the machine that processed them. Anything
   a design depends on must be IN the architecture doc, not linked from the
   archive. Links into `_archive/` are allowed as local breadcrumbs only.
7. **Frontmatter is minimal.** Only `status`, `created`, and `links`. Resist
   adding fields.

## File naming

- Inbox: `YYYY-MM-DD-slug.md` (e.g. `2026-06-11-auth-ideas.md`)
- Architecture: `slug.md` (e.g. `auth-flow.md`)
- Checklists: `slug.md`, matching its architecture doc name where possible
- Decisions: `NNN-slug.md`, sequential (e.g. `004-postgres-over-sqlite.md`)

## When asked to write code

1. Check `brain/2-checklists/` for a relevant checklist first.
2. If none exists but an architecture doc does, suggest `/breakdown` before coding.
3. If neither exists and the task is non-trivial, suggest `/plan` first.
4. Trivial fixes (typos, small bugs) skip the pipeline — just fix them.
