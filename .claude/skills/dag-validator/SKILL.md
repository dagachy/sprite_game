---
name: dag-validator
description: 오케스트레이터·배치 작업의 depends_on DAG(순환/dangling 참조/병렬 레벨) 진단 진입점. 단일 tasks.json 또는 디렉토리를 dag-validator-auditor 에이전트로 감사하고 리포트를 반환한다. 사용자가 "DAG 점검", "의존성 검증", "batches audit", "순환 탐지" 등을 요청할 때 사용.
---

# dag-validator

작업 의존성 DAG 진단 라우터.
단일 모드 / 배치 모드 두 가지를 지원한다.

---

## 모드 결정

- `.json` 파일 경로 → **단일 모드**.
- 디렉토리 경로 또는 "모든 배치 작업" → **배치 모드** (`**/tasks.json` 또는 `**/batches.json` glob).

---

## 단일 모드

1. `dag-validator-auditor` 1회 호출. `TARGET=<absolute path>`.
2. 리포트 그대로 노출.
3. Verdict가 `CYCLE` / `DANGLING` 이면 1줄 재강조.

---

## 배치 모드

1. `**/tasks.json`, `**/batches.json` glob 수집.
2. 각 파일 **병렬 호출**.
3. 집계 표:

```
| File | Tasks | Levels | Verdict | Issues |
|------|------:|-------:|---------|--------|
```

4. 끝에 "CYCLE N / DANGLING M / VALID K / 전체 T" 요약.

---

## 입력 스키마

```json
{
  "tasks": [
    {"id": "a", "depends_on": []},
    {"id": "b", "depends_on": ["a"]},
    {"id": "c", "depends_on": ["a", "b"]}
  ]
}
```

- `id` 필수, 유일.
- `depends_on` 선택, 배열 of ids. 생략 시 빈 배열.

---

## 자가 검증

```
<플러그인 루트>/.claude/skills/dag-validator/samples/
├── valid-dag/tasks.json    # VALID + levels=[["a"],["b"],["c"]]
├── cycle/tasks.json        # CYCLE 감지
└── dangling/tasks.json     # DANGLING 참조 감지
```

3/3 Verdict 일치 → PASS.

---

## 범용 적용 메모

- 오케스트레이터 스킬에서 Phase 간 의존성, 또는 배치 작업 파이프라인 모두에 적용.
- 병렬 레벨 산출(Kahn's algorithm)으로 "어디까지 병렬화 가능한지" 가시화.
