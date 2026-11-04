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
  - **왜:** 파일 한 개는 라벨 한 건이지만, 디렉토리는 전체 스킬의 심각도 분포를 봐야 교정 물량을 가늠할 수 있다.
- 디렉토리 경로 또는 "모든 스킬" → **배치 모드** (`**/SKILL.md` glob).

---

## 단일 모드

1. `antipattern-detector-auditor` 1회 호출, `TARGET=<path>`.
2. 리포트 그대로 노출.
3. ANTIPATTERN이면 심각도 요약 1줄 재강조.
   - **왜:** 안티패턴 여부만으로는 어디부터 고칠지 알 수 없으므로, 심각도를 함께 보여 교정 우선순위를 정하게 한다.

---

## 배치 모드

1. `**/SKILL.md` glob 수집.
2. 각 파일 **병렬 호출** (10개 단위 배치).
   - **왜:** 스킬 수만큼 감사 호출이 생기므로 10개씩 끊어 부하를 제한한다.
3. 집계 표:

```
| Skill | Giant | NoRef | NoWhy | Severity | Verdict |
|-------|:-----:|:-----:|:-----:|:--------:|---------|
```

4. 끝에 "High N / Medium M / Low K / Clean T / 전체 X" 요약.
   - **왜:** 심각도 분포를 보면 고칠 물량과 순서를 한 번에 가늠할 수 있다.

---

## 안티패턴 3종

| # | 이름 | 신호 | 심각도 |
|---|------|------|:------:|
| 1 | giant-skill | lines ≥ SIZE_THRESHOLD | **High** |
| 2 | no-references | 같은 디렉토리에 `references/` or `docs/` 부재 | **Medium** |
| 3 | no-why | 본문에 "왜/because/why/때문" 서술 < WHY_MIN | **Low** |

**왜:** giant-skill이 High인 이유는 본문 한 덩어리가 매 호출마다 컨텍스트를 크게 차지해 토큰 낭비가 가장 크기 때문이다. no-references는 참조로 빼야 할 내용이 본문에 남았을 가능성을 알리므로 Medium, no-why는 동작에 지장이 없어 Low로 둔다.

---

## 임계값 override

- `SIZE_THRESHOLD` (기본 `500`)
  - **왜:** 500줄은 이 스킬의 기본 기준선이며, 프로젝트의 스킬 크기 분포에 맞춰 override한다.
- `WHY_MIN` (기본 `1`)
  - **왜:** 근거 서술이 한 번이라도 있는지만 보는 낮은 문턱이다. 근거의 질은 이 스킬이 판단하지 않는다.
- `REF_DIR_NAMES` (기본 `references|docs`): 조건부 참조 디렉토리 이름.
  - **왜:** 프로젝트마다 참조 폴더 이름이 달라도 같은 역할로 인정해 no-references 오탐을 막는다.

---

## 자가 검증

```
<플러그인 루트>/.claude/skills/antipattern-detector/samples/
├── clean/SKILL.md + docs/x.md    # CLEAN
├── giant-skill/SKILL.md          # ANTIPATTERN High
└── no-why/SKILL.md + docs/x.md   # ANTIPATTERN Low
```

3/3 Verdict + Severity 일치 → PASS.

**왜:** 세 샘플이 CLEAN / High / Low를 모두 맞혀야 심각도 라벨을 믿고 교정 순서를 정할 수 있다.

---

## 범용 적용 메모

- 책 ex-05-12는 안티패턴 "라벨링" 이 핵심 — 신호 발현 → 심각도 → 교정 우선순위.
  - **왜:** 신호만 보고 고치면 순서가 없으므로, 라벨을 거쳐야 무엇을 먼저 고칠지 정해진다.
- `separation-signals` 와 giant-skill 신호가 겹치지만, 책임이 다름:
  - **왜:** 두 스킬이 같은 신호를 보지만 질문이 달라(분리 여부 / 심각도), 책임을 나눠야 같은 결함을 두 번 세지 않는다.
  - separation-signals: **왜 분리해야 하는가** (크기/도메인/조건부 세 가지 중 뭐가 신호인가)
  - antipattern-detector: **얼마나 심각한가** (High/Medium/Low 라벨)
- 함께 돌리면 pre-flight 의사결정 완성.
