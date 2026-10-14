## Ticket

Closes #<!-- issue number; ticket Tnnn is issue #(nnn + 17) -->

## What changed

<!-- 2–5 lines: what a reviewer will see, and why. -->

## Acceptance criteria

<!-- Copy the ticket's checklist. Tick what is met and add evidence (test name or file). Mark anything deferred and link the follow-up issue. -->

- [ ] 

## Checks run

- [ ] Backend: `ruff check`, `pytest`, `makemigrations --check`, `spectacular --validate` (or n/a)
- [ ] Mobile: `flutter analyze`, `flutter test`, Drift schema verify (or n/a)
- [ ] Stack starts with `docker compose up -d` (infra changes only)

## Notes

<!-- Decisions logged in docs/DECISIONS.md, VERIFY results, new or changed commands in CLAUDE.md, migrations to watch. -->
