---
description: Extract recurring execution knowledge into a reusable skill (rule of three)
---

Optional focus (a checklist, area, or procedure): $ARGUMENTS

You are growing the system's skill layer in `.claude/skills/`. Skills are
PROCEDURAL knowledge — how we do a recurring activity in this repo. They are
not documentation (that's `brain/4-reference/`) and not design (that's
`brain/1-architecture/`).

1. Gather evidence of recurrence: recent git log, completed checklists in
   `brain/2-checklists/`, and this conversation. List candidate procedures
   that have now been performed or explained at least THREE times
   (rule of three — below that, do not abstract; say so and stop).

2. For each qualifying candidate, check `.claude/skills/` first:
   **extend an existing skill before creating a new one.** Prefer few, rich
   skills over many shallow ones. A new skill needs a genuinely distinct
   recurring activity, not a variant.

3. Show me the proposed skill content (or diff to an existing skill) and
   wait for approval. A skill file is
   `.claude/skills/<slug>/SKILL.md` with frontmatter `name` and
   `description` (the description states WHEN to use it — claude-code uses
   it for discovery), then the procedure: steps, repo-specific commands,
   file conventions, pitfalls. Under ~100 lines; link brain docs rather
   than duplicating them.

4. After writing, note in the skill a one-line changelog entry
   (`<!-- YYYY-MM-DD: extended with X -->`). Skills are committed and
   code-reviewed like code.

Never create a skill for a one-off, a per-feature task, or anything an
architecture doc already answers. Granularity is the enemy: one skill per
recurring activity.
