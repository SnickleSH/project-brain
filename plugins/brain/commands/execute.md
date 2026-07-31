---
description: Implement the next unchecked items from a checklist
---

Checklist (optionally followed by item numbers, a count, or `--serial`): $ARGUMENTS

You are performing **Stage 3 → code execution** of the brain pipeline.

0. Check `.claude/skills/` for skills whose description matches this work
   and follow them. If during implementation you explain or invent the same
   repo-specific procedure for what is clearly the third time, say so and
   suggest `/brain:distill` after the item completes.

1. Read the checklist in `brain/2-checklists/`. Check its `status:` — the two
   kinds of checklist behave differently and confusing them is dangerous:

   - **Derived** (`status: open`, produced by `/brain:breakdown`) — read its
     linked architecture doc too. If it has a `## Blocked on` section with
     open items, surface them and stop.
   - **Standing** (`status: standing`, a backlog fed by `/brain:triage`) —
     there is no source design and that is correct; do not go looking for one
     and do not invent one. Items here are independent arrivals, not a
     decomposed plan.

   FAIL CLOSED: a file named `*-backlog.md` that is missing `status: standing`
   is a malformed backlog, not a derived checklist. Report it and stop — do
   NOT fall through to the take-all default below, which is exactly the
   dangerous reading. (Lint fails on this too, but the hook only runs at
   commit time, which is after the damage.)

2. Select work:
   - **If the checklist is `status: standing`, the take-everything default is
     OFF.** Require explicit selection: item numbers, a count, or a filter I
     give you. If I named none, list the open items with their dates, ask
     which to take, and stop. A standing backlog accumulates unrelated
     arrivals with real external side effects — DNS, billing, third-party
     integrations, live sites. "All remaining items, in parallel" is the
     right default for one decomposed design and the wrong one for a queue.
     Nothing else in this step changes: once I have selected, the fan-out and
     verification rules below apply normally.
   - If I passed `--serial`, take the next **one** unchecked item only and
     work it on the main thread — no delegation. Use this when items share
     files, have ordering dependencies, or I want to review each in turn.
   - If I specified item numbers or a count, take those.
   - Otherwise, for a **derived** checklist only, take **all** remaining
     unchecked items.
   - Within the selected set, fan out the genuinely independent items
     (touch different files, no shared "done when", no ordering
     dependency) to parallel subagents — one Agent per independent item.
     Keep dependent or same-file items on the main thread, sequenced, to
     avoid conflicting edits. Per CLAUDE.md, subagents are a last resort
     for real isolation/parallelism, so only fan out where the parallelism
     is real. If nothing is safely parallelizable, just work the set
     serially on the main thread.

3. For each selected item (or for each subagent, if delegating):
   - Implement it exactly as scoped. If the item turns out to be wrong or
     underspecified against the real codebase, stop and tell me what you
     found — propose a checklist or architecture amendment instead of
     improvising.
   - Run the item's "done when" verification (tests, build, manual command).
   - Close the item, which differs by checklist kind:
     - **Derived** → mark it `[x]` in place. The checklist is disposable and
       dies with the feature, so completed items are harmless.
     - **Standing** → **delete the line.** Sweep on complete; never leave
       `[x]` in a standing backlog. It lives forever, so checked items are
       pure monotonic growth — the bloat this whole layer exists to avoid.
       Git holds the history. If the fact that it happened matters later
       (shipped work, a client-visible change), append one dated line to
       `brain/log/<stream>.md` in the same commit.

   When delegating, give each subagent the single item's full scope and
   its "done when" check, and have it report back the diff plus whether
   verification passed. Close each item on the main thread once its
   subagent reports green — don't let parallel agents race on the
   checklist file.

4. Stage the code changes AND the checklist update together, and propose a
   commit message of the form
   `<scope>: <item summary> (brain: <checklist-filename>: "<first words of item>")`.
   Never reference items by number — checklists get edited and regenerated,
   numbers dangle; quoted text is greppable forever. For a **standing** item,
   quote the work text and not the leading arrival date, and say the line was
   swept — e.g. `seo: add GA4 to landing page (brain: startup-backlog.md:
   swept "Set up GA4 on the landing page")`. The line no longer exists in
   HEAD, so `git log -S'<quoted text>'` is the only way to find it later. When several items were
   done in one run, propose one commit per item (or per coherent group) so
   each stays revertable. Do not commit unless I confirm.

5. If implementation contradicted the architecture doc in any durable way,
   draft an ADR in `brain/3-decisions/` using the template and tell me.

Finish by printing remaining open count and the next item's title. For a
standing backlog, also flag any line dated more than ~30 days ago: stale
arrivals are how a backlog turns into a landfill, and they want a decision
(do it, or delete it) rather than another pass.
