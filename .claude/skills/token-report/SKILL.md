---
name: token-report
description: Summarize this session's token usage (context size, cache reads and creations, idle gaps, subagent cost) and point out the biggest sources of waste. Use when the user asks where tokens went, or at the end of a long session.
---

# token-report

Run the analyzer on the newest transcript of the current project and report the result.

## Steps

1. Run:
   ```
   python3 "$HOME/.claude/token-guard/scripts/analyze.py" --latest "$PWD"
   ```
2. Summarize the output for the user in a short table. Mark the largest item.
3. Explain the top cause using these rules:
   - `context_max` above 200K or a high `context_median`: the session is too long. Suggest a handoff and `/clear` at the next unit boundary.
   - `idle_gaps_over_5min` above 0 with a large `cache_create`: the cache expired during a break. Suggest `/handoff` before breaks.
   - `subagents.cache_create` larger than the main `cache_create`: subagent overuse. Suggest reusing agents with SendMessage.
   - `big_creations` above 0: a large file or image was loaded in one turn. Suggest bounded reads or delegating the review.
4. Keep the recommendation to at most three concrete actions.

## Notes

- Numbers come from the transcript usage fields. Streamed records can repeat, so treat the totals as approximate. The ranking is reliable.
- If the command reports that no transcript exists, the current directory is probably not a Claude Code project. Ask the user for the transcript path and run `analyze.py <path>`.
