#!/usr/bin/env python3
"""Claude Code usage for the Waybar monitor island (custom/claude).

    claude-usage.py          JSON for Waybar: subscription session/weekly usage (from the status line cache)
                             or today's tokens; tooltip with today / last 7 days by model
    claude-usage.py report   the same numbers as plain text

Reads ~/.claude/projects/**/*.jsonl incrementally (byte offsets kept in ~/.cache/claude/usage-index.json),
so each run only parses new lines. Rate limits come from ~/.cache/claude/ratelimits.json, written by
~/.claude/statusline.sh while a Claude Code session is open.
"""
import json
import sys
import time
from html import escape
from datetime import datetime, timedelta
from pathlib import Path

HOME = Path.home()
PROJECTS = HOME / ".claude" / "projects"
CACHE = HOME / ".cache" / "claude"
INDEX = CACHE / "usage-index.json"
LIMITS = CACHE / "ratelimits.json"
KEEP_DAYS = 31
CLOCK, CALENDAR = "\U000F0150", "\U000F00ED"   # nf-md-clock_outline, nf-md-calendar


def load_index():
    try:
        return json.loads(INDEX.read_text())
    except (OSError, ValueError):
        return {"files": {}, "days": {}}


def scan(index):
    files, days = index["files"], index["days"]
    for path in PROJECTS.glob("**/*.jsonl"):
        key = str(path)
        st = files.get(key, {"offset": 0, "last": None})
        size = path.stat().st_size
        if size < st["offset"]:          # file was rewritten: start over
            st = {"offset": 0, "last": None}
        if size == st["offset"]:
            files[key] = st
            continue
        with path.open("rb") as f:
            f.seek(st["offset"])
            chunk = f.read()
        end = chunk.rfind(b"\n") + 1     # only complete lines; the rest is read next time
        for raw in chunk[:end].splitlines():
            try:
                rec = json.loads(raw)
            except ValueError:
                continue
            msg = rec.get("message") or {}
            usage = msg.get("usage")
            if rec.get("type") != "assistant" or not usage:
                continue
            rid = rec.get("requestId")
            if rid and rid == st["last"]:   # one request is logged once per content block
                continue
            st["last"] = rid
            ts = rec.get("timestamp", "")
            try:
                day = datetime.fromisoformat(ts.replace("Z", "+00:00")).astimezone().strftime("%Y-%m-%d")
            except ValueError:
                continue
            model = msg.get("model", "?").replace("claude-", "")
            row = days.setdefault(day, {}).setdefault(model, [0, 0, 0, 0, 0])
            row[0] += usage.get("input_tokens", 0)
            row[1] += usage.get("cache_read_input_tokens", 0) or 0
            row[2] += usage.get("cache_creation_input_tokens", 0) or 0
            row[3] += usage.get("output_tokens", 0)
            row[4] += 1
        st["offset"] += end
        files[key] = st
    cutoff = (datetime.now() - timedelta(days=KEEP_DAYS)).strftime("%Y-%m-%d")
    for day in [d for d in days if d < cutoff]:
        del days[day]
    files = {k: v for k, v in files.items() if Path(k).exists()}
    index["files"] = files
    CACHE.mkdir(parents=True, exist_ok=True)
    tmp = INDEX.with_suffix(".tmp")
    tmp.write_text(json.dumps(index))
    tmp.replace(INDEX)


def human(n):
    for unit, size in (("B", 1e9), ("M", 1e6), ("k", 1e3)):
        if n >= size:
            return f"{n / size:.1f}{unit}"
    return str(int(n))


def totals(days, dates):
    by_model, all_ = {}, [0, 0, 0, 0, 0]
    for d in dates:
        for model, row in days.get(d, {}).items():
            acc = by_model.setdefault(model, [0, 0, 0, 0, 0])
            for i, v in enumerate(row):
                acc[i] += v
                all_[i] += v
    return all_, by_model


def lines_for(label, all_, by_model):
    total = sum(all_[:4])
    out = [f"<b>{label}</b>  {human(total)} tokens  ·  {all_[4]} requests"]
    if total:
        out.append(f"  cache read {human(all_[1])} ({all_[1] * 100 // total}%)  ·  "
                   f"cache write {human(all_[2])}  ·  input {human(all_[0])}  ·  output {human(all_[3])}")
        for model, row in sorted(by_model.items(), key=lambda kv: -sum(kv[1][:4])):
            if model.startswith("<") or not sum(row[:4]):   # <synthetic> is not a model (and breaks Pango markup)
                continue
            out.append(f"  {escape(model)}: {human(sum(row[:4]))}")
    return out


def when(value):
    """Reset time (epoch seconds or ISO 8601): `18:20` if today, else `Mon 02/11 18:20`."""
    try:
        if str(value).isdigit():
            dt = datetime.fromtimestamp(int(value))
        else:
            dt = datetime.fromisoformat(str(value).replace("Z", "+00:00")).astimezone().replace(tzinfo=None)
    except ValueError:
        return str(value)
    if dt.date() == datetime.now().date():
        return dt.strftime("%H:%M")
    return dt.strftime("%a %d/%m %H:%M")


def limits():
    try:
        lim = json.loads(LIMITS.read_text())
    except (OSError, ValueError):
        return None
    if time.time() - lim.get("updated", 0) > 6 * 3600:   # stale: the 5-hour window has rolled over
        return None
    return lim


def main():
    index = load_index()
    scan(index)
    days = index["days"]
    today = datetime.now().strftime("%Y-%m-%d")
    week = [(datetime.now() - timedelta(days=i)).strftime("%Y-%m-%d") for i in range(7)]
    t_all, t_models = totals(days, [today])
    w_all, w_models = totals(days, week)

    tip = lines_for("Today", t_all, t_models) + [""] + lines_for("Last 7 days", w_all, w_models)
    lim = limits()
    pct = week_pct = None
    if lim:
        pct = round(lim["five_hour"])
        week_pct = None if lim.get("seven_day") is None else round(lim["seven_day"])
        week_line = f"  Week  {week_pct}%" if week_pct is not None else None
        if week_line and lim.get("seven_day_resets_at"):
            week_line += f"  ·  resets {when(lim['seven_day_resets_at'])}"
        tip = ["<b>Plan usage</b>",
               f"  Session (5h)  {pct}%" + (f"  ·  resets {when(lim['resets_at'])}" if lim.get("resets_at") else "")
               ] + ([week_line] if week_line else []) + [""] + tip
    tip += ["", "Click: Claude Code usage report (ccusage)"]

    if "report" in sys.argv[1:]:
        print("\n".join(tip).replace("<b>", "").replace("</b>", ""))
        return
    if pct is None:
        text = human(sum(t_all[:4]))
    else:    # clock = session (5h), calendar = week; Material Design glyphs, dimmed
        dim = '<span alpha="55%">{}</span>'
        text = dim.format(CLOCK) + f" {pct}%"
        if week_pct is not None:
            text += "  " + dim.format(CALENDAR) + f" {week_pct}%"
    cls = "normal"
    if pct is not None:
        worst = max(pct, week_pct or 0)
        cls = "critical" if worst >= 90 else "warning" if worst >= 70 else "normal"
    print(json.dumps({"text": text, "tooltip": "\n".join(tip), "class": cls,
                      "percentage": pct if pct is not None else 0}))


if __name__ == "__main__":
    main()
