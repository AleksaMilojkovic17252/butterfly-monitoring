"""Build evaluation/interop/cite/report.html from testng-results.xml (TEAM Engine REST gives no HTML)."""
import collections, html, sys
import xml.etree.ElementTree as ET

src, dst = sys.argv[1], sys.argv[2]
root = ET.parse(src).getroot()
suite = root.find("suite")
rows = collections.defaultdict(list)
for m in root.iter("test-method"):
    if m.get("is-config") == "true":
        continue
    first = m.find("params/param/value")
    target = ""
    if first is not None and first.text and "id=" in first.text:
        target = first.text.split("id=")[1].split(",")[0].strip()
    msg = (m.findtext("exception/message") or "").strip().replace("\n", " ")[:300]
    rows[m.get("status")].append((m.get("name"), target, msg, m.get("description") or ""))

out = ["<!doctype html><meta charset=utf-8><title>CITE report (OGC API - Features 1.0)</title>",
       "<style>body{font:14px sans-serif;margin:2em}td,th{border:1px solid #ccc;padding:4px 8px;text-align:left}table{border-collapse:collapse}</style>",
       f"<h1>{html.escape(suite.get('name'))}</h1>",
       f"<p>Started {suite.get('started-at')}, finished {suite.get('finished-at')}. Generated from testng-results.xml "
       "(TEAM Engine REST answers XML and EARL, not HTML; the raw files are next to this one).</p>",
       f"<p><b>total {root.get('total')} · passed {root.get('passed')} · failed {root.get('failed')} · skipped {root.get('skipped')}</b></p>"]
for status in ("FAIL", "SKIP"):
    grouped = collections.Counter(rows[status])
    out.append(f"<h2>{status} ({len(rows[status])})</h2><table><tr><th>n</th><th>test</th><th>collection</th><th>message</th></tr>")
    for (name, target, msg, _), n in sorted(grouped.items()):
        out.append(f"<tr><td>{n}</td><td>{html.escape(name)}</td><td>{html.escape(target)}</td><td>{html.escape(msg)}</td></tr>")
    out.append("</table>")
passed = collections.Counter(n for n, *_ in rows["PASS"])
out.append(f"<h2>PASS ({len(rows['PASS'])})</h2><table><tr><th>n</th><th>test</th></tr>")
for name, n in sorted(passed.items()):
    out.append(f"<tr><td>{n}</td><td>{html.escape(name)}</td></tr>")
out.append("</table>")
open(dst, "w").write("\n".join(out))
