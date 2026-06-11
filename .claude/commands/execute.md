---
description: Implement the next unchecked items from a checklist
---

Checklist (optionally followed by item numbers or a count): $ARGUMENTS

You are performing **Stage 3 → code execution** of the brain pipeline.

1. Read the checklist in `brain/2-checklists/` and its linked architecture
   doc. If the checklist has a `## Blocked on` section with open items,
   surface them and stop.

2. Select work:
   - If I specified item numbers or a count, take those.
   - Otherwise take the next **one** unchecked item.

3. For each selected item:
   - Implement it exactly as scoped. If the item turns out to be wrong or
     underspecified against the real codebase, stop and tell me what you
     found — propose a checklist or architecture amendment instead of
     improvising.
   - Run the item's "done when" verification (tests, build, manual command).
   - Mark it `[x]` in the checklist file.

4. Stage the code changes AND the checklist update together, and propose a
   commit message of the form `<scope>: <item summary> (brain: <checklist>#<n>)`.
   Do not commit unless I confirm.

5. If implementation contradicted the architecture doc in any durable way,
   draft an ADR in `brain/3-decisions/` using the template and tell me.

Finish by printing remaining unchecked count and the next item's title.
