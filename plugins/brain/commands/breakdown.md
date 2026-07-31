---
description: Break an architecture doc into an actionable technical checklist
---

Architecture doc: $ARGUMENTS

You are performing **Stage 2 → low-level handoff** of the brain pipeline.

1. Read the named doc in `brain/1-architecture/` (resolve fuzzy names; if
   ambiguous, list candidates and stop). Also read any docs it `[[links]]` to,
   and skim the actual codebase areas it touches so the checklist matches
   reality, not assumptions.

   This command produces **derived** checklists only (`status: open`), one per
   design, disposable, dying with the feature. Work that merely *arrived* —
   shallow, no design behind it — never comes through here: `/brain:triage`
   puts it on the standing backlog directly. If the argument you were given is
   not an architecture doc, say so and point at `/brain:triage` instead of
   inventing a design to decompose.

2. Write the checklist at the same path under `brain/2-checklists/` that the
   design has under `brain/1-architecture/` — subfolders included, so
   `1-architecture/health/training-program.md` yields
   `2-checklists/health/training-program.md`. The contract requires checklists
   to mirror architecture; writing them flat loses that. Use
   `brain/_templates/checklist.md`. Requirements for items:
   - Each item is **one commit-sized unit of work**: concrete file paths,
     function/module names, and a verifiable "done when" condition.
   - Ordered by dependency. Group with `##` phase headers only when there are
     more than ~8 items.
   - Include test/verification items inline, not as an afterthought phase.
   - No item should require re-deriving a design decision. If you find a gap
     the architecture doc doesn't answer, STOP, list the open questions at the
     top of the checklist under `## Blocked on`, and tell me — do not invent
     answers.

3. Link the checklist back to its architecture doc in frontmatter, and add a
   `links:` entry in the architecture doc pointing to the checklist.

4. Finish by printing the checklist path, item count, and the suggested next
   command (`/brain:execute <checklist>`).

Do not write any implementation code in this command.
