# _workspace

phase 간 산출물을 넘기는 작업 공간이다. 팀은 작업마다 새로 구성하고, phase 단위로 실행한다.

## 규칙

- 경로: `_workspace/<phase>/<agent>/` 아래에 해당 에이전트의 산출물을 쓴다.
- 다음 phase의 에이전트는 이전 phase의 산출물 경로를 읽어 이어받는다.
- 한 phase에서 동시에 활성화되는 에이전트는 최대 5명이다(`.claude/phases.json`의 `max_concurrent`).
- 작업 한 건이 끝나면 산출물은 그대로 두고, 필요한 결론만 `HANDOFF.md`에 옮긴다.
