# token-report 진단 규칙

스크립트 출력의 항목을 아래 조건으로 판정한다. 조건이 여러 개 걸리면 절대치가 가장 큰 항목부터 설명한다.

- `context_max` 200K 초과 또는 `context_median`이 높음: 세션이 너무 길다. 다음 작업 단위 경계에서 handoff와 `/clear`를 권한다.
  - **왜:** 사용자 CLAUDE.md가 컨텍스트가 20만 토큰을 넘기 전에 정리하라고 정하므로, 이 기준을 넘는 세션은 작업 단위 경계에서 handoff와 `/clear`를 권한다.
- `idle_gaps_over_5min` 0 초과이면서 `cache_create`가 큼: 쉬는 동안 캐시가 만료됐다. 쉬기 전에 `/handoff`를 권한다.
  - **왜:** 5분이 넘는 공백이면 캐시가 만료되어 컨텍스트 전체를 다시 쓰게 되므로, 쉬기 전에 handoff로 상태를 남기라는 CLAUDE.md 규칙과 같은 이유다.
- `subagents.cache_create`가 메인 `cache_create`보다 큼: 서브에이전트 과다 사용. SendMessage로 기존 에이전트를 재사용하라고 권한다.
  - **왜:** 서브에이전트를 새로 띄울 때마다 맥락을 처음부터 다시 쓰므로, 서브에이전트의 cache_create가 메인보다 크면 그것이 주된 낭비다. SendMessage로 기존 에이전트를 이으면 이 비용을 피한다.
- `big_creations` 0 초과: 한 턴에 큰 파일이나 이미지가 올라왔다. offset/limit로 구간만 읽거나 리뷰를 위임하라고 권한다.
  - **왜:** 한 턴에 큰 파일이 통째로 올라오면 cache_create가 한꺼번에 튀므로, offset/limit로 필요한 구간만 읽거나 리뷰를 위임하라는 CLAUDE.md 규칙과 같은 이유다.
