---
name: menu-pattern
description: 메뉴판 라우터 적합성(라우터 크기·조건부 링크·본문 금지·references cross-ref 금지) 진단 진입점. 단일 라우터 SKILL.md 또는 디렉토리 안의 모든 SKILL.md를 menu-pattern-auditor 에이전트로 감사하고 집계 리포트를 반환한다. 사용자가 "메뉴판 원칙 점검", "라우터 적합성 감사", "menu pattern audit" 등을 요청할 때 사용.
---

# menu-pattern

메뉴판 라우터 적합성 진단 라우터.
단일 모드 / 배치 모드 두 가지를 지원한다.

---

## 모드 결정

- 사용자가 `.md` 파일 경로를 주면 **단일 모드**.
- 디렉토리 경로를 주거나 "모든 라우터" / "전체 감사"를 요청하면 **배치 모드** (디렉토리 미지정 시 기본 `.claude/skills/` 사용).

둘 다 모호하면 질문 한 번으로 확인한다.

**왜:** 단일 감사와 배치 감사는 호출되는 에이전트 수가 크게 달라, 잘못 고르면 불필요한 비용이 대량으로 나간다.

---

## 단일 모드

입력: 라우터 SKILL.md 절대 경로 1개.

1. `menu-pattern-auditor` 에이전트를 1회 호출. 프롬프트에 아래 변수 전달:
   - `ROUTER=<absolute path>`
   - `REFS_DIR=<ROUTER 폴더>/references/` (호출자가 override하지 않으면 기본값).

**왜:** references는 라우터 바로 옆 폴더에 있어야 R4(references 간 cross-ref 금지) 검사가 실제 대상을 찾아 판정할 수 있다.
2. 에이전트가 반환한 리포트를 그대로 사용자에게 노출.
3. Verdict가 `PATTERN BROKEN` 이면 Hints 라인을 요약 1줄로 재강조.

**왜:** BROKEN 판정은 라우터의 맥락 비용을 줄이려는 목표에 직결되므로, 수정 힌트가 리포트 깊숙이 묻히지 않게 먼저 보여 준다.

---

## 배치 모드

입력: 디렉토리 경로 (예: `.claude/skills/`, `~/.claude/skills/`).

1. `**/SKILL.md` glob으로 대상 파일 수집.
2. 각 파일마다 `menu-pattern-auditor` 에이전트를 **병렬 호출** (단일 메시지에 다수 Agent 툴 호출). 파일이 많을 경우 10개 단위로 배치 처리.

**왜:** 10개 단위로 끊으면 동시에 떠 있는 감사 에이전트 수가 제한되어, 많은 스킬을 한꺼번에 돌릴 때 컨텍스트와 비용이 한꺼번에 튀지 않는다.
3. 결과를 집계 표로 출력:

```
| Skill | Lines | R1 | R2 | R3 | R4 | Verdict        |
|-------|------:|:--:|:--:|:--:|:--:|----------------|
| ...   |   N   | p/f| p/f| p/f| p/f| COMPLIANT|...  |
```

4. 표 끝에 "COMPLIANT N건 / BROKEN M건 / 전체 K건" 요약을 1줄로 덧붙인다.

**왜:** 전체 중 몇 건이 깨졌는지 한 줄로 보여야, 어느 라우터부터 손볼지 우선순위를 바로 정할 수 있다.

---

## 임계값 override

호출자는 아래 환경변수로 임계값을 조정할 수 있다. 에이전트 프롬프트에 그대로 전달한다.

- `MENU_MAX_LINES` (기본 30)
- `MENU_MIN_LINKS` (기본 2)
- `REFS_DIR` — references 폴더 경로 override

**왜:** MENU_MAX_LINES는 라우터가 매번 맥락에 올라가는 비용을 묶어 두기 위한 상한이고, MENU_MIN_LINKS는 링크가 하나뿐이면 분기가 아닌 단순 포인터라 메뉴판으로 볼 근거가 없기 때문이다. REFS_DIR override는 기본 위치와 다른 구조를 감사할 때만 쓴다.

---

## 적용 범위 주의

이 스킬은 **"라우터 성격의 SKILL.md"에만 의미가 있다**. 모든 SKILL.md가 라우터여야 하는 건 아니다.

- 적용 대상: 조건부로 다른 자원을 로드하는 분기형 스킬 (책의 메뉴판 패턴)
- 적용 제외: 자체 완결 스킬 (단일 책임, 분기 없음)

**왜:** 자체 완결 스킬에 메뉴판 패턴을 씌우면 분기가 없어 링크를 억지로 늘리게 되므로, 적용 대상을 분기형 스킬로 한정한다.

배치 모드에서는 모든 SKILL.md를 감사하지만, 라우터가 아닌 스킬은 R2(링크 수 미달)로 fail이 뜰 수 있다. **라우터로 설계한 스킬만** 결과를 신뢰한다.

**왜:** 분기가 없는 스킬은 R2에서 필연적으로 fail하므로, 이를 위반으로 읽으면 멀쩡한 스킬을 잘못 고치게 된다.

---

## 자가 검증

다음 디렉토리에 샘플 2건이 있으면 배치 모드로 돌려 결과가 각 샘플 의도대로 나오는지 확인한다.

```
<플러그인 루트>/.claude/skills/menu-pattern/samples/
├── compliant/SKILL.md + references/*  # R1~R4 모두 pass
└── violations/SKILL.md + references/* # R1·R3·R4 fail (R2는 pass)
```

- `compliant/`: Verdict = COMPLIANT.
- `violations/`: Verdict = PATTERN BROKEN, R1·R3·R4 모두 fail.

2/2 일치하면 PASS. 어긋나면 패턴·임계값을 조정.

**왜:** 감사 기준이 실제 위반은 잡고 정상 스킬은 통과시키는지 샘플로 먼저 확인해야, 이후 실제 스킬의 판정을 믿을 수 있다.

---

## 범용 적용 메모

이 스킬은 "condition" 플러그인 번들의 1개 스킬이다. 다른 진단 스킬과의 관계:

- `separation-signals`: 스킬을 **쪼갤지 말지** (regex)
- `prose-pruner`: 스킬 본문을 **다듬기** (LLM 3원칙)
- `menu-pattern`: 라우터가 **메뉴판으로 올바른지** (regex)

전형적 흐름은 "separation-signals로 분리 후 → menu-pattern 으로 라우터 적합성 확인 → prose-pruner로 각 references 다이어트".

**왜:** 분리가 파일 구조를 바꾸므로, 라우터 검사나 다이어트를 분리 전에 하면 그 결과를 다시 해야 한다. 이 순서를 지켜야 각 단계가 한 번씩만 돈다.
