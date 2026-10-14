#!/usr/bin/env python3
"""Regenerate docs/TICKETS.md from the GitHub issues.

GitHub Issues are the source of truth for ticket text and status. This script
reads them with the GitHub CLI and writes a flat index that Claude Code (and
you) can grep without a network call.

Usage:
    python3 scripts/tickets_index.py                 # calls `gh issue list`
    python3 scripts/tickets_index.py --json issues.json
    python3 scripts/tickets_index.py --check         # exit 1 if the file is stale

Status rules:
    done         issue is closed (state_reason "completed")
    dropped      issue is closed as "not planned"
    in progress  issue is open and has the `in-progress` label
    ready        issue is open and every hard dependency is done
    blocked      issue is open and at least one hard dependency is not done

Hard dependencies are the T-numbers in "Depends on" outside parentheses.
Text in parentheses (e.g. "plant views added when T051/T053 are done") is a
soft note and does not block.
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
OUT = REPO_ROOT / "docs" / "TICKETS.md"
ISSUES_URL = "https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues"
GH_FIELDS = "number,title,state,stateReason,body,labels,milestone"

TICKET_TITLE = re.compile(r"^(T\d{3}) · (.+)$")
HEADER_FIELD = re.compile(r"\*\*(?P<key>[^*]+):\*\*\s*(?P<val>.*?)(?=\s*·\s*\*\*|$)")
AC_START = re.compile(r"^\*\*Acceptance criteria\*\*\s*$", re.M)
SECTION = re.compile(r"^\*\*[^*]+\*\*\s*$", re.M)
PRIORITIES = ("must", "should", "could")

# Build order from the roadmap issue (#2, section D.2). Update both together.
STAGES = [
    ("1 · Foundations", "T001 T002 T003 T006 T004 T005 T009 T007 T008 T010"),
    ("2a · Accounts and projects", "T011 T013 T014 T012 T015 T016 T018 T017"),
    ("2b · Catalogues and transects", "T019 T020 T021 T022 T024"),
    ("3 · Sync core", "T025 T026 T029 T030 T027 T028 T031 T032"),
    ("4 · Field visit and observations",
     "T033 T034 T035 T036 T037 T042 T039 T044 T045 T055 T040 T041 T043 T038"),
    ("5 · Photos, environment, export, OGC", "T049 T050 T063 T064 T067 T068 T069 T059"),
    ("6 · Simulation and evaluation", "T071 T072 T070 T073 T074 T075"),
    ("P1 Should/Could fill (only if the velocity checkpoint allows)",
     "T046 T048 T051 T052 T053 T054 T058 T057 T056 T047 T061 T062 T065 T023 T060 T066"),
    ("7 · SensorThings (Phase 2)", "T076 T077 T078 T079 T081 T080"),
    ("8 · EDR (Phase 2)", "T082 T083 T084 T085"),
    ("9 · Moving Features + MobilityDB (Phase 2)",
     "T086 T087 T089 T088 T090 T092 T091 T093 T094"),
    ("10 · Evaluation (Phase 2)", "T095 T096 T097"),
]


def load_issues(json_path: str | None) -> list[dict]:
    if json_path:
        return json.loads(Path(json_path).read_text())
    cmd = ["gh", "issue", "list", "--state", "all", "--limit", "500", "--json", GH_FIELDS]
    return json.loads(subprocess.run(cmd, check=True, capture_output=True, text=True).stdout)


def parse_ticket(issue: dict) -> dict | None:
    m = TICKET_TITLE.match(issue["title"])
    if not m:
        return None
    body = issue.get("body") or ""
    header_line = next((ln for ln in body.splitlines() if ln.startswith("**ID:**")), "")
    header = {f["key"].strip(): f["val"].strip() for f in HEADER_FIELD.finditer(header_line)}

    depends_raw = header.get("Depends on", "—")
    hard = re.findall(r"T\d{3}", re.sub(r"\([^)]*\)", "", depends_raw))
    soft_notes = [n for n in re.findall(r"\(([^)]*)\)", depends_raw) if not re.fullmatch(r"#\d+", n)]

    ac = ""
    start = AC_START.search(body)
    if start:
        rest = body[start.end():]
        nxt = SECTION.search(rest)
        ac = (rest[: nxt.start()] if nxt else rest).strip()
        ac = ac.split("\n---")[0].strip()

    labels = [lb["name"] if isinstance(lb, dict) else lb for lb in issue.get("labels", [])]
    milestone = issue.get("milestone") or {}
    milestone = milestone.get("title", "") if isinstance(milestone, dict) else milestone
    state = issue["state"].lower()
    reason = (issue.get("stateReason") or "").lower()
    return {
        "id": m.group(1),
        "title": m.group(2),
        "number": issue["number"],
        "labels": labels,
        "priority": next((p for p in PRIORITIES if p in labels), ""),
        "phase": "P2" if "Phase 2" in milestone else "P1",
        "epic": re.sub(r"\s*\(#\d+\)", "", header.get("Epic", "")),
        "estimate": header.get("Estimate", ""),
        "implements": header.get("Implements", ""),
        "depends": sorted(set(hard)),
        "soft_notes": soft_notes,
        "ac": ac,
        "closed": state == "closed",
        "dropped": state == "closed" and reason == "not_planned",
        "in_progress": state == "open" and "in-progress" in labels,
    }


def status(t: dict, by_id: dict) -> str:
    if t["dropped"]:
        return "dropped"
    if t["closed"]:
        return "done"
    if t["in_progress"]:
        return "in progress"
    open_deps = [d for d in t["depends"] if not by_id.get(d, {}).get("closed")]
    return "blocked" if open_deps else "ready"


def render(tickets: list[dict]) -> str:
    by_id = {t["id"]: t for t in tickets}
    link = lambda t: f"[#{t['number']}]({ISSUES_URL}/{t['number']})"  # noqa: E731
    out = [
        "# Tickets",
        "",
        "<!-- GENERATED by scripts/tickets_index.py from GitHub Issues. Do not edit by hand; "
        "change the issue, then rerun the script. -->",
        "",
        "Source of truth: GitHub Issues. Conventions: issue #1. Roadmap, capacity and cut lines: issue #2.",
        "Ticket `Tnnn` is issue #(nnn + 17). Epic `Enn` is issue #(nn + 2).",
        "",
        "Status: `ready` = open, all hard dependencies done · `blocked` = a hard dependency is open · "
        "`in progress` = has the `in-progress` label · `done` = closed · `dropped` = closed as not planned.",
        "",
    ]
    counts: dict[str, int] = {}
    for t in tickets:
        counts[status(t, by_id)] = counts.get(status(t, by_id), 0) + 1
    out += ["**Summary:** " + " · ".join(f"{k} {v}" for k, v in sorted(counts.items())), ""]

    out += ["## Build order", "",
            "Work tickets in this order (roadmap issue #2, D.2). `/next-ticket` picks the first "
            "`ready` ticket in this list. Phase 1 is the February target; Phase 2 comes after.", ""]
    for stage, ids in STAGES:
        cells = []
        for tid in ids.split():
            t = by_id.get(tid)
            mark = {"done": "✅", "in progress": "🔨", "ready": "▶️", "dropped": "✖️"}.get(
                status(t, by_id) if t else "", "")
            cells.append(f"{tid}{mark}")
        out.append(f"- **{stage}:** " + ", ".join(cells))
    out += ["", "Legend: ✅ done · 🔨 in progress · ▶️ ready · no mark = blocked", ""]

    out += ["## Index", "",
            "| ID | Issue | Title | Phase | Priority | Depends on | Est. | Status |",
            "|---|---|---|---|---|---|---|---|"]
    for t in tickets:
        deps = ", ".join(t["depends"]) or "—"
        out.append(f"| {t['id']} | {link(t)} | {t['title'].replace('|', '/')} | {t['phase']} | "
                   f"{t['priority']} | {deps} | {t['estimate']} | {status(t, by_id)} |")
    out.append("")

    out += ["## Acceptance criteria", ""]
    for t in tickets:
        out.append(f"### {t['id']} · {t['title']}")
        meta = (f"{link(t)} · {t['epic']} · {t['phase']} · {t['priority']} · "
                f"labels: {', '.join(f'`{lb}`' for lb in t['labels'])} · implements {t['implements']} · "
                f"est. {t['estimate']} · **{status(t, by_id)}**")
        out += [meta, "", f"Depends on: {', '.join(t['depends']) or '—'}"]
        if t["soft_notes"]:
            out.append(f"Notes: {'; '.join(t['soft_notes'])}")
        out += ["", t["ac"] or "_No acceptance criteria found in the issue body._", ""]
    return "\n".join(out).rstrip() + "\n"


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--json", help="read issues from a JSON file instead of calling gh")
    ap.add_argument("--check", action="store_true", help="exit 1 if docs/TICKETS.md is out of date")
    args = ap.parse_args()

    tickets = [t for i in load_issues(args.json) if (t := parse_ticket(i))]
    tickets.sort(key=lambda t: t["id"])
    text = render(tickets)
    if args.check:
        current = OUT.read_text() if OUT.exists() else ""
        if current != text:
            print("docs/TICKETS.md is out of date; run python3 scripts/tickets_index.py", file=sys.stderr)
            return 1
        return 0
    OUT.write_text(text)
    print(f"wrote {OUT.relative_to(REPO_ROOT)} ({len(tickets)} tickets)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
