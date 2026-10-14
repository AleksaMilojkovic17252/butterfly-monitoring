---
description: Review the current diff against the ticket's acceptance criteria and project conventions
argument-hint: "[T0xx]"
allowed-tools: Bash(git diff:*), Bash(git log:*), Bash(git status:*), Bash(gh issue view:*), Read, Grep, Glob
---

Review my changes. Ticket (if empty, infer from the branch name `t0xx-…`): $ARGUMENTS

Do not edit files during the review; report only.

1. Get the diff: `git diff <default-branch>...HEAD` plus uncommitted changes (`git diff`, `git status`).
2. Get the acceptance criteria: `gh issue view <n>` (ticket `Tnnn` is issue #(nnn + 17)), or the
   ticket's section in `docs/TICKETS.md` if `gh` is unavailable.
3. Produce, in this order:

   **Acceptance criteria** — a table: criterion · met / partly / not met · evidence (file:line or
   test name). Be strict: "a test exists" is only met if the test actually asserts the behaviour.

   **Blocking issues** — bugs, missing tests for new behaviour, and violations of
   `docs/CONVENTIONS.md` / CLAUDE.md "Do not", in particular:
   - model without `db_table`, non-UUID PK on a synced table, missing `SyncableModel` /
     `AttachSyncTrigger`, hard delete of synced rows
   - native PostgreSQL ENUM instead of `TextChoices` + `CheckConstraint`
   - geometry not SRID 4326 or missing GiST index
   - `QuerySet.update()` on an audited model; history revert enabled
   - business logic in views/serializers instead of services; error body not `{code, detail, fields}`
   - permission checks missing (researchers must only see their projects and own records)
   - Drift: UI writing synced tables directly; schema change without `make-migrations` snapshot
   - `geo` view with `security_invoker`, or grants on `public` to `pygeoapi_ro`
   - edited applied migration; new dependency not approved; secrets or `.env` committed
   - work outside the ticket's scope

   **Non-blocking** — naming, readability, small simplifications. Keep it short.

   **Verdict** — ready / ready after fixes / not ready, in one line.

For large diffs you may delegate the convention check to the `code-reviewer` agent and merge its
findings into this report.
