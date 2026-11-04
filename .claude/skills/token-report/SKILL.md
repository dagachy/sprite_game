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
3. Explain the top cause using the rules in [진단 규칙](references/rules.md).

**왜:** 판정 규칙을 분리해 두면 이 파일은 실행 절차만 남아, 세션마다 읽는 토큰이 줄어든다.
4. Keep the recommendation to at most three concrete actions.

**왜:** 권고가 많으면 실행되지 않으므로, 상위 세 개로 제한해 우선순위를 남긴다.

## Notes

- Numbers come from the transcript usage fields. Streamed records can repeat, so treat the totals as approximate. The ranking is reliable.

**왜:** 스트리밍 기록의 중복은 항목 전체에 비슷하게 섞이므로 절대치는 부풀어도 항목 간 상대 순위는 유지된다. 그래서 순위만 신뢰하라고 적는다.
- If the command reports that no transcript exists, the current directory is probably not a Claude Code project. Ask the user for the transcript path and run `analyze.py <path>`.

**왜:** 스크립트는 현재 디렉토리에 대응하는 transcript를 찾으므로, 프로젝트가 맞지 않으면 엉뚱한 세션을 분석하게 된다. 경로를 직접 받는 것이 안전하다.
