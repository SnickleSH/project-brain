---
status: accepted
created: 2026-06-11
links: []
---

# 001. In-repo markdown brain over Notion + MCP

**Context** — Planning lived in Notion, accessed via MCP. Every read cost a
remote tool round-trip; plans and code drifted because they versioned separately.

**Decision** — We will keep all planning artifacts as markdown inside the repo,
operated on directly by claude-code.

**Consequences** — Plans are diff-able and PR-reviewable; zero MCP token
overhead; offline-capable. We give up Notion's databases, sharing UI, and
non-technical collaborator access.
