---
status: active
created: {{date}}
links: []
---

# {{source}} — external source runbook

<!-- Put this in brain/4-reference/. It declares a stream of material that
     lives OUTSIDE the repo — a Google Sheet, a broker API, a scraper's
     output — so commands know it exists and how to reach it.

     Why this file rather than mirroring the data into brain/: the brain
     holds intent, procedure and judgment. Anything re-pullable or
     externally authoritative is bulk, and bulk in brain/ is a lint failure.
     Pulled snapshots land in data/ (gitignored). What you CONCLUDE from
     them lands in brain/log/. -->

## What it is

<!-- One or two sentences. What this source is authoritative for. -->

## Where it lives

<!-- The identifier: sheet URL/ID, doc ID, API endpoint, table name.
     Never a credential — redact anything key-shaped to <redacted:kind>. -->

## How to pull it

<!-- The exact operation: the MCP tool and arguments, or the script in
     tools/, and where the snapshot lands under data/. Written so that
     someone (or /brain:analyze in log mode) can follow it cold. -->

## What it feeds

<!-- Which log stream, policy doc, or analysis depends on this.
     Use [[wikilinks]]. -->

## Failure modes

<!-- How it goes wrong: rate limits, schema changes, silent truncation,
     stale caches, auth expiry. What a bad pull looks like so nobody
     reasons confidently about data they did not actually get. -->
