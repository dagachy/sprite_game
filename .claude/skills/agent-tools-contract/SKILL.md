---
name: agent-tools-contract
description: 에이전트 tools 필드가 역할에 적합한지(권한 과소/과잉, 자동 커밋 리스크) 진단 진입점. 단일 agent .md 또는 디렉토리를 agent-tools-contract-auditor 에이전트로 감사하고 집계 리포트를 반환한다. 사용자가 "에이전트 권한 점검", "tools contract audit", "역할 적합성 감사" 등을 요청할 때 사용.
---

# agent-tools-contract

에이전트 tools 필드 역할 적합성 진단 라우터.
단일 모드 / 배치 모드 두 가지를 지원한다.

---

## 모드 결정

- `.md` 파일 경로 → **단일 모드**.
- 디렉토리 경로 또는 "모든 에이전트" → **배치 모드** (기본 `.claude/agents/`).
  - **왜:** 파일 한 개는 권한 판정 한 건이지만, 디렉토리는 역할 전체의 권한 분포를 봐야 과잉 권한이 드러나므로 모드를 나눈다.

---

## 단일 모드

1. `agent-tools-contract-auditor` 1회 호출. `TARGET=<absolute path>`.
2. 리포트 그대로 노출.
3. Verdict가 `OVERPRIVILEGED` / `RISK` 이면 1줄 재강조.
   - **왜:** 과잉 권한과 자동 커밋 리스크는 잘못 실행되면 되돌리기 어려운 변경으로 이어지므로 눈에 띄게 한다.

---

## 배치 모드

1. `*.md` glob 수집.
2. 각 파일 **병렬 호출** (10개 단위 배치).
   - **왜:** 에이전트 수만큼 감사 호출이 생기므로 10개씩 끊어 동시 부하를 제한한다.
3. 집계 표:

```
| Agent | Role | Tools | Verdict |
|-------|------|-------|---------|
```

4. 끝에 "OVERPRIVILEGED N / RISK M / COMPLIANT K / 전체 T" 요약.
   - **왜:** 권한 문제가 몇 건인지 한눈에 보여 우선 수정 대상을 정하게 한다.

---

## 임계값 override

- `READ_ONLY_KEYWORDS` (기본: `auditor|analyzer|reviewer|reader|inspector|scanner|감사|검토|분석`)
  - **왜:** 이름에 읽기 전용 역할이 드러나는 에이전트에 Write/Edit가 있으면 과잉으로 판정하기 위한 역할 신호다 (`read-only-bad` 샘플: auditor + Write → OVERPRIVILEGED).
- `ORCHESTRATOR_KEYWORDS` (기본: `orchestrator|coordinator|router|조율|라우터|오케스트레이터`)
  - **왜:** 조율 역할은 DELEGATE_TOOLS로 다른 에이전트를 부르는 쪽이라, 이 키워드로 따로 구분해야 위임 도구 보유를 정당하게 판단할 수 있다.
- `WRITE_TOOLS` (기본: `Write|Edit|NotebookEdit`)
  - **왜:** 파일을 바꿀 수 있는 도구 집합이라, 읽기 역할과 비교해 과잉 여부를 가르는 기준이 된다.
- `DELEGATE_TOOLS` (기본: `Task|SendMessage`)
  - **왜:** 다른 에이전트를 호출할 수 있는 도구라, 역할 범위를 넘는 위임이 생기는지 따로 본다.

---

## 자가 검증

```
<플러그인 루트>/.claude/skills/agent-tools-contract/samples/
├── read-only-good/sample.md     # reviewer + Read/Grep → COMPLIANT
├── read-only-bad/sample.md      # auditor + Write → OVERPRIVILEGED
└── bash-no-safety/sample.md     # writer + Bash, git 금지 명시 없음 → RISK
```

3/3 Verdict 일치 → PASS.

**왜:** 세 샘플이 COMPLIANT / OVERPRIVILEGED / RISK 경로를 하나씩 대표한다. `bash-no-safety`가 RISK인 이유는 Bash를 가진 쓰기 에이전트가 git 금지를 명시하지 않으면 자동 커밋 같은 되돌리기 어려운 변경을 할 수 있기 때문이다.

---

## 범용 적용 메모

- `harness-structure` → 뼈대 존재 → `agent-frontmatter` → 메타 완비 → **`agent-tools-contract` → 권한 적합성** 순서가 pre-flight 자연스러운 흐름.
  - **왜:** 뼈대와 메타가 깨진 상태에서 권한을 판정하면 엉뚱한 파일을 기준으로 결론이 나므로, 앞 단계부터 확인한다.
- 역할 키워드 사전은 override로 프로젝트별 어휘 확장 가능.
  - **왜:** 프로젝트마다 역할을 부르는 말이 달라, 기본 사전만으로는 읽기 전용 역할을 놓칠 수 있다.
