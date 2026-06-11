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

2. Read any existing docs in `brain/1-architecture/` that the topic touches,
   so the new doc links to them instead of repeating them.

3. Write (or update) `brain/1-architecture/<slug>.md` using
   `brain/_templates/architecture.md` as the skeleton. The doc must:
   - State the problem in 2–3 sentences before any solution.
   - Make concrete technology and structure decisions, not option lists.
     Where a real trade-off was resolved, record it as a one-line entry and
     flag that it deserves an ADR in `brain/3-decisions/`.
   - Reference source notes and related docs via `[[wikilinks]]`.
   - Stay under ~150 lines. If it wants to be longer, split by domain.

4. Archive the consumed notes: for each inbox note you synthesized, set
   `status: processed` in frontmatter, add a `links:` entry pointing to the
   new architecture doc, then MOVE the file from `brain/0-inbox/` to
   `brain/_archive/` (create the folder if missing; it is gitignored).
   Keep filenames unchanged. Do not delete or rewrite note bodies.
   Because the archive never reaches git, the architecture doc must contain
   everything the design needs — never rely on an archived note as a source
   of truth.

5. Finish by printing: the path of the doc you wrote, the notes you archived
   (now in `brain/_archive/`), and the suggested next command
   (`/breakdown <doc>`).

Do not write any code or checklists in this command.
