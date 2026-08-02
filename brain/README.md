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
`/brain:execute`; `status:` frontmatter plus git is the entire board.

## The pipeline

Everything enters through one door and is then routed. The deep path
(synthesis → design → checklist) is for material that needs a decision; the
shallow path skips straight to work.

```
                                        ┌─ FACT ──▶ 4-reference/
                                        │
            /brain:capture              ├─ TASK ──▶ 2-checklists/<domain>-backlog.md ─┐
 anything ──────────────▶ 0-inbox ──────┤             (standing)                      │
                             │  /brain: ├─ LOG ───▶ log/<stream>.md                   │
                             │  triage  │                                             │
                             │          └─ NOISE ─▶ _archive/                         │
                             │                                                        │
                             ▼ DESIGN stays put                                       │
                        /brain:plan                                                   │
                             │                                                        │
                             ▼           /brain:breakdown        /brain:execute       │
                      1-architecture ──────────────▶ 2-checklists ──────────▶ code ◀──┘
                             │                          (derived)
                             ▼ (when a trade-off is resolved)
                        3-decisions/ (ADRs)
```

| Stage | Folder | Contains | Mutability |
|---|---|---|---|
| Capture | `0-inbox/` | raw, unpolished input. After triage: only what needs **thought** | append-only |
| Synthesis | `1-architecture/` | one settled design doc per feature/domain | stable; amended when reality disagrees |
| Handoff | `2-checklists/` | **derived** checklists (one per design, disposable) and one **standing** backlog per domain (dated lines, swept on completion) | machine-managed |
| Record | `3-decisions/` | short ADRs: context → decision → consequences | immutable; superseded, never edited |
| Reference | `4-reference/` | durable facts: runbooks, API quirks, external-source runbooks — one file per topic | append/amend |
| Log | `log/` | append-only observation streams — one file per stream, no frontmatter | append-only; never synthesized |
| Archive | `_archive/` | inbox notes consumed by `/brain:plan` or `/brain:triage` | **gitignored**, local-only |
| Skeletons | `_templates/` | the document templates the commands use | edit to taste |

`log/` is unnumbered on purpose: it is not a refinement stage but an input
stream that never refines. It must not go in `0-inbox/`, which gets synthesized
and archived out of git — pointing `/brain:capture` at a training history would
destroy it — and it must not go in `4-reference/`, which is deduplicated facts
rather than append-only history.

### Why the archive is gitignored

Raw notes are working material, not team knowledge. Once `/brain:plan` has absorbed
them into an architecture doc, keeping them in git would (a) bloat history
with throwaway text, (b) leak half-formed thinking into PRs, and (c) tempt
people to treat raw notes as a source of truth. So `/brain:plan` moves consumed
notes to `_archive/` automatically — they stay on your machine as breadcrumbs
(searchable, recoverable, linkable locally) but never reach the remote.

The corollary is the system's most important rule: **load-bearing facts must
survive in git.** On a teammate's clone the archive is empty, so anything a
design depends on has to live in a committed brain file — the doc itself, or a
`4-reference/` topic it links to. The link is preferred: see
`3-decisions/003-evidence-by-reference.md` for why copying was the wrong way
to satisfy the same requirement.

## The commands

Shipped by the `brain` plugin, so they are namespaced `/brain:<name>` and are
identical in every repo you install them into.

### `/brain:capture <text>` — get it out of your head

Appends a verbatim note to `0-inbox/` as `YYYY-MM-DD-slug.md`. No summarizing,
no "improving", no filing decisions. Capture is judgment-free by design: the
moment capturing requires thinking about where something belongs, you stop
capturing. Five seconds, back to work.

Also valid: creating inbox files by hand, piping in exports, pasting meeting
transcripts. Anything in the folder is fair game.

### `/brain:triage` — empty the inbox without thinking hard

The volume command. Reads the inbox and routes it, **classifying per item
rather than per note** — a real capture is a dump containing two tasks, a
fact, and half a design, so classifying the note as a whole would misfile most
of it. Five destinations: FACT → `4-reference/`, TASK → a dated line on the
standing backlog, LOG → a `log/` stream, NOISE → archived, and DESIGN → left
exactly where it is.

That last one is the point. After triage the inbox holds only what needs a
decision, so `/brain:plan` becomes an occasional deep operation instead of the
toll gate every note has to pass. Without this split, "set up GA4 on the
landing page" can only leave the inbox by having an architecture doc invented
for it — which is how a repo fills with per-task artifacts.

It prints the full classification and waits for your confirmation before
moving anything; misrouting loses material. Run it weekly, or whenever the
inbox has piled up.

### `/brain:plan [topic]` — synthesize inbox → architecture

- **Without a topic**: surveys the inbox, reports the themes it sees, asks
  which to synthesize. Use this as your map when the inbox has piled up.
- **With a topic**: reads the relevant inbox notes *and* existing architecture
  docs, then writes (or **incrementally updates** — no duplicates) one doc in
  `1-architecture/`. Decisions, not option lists; under ~150 lines; wikilinks
  to related docs instead of repetition.
- **Then archives**: consumed notes get `status: processed`, a link to the
  doc that absorbed them, and are moved to `_archive/` automatically. The
  inbox file count is therefore always your real backlog.

Read every doc `/brain:plan` writes. Synthesis is the step where your judgment
matters most; a wrong conclusion here propagates into checklists and code.

### `/brain:analyze <doc or theme>` — stress-test a design (pipeline does not advance)

The command for staying in the high-level phase. Reads the design, its links,
relevant ADRs, and the code it touches, then reports underspecification,
reality mismatches, unexamined alternatives, cross-doc tension, and risk
concentration — ranked by how much downstream work each endangers. It never
edits architecture docs or writes checklists; when the session ends it
distills durable findings into one inbox note so `/brain:plan` can fold them in.
It closes by answering the gate question: does interrogation still produce
new blocking questions? Loop `/brain:analyze` → `/brain:plan` until the answer is no.

**Log mode.** When the domain has a stream in `log/`, `/brain:analyze` reads it from
the last `## Review YYYY-MM-DD` marker and adds four checks: adherence (what
the doc says vs. what the log shows), efficacy (did following it produce what
it promised), drift (practice that changed with no decision behind it), and
staleness. It then appends a new review marker — that marker, not a state
file, is how the next run knows its window.

This is what makes the system work for domains that never converge, where the
question is not "is this design right" but "is this policy still true". Such
domains have no natural forcing function — nothing piles up to nag you — so
put log mode on a schedule. A scheduled run that finds nothing writes only the
marker: no inbox note, no noise, because the inbox count is the backlog and a
recurring command must not pollute it.

### `/brain:breakdown <architecture-doc>` — design → checklist

Reads the design, its linked docs, **and the actual codebase areas it
touches**, then writes a checklist where every item is one commit-sized unit
with concrete file paths and a verifiable "done when" condition.

If the design has gaps, `/brain:breakdown` does not improvise — it halts and writes
the open questions under a `## Blocked on` section. That's the system working:
answer the questions, update the architecture doc, re-run.

### `/brain:execute <checklist> [items|n|--serial]` — checklist → code

Implements the selected items — by default *all* remaining ones on a derived
checklist, or the single next one with `--serial`. Runs each item's
verification, closes it, and stages the code change **and** the checklist
update together so plan and code can never drift in history. If the real
codebase contradicts an item, it stops and proposes an amendment upstream
instead of patching around it. Durable contradictions become draft ADRs.

The two checklist kinds diverge here, and it matters:

- **Derived** (`status: open`) — defaults to taking *all* remaining items and
  fanning the independent ones out to parallel subagents. Safe, because the
  set is bounded by one design that was reviewed as a whole. Completed items
  stay `[x]`; the file dies with the feature.
- **Standing** (`status: standing`) — that default is off. A backlog is a queue
  of unrelated arrivals with real external side effects (DNS, billing, live
  sites), so it requires explicit selection. Completed items are **deleted**,
  not checked: a file that lives forever cannot accumulate `[x]` lines without
  becoming the bloat this layer exists to prevent. Git keeps the history; if
  the record matters beyond that, one dated line goes to `log/`.

### `/brain:distill` — grow the skill layer

Skills (`.claude/skills/<slug>/SKILL.md`) are the layer that learns across
features: reusable, repo-specific *procedures* — how migrations are written
here, how report queries get tested — auto-discovered by claude-code and
loaded when relevant. `/brain:distill` mints them under the **rule of three** (a
procedure must recur three times before it's abstracted) and **extends an
existing skill before creating a new one**, so the layer stays few-and-rich
instead of many-and-shallow. Skills hold procedure; `4-reference/` holds
facts; architecture holds design. This — not sprint files — is how knowledge
transfers between features: each `/brain:execute` cycle runs a little smarter than
the last. Subagents (`.claude/agents/`) are the rung above, reserved for
genuine parallelism/isolation needs; the root `CLAUDE.md` stays the only
router.

## Mechanical enforcement

The contract is prompt-enforced, and prompt compliance decays — so
`tools/brain-lint.sh` enforces the invariants in code, as a pre-commit hook
(installed by `/brain:init`, refreshed by `/brain:sync`).

**Fails** the commit on: credential-looking strings in committed brain files;
index↔filesystem drift; any non-markdown or >100KB file under `brain/`.
**Warns** on: broken wikilinks, missing frontmatter, inbox notes older than 14
days, backlog lines older than 30 days, undated or unswept `[x]` backlog
lines, architecture docs past 150 lines, and log streams past 500.
`BRAIN_LINT_STRICT=1` upgrades warnings to failures.

Two deliberate choices in there. Oversized docs only *warn*: the hook runs on
every commit against the working tree, and failing would block an unrelated
code commit until someone performed a doc split — the worst possible moment
for that work. And staleness is computed from the **filename date**, never
`mtime`, because a fresh clone rewrites mtime and would silently erase real
staleness exactly when someone new picks the repo up.

`/brain:tidy` remains the judgment-level audit on top; lint is the
deterministic floor beneath it. The rule of thumb when adding anything to this
system: a rule that can only be stated in prose will eventually be violated by
an agent for whom creating a file is free. Prefer rules that are lintable, or
structurally impossible to break.

### Two gates, because git hooks don't travel

`core.hooksPath` is local config, so a fresh clone runs no git hooks until
someone sets it by hand — and the absence of enforcement looks exactly like
passing. So the plugin carries its own gate:

| | covers | travels? |
|---|---|---|
| git `pre-commit` hook | commits typed in a terminal | no — per clone, needs `git config core.hooksPath` |
| plugin `PreToolUse` hook | commits issued by an agent | **yes** — ships with the plugin, no setup |

The plugin hook runs `brain-lint` before any agent-issued `git commit` and
blocks it on failure, in every repo and every clone with zero configuration.
It honours `--no-verify`: a gate with no bypass gets disabled wholesale rather
than bypassed once.

A `SessionStart` hook reports the gaps the plugin cannot close — hooks present
but inert because `core.hooksPath` is unset, or a `pre-commit` file that exists
without the execute bit (git skips those silently, printing one `hint:` line).
It reports and never runs `git config` for you; a plugin quietly rewriting your
repo's configuration is the wrong trade.

Relatedly: architecture docs carry an `## Evidence` section holding
`[[reference-topic]]` links rather than copied facts. The requirement is that
load-bearing facts survive in **git**, and `4-reference/` is committed and
deduplicated — so evidence points at it instead of duplicating it, and gets
rewritten rather than appended to. Copying was the largest single source of
doc growth.

## Beyond software

Nothing above is software-specific except the examples. The same stages serve
investing, health, coursework, or a startup you do the technical work for —
but three things are worth knowing before you spread it around.

**Work has three shapes, and they are properties of an item, not of a repo.**
Some work *converges* (a design ships, and it's done). Some *recurs* with no
end state (a training program, an allocation policy — there is a policy, a
log, and a periodic review). Some simply *arrives* from outside (a client asks
for SEO, an integration breaks). No domain is purely one: a startup contains
projects, ops, and at least one practice. So don't classify the domain —
classify each item as it lands. That is exactly what `/brain:triage` does, and
why the shapes appear there rather than as a taxonomy you have to commit to.

**One repo per deliverable.** If a domain has its own codebase or output, it
gets its own repo with the brain inside it: each software project, the startup,
investing (it has pullers and data). If it doesn't — health, workout,
coursework — it becomes a domain subfolder inside one personal repo, so the
cross-domain links actually resolve in one Obsidian vault. Even there, keep
exactly one `0-inbox/`: capture has to be zero-decision, and triage is what
routes. Domains partition everything downstream, not the front door.

**Subject vs. instruments.** In a software repo the codebase is the brain's
subject. In investing, the scripts are instruments that *produce* material the
brain reasons about — a different relationship, and it sets the boundary:

> Machine-regenerable or externally authoritative → `data/` (gitignored).
> Judgment or irreplaceable → `brain/log/` (committed).

Pullers live in `tools/`, snapshots in `data/`, and a runbook in
`4-reference/` (see `_templates/external-source.md`) declares where the source
is and how to read it. `/brain:analyze` in log mode follows that runbook, and
says so when it can't reach the source rather than reasoning about data it
never saw. This is how an external stream — a Google Sheet you log workouts
into from your phone, a broker API — participates without its bulk ever
entering the graph.

## Workflows

### Bootstrapping into an existing project (or from Notion/another tool)

1. **Drain, don't migrate.** Export old notes to markdown and dump them into
   `0-inbox/` raw. Don't hand-sort them into `1-architecture/` — that imports
   the old tool's stale structure instead of synthesizing against reality.
2. `/brain:triage` to dispatch the shallow majority — facts, tasks, and log
   entries route themselves out, and what's left in the inbox is the material
   that genuinely needs a design. Doing this first is what stops a drained
   export from becoming forty architecture docs.
3. `/brain:plan` (no topic) to survey the residue.
4. Synthesize one domain at a time, smallest coherent unit first. The inbox
   drains over a few sessions; that's normal, not debt.
5. **Migrating from an agentic framework (GSD-style):** point `/brain:triage`
   or `/brain:plan` at the old planning folder — both stage files into the
   inbox themselves; triage first is usually right. Its
   docs are ingested as *claims to verify against the code* (they may be
   stale), resolved trade-offs become ADRs, encoded conventions are
   `/brain:distill` candidates, and state/progress/task files are deliberately
   skipped: checklists get re-derived fresh via `/brain:breakdown` once the
   architecture settles. Rescue genuinely in-flight work by hand with
   `/brain:capture`.
5. **Capture the terrain, not just your intentions**: have claude-code read
   the parts of the existing codebase your work touches and `/brain:capture` its
   findings, then `/brain:plan` them. The brain should know how things *are* before
   deciding how they *will be*.

### Ingesting new information

Meeting outcomes, requirements, a paper, a hunch: `/brain:capture` it the moment it
appears, individually, without batching or polishing. When several captures
accumulate on a theme, run one `/brain:plan <theme>` to fold them all in. Capture is
continuous; synthesis is batched.

### Diving deeper into a topic (the analysis loop)

`/brain:analyze` now closes the loop itself: stress-test → discussion → distilled
inbox note → a single gated question ("fold these findings into the doc
now?"). Confirm, and it performs the synthesis in the same session; decline,
and the note waits for a later `/brain:plan`. The gate exists on purpose — an
ungated loop would have the model interrogating its own design and grading
its own synthesis with you as a spectator. The discussion in the middle is
the product.

High-level planning is a loop, not a step — `/brain:plan` once is a first draft of
what you used to think, not a settled design. The loop:

1. Pick the thin or contested architecture doc (the Obsidian graph view makes
   thin/orphaned nodes visible).
2. `/brain:analyze <doc>` — structured stress-test against the codebase — or
   interrogate freely in a plain session for open-ended exploration.
3. Capture the output: `/brain:analyze` distills its findings into an inbox note
   itself; in free sessions, `/brain:capture` every insight and open question —
   **conversations are scratch space; files are memory.**
4. `/brain:plan <topic>` to fold findings back into the doc. Real trade-offs that
   get resolved become ADRs.
5. Repeat until interrogation stops producing new blocking questions. That —
   not having run `/brain:plan` once — is the gate to `/brain:breakdown`. Descending
   early is cheap to undo (checklists are disposable; delete and regenerate),
   but the habit to build is: breakdown only designs you'd bet a sprint on.

### When reality disagrees with the plan

Never patch the checklist. Amend the architecture doc, record an ADR if a
trade-off flipped, re-run `/brain:breakdown`. Checklists are disposable; the design
layer is the asset.

### Hygiene (10 minutes, weekly)

- `/brain:triage` first — it is the cheap pass. What it leaves in the inbox is
  the genuinely hard material, and that list should be short.
- `ls brain/0-inbox/` — anything still here after triage needs a decision.
  Older than two weeks → `/brain:plan` it or admit it never mattered. Lint warns.
- Skim the standing backlog for lines older than 30 days. Do it, shrink it, or
  delete it — a backlog that only grows is a landfill, and lint warns about
  this too because it is the main way triage fails over time.
- Obsidian graph: orphan nodes are unsynthesized knowledge; oversized nodes
  want splitting.
- Mark shipped derived checklists `status: done`. Delete nothing — that's what
  the archive and `status: superseded` are for. Standing backlogs are the one
  exception: their completed lines are deleted on the completing commit.

## How the wiki stays organized as it grows

The graph self-organizes only up to a point; past ~15 docs, three mechanisms
keep it from sprawling:

1. **The routing table.** `1-architecture/_index.md` holds one line per doc
   stating what it owns. `/brain:plan` consults it before creating anything (so
   topics route to their existing doc instead of spawning near-duplicates
   like `auth-flow.md` vs `authentication.md`) and updates it whenever a doc
   is created, renamed, split, or superseded. It contains pointers only —
   regenerable navigation, not state.
2. **The splitting convention.** A doc past ~150 lines, or a domain reaching
   3+ docs, becomes a subfolder: `<domain>/overview.md` for scope and how the
   children relate, plus one child per sub-domain with globally unique
   filenames (wikilinks resolve by filename). Checklists mirror the layout.
3. **`/brain:tidy`** — a monthly audit that detects index drift, duplicate and
   thin topics across both `1-architecture/` and `4-reference/`, broken
   wikilinks, oversized docs, orphans, designs contradicted by newer ADRs,
   stale derived checklists, stale and unswept backlog lines, Evidence
   sections that copy what reference already holds, and log streams due for a
   year split. It proposes fixes and executes only what you approve; obsolete
   docs are superseded-and-linked, never deleted.

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

The framework ships as a Claude Code plugin. Add the marketplace once per
machine, then install:

```shell
/plugin marketplace add ~/projects/project-brain
/plugin install brain@project-brain
/reload-plugins
```

Then, inside any repo you want a brain in:

```shell
/brain:init
```

`/brain:init` is idempotent and creates only the *content* tree — the stages
(including `log/` and a local `_archive/`), the templates, `.gitignore`
entries, `tools/brain-lint.sh` plus the pre-commit hook, and the operating
contract wrapped in `<!-- BRAIN:START v1 -->` markers in the target's
`CLAUDE.md`. The commands themselves stay in the plugin and are never copied
in — which is the entire point. A repo cannot drift from a framework it does
not contain.

When the framework improves, update the plugin once and run `/brain:sync` in
each repo. Sync replaces the contract block and `brain-lint.sh`, offers
template diffs one at a time, and never touches a single file under
`0-inbox`…`4-reference`, `log/`, `_archive/`, or `.claude/skills/`.

**Repos installed by the old `install.sh`** carry local copies of the commands
and an unmarked contract. Run `/brain:init` there: it detects both, offers to
delete the stale command copies (leaving your distilled skills alone), and
shows you a diff before deciding what to do with the existing contract text.
Do this before running `/brain:sync`, which refuses to guess across a
half-marked file.
