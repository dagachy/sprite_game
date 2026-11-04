---
name: separation-signals
description: 스킬 분리 신호(크기 / 도메인 분기 / 조건부 상세) 진단 진입점. 단일 SKILL.md 또는 디렉토리 안의 모든 SKILL.md를 skill-size-auditor 에이전트로 감사하고 집계 리포트를 반환한다. 사용자가 "분리 신호 점검", "스킬 분리 진단", "separation signals audit" 등을 요청할 때 사용.
---

# separation-signals

스킬 분리 신호 진단 라우터.
단일 모드 / 배치 모드 두 가지를 지원한다.

---

## 모드 결정

- 사용자가 `.md` 파일 경로를 주면 **단일 모드**.
- 디렉토리 경로를 주거나 "모든 스킬" / "전체 감사"를 요청하면 **배치 모드** (디렉토리 미지정 시 기본 `.claude/skills/` 사용).

둘 다 모호하면 질문 한 번으로 확인한다.

---

## 단일 모드

입력: SKILL.md 절대 경로 1개.

1. `skill-size-auditor` 에이전트를 1회 호출. 프롬프트에 `TARGET=<absolute path>` 를 전달.
2. 에이전트가 반환한 리포트를 그대로 사용자에게 노출.
3. 발현 신호가 있으면 Recommendation 라인을 먼저 요약 1줄로 재강조한다.

---

## 배치 모드

입력: 디렉토리 경로 (예: `.claude/skills/`, `~/.claude/skills/`).

1. `**/SKILL.md` glob으로 대상 파일 수집.
2. 각 파일마다 `skill-size-auditor` 에이전트를 **병렬 호출** (단일 메시지에 다수 Agent 툴 호출). 파일이 많을 경우 10개 단위로 배치 처리.
3. 결과를 집계 표로 출력:

```
| Skill | Lines | size | domain | conditional | Recommendation |
|-------|------:|:----:|:------:|:-----------:|----------------|
| ...   |   N   | y/n  |  y/n   |     y/n     | ...            |
```

4. 표 끝에 "분리 권고 N건 / 전체 M건" 요약을 1줄로 덧붙인다.

---

## 임계값 override

호출자는 아래 환경변수로 임계값을 조정할 수 있다. 에이전트 프롬프트에 그대로 전달한다.

- `SIZE_THRESHOLD` (기본 500)
- `DOMAIN_MATCH_MIN` (기본 2)
- `CONDITIONAL_MATCH_MIN` (기본 1)

---

## 자가 검증

다음 디렉토리에 샘플 3건이 있으면 배치 모드로 돌려 결과가 각각 의도한 신호만 발현하는지 확인한다.

```
<플러그인 루트>/.claude/skills/separation-signals/samples/
├── size/SKILL.md          # 크기만 yes
├── domain/SKILL.md        # 도메인만 yes
└── conditional/SKILL.md   # 조건부만 yes
```

3/3 일치하면 PASS. 어긋나면 패턴·임계값을 조정.

---

## 범용 적용 메모

이 스킬은 "condition" 플러그인 번들의 1개 스킬이다. 다른 감사 스킬(`harness-health`, `memory-staleness` 등)이 추가되더라도 각자 독립 폴더로 들어오며, 이 스킬은 **분리 신호 진단 하나**에만 책임을 진다.
