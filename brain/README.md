# brain/ — an in-repo second brain & execution pipeline

A markdown knowledge graph that lives **inside the project repository**, next
to the code it plans. `claude-code` is the engine — it reads, synthesizes, and
writes these files directly in its native context (no MCP round-trips, no
remote-fetch token overhead). Obsidian or VSCode is strictly the viewer.

This system is project-scoped by design: clone the repo, get the brain. It is
not a central wiki, and it deliberately carries no agent-framework state
(no manifests, no progress JSON, no orchestration files). Progress is
checkbox state plus git history — nothing else.

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

## Workflows

### Bootstrapping into an existing project (or from Notion/another tool)

1. **Drain, don't migrate.** Export old notes to markdown and dump them into
   `0-inbox/` raw. Don't hand-sort them into `1-architecture/` — that imports
   the old tool's stale structure instead of synthesizing against reality.
2. `/plan` (no topic) to survey what you actually brought over.
3. Synthesize one domain at a time, smallest coherent unit first. The inbox
   drains over a few sessions; that's normal, not debt.
4. **Capture the terrain, not just your intentions**: have claude-code read
   the parts of the existing codebase your work touches and `/capture` its
   findings, then `/plan` them. The brain should know how things *are* before
   deciding how they *will be*.

### Ingesting new information

Meeting outcomes, requirements, a paper, a hunch: `/capture` it the moment it
appears, individually, without batching or polishing. When several captures
accumulate on a theme, run one `/plan <theme>` to fold them all in. Capture is
continuous; synthesis is batched.

### Diving deeper into a topic

A deep dive is the loop at higher resolution on one node of the graph:

1. Pick the thin or contested architecture doc (the Obsidian graph view makes
   thin/orphaned nodes visible).
2. Interrogate it in a claude-code session, anchored on the doc and the code:
   *"Read brain/1-architecture/X.md and src/X/. Where is the design
   underspecified? What would block implementation?"*
3. `/capture` every insight and open question the session produces —
   **conversations are scratch space; files are memory.** Unrecorded insight
   is lost when the session ends.
4. `/plan <topic>` to fold findings back into the doc. If a real trade-off got
   resolved, it becomes an ADR.

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
