---
status: open
created: 2026-06-11
links: ["[[example-health-endpoint]]"]
---

# Example: health endpoint — checklist

> Source design: [[example-health-endpoint]]

## Blocked on
<!-- empty = ready -->

## Items
- [ ] Add `GET /healthz` handler in `src/server/routes/health.py` returning `{"status":"ok"}` — done when: `curl :8000/healthz` returns 200
- [ ] Add `GET /readyz` with a 500ms-timeout `SELECT 1` against the pool in the same file — done when: route returns 503 with DB stopped, 200 with DB up
- [ ] Register both routes in `src/server/app.py` — done when: integration test `tests/test_health.py` passes
- [ ] Write `tests/test_health.py` covering 200 + 503 paths — done when: `pytest tests/test_health.py` green
