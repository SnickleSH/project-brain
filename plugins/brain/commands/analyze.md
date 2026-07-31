---
description: Stress-test a design against reasoning, the code, and (in log mode) what the log says actually happened
---

Target (architecture doc, or a theme spanning several): $ARGUMENTS

You are working WITHIN the high-level planning stage. This command never
produces checklists or code, and never edits architecture docs directly —
its only output is analysis in conversation plus notes in the inbox.

1. Read the target doc(s) in `brain/1-architecture/`, everything they
   `[[link]]` to, relevant ADRs in `brain/3-decisions/`, and the actual
   codebase areas the design touches. If the target is ambiguous, list
   candidates and stop.

   **Then check for a log stream.** If `brain/log/` holds a stream belonging
   to this domain, read it from the last `## Review YYYY-MM-DD` marker to the
   end (all of it if there is no marker) and switch on **log mode** for this
   run. Log mode is not a different command — it is the same interrogation
   with a second evidence source. Without a stream you are testing the design
   against reasoning and the code; with one you are also testing it against
   what actually happened. Say which mode you are in before you report.

   If the stream is declared external (a `brain/4-reference/` runbook naming a
   Google Sheet, a database, a puller script), follow the runbook to read it,
   and say so. If you cannot reach it, report that and continue in plain mode
   rather than reasoning about data you did not see.

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

   In **log mode**, add these four — they are the whole reason a policy that
   never converges needs interrogating at all:
   - **Adherence**: what the doc says to do vs. what the log shows was done.
     Report the gap plainly, with dates. Do not soften it, and do not treat a
     gap as automatically a failure of discipline — a policy nobody follows is
     often a policy that was wrong.
   - **Efficacy**: where the log carries outcomes, did following the policy
     produce what it promised? Name the metric and the window. If the window
     is too short to conclude anything, say that instead of concluding.
   - **Drift**: practice that has quietly changed without a decision behind
     it. This is the most valuable finding here — it is how a policy becomes
     fiction. Propose either an ADR ratifying the new practice or a correction
     back to the old one.
   - **Staleness**: assumptions in the doc that the log contradicts, or that
     time has simply overtaken.

3. NOTHING-NEW SHORT-CIRCUIT (log mode only). If the window since the last
   review contains nothing that changes the picture — the policy was followed,
   outcomes are within expectation, no drift, no new blocking question — then
   say exactly that in one or two lines, append only the marker to the stream,
   write NO inbox note, and stop.

   The marker must carry its own evidence, so a cheap pass is visible as one:
   `## Review YYYY-MM-DD — nothing new; N entries, YYYY-MM-DD..YYYY-MM-DD`.

   **Never write the marker if you could not actually read the window.** If the
   stream is empty, or an external source declared in its runbook was
   unreachable, say so and stop without a marker. Writing one would advance the
   review window past material nobody ever looked at, and the loss is silent
   and permanent.
   This exists because log mode is meant to be run on a schedule, and a
   scheduled command that files a note every time would quietly destroy the
   one metric the system has: the inbox file count IS the backlog. A review
   that finds nothing must leave no trace but the marker.

4. Present the findings in conversation, ranked by how much downstream work
   each one endangers. Be specific and cite files/lines. Then discuss with
   me — answer my follow-ups, explore alternatives I raise.

5. When I say the session is done (or I say "capture this"), distill the
   durable findings — resolved answers, open questions, flagged risks —
   into ONE inbox note (`brain/0-inbox/YYYY-MM-DD-analysis-<slug>.md`),
   written for future synthesis, not as a transcript. Then suggest
   `/brain:plan <topic>` to fold it into the doc.

   In log mode, also append a `## Review YYYY-MM-DD` marker to the end of the
   stream file, with one line naming what the review concluded. That marker —
   not a state file — is how the next run knows its window. It is the only
   thing this command ever writes to a log stream: never edit, reformat, or
   summarize existing entries, and never write observations of your own into
   a stream.

6. If during analysis we firmly resolve a real trade-off, offer to draft an
   ADR in `brain/3-decisions/` — but only with my confirmation.

7. GATED FOLD: after the inbox note is written, ask exactly once:
   "Fold these findings into the doc now?" If I confirm, perform the full
   /brain:plan procedure for this topic in this same session (incremental doc
   update, evidence preservation, archiving the analysis note, index
   update). If I decline or don't answer, stop — the note waits in the
   inbox for a later /brain:plan. Never fold without the explicit confirmation.

Exit criterion to report at the end (after any fold): does interrogating this design still
produce new blocking questions? If yes, recommend another /brain:analyze or /brain:plan
cycle. If no, the doc is ready for /brain:breakdown.
