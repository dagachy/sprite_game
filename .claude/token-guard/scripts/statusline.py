"""Status line: show current context size and when the prompt cache expires.

Claude Code re-renders the status line after each message, so it shows an absolute expiry
time instead of a countdown that would go stale between renders.
Output is empty when disabled with `tgctl.py statusline off`.
"""

import sys
import time

from tg_lib import fmt_k, last_turn, load_config, log_error, read_hook_input


def render(cfg, transcript_path, now=None):
    if not cfg.get("statusline", True):
        return ""
    turn = last_turn(transcript_path or "")
    if not turn or turn["ts"] is None:
        return "token-guard · ctx - · 캐시 -"

    now = time.time() if now is None else now
    expires = turn["ts"] + cfg["cache_ttl_seconds"]
    if now < expires:
        cache = "캐시 " + time.strftime("%H:%M", time.localtime(expires)) + "까지"
    else:
        cache = "캐시 만료"

    warn = " ⚠" if turn["context"] >= cfg["context_warn_tokens"] else ""
    return f"token-guard · ctx {fmt_k(turn['context'])}{warn} · {cache}"


def main():
    data = read_hook_input()
    text = render(load_config(), data.get("transcript_path"))
    if text:
        sys.stdout.write(text)


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        log_error("statusline", exc)
    sys.exit(0)
