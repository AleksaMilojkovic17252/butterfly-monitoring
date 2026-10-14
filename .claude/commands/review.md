---
description: Review the current diff against the ticket's acceptance criteria and project conventions
argument-hint: "[T0xx]"
allowed-tools: Bash(git diff:*), Bash(git log:*), Bash(git status:*), Read, Grep, Glob
---

Review my changes. Ticket (if empty, infer from the branch name `t0xx-…`): $ARGUMENTS

Do not edit files during the review; report only.

1. Get the diff: `git diff main...HEAD` plus uncommitted changes (`git diff`, `git status`).
2. Get the acceptance criteria from the ticket's section in `docs/TICKET_DETAILS.md`
   (search `### T0xx ·`).
3. Produce, in this order:

   **Acceptance criteria**: a table of criterion · met / partly / not met / skipped (test or CI
   only, per D-021) · evidence (file:line, or the manual step that shows it).

   **Blocking issues**: bugs, and violations of `docs/CONVENTIONS.md` or CLAUDE.md "Do not", in
   particular:
   - model without `db_table`, non-UUID PK on a synced table, missing `SyncableModel` /
     `AttachSyncTrigger`, hard delete of synced rows
   - native PostgreSQL ENUM instead of `TextChoices` + `CheckConstraint`
   - geometry not SRID 4326 or missing GiST index
   - `QuerySet.update()` on an audited model; history revert enabled
   - business logic in views/serializers instead of services; error body not `{code, detail, fields}`
   - missing permission checks (researchers see only their projects and own records; admin-only
     operations stay admin-only)
   - Drift: UI writing synced tables directly; schema change without a `make-migrations` snapshot
   - `geo` view with `security_invoker`, or grants on `public` to `pygeoapi_ro`
   - edited applied migration; unapproved dependency; secrets or `.env` committed
   - work outside the ticket's scope

   **Non-blocking**: naming, readability, small simplifications. Keep it short.

   **Verdict**: ready / ready after fixes / not ready, in one line.

For large diffs you may delegate the convention check to the `code-reviewer` agent and merge its
findings into this report.
