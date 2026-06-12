---
description: The planning loop — stress-test a design, discuss, capture, and optionally fold findings back
---

Target (architecture doc, or a theme spanning several): $ARGUMENTS

You are working WITHIN the high-level planning stage. This command never
produces checklists or code, and never edits architecture docs directly —
its only output is analysis in conversation plus notes in the inbox.

1. Read the target doc(s) in `brain/1-architecture/`, everything they
   `[[link]]` to, relevant ADRs in `brain/3-decisions/`, and the actual
   codebase areas the design touches. If the target is ambiguous, list
   candidates and stop.

2. Stress-test the design. Work through, with evidence from the files you
   read — not generic checklisting:
   - **Underspecification**: what would block an implementer? What does the
     doc leave to be invented on the spot?
   - **Reality mismatches**: assumptions the codebase, data, or existing
     conventions contradict.
   - **Unexamined alternatives**: decisions stated without a trade-off; for
     each, name the strongest alternative and what would make it win.
   - **Cross-doc tension**: places where this design and a sibling doc or
     ADR pull in different directions.
   - **Risk concentration**: the one or two bets that, if wrong, invalidate
     the most downstream work.

3. Present the findings in conversation, ranked by how much downstream work
   each one endangers. Be specific and cite files/lines. Then discuss with
   me — answer my follow-ups, explore alternatives I raise.

4. When I say the session is done (or I say "capture this"), distill the
   durable findings — resolved answers, open questions, flagged risks —
   into ONE inbox note (`brain/0-inbox/YYYY-MM-DD-analysis-<slug>.md`),
   written for future synthesis, not as a transcript. Then suggest
   `/plan <topic>` to fold it into the doc.

5. If during analysis we firmly resolve a real trade-off, offer to draft an
   ADR in `brain/3-decisions/` — but only with my confirmation.

6. GATED FOLD: after the inbox note is written, ask exactly once:
   "Fold these findings into the doc now?" If I confirm, perform the full
   /plan procedure for this topic in this same session (incremental doc
   update, evidence preservation, archiving the analysis note, index
   update). If I decline or don't answer, stop — the note waits in the
   inbox for a later /plan. Never fold without the explicit confirmation.

Exit criterion to report at the end (after any fold): does interrogating this design still
produce new blocking questions? If yes, recommend another /analyze or /plan
cycle. If no, the doc is ready for /breakdown.
