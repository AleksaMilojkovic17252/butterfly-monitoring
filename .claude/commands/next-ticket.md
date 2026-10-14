---
description: Pick the next unblocked ticket (or the one given) and start it
argument-hint: "[T0xx]"
allowed-tools: Bash(git status:*), Bash(git switch:*), Bash(git checkout -b:*), Bash(git log:*), Read, Grep, Glob, Edit
---

Start work on a ticket. Requested ticket (may be empty): $ARGUMENTS

1. Open `docs/TICKETS.md`. A ticket is **ready** when its status is `todo` and every ticket in its
   "Depends on" column is `done` or `dropped`.
2. Choose the ticket:
   - If a ticket ID was given, use it. If it is not ready, list the dependencies that are not done
     and stop.
   - If a ticket is already `in progress`, offer to resume it instead of starting a new one.
   - Otherwise take the **first ready ticket in the "Build order" list**, reading the stages top to
     bottom. Skip the "Should/Could fill" stage and the Phase 2 stages until every Phase 1 Must
     ticket is done (study tickets T076/T082/T086 only if the user asks).
3. Read the ticket in full: its section in `docs/TICKET_DETAILS.md` (search `### T0xx ·`). Read the
   dependencies' sections only as far as needed to know what they built. Read the parts of
   `docs/CONVENTIONS.md` and `docs/DECISIONS.md` the ticket touches, and any outline section it cites
   in `docs/reference/development-plan.md`.
4. Check the working tree is clean (`git status`). If not, stop and ask.
5. Create branch `t0xx-<short-slug>` from `main`.
6. Write a short plan and **stop for the user's go-ahead** before writing code:
   - one line on what the ticket delivers
   - files and migrations to add or change
   - how each acceptance criterion will be shown working by hand
   - acceptance criteria you will skip because they only ask for automated tests or CI (D-021)
   - any `VERIFY` items, TODOs in CLAUDE.md, or open questions this ticket must settle
   - anything that looks like it needs a new dependency (needs the user's approval)
7. After the go-ahead, set the ticket's status to `in progress` in `docs/TICKETS.md` (index row and
   the ticket's heading line), then implement following CLAUDE.md "How to work a ticket" and finish
   with `/finish-ticket`.
