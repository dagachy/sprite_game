---
name: antipattern-detector
description: SKILL.md 안티패턴 3종(거대 SKILL / references 부재 / 근거 누락) 진단·심각도 라벨링 진입점. 단일 SKILL.md 또는 디렉토리를 antipattern-detector-auditor 에이전트로 감사하고 집계 리포트를 반환한다. 사용자가 "안티패턴 점검", "antipattern audit", "스킬 품질 라벨" 등을 요청할 때 사용.
---

# antipattern-detector

SKILL.md 안티패턴 라벨링 라우터.
단일 모드 / 배치 모드 두 가지를 지원한다.

---

## 모드 결정

- `.md` 파일 경로 → **단일 모드**.
- 디렉토리 경로 또는 "모든 스킬" → **배치 모드** (`**/SKILL.md` glob).

---

## 단일 모드

1. `antipattern-detector-auditor` 1회 호출, `TARGET=<path>`.
2. 리포트 그대로 노출.
3. ANTIPATTERN이면 심각도 요약 1줄 재강조.

---

## 배치 모드

1. `**/SKILL.md` glob 수집.
2. 각 파일 **병렬 호출** (10개 단위 배치).
3. 집계 표:

```
| Skill | Giant | NoRef | NoWhy | Severity | Verdict |
|-------|:-----:|:-----:|:-----:|:--------:|---------|
```

4. 끝에 "High N / Medium M / Low K / Clean T / 전체 X" 요약.

---

## 안티패턴 3종

| # | 이름 | 신호 | 심각도 |
|---|------|------|:------:|
| 1 | giant-skill | lines ≥ SIZE_THRESHOLD | **High** |
| 2 | no-references | 같은 디렉토리에 `references/` or `docs/` 부재 | **Medium** |
| 3 | no-why | 본문에 "왜/because/why/때문" 서술 < WHY_MIN | **Low** |

---

## 임계값 override

- `SIZE_THRESHOLD` (기본 `500`)
- `WHY_MIN` (기본 `1`)
- `REF_DIR_NAMES` (기본 `references|docs`): 조건부 참조 디렉토리 이름.

---

## 자가 검증

```
<플러그인 루트>/.claude/skills/antipattern-detector/samples/
├── clean/SKILL.md + docs/x.md    # CLEAN
├── giant-skill/SKILL.md          # ANTIPATTERN High
└── no-why/SKILL.md + docs/x.md   # ANTIPATTERN Low
```

3/3 Verdict + Severity 일치 → PASS.

---

## 범용 적용 메모

- 책 ex-05-12는 안티패턴 "라벨링" 이 핵심 — 신호 발현 → 심각도 → 교정 우선순위.
- `separation-signals` 와 giant-skill 신호가 겹치지만, 책임이 다름:
  - separation-signals: **왜 분리해야 하는가** (크기/도메인/조건부 세 가지 중 뭐가 신호인가)
  - antipattern-detector: **얼마나 심각한가** (High/Medium/Low 라벨)
- 함께 돌리면 pre-flight 의사결정 완성.
