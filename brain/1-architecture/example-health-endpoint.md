---
status: active
created: 2026-06-11
links: ["[[2026-06-11-example-health-endpoint]]", "[[example-health-endpoint-checklist]]"]
---

# Example: health endpoint

> Delete this file (and its inbox/checklist siblings) once you've seen the format.

## Problem
The load balancer and k8s probes need to distinguish "process is up" from
"process can serve traffic". We currently expose neither.

## Design
Two routes in the existing HTTP server: `GET /healthz` (liveness — returns 200
if the process responds) and `GET /readyz` (readiness — 200 only if the DB
pool answers `SELECT 1` within 500ms). No auth, no body beyond `{"status": "..."}`.

## Interfaces & contracts
- `GET /healthz` → `200 {"status":"ok"}` always while running
- `GET /readyz`  → `200` ready / `503 {"status":"degraded","check":"db"}`

## Trade-offs resolved
- Chose two routes over one with query params because probe configs stay dumb.

## Out of scope
Version reporting, dependency dashboards, metrics.
