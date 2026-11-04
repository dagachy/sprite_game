---
name: token-report
description: Summarize this session's token usage (context size, cache reads and creations, idle gaps, subagent cost) and point out the biggest sources of waste. Use when the user asks where tokens went, or at the end of a long session.
---

# token-report

Run the analyzer on the newest transcript of the current project and report the result.

**왜:** 최신 세션만 보면 지금 작업의 낭비 원인을 바로 짚을 수 있고, 현재 프로젝트로 한정하면 다른 프로젝트의 기록이 섞이지 않는다.

## Steps

1. Run:
   ```
   python3 "$HOME/.claude/token-guard/scripts/analyze.py" --latest "$PWD"
   ```
2. Summarize the output for the user in a short table. Mark the largest item.

**왜:** 수치는 스크립트가 transcript의 usage 필드에서 직접 집계한 값이라 모델이 추정하면 오차가 생기므로, 표는 스크립트 출력만 옮긴다. 가장 큰 항목이 낭비의 1순위이므로 표에서 표시해 바로 보이게 한다.
3. Explain the top cause using these rules:
   - `context_max` above 200K or a high `context_median`: the session is too long. Suggest a handoff and `/clear` at the next unit boundary.

**왜:** 사용자 CLAUDE.md가 컨텍스트가 20만 토큰을 넘기 전에 정리하라고 정하므로, 이 기준을 넘는 세션은 작업 단위 경계에서 handoff와 `/clear`를 권한다.
   - `idle_gaps_over_5min` above 0 with a large `cache_create`: the cache expired during a break. Suggest `/handoff` before breaks.

**왜:** 5분이 넘는 공백이면 캐시가 만료되어 컨텍스트 전체를 다시 쓰게 되므로, 쉬기 전에 handoff로 상태를 남기라는 CLAUDE.md 규칙과 같은 이유다.
   - `subagents.cache_create` larger than the main `cache_create`: subagent overuse. Suggest reusing agents with SendMessage.

**왜:** 서브에이전트를 새로 띄울 때마다 맥락을 처음부터 다시 쓰므로, 서브에이전트의 cache_create가 메인보다 크면 그것이 주된 낭비다. SendMessage로 기존 에이전트를 이으면 이 비용을 피한다.
   - `big_creations` above 0: a large file or image was loaded in one turn. Suggest bounded reads or delegating the review.

**왜:** 한 턴에 큰 파일이 통째로 올라오면 cache_create가 한꺼번에 튀므로, offset/limit로 필요한 구간만 읽거나 리뷰를 위임하라는 CLAUDE.md 규칙과 같은 이유다.
4. Keep the recommendation to at most three concrete actions.

**왜:** 권고가 많으면 실행되지 않으므로, 상위 세 개로 제한해 우선순위를 남긴다.

## Notes

- Numbers come from the transcript usage fields. Streamed records can repeat, so treat the totals as approximate. The ranking is reliable.

**왜:** 스트리밍 기록의 중복은 항목 전체에 비슷하게 섞이므로 절대치는 부풀어도 항목 간 상대 순위는 유지된다. 그래서 순위만 신뢰하라고 적는다.
- If the command reports that no transcript exists, the current directory is probably not a Claude Code project. Ask the user for the transcript path and run `analyze.py <path>`.

**왜:** 스크립트는 현재 디렉토리에 대응하는 transcript를 찾으므로, 프로젝트가 맞지 않으면 엉뚱한 세션을 분석하게 된다. 경로를 직접 받는 것이 안전하다.
