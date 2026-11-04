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
  - **왜:** 파일 하나는 DAG 한 개를 검증하고, 디렉토리는 여러 배치 파일의 결과를 집계해야 하므로 모드를 나눈다.
- 디렉토리 경로 또는 "모든 배치 작업" → **배치 모드** (`**/tasks.json` 또는 `**/batches.json` glob).

---

## 단일 모드

1. `dag-validator-auditor` 1회 호출. `TARGET=<absolute path>`.
2. 리포트 그대로 노출.
3. Verdict가 `CYCLE` / `DANGLING` 이면 1줄 재강조.
   - **왜:** 순환이나 끊긴 참조가 있으면 해당 작업이 시작되지 못하거나 실패하므로, 실행 전에 반드시 보이게 한다.

---

## 배치 모드

1. `**/tasks.json`, `**/batches.json` glob 수집.
   - **왜:** 오케스트레이터마다 파일 이름이 달라, 두 이름을 모두 잡아야 검증에서 빠지는 배치가 없다.
2. 각 파일 **병렬 호출**.
3. 집계 표:

```
| File | Tasks | Levels | Verdict | Issues |
|------|------:|-------:|---------|--------|
```

4. 끝에 "CYCLE N / DANGLING M / VALID K / 전체 T" 요약.
   - **왜:** 검증 실패 건수를 한 줄로 보여 배치 실행 가능 여부를 빠르게 판단하게 한다.

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
  - **왜:** depends_on이 id로만 작업을 가리키므로, id가 중복되면 의존 대상이 모호해진다.
- `depends_on` 선택, 배열 of ids. 생략 시 빈 배열.
  - **왜:** 의존이 없는 작업은 생략해도 독립으로 처리되어, 입력을 작성하는 부담을 줄인다.

---

## 자가 검증

```
<플러그인 루트>/.claude/skills/dag-validator/samples/
├── valid-dag/tasks.json    # VALID + levels=[["a"],["b"],["c"]]
├── cycle/tasks.json        # CYCLE 감지
└── dangling/tasks.json     # DANGLING 참조 감지
```

3/3 Verdict 일치 → PASS.

**왜:** valid(레벨 산출), cycle(순환 탐지), dangling(끊긴 참조) 세 경로가 모두 맞아야 검증기의 판정을 믿을 수 있다.

---

## 범용 적용 메모

- 오케스트레이터 스킬에서 Phase 간 의존성, 또는 배치 작업 파이프라인 모두에 적용.
- 병렬 레벨 산출(Kahn's algorithm)으로 "어디까지 병렬화 가능한지" 가시화.
  - **왜:** 같은 레벨의 작업은 서로 의존이 없어 동시에 돌릴 수 있으므로, 병렬 범위를 레벨로 보여 준다.
