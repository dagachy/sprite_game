---
name: prose-pruner
description: SKILL.md 본문을 컨텍스트 절약 3원칙(일반 지식 / 도메인 관례 / 산문 압축)으로 진단·가지치기하는 진입점. 단일 SKILL.md 또는 디렉토리 안의 모든 SKILL.md를 prose-pruner 에이전트로 감사하고 산출물·집계 리포트를 반환한다. 사용자가 "스킬 본문 다이어트", "3원칙 진단", "prose prune" 등을 요청할 때 사용.
---

# prose-pruner

스킬 본문 3원칙 가지치기 라우터.
단일 모드 / 배치 모드 두 가지를 지원한다.

---

## 모드 결정

- 사용자가 `.md` 파일 경로를 주면 **단일 모드**.
- 디렉토리 경로를 주거나 "모든 스킬" / "전체 다이어트"를 요청하면 **배치 모드** (디렉토리 미지정 시 기본 `.claude/skills/` 사용).

둘 다 모호하면 질문 한 번으로 확인한다.

---

## 단일 모드

입력: SKILL.md 절대 경로 1개.

1. `prose-pruner` 에이전트를 1회 호출. 프롬프트에 아래 변수 전달:
   - `TARGET=<absolute path>`
   - `PRINCIPLES_PATH=<플러그인 설치 경로>/.claude/skills/prose-pruner/docs/principles.md`
   - `OUTPUT_DIR` 는 호출자가 지정하지 않으면 에이전트 기본값(`<TARGET 폴더>/audit/`) 사용.
2. 에이전트가 생성한 `diagnosis.md` 상단과 `diff-summary.md` 의 감소율을 요약 1줄로 재강조.
3. 산출물 4종의 **절대 경로**를 사용자에게 노출.

---

## 배치 모드

입력: 디렉토리 경로 (예: `.claude/skills/`, `~/.claude/skills/`).

1. `**/SKILL.md` glob으로 대상 파일 수집.
2. 각 파일마다 `prose-pruner` 에이전트를 **병렬 호출** (단일 메시지에 다수 Agent 툴 호출). 파일이 많을 경우 5개 단위로 배치 처리 (산출물 쓰기 I/O 고려).
3. 결과를 집계 표로 출력:

```
| Skill | Lines(before→after) | Δ% | P1 | P2 | P3 | FP | Note |
|-------|---------------------|---:|---:|---:|---:|---:|------|
| ...   | 320 → 210           | 34 |  2 |  1 |  3 |  0 |      |
```

4. 표 끝에 "감소 기준 달성 N건 / 전체 M건" 요약을 1줄로 덧붙인다.

---

## 임계값 override

호출자는 아래 환경변수로 임계값을 조정할 수 있다. 에이전트 프롬프트에 그대로 전달한다.

- `MIN_REDUCTION_PCT` (기본 30) — sample-after 최소 감소율
- `PRINCIPLES_PATH` — 3원칙 정의 파일 교체(팀 전용 원칙으로 override 가능)
- `OUTPUT_DIR` — 산출물 저장 디렉토리

---

## 자가 검증

다음 디렉토리에 샘플 2건이 있으면 배치 모드로 돌려 결과가 각 샘플 의도대로 나오는지 확인한다.

```
<플러그인 루트>/.claude/skills/prose-pruner/samples/
├── violations/SKILL.md   # P1/P2/P3 각 1건 (명시 anchor 포함)
└── clean/SKILL.md        # 위반 0건 (가지치기 거의 없음)
```

- `violations/`: 진단 P1/P2/P3 각 1건 이상 + false positive 0 + sample-after 감소율 ≥ 30%.
- `clean/`: 진단 0건 + sample-after 감소율 ≤ 5%.

2/2 PASS면 OK. 어긋나면 anchor 주석·원칙 정의·에이전트 프롬프트를 재검토.

---

## 범용 적용 메모

이 스킬은 "condition" 플러그인 번들의 1개 스킬이다. `separation-signals`(분리 신호)와는 **상보적**이다.

- `separation-signals`: 스킬을 **쪼갤지 말지** 판단 (regex 신호)
- `prose-pruner`: 스킬 본문을 **다듬기** (LLM 3원칙)

전형적 흐름은 "separation-signals로 분리 후 → 쪼개진 각 스킬에 prose-pruner로 다이어트".
