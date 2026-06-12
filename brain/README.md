# brain/ — an in-repo second brain & execution pipeline

A markdown knowledge graph that lives **inside the project repository**, next
to the code it plans. `claude-code` is the engine — it reads, synthesizes, and
writes these files directly in its native context (no MCP round-trips, no
remote-fetch token overhead). Obsidian or VSCode is strictly the viewer.

This system is project-scoped by design: clone the repo, get the brain. It is
not a central wiki, and it deliberately carries no agent-framework state
(no manifests, no progress JSON, no orchestration files). Progress is
checkbox state plus git history — nothing else.

Its constitution: **weight is acceptable; granularity is not.** Layers may
grow richer over time — commands improve, skills accumulate, docs densify —
but units of work stay coarse: one doc per domain, one checklist per design,
one skill per recurring activity. No per-task, per-sprint, or per-session
artifacts, ever. A sprint is whichever open checklists you choose to
`/execute`; `status:` frontmatter plus git is the entire board.

## The pipeline

Every piece of information moves left to right through four stages, each with
one command:

```
            /capture           /plan              /breakdown          /execute
 anything ──────────▶ 0-inbox ───────▶ 1-architecture ───────▶ 2-checklists ───────▶ code
                         │                    │
                         ▼ (after /plan)      ▼ (when a trade-off is resolved)
                     _archive/            3-decisions/
                    (gitignored)            (ADRs)
```

| Stage | Folder | Contains | Mutability |
|---|---|---|---|
| Capture | `0-inbox/` | raw, unpolished input — only **unprocessed** material | append-only |
| Synthesis | `1-architecture/` | one settled design doc per feature/domain | stable; amended when reality disagrees |
| Handoff | `2-checklists/` | commit-sized tasks derived from one design doc | machine-managed; disposable |
| Record | `3-decisions/` | short ADRs: context → decision → consequences | immutable; superseded, never edited |
| Reference | `4-reference/` | durable facts: runbooks, API quirks, glossary — one file per topic | append/amend |
| Archive | `_archive/` | processed inbox notes, moved here by `/plan` | **gitignored**, local-only |
| Skeletons | `_templates/` | the four document templates the commands use | edit to taste |

### Why the archive is gitignored

Raw notes are working material, not team knowledge. Once `/plan` has absorbed
them into an architecture doc, keeping them in git would (a) bloat history
with throwaway text, (b) leak half-formed thinking into PRs, and (c) tempt
people to treat raw notes as a source of truth. So `/plan` moves consumed
notes to `_archive/` automatically — they stay on your machine as breadcrumbs
(searchable, recoverable, linkable locally) but never reach the remote.

The corollary is the system's most important rule: **architecture docs must
stand alone.** Anything a design depends on must be in the doc itself, because
on a teammate's clone the archive is empty.

## The commands

Defined in `.claude/commands/`; available as slash commands inside `claude`.

### `/capture <text>` — get it out of your head

Appends a verbatim note to `0-inbox/` as `YYYY-MM-DD-slug.md`. No summarizing,
no "improving", no filing decisions. Capture is judgment-free by design: the
moment capturing requires thinking about where something belongs, you stop
capturing. Five seconds, back to work.

Also valid: creating inbox files by hand, piping in exports, pasting meeting
transcripts. Anything in the folder is fair game for `/plan`.

### `/plan [topic]` — synthesize inbox → architecture

- **Without a topic**: surveys the inbox, reports the themes it sees, asks
  which to synthesize. Use this as your map when the inbox has piled up.
- **With a topic**: reads the relevant inbox notes *and* existing architecture
  docs, then writes (or **incrementally updates** — no duplicates) one doc in
  `1-architecture/`. Decisions, not option lists; under ~150 lines; wikilinks
  to related docs instead of repetition.
- **Then archives**: consumed notes get `status: processed`, a link to the
  doc that absorbed them, and are moved to `_archive/` automatically. The
  inbox file count is therefore always your real backlog.

Read every doc `/plan` writes. Synthesis is the step where your judgment
matters most; a wrong conclusion here propagates into checklists and code.

### `/analyze <doc or theme>` — stress-test a design (pipeline does not advance)

The command for staying in the high-level phase. Reads the design, its links,
relevant ADRs, and the code it touches, then reports underspecification,
reality mismatches, unexamined alternatives, cross-doc tension, and risk
concentration — ranked by how much downstream work each endangers. It never
edits architecture docs or writes checklists; when the session ends it
distills durable findings into one inbox note so `/plan` can fold them in.
It closes by answering the gate question: does interrogation still produce
new blocking questions? Loop `/analyze` → `/plan` until the answer is no.

### `/breakdown <architecture-doc>` — design → checklist

Reads the design, its linked docs, **and the actual codebase areas it
touches**, then writes a checklist where every item is one commit-sized unit
with concrete file paths and a verifiable "done when" condition.

If the design has gaps, `/breakdown` does not improvise — it halts and writes
the open questions under a `## Blocked on` section. That's the system working:
answer the questions, update the architecture doc, re-run.

### `/execute <checklist> [n]` — checklist → code

Implements the next unchecked item (or `n` items), runs each item's
verification, ticks it `[x]`, and stages the code change **and** the checklist
update together so plan and code can never drift in history. If the real
codebase contradicts an item, it stops and proposes an amendment upstream
instead of patching around it. Durable contradictions become draft ADRs.

### `/distill` — grow the skill layer

Skills (`.claude/skills/<slug>/SKILL.md`) are the layer that learns across
features: reusable, repo-specific *procedures* — how migrations are written
here, how report queries get tested — auto-discovered by claude-code and
loaded when relevant. `/distill` mints them under the **rule of three** (a
procedure must recur three times before it's abstracted) and **extends an
existing skill before creating a new one**, so the layer stays few-and-rich
instead of many-and-shallow. Skills hold procedure; `4-reference/` holds
facts; architecture holds design. This — not sprint files — is how knowledge
transfers between features: each `/execute` cycle runs a little smarter than
the last. Subagents (`.claude/agents/`) are the rung above, reserved for
genuine parallelism/isolation needs; the root `CLAUDE.md` stays the only
router.

## Mechanical enforcement

The contract is prompt-enforced, and prompt compliance decays — so
`tools/brain-lint.sh` enforces the invariants in code, as a pre-commit hook
(installed by `install.sh`): **fails** the commit on credential-looking
strings in committed brain files and on index↔filesystem drift; **warns** on
broken wikilinks, missing frontmatter, and inbox notes older than 14 days.
`BRAIN_LINT_STRICT=1` upgrades warnings to failures. `/tidy` remains the
judgment-level audit on top; lint is the deterministic floor beneath it.
Relatedly: architecture docs carry an `## Evidence` section — load-bearing
facts copied out of source notes before they're archived, so decisions stay
traceable even though raw notes never reach git.

## Workflows

### Bootstrapping into an existing project (or from Notion/another tool)

1. **Drain, don't migrate.** Export old notes to markdown and dump them into
   `0-inbox/` raw. Don't hand-sort them into `1-architecture/` — that imports
   the old tool's stale structure instead of synthesizing against reality.
2. `/plan` (no topic) to survey what you actually brought over.
3. Synthesize one domain at a time, smallest coherent unit first. The inbox
   drains over a few sessions; that's normal, not debt.
4. **Migrating from an agentic framework (GSD-style):** drag/point `/plan`
   at the old planning folder — it stages files into the inbox itself. Its
   docs are ingested as *claims to verify against the code* (they may be
   stale), resolved trade-offs become ADRs, encoded conventions are
   `/distill` candidates, and state/progress/task files are deliberately
   skipped: checklists get re-derived fresh via `/breakdown` once the
   architecture settles. Rescue genuinely in-flight work by hand with
   `/capture`.
5. **Capture the terrain, not just your intentions**: have claude-code read
   the parts of the existing codebase your work touches and `/capture` its
   findings, then `/plan` them. The brain should know how things *are* before
   deciding how they *will be*.

### Ingesting new information

Meeting outcomes, requirements, a paper, a hunch: `/capture` it the moment it
appears, individually, without batching or polishing. When several captures
accumulate on a theme, run one `/plan <theme>` to fold them all in. Capture is
continuous; synthesis is batched.

### Diving deeper into a topic (the analysis loop)

`/analyze` now closes the loop itself: stress-test → discussion → distilled
inbox note → a single gated question ("fold these findings into the doc
now?"). Confirm, and it performs the synthesis in the same session; decline,
and the note waits for a later `/plan`. The gate exists on purpose — an
ungated loop would have the model interrogating its own design and grading
its own synthesis with you as a spectator. The discussion in the middle is
the product.

High-level planning is a loop, not a step — `/plan` once is a first draft of
what you used to think, not a settled design. The loop:

1. Pick the thin or contested architecture doc (the Obsidian graph view makes
   thin/orphaned nodes visible).
2. `/analyze <doc>` — structured stress-test against the codebase — or
   interrogate freely in a plain session for open-ended exploration.
3. Capture the output: `/analyze` distills its findings into an inbox note
   itself; in free sessions, `/capture` every insight and open question —
   **conversations are scratch space; files are memory.**
4. `/plan <topic>` to fold findings back into the doc. Real trade-offs that
   get resolved become ADRs.
5. Repeat until interrogation stops producing new blocking questions. That —
   not having run `/plan` once — is the gate to `/breakdown`. Descending
   early is cheap to undo (checklists are disposable; delete and regenerate),
   but the habit to build is: breakdown only designs you'd bet a sprint on.

### When reality disagrees with the plan

Never patch the checklist. Amend the architecture doc, record an ADR if a
trade-off flipped, re-run `/breakdown`. Checklists are disposable; the design
layer is the asset.

### Hygiene (10 minutes, weekly)

- `ls brain/0-inbox/` — since processed notes auto-archive, anything still
  here is genuinely unprocessed. Older than a week → `/plan` it or admit it
  never mattered.
- Obsidian graph: orphan nodes are unsynthesized knowledge; oversized nodes
  want splitting.
- Mark shipped checklists `status: done`. Delete nothing — that's what the
  archive and `status: superseded` are for.

## How the wiki stays organized as it grows

The graph self-organizes only up to a point; past ~15 docs, three mechanisms
keep it from sprawling:

1. **The routing table.** `1-architecture/_index.md` holds one line per doc
   stating what it owns. `/plan` consults it before creating anything (so
   topics route to their existing doc instead of spawning near-duplicates
   like `auth-flow.md` vs `authentication.md`) and updates it whenever a doc
   is created, renamed, split, or superseded. It contains pointers only —
   regenerable navigation, not state.
2. **The splitting convention.** A doc past ~150 lines, or a domain reaching
   3+ docs, becomes a subfolder: `<domain>/overview.md` for scope and how the
   children relate, plus one child per sub-domain with globally unique
   filenames (wikilinks resolve by filename). Checklists mirror the layout.
3. **`/tidy`** — a monthly audit that detects index drift, suspected
   duplicates, broken wikilinks, oversized docs, orphans, designs
   contradicted by newer ADRs, and stale checklists. It proposes fixes and
   executes only what you approve; obsolete docs are superseded-and-linked,
   never deleted.

## Conventions

- **Wikilinks over duplication.** `[[doc-slug]]` everywhere; copying content
  between stages is how second brains rot.
- **Minimal frontmatter.** `status`, `created`, `links`. Nothing else.
- **Naming.** Inbox: `YYYY-MM-DD-slug.md` · Architecture/checklists: `slug.md`
  (matching pairs) · Decisions: `NNN-slug.md`, sequential.
- **Plan and code share commits.** A PR that changes behavior should show the
  checklist tick — and any design amendment — in the same diff.
- **Trivial fixes skip the pipeline.** Typos and small bugs don't need a
  checklist; the contract in `CLAUDE.md` tells the model so.

## Viewing the graph

- **Obsidian** (Windows host, WSL repo): open `brain/` as a vault via
  `\\wsl$\Ubuntu\home\<you>\<repo>\brain`. Viewer only — heavy file I/O
  (claude-code) stays native in WSL, so `/mnt/c` permission and inotify
  problems never touch the execution path. Workspace files are gitignored.
- **VSCode**: Remote-WSL extension; add Foam or Markdown Memo for clickable
  wikilinks and a graph in the same window.

## Installing into another repo

```bash
./install.sh ~/projects/another-repo
```

Idempotent. Creates the folders (including a local `_archive/`), copies
commands and templates, appends the operating contract to the target's
`CLAUDE.md`, and patches `.gitignore` (archive + Obsidian workspace state).
Refuses `/mnt/c/...` targets to keep you on native WSL paths.
