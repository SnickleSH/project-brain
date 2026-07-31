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
     (judge by content, not just names); propose which absorbs which. Cover
     `brain/4-reference/` the same way: triage appends there on every run, so
     it now has the highest write volume in the graph and is where near-
     duplicate topics (`stripe-api.md` vs `stripe-webhooks.md`) actually
     accumulate. Flag thin topics too — a reference file under ~8 lines is
     usually a fragment that belongs inside a broader one.
   - **Broken links** — wikilinks resolving to nothing (links into
     `_archive/` are exempt: local breadcrumbs by design).
   - **Oversized docs** — past ~150 lines; propose the split per the
     CLAUDE.md splitting convention.
   - **Orphans** — docs nothing links to and that link to nothing.
   - **Contradicted designs** — `status: active` docs that a newer ADR or a
     sibling doc contradicts; propose amendment or `status: superseded`.
   - **Stale checklists** — `status: open` (derived) checklists whose source
     doc has materially changed since; propose abandon + re-`/brain:breakdown`.
   - **Stale backlog lines** — in `status: standing` backlogs, items dated
     more than ~30 days ago. These have no source doc and that is correct —
     do not report them as orphans. Propose one of: do it now, rewrite it
     smaller, or delete it. A backlog that only grows is a landfill.
   - **Leftover `[x]` in standing backlogs** — completed items must be swept
     on the completing commit, not left checked. Propose deleting each, and
     appending a dated line to `brain/log/` where the record matters.
   - **Evidence drift** — architecture docs whose `## Evidence` section copies
     facts that already live in `brain/4-reference/`, or cites material the
     current design no longer rests on. Propose replacing copies with
     `[[reference-topic]]` links and dropping uncited lines. This is the
     single biggest source of doc growth, so check it on every run.
   - **Log hygiene** — streams past ~500 lines, and any stream containing bulk
     that should be in `data/` instead of judgment that belongs here.
     A year split means: create `workout-2027.md` and stop appending to
     `workout-2026.md`. **Never edit or rewrite the old file** — a log is the
     one irreplaceable artifact in the graph, and nothing else can reconstruct
     it. Carry the last `## Review` marker forward into the new file so the
     next review window starts where the old one ended.

3. Wait for my decisions, then execute only the approved fixes. Rules:
   merges and splits go through doc edits + index updates; obsolete docs get
   `status: superseded` and a link to their replacement — never deleted;
   every change keeps `_index.md` consistent in the same operation.

4. Finish with a one-line health summary: doc count, link count, issues
   found vs fixed.
