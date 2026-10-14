---
description: Pick the next unblocked ticket (or the one given) and start it
argument-hint: "[T0xx]"
allowed-tools: Bash(gh issue view:*), Bash(gh issue list:*), Bash(git status:*), Bash(git switch:*), Bash(git checkout -b:*), Bash(python3 scripts/tickets_index.py:*), Read, Grep, Glob
---

Start work on a ticket. Requested ticket (may be empty): $ARGUMENTS

1. Refresh the index: `python3 scripts/tickets_index.py`. If `gh` fails (not installed or not
   authenticated), say so and fall back to the existing `docs/TICKETS.md`, noting it may be stale.
2. Choose the ticket:
   - If a ticket ID was given, use it. If its status is `blocked`, list the open hard dependencies
     and stop.
   - Otherwise take the **first `ready` ticket in the "Build order" list** of `docs/TICKETS.md`,
     reading the stages top to bottom. Skip the "Should/Could fill" stage and Phase 2 stages unless
     every Phase 1 Must ticket before them is done (study tickets T076/T082/T086 are the exception,
     and only if the user asks for them). If a ticket is already `in progress`, offer to resume it
     instead of starting a new one.
3. Read the ticket in full: `gh issue view <issue-number>` (ticket `Tnnn` is issue #(nnn + 17)).
   Read the hard dependencies' issues only as far as needed to know what they built. Read the parts
   of `docs/CONVENTIONS.md` and `docs/DECISIONS.md` the ticket touches, and any outline section it
   cites in `docs/reference/development-plan.md`.
4. Check the working tree is clean (`git status`). If not, stop and ask.
5. Create branch `t0xx-<short-slug>` from the default branch.
6. Write a short plan and **stop for the user's go-ahead** before writing code:
   - one line on what the ticket delivers
   - files and migrations to add or change
   - tests to write, mapped to each acceptance criterion
   - any `VERIFY` items, TODOs in CLAUDE.md, or open questions this ticket must settle
   - anything that looks like it needs a new dependency (needs the user's approval)
7. After the go-ahead, add the `in-progress` label:
   `gh issue edit <n> --add-label in-progress` (if the label is missing, ask before creating it with
   `gh label create in-progress --color FBCA04`). Then implement following CLAUDE.md "How to work a
   ticket", and finish with `/finish-ticket`.
