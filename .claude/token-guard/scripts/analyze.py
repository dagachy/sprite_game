"""Summarize token usage of a Claude Code session transcript.

Usage:
  python3 analyze.py <transcript.jsonl>
  python3 analyze.py --latest <project_dir>   # newest session of a project cwd
"""

import glob
import json
import os
import statistics
import sys
from pathlib import Path

from tg_lib import DEFAULTS, fmt_k, usage_of

IDLE_GAP_SECONDS = 300


def iter_entries(path):
    with open(path, encoding="utf-8", errors="ignore") as f:
        for line in f:
            try:
                yield json.loads(line)
            except ValueError:
                continue


def summarize(path, big_creation=DEFAULTS["big_creation_tokens"]):
    turns = []
    agent_calls = 0
    for entry in iter_entries(path):
        turn = usage_of(entry)
        if turn:
            turns.append(turn)
        msg = entry.get("message") if isinstance(entry, dict) else None
        if isinstance(msg, dict) and isinstance(msg.get("content"), list):
            agent_calls += sum(
                1 for c in msg["content"]
                if isinstance(c, dict) and c.get("type") == "tool_use" and c.get("name") == "Agent"
            )

    contexts = [t["context"] for t in turns]
    gaps = [
        b["ts"] - a["ts"]
        for a, b in zip(turns, turns[1:])
        if a["ts"] is not None and b["ts"] is not None
    ]
    expired = [g for g in gaps if g > IDLE_GAP_SECONDS]
    summary = {
        "turns": len(turns),
        "context_median": int(statistics.median(contexts)) if contexts else 0,
        "context_max": max(contexts) if contexts else 0,
        "cache_read": sum(t["read"] for t in turns),
        "cache_create": sum(t["create"] for t in turns),
        "output": sum(t["output"] for t in turns),
        "big_creations": sum(1 for t in turns if t["create"] >= big_creation),
        "idle_gaps_over_5min": len(expired),
        "longest_idle_minutes": round(max(gaps) / 60) if gaps else 0,
        "agent_calls": agent_calls,
    }

    sub_dir = Path(path).with_suffix("") / "subagents"
    sub = {"subagent_files": 0, "cache_read": 0, "cache_create": 0, "output": 0}
    for sub_path in glob.glob(str(sub_dir / "*.jsonl")):
        sub["subagent_files"] += 1
        for entry in iter_entries(sub_path):
            turn = usage_of(entry)
            if turn:
                sub["cache_read"] += turn["read"]
                sub["cache_create"] += turn["create"]
                sub["output"] += turn["output"]
    summary["subagents"] = sub
    return summary


def latest_transcript(project_dir):
    """Map a cwd to its Claude Code project folder and return the newest transcript."""
    encoded = project_dir.replace("/", "-")
    root = Path.home() / ".claude" / "projects" / encoded
    files = sorted(root.glob("*.jsonl"), key=os.path.getmtime)
    return str(files[-1]) if files else None


def render(s):
    sub = s["subagents"]
    lines = [
        f"turns: {s['turns']}",
        f"context: median {fmt_k(s['context_median'])}, max {fmt_k(s['context_max'])}",
        f"cache read: {s['cache_read']:,}",
        f"cache create: {s['cache_create']:,}",
        f"output: {s['output']:,}",
        f"big cache creations (>= {fmt_k(DEFAULTS['big_creation_tokens'])}): {s['big_creations']}",
        f"idle gaps over 5 min: {s['idle_gaps_over_5min']} (longest {s['longest_idle_minutes']} min)",
        f"Agent calls: {s['agent_calls']}",
        f"subagents: {sub['subagent_files']} files, read {sub['cache_read']:,}, "
        f"create {sub['cache_create']:,}, output {sub['output']:,}",
    ]
    return "\n".join(lines)


def main(argv):
    if len(argv) == 3 and argv[1] == "--latest":
        path = latest_transcript(argv[2])
        if not path:
            print(f"no transcript found for {argv[2]}")
            return 1
    elif len(argv) == 2:
        path = argv[1]
    else:
        print(__doc__)
        return 2
    print(render(summarize(path)))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
