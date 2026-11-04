---
name: team-size-governor
description: 하네스 팀 규모 상한(전체 에이전트 수 / Phase별 동시 활성 수) 진단 진입점. 디렉토리 또는 phases.json을 team-size-governor-auditor 에이전트로 감사하고 리포트를 반환한다. 사용자가 "팀 규모 점검", "에이전트 수 상한", "team size audit", "Phase 활성 매트릭스" 등을 요청할 때 사용.
---

# team-size-governor

하네스 팀 규모 진단 라우터.
2 모드: 디렉토리 모드 / 매트릭스 모드.

---

## 모드 결정

- 입력이 `.json` 파일 → **매트릭스 모드** (Phase별 활성 매트릭스 검증).
- 입력이 디렉토리 → **디렉토리 모드** (`.claude/agents/*.md` 전체 수 검증).
- 둘 다 가능하면 유저에 확인 질문.

---

## 디렉토리 모드

입력: 하네스 루트 디렉토리.

1. `team-size-governor-auditor` 1회 호출, `TARGET=<path>` + `MODE=directory`.
2. 에이전트가 `.claude/agents/*.md` 수를 세어 `MAX_TEAM_SIZE` (기본 5)와 비교.
3. 리포트 노출.

---

## 매트릭스 모드

입력: phases.json (스키마는 아래).

1. `team-size-governor-auditor` 1회 호출, `TARGET=<path>` + `MODE=matrix`.
2. Phase별 active 수 중 최대값을 `MAX_CONCURRENT` (기본 5)와 비교.
3. 리포트 노출.

---

## 입력 스키마 (매트릭스 모드)

```json
{
  "phases": {
    "A": ["agent1", "agent2"],
    "B": ["agent3", "agent4", "agent5"]
  },
  "max_concurrent": 5
}
```

`max_concurrent` 생략 시 기본 5. 환경변수 `MAX_CONCURRENT` override 우선.

---

## 임계값 override

- `MAX_TEAM_SIZE` (기본 `5`): 디렉토리 모드 상한.
- `MAX_CONCURRENT` (기본 `5`): Phase별 상한.

---

## 자가 검증

```
<플러그인 루트>/.claude/skills/team-size-governor/samples/
├── small-team/              # 디렉토리 모드 - 3명 → COMPLIANT
├── exceeds-total/           # 디렉토리 모드 - 7명 → EXCEEDS_TOTAL
└── exceeds-per-phase/phases.json  # 매트릭스 모드 - 7명 Phase 포함 → EXCEEDS_PER_PHASE
```

3/3 Verdict 일치 → PASS.

---

## 범용 적용 메모

- ex-06-15 "292 agent incident" 교훈: 팀 규모가 커지면 조율 비용 N² 증가. 상한 5명이 경험칙.
- ex-12-03 Phase별 활성 매트릭스: 전체 8명이어도 Phase당 3~4명 활성이면 OK.
