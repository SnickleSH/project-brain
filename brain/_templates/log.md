# {{stream}} log

<!-- Append-only observation stream. One file per stream, never per session.
     Split by year past ~500 lines (workout-2026.md, workout-2027.md).

     THE APPEND CONTRACT — every command that writes here obeys it:
     1. Appends ALWAYS go to the END of the file. Newest at the bottom.
     2. If the last `## YYYY-MM-DD` heading is not today's — including when a
        `## Review` marker sits between it and the end — open a NEW date
        heading rather than reusing an earlier one. Writing under an older
        heading buries the entry above the last review marker, where the next
        review will never see it.
     3. Entries are bullets under a date heading. Never reformat, aggregate,
        or summarize what is already here.

     This file holds JUDGMENT and OBSERVATION, not bulk data. If a number can
     be re-pulled from a script or an external source, it belongs in data/
     (gitignored), not here. What belongs here is what you concluded.

     No frontmatter: log streams are exempt (brain-lint knows).

     /brain:analyze writes `## Review YYYY-MM-DD` markers into this file. Those
     markers are how the next review knows which window to read. Do not
     delete them. -->

## {{date}}
-
