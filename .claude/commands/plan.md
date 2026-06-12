---
description: Synthesize raw inbox notes into a formal architecture doc
---

Topic: $ARGUMENTS

You are performing **Stage 1 → high-level planning** of the brain pipeline.

1. Read every file in `brain/0-inbox/` (the inbox contains only unprocessed
   notes — processed ones live in `brain/_archive/`). Identify the ones
   relevant to the topic above.
   If the topic is empty, list unprocessed notes grouped by apparent theme
   and ask me which to synthesize — then stop and wait.
   BATCHING GUARD: if more than ~15 notes are relevant, do NOT read all
   bodies at once. Survey filenames + first lines, propose themed batches,
   confirm with me, and process one batch per pass.

2. Consult `brain/1-architecture/_index.md` FIRST to determine whether an
   existing doc already owns this topic — update that doc rather than
   creating a near-duplicate. Then read any docs the topic touches,
   so the new doc links to them instead of repeating them.

3. Route non-design material first: notes that are durable FACTS rather
   than design input (API quirks, runbooks, environment setup, glossary,
   "X silently breaks when Y") go to `brain/4-reference/<topic>.md` —
   create or append, keep one file per topic. Then write (or update)
   `brain/1-architecture/<slug>.md` using
   `brain/_templates/architecture.md` as the skeleton. The doc must:
   - State the problem in 2–3 sentences before any solution.
   - Make concrete technology and structure decisions, not option lists.
     Where a real trade-off was resolved, record it as a one-line entry and
     flag that it deserves an ADR in `brain/3-decisions/`.
   - Reference source notes and related docs via `[[wikilinks]]`.
   - Stay under ~150 lines. If it wants to be longer, split by domain.
   - EVIDENCE PRESERVATION: copy each load-bearing fact from the source
     notes into the doc's `## Evidence` section as one line
     (`fact — origin, date`). Sources get archived out of git, so any fact
     a decision rests on must survive in the doc itself.

4. Archive the consumed notes: for each inbox note you synthesized, set
   `status: processed` in frontmatter, add a `links:` entry pointing to the
   new architecture doc, then MOVE the file from `brain/0-inbox/` to
   `brain/_archive/` (create the folder if missing; it is gitignored).
   Keep filenames unchanged. Do not delete or rewrite note bodies.
   Because the archive never reaches git, the architecture doc must contain
   everything the design needs — never rely on an archived note as a source
   of truth.

5. Update `brain/1-architecture/_index.md`: add/adjust the one-line entry
   for the doc you wrote. If the doc crossed ~150 lines or its domain now has
   3+ docs, perform the splitting convention from CLAUDE.md (subfolder with
   overview.md) and reflect it in the index.

6. Finish by printing: the path of the doc you wrote, the notes you archived
   (now in `brain/_archive/`), and the suggested next command
   (`/breakdown <doc>`).

Do not write any code or checklists in this command.
