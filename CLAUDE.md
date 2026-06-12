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
brain/4-reference/    durable facts: runbooks, API quirks, glossary (one file per topic)
brain/_archive/       processed inbox notes — GITIGNORED, local-only, never committed
.claude/skills/       reusable procedural knowledge, minted by /distill
```

Commands (defined in `.claude/commands/`):

- `/plan <topic>` — synthesize inbox notes into an architecture doc
- `/analyze <doc|theme>` — stress-test a design; findings go to the inbox, pipeline does not advance
- `/breakdown <architecture-doc>` — derive a technical checklist from a design (only when /analyze stops surfacing blockers)
- `/execute <checklist>` — implement the next unchecked items as code
- `/capture <text>` — append a quick note to the inbox
- `/tidy` — audit the graph for duplicates, broken links, and drift; fixes require confirmation
- `/distill` — extract a thrice-recurring procedure into a skill in `.claude/skills/`

`tools/brain-lint.sh` mechanically enforces this contract (secrets, index
drift, broken links, frontmatter); it runs as a pre-commit hook.

## The granularity principle

Weight is acceptable; granularity is not. Layers may grow richer over time
(better commands, accumulated skills, denser docs) but units of work stay
coarse: ONE doc per domain, ONE checklist per design, ONE skill per
recurring activity, ONE reference file per topic. Never create per-task,
per-sprint, or per-session artifacts. There is no sprint file: a sprint is
whichever open checklists get /execute'd; `status:` frontmatter + git is
the whole board.

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
7. **No secrets in the brain.** Raw captures often carry credentials. When
   writing ANY brain file, redact credential-looking strings (keys, tokens,
   passwords, connection strings) to `<redacted:kind>`. brain-lint blocks
   commits containing them; treat a lint failure as: redact, then retry.
8. **Skills follow the rule of three.** Procedures become `.claude/skills/`
   entries only on their third recurrence, via /distill, extending an
   existing skill before creating a new one. Skills hold procedure;
   `brain/4-reference/` holds facts; architecture holds design. Subagents
   (`.claude/agents/`) are a last resort for genuine isolation/parallelism —
   this CLAUDE.md remains the only router.
9. **Frontmatter is minimal.** Only `status`, `created`, and `links`. Resist
   adding fields.

## Keeping the graph organized as it grows

- **`brain/1-architecture/_index.md` is the routing table.** One line per doc
  stating what it owns. Before creating ANY new architecture doc, consult the
  index; if an existing doc owns the topic, update that doc instead. After
  creating, renaming, splitting, or superseding a doc, update the index in
  the same operation. The index contains no content — only pointers — so it
  is navigation, not state.
- **Splitting convention.** When a doc exceeds ~150 lines or a domain
  accumulates 3+ docs, split into a subfolder:
  `1-architecture/<domain>/overview.md` (the parent: scope, how the children
  relate) plus one child doc per sub-domain. Wikilinks keep resolving by
  filename, so make child filenames globally unique
  (`reports-delivery.md`, not `delivery.md`).
- **Checklists mirror architecture.** A checklist keeps the same relative
  path/name as the doc it derives from.
- **Superseding, not deleting.** A doc made obsolete gets
  `status: superseded`, a link to its replacement, and stays in place.

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
