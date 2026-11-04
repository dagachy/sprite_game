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

---

## 단일 모드

1. `agent-tools-contract-auditor` 1회 호출. `TARGET=<absolute path>`.
2. 리포트 그대로 노출.
3. Verdict가 `OVERPRIVILEGED` / `RISK` 이면 1줄 재강조.

---

## 배치 모드

1. `*.md` glob 수집.
2. 각 파일 **병렬 호출** (10개 단위 배치).
3. 집계 표:

```
| Agent | Role | Tools | Verdict |
|-------|------|-------|---------|
```

4. 끝에 "OVERPRIVILEGED N / RISK M / COMPLIANT K / 전체 T" 요약.

---

## 임계값 override

- `READ_ONLY_KEYWORDS` (기본: `auditor|analyzer|reviewer|reader|inspector|scanner|감사|검토|분석`)
- `ORCHESTRATOR_KEYWORDS` (기본: `orchestrator|coordinator|router|조율|라우터|오케스트레이터`)
- `WRITE_TOOLS` (기본: `Write|Edit|NotebookEdit`)
- `DELEGATE_TOOLS` (기본: `Task|SendMessage`)

---

## 자가 검증

```
<플러그인 루트>/.claude/skills/agent-tools-contract/samples/
├── read-only-good/sample.md     # reviewer + Read/Grep → COMPLIANT
├── read-only-bad/sample.md      # auditor + Write → OVERPRIVILEGED
└── bash-no-safety/sample.md     # writer + Bash, git 금지 명시 없음 → RISK
```

3/3 Verdict 일치 → PASS.

---

## 범용 적용 메모

- `harness-structure` → 뼈대 존재 → `agent-frontmatter` → 메타 완비 → **`agent-tools-contract` → 권한 적합성** 순서가 pre-flight 자연스러운 흐름.
- 역할 키워드 사전은 override로 프로젝트별 어휘 확장 가능.
