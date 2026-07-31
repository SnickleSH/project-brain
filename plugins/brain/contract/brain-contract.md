# Project Brain — Operating Contract

This repository contains a markdown knowledge graph in `brain/`. It is the single
source of truth for planning. Treat it as part of the codebase: read it before
planning, update it after acting, commit it with code.

## Pipeline

Raw thought flows through the stages below. Never skip a stage silently.

```
brain/0-inbox/        raw notes, ideas, meeting dumps, pasted links (unprocessed ONLY)
brain/1-architecture/ synthesized design docs (one per feature/domain)
brain/2-checklists/   derived checklists (one per design) + one standing backlog
brain/3-decisions/    short ADRs — why we chose X over Y
brain/4-reference/    durable facts: runbooks, API quirks, glossary (one file per topic)
brain/log/            append-only observation streams (one file per stream)
brain/_archive/       processed inbox notes — GITIGNORED, local-only, never committed
.claude/skills/       reusable procedural knowledge, minted by /brain:distill
```

Commands come from the `brain` plugin and are namespaced:

- `/brain:capture <text>` — append a quick note to the inbox
- `/brain:triage` — dispatch the inbox: facts → reference, tasks → the standing
  backlog, observations → a log stream, noise → archive. Designs stay put.
- `/brain:plan <topic>` — synthesize inbox notes into an architecture doc
- `/brain:analyze <doc|domain>` — stress-test a design; in **log mode** (when the
  domain has a log stream) also test the policy against what actually happened.
  Findings land in the inbox; the doc is updated only behind an explicit
  confirmation, and the only thing ever written to a log stream is a
  `## Review` marker.
- `/brain:breakdown <doc>` — derive a checklist from a design
- `/brain:execute <checklist>` — implement unchecked items as code
- `/brain:tidy` — audit the graph for duplicates, broken links, and drift
- `/brain:distill` — extract a thrice-recurring procedure into a skill
- `/brain:init` / `/brain:sync` — scaffold, and refresh the framework layer

`tools/brain-lint.sh` mechanically enforces this contract and runs as a
pre-commit hook. It FAILS on secrets, index drift, bulk under `brain/`, a
backlog missing `status: standing`, and `## Evidence` links that resolve to
nothing committed; it warns on broken links, missing frontmatter, and
staleness.

## Not everything needs a design

`/brain:plan` is for material that requires a decision. Shallow work that
arrived ready to do goes straight to the standing backlog via `/brain:triage`.
Never invent an architecture doc so a task has somewhere to live — that is how
the graph fills with per-task artifacts.

## The granularity principle

Weight is acceptable; granularity is not. Layers may grow richer over time
(better commands, accumulated skills, denser docs) but units of work stay
coarse: ONE doc per domain, ONE derived checklist per design, ONE standing
backlog per repo (or per domain subfolder), ONE skill per recurring activity,
ONE reference file per topic, ONE log file per stream. Never create per-task,
per-sprint, or per-session artifacts. There is no sprint file: a sprint is
whichever open checklists get /brain:execute'd; `status:` frontmatter + git is
the whole board.

## Rules

1. **Links over duplication.** Reference other docs with `[[wikilinks]]`
   (Obsidian-style). Never copy content between stages — link to it.
2. **Checklists are the execution interface.** When writing code, work from a
   checklist in `brain/2-checklists/`. Two kinds, different lifecycles:
   - **Derived** (`status: open`, from /brain:breakdown) — disposable, dies
     with the feature. Mark items `[x]` in the same commit as the code.
   - **Standing** (`status: standing`, fed by /brain:triage) — lives forever,
     so it is **swept, not checked**: the completing commit deletes the line,
     appending to `brain/log/` if the record matters. Every line carries the
     date it arrived. `/brain:execute` never takes all items from a standing
     backlog without explicit selection.
3. **Architecture docs are stable; checklists are disposable.** If
   implementation reveals the design was wrong, update the architecture doc
   and note it in `brain/3-decisions/` — don't patch around it in the checklist.
4. **No state files.** Progress lives in checkbox state and git history.
   Do not create status JSON, manifests, or progress trackers.
5. **Processed input gets archived automatically.** When `/brain:plan` or
   `/brain:triage` consumes an inbox note, it moves it to `brain/_archive/`
   and links what absorbed it — `status: processed` when it was absorbed,
   `status: discarded` when it was noise. The inbox therefore contains only
   unprocessed material — its file count IS the backlog. Never delete notes;
   archive them. Never commit the archive.
6. **Load-bearing facts must survive in git.** `brain/_archive/` is gitignored,
   so anything a design depends on must live in a COMMITTED brain file: the
   architecture doc itself, or a `brain/4-reference/` topic it links to.
   Prefer the link — `## Evidence` holds references, not copies, and gets
   rewritten rather than appended to. Links into `_archive/` are local
   breadcrumbs only, never a source of truth.
7. **No secrets in the brain.** Raw captures often carry credentials. When
   writing ANY brain file, redact credential-looking strings (keys, tokens,
   passwords, connection strings) to `<redacted:kind>`. brain-lint blocks
   commits containing them; treat a lint failure as: redact, then retry.
8. **The brain holds intent, procedure, and judgment — never bulk.** Anything
   machine-generated, re-pullable, or externally authoritative (datasets,
   exports, API dumps, spreadsheet mirrors) lives in `data/`, which is
   gitignored, with a `brain/4-reference/` runbook saying where it comes from
   and how to pull it. `brain/log/` holds what you concluded, not what a
   script produced. brain-lint fails on non-markdown or >100KB files in `brain/`.
9. **Skills follow the rule of three.** Procedures become `.claude/skills/`
   entries only on their third recurrence, via /brain:distill, extending an
   existing skill before creating a new one. Skills hold procedure;
   `brain/4-reference/` holds facts; architecture holds design. Subagents
   (`.claude/agents/`) are a last resort for genuine isolation/parallelism —
   this CLAUDE.md remains the only router.
10. **Frontmatter is minimal.** Only `status`, `created`, and `links`. Resist
    adding fields. Log streams carry no frontmatter at all.

## Keeping the graph organized as it grows

- **`brain/1-architecture/_index.md` is the routing table.** One line per doc
  stating what it owns. Before creating ANY new architecture doc, consult the
  index; if an existing doc owns the topic, update that doc instead. After
  creating, renaming, splitting, or superseding a doc, update the index in
  the same operation. The index contains no content — only pointers — so it
  is navigation, not state.
- **Splitting convention.** When a doc exceeds ~150 lines or a domain
  accumulates 3+ docs, split into a subfolder:
  `1-architecture/<domain>/<domain>-overview.md` (the parent: scope, how the
  children relate) plus one child doc per sub-domain. Wikilinks resolve by
  filename, so EVERY filename under `1-architecture/` must be globally
  unique — `health-overview.md` not `overview.md`, `reports-delivery.md` not
  `delivery.md`. Lint fails on duplicate basenames.
- **Checklists mirror architecture.** A derived checklist keeps the same
  relative path/name as the doc it derives from.
- **Superseding, not deleting.** A doc made obsolete gets
  `status: superseded`, a link to its replacement, and stays in place.

## File naming

- Inbox: `YYYY-MM-DD-slug.md` (e.g. `2026-06-11-auth-ideas.md`)
- Architecture: `slug.md` (e.g. `auth-flow.md`)
- Checklists: `slug.md` matching its architecture doc; standing backlogs are
  `<repo-or-domain>-backlog.md`
- Decisions: `NNN-slug.md`, sequential (e.g. `004-postgres-over-sqlite.md`)
- Logs: `<stream>.md`, split by year past ~500 lines (`workout-2026.md`)

## When asked to write code

1. Check `brain/2-checklists/` for a relevant checklist first.
2. If none exists but an architecture doc does, suggest `/brain:breakdown`.
3. If the work is shallow and arrived ready to do, it belongs on the standing
   backlog via `/brain:triage` — not in a new architecture doc.
4. If neither exists and the task genuinely needs a decision, suggest
   `/brain:plan` first.
5. Trivial fixes (typos, small bugs) skip the pipeline — just fix them.
