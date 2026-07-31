---
status: accepted
created: 2026-07-31
links: []
---

# 003. Evidence by reference, not by copy

**Context** — Because `brain/_archive/` is gitignored, `/brain:plan` required
every load-bearing fact to be copied out of source notes into the architecture
doc's `## Evidence` section. Nothing ever pruned that section, so it grew
monotonically with each `/brain:plan` pass over the same doc — the single
largest cause of doc bloat, and the mechanism that pushed docs past the
150-line splitting threshold for reasons unrelated to design complexity.
Committing the archive would have removed the requirement, but that was
declined: raw notes stay local.

**Decision** — We will keep the requirement that load-bearing facts survive in
git, and satisfy it through `brain/4-reference/` — which is committed,
deduplicated, and already the documented home for durable facts — rather than
through per-doc copies. `## Evidence` holds one wikilink per supporting
reference topic plus only observations specific to that design, and is
rewritten rather than appended to on each pass. Rule 6 changes from "must be
IN the architecture doc" to "must be in a committed brain file: the doc, or a
reference topic it links to."

**Consequences** — Doc growth becomes bounded: reference dedupes on append, so
docs grow by links instead of copies, and rule 1 (links over duplication)
finally applies to evidence as it does everywhere else. Facts become reusable
across designs instead of duplicated per design. The archive stays gitignored
and rule 6's intent is fully preserved — nothing load-bearing is reachable
only through `_archive/`. The cost is one more indirection when reading a doc
cold, and `/brain:tidy` gains a standing check for Evidence sections that
still copy what reference already holds.
