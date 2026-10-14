---
description: Run checks, update the ticket status and summarise the work
argument-hint: "[T0xx]"
---

Finish the current ticket. Ticket (if empty, infer it from the branch name `t0xx-…`): $ARGUMENTS

1. **Checks.** Look at `git diff --stat` against the default branch to see what was touched, then run
   every check from the CLAUDE.md "Commands" section that applies:
   - `backend/` changed: `ruff check`, `pytest`, `python manage.py makemigrations --check`,
     `python manage.py spectacular --validate --file /tmp/schema.yaml`
   - `mobile/` changed: `flutter analyze`, `flutter test`, Drift schema verify if tables changed
   - infra changed: `docker compose … config` and bring up only the affected service if needed
   If a command is still a TODO in CLAUDE.md, say which and what you ran instead. If any check fails,
   fix it or stop and report; do not continue with red checks.
2. **Acceptance criteria.** Read the issue (`gh issue view <n>`). For each criterion, state met / not
   met / deferred with evidence (test name, file:line, command output). Anything not met: stop and
   ask whether to continue working or defer it to a follow-up issue.
3. **Self-review.** Run the `/review` checklist on the diff, or delegate to the `code-reviewer` agent
   for larger diffs. Fix blocking findings.
4. **Commit** any remaining changes as `T0xx: <imperative summary>` with `Refs #<n>`.
5. **Docs.** If a design choice was made, append an entry to `docs/DECISIONS.md`. If a command,
   path or TODO in CLAUDE.md is now known, update CLAUDE.md. Write any `VERIFY` results where the
   ticket says.
6. **Status.** With the user's OK:
   - push the branch and open a PR with the template, body containing `Closes #<n>`
   - tick the satisfied checkboxes in the issue body and post one comment: what was built, what was
     deferred (with issue links), VERIFY results, and `Actual: x d` if the user tells you the time
   - remove the `in-progress` label: `gh issue edit <n> --remove-label in-progress`
   - regenerate `docs/TICKETS.md` (`python3 scripts/tickets_index.py`) and commit it on the branch
   The issue closes when the PR merges; do not close it by hand.
7. **Summary** for the user, under 15 lines: ticket and PR link, what changed, checks run and their
   result, deferred items, decisions logged, and which ticket `/next-ticket` would pick next.
