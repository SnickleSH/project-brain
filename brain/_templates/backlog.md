---
status: standing     # standing — fed by /brain:triage, never derived from a design
created: {{date}}
links: []
---

# {{title}} — standing backlog

> Demand-driven work that arrives from outside. One standing backlog per repo
> (per domain subfolder in a multi-domain repo). Not derived from an
> architecture doc — `/brain:triage` feeds it directly.

<!-- LIFECYCLE — differs from a derived checklist on purpose:
     - Every line is DATED at the moment /brain:triage adds it. The date is the
       staleness signal that the inbox used to provide.
     - SWEEP ON COMPLETE. The commit that finishes an item DELETES its line
       (and appends a line to brain/log/<stream>.md if the record matters).
       Never leave `[x]` here — a standing backlog lives forever, so checked
       items are pure monotonic growth.
     - /brain:execute will NOT take all items from this file. Standing status
       forces explicit selection.
     Anything needing a real design does not belong here — it stays in the
     inbox for /brain:plan. -->

## Items

- [ ] {{date}}: <one line of work — concrete, with a "done when" if non-obvious>
