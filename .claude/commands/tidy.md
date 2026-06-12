---
description: Audit the brain graph for rot — duplicates, broken links, drift — and propose fixes
---

You are auditing graph health. Read-only first; nothing changes without my
confirmation. Run this monthly or when the graph feels disorganized.

1. Build the picture: read `brain/1-architecture/_index.md`, list all files
   under `brain/` (except `_archive/`), and extract every `[[wikilink]]`.

2. Report findings under exactly these headings, each with concrete file
   paths and a proposed fix. Skip headings with no findings.
   - **Index drift** — docs missing from the index; index entries whose doc
     is gone or renamed.
   - **Suspected duplicates** — architecture docs with overlapping ownership
     (judge by content, not just names); propose which absorbs which.
   - **Broken links** — wikilinks resolving to nothing (links into
     `_archive/` are exempt: local breadcrumbs by design).
   - **Oversized docs** — past ~150 lines; propose the split per the
     CLAUDE.md splitting convention.
   - **Orphans** — docs nothing links to and that link to nothing.
   - **Contradicted designs** — `status: active` docs that a newer ADR or a
     sibling doc contradicts; propose amendment or `status: superseded`.
   - **Stale checklists** — `status: open` checklists whose source doc has
     materially changed since; propose abandon + re-`/breakdown`.

3. Wait for my decisions, then execute only the approved fixes. Rules:
   merges and splits go through doc edits + index updates; obsolete docs get
   `status: superseded` and a link to their replacement — never deleted;
   every change keeps `_index.md` consistent in the same operation.

4. Finish with a one-line health summary: doc count, link count, issues
   found vs fixed.
