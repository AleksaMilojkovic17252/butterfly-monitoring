---
description: Run checks, update the ticket status and summarise the work
argument-hint: "[T0xx]"
---

Finish the current ticket. Ticket (if empty, infer it from the branch name `t0xx-…`): $ARGUMENTS

1. **Checks.** Look at `git diff --stat main...HEAD` plus uncommitted changes, then run what applies
   from the CLAUDE.md "Commands" section:
   - `backend/` changed: `ruff format`, `ruff check`, `makemigrations --check`, `manage.py check`
   - `mobile/` changed: `dart format`, `flutter analyze`, Drift `make-migrations` if tables changed
   - infra changed: `docker compose … config`, then bring up the affected services
   No automated tests (D-021). Fix anything that fails; do not continue with errors.
2. **Manual run.** Start what the ticket touched and confirm it works (stack up and call the
   endpoint, open the admin page, run the app). If you cannot run something here, say so and
   give the user exact steps to check it on their laptop or phone.
3. **Acceptance criteria.** From the ticket's section in `docs/TICKET_DETAILS.md`, state for each
   criterion: met / skipped (test or CI only) / not met, with evidence (file:line, command output,
   manual step). Anything not met: stop and ask whether to keep working or defer it.
4. **Self-review.** Apply the `/review` checklist to the diff, or delegate to the `code-reviewer`
   agent for larger diffs. Fix blocking findings.
5. **Docs.** Append to `docs/DECISIONS.md` for any design choice a later session needs. Update
   CLAUDE.md if a command, path or TODO is now known. Write `VERIFY` results where the ticket says.
6. **Status.** In `docs/TICKETS.md` set the ticket to `done` (index row and heading line). If
   something was deferred, add a `Deferred:` line under the ticket's heading.
7. **Commit** as `T0xx: <imperative summary>` with `Closes #<issue>` (issue = nnn + 17) in the
   message body, so GitHub closes the issue when the commit reaches `main` there.
8. **Merge.** Ask the user before merging the branch into `main`. Never push; the user pushes.
9. **Summary** for the user, under 15 lines: what changed, how to demo it, checks run, skipped or
   deferred criteria, decisions logged, and which ticket `/next-ticket` would pick next.
