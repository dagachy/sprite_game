---
name: agent-frontmatter
description: 에이전트 정의 파일의 frontmatter 완비성(필수 4필드 + 본문 프롬프트) 진단 진입점. 단일 agent .md 또는 디렉토리를 agent-frontmatter-auditor 에이전트로 감사하고 집계 리포트를 반환한다. 사용자가 "에이전트 frontmatter 점검", "agent frontmatter audit", "에이전트 메타 검증" 등을 요청할 때 사용.
---

# agent-frontmatter

에이전트 정의 frontmatter 완비성 진단 라우터.
단일 모드 / 배치 모드 두 가지를 지원한다.

---

## 모드 결정

- 사용자가 `.md` 파일 경로를 주면 **단일 모드**.
- 디렉토리 경로를 주거나 "모든 에이전트"/"전체 감사"를 요청하면 **배치 모드** (기본 `.claude/agents/`).
  - **왜:** 파일 하나의 요청에 집계 절차를 붙이지 않고, 디렉토리 단위 요청에만 배치 집계를 돌려 비용을 아낀다.

---

## 단일 모드

입력: agent `.md` 절대 경로 1개.

1. `agent-frontmatter-auditor` 에이전트 1회 호출. 프롬프트에 `TARGET=<absolute path>`.
2. 리포트 그대로 노출.
3. Verdict가 `BROKEN` 이면 "로드 실패 위험" 1줄로 재강조.
   - **왜:** BROKEN은 에이전트가 로드되지 않을 수 있는 상태라, 긴 리포트 끝에서 한 번 더 짚어 놓치지 않게 한다.

---

## 배치 모드

입력: 디렉토리 경로.

1. `*.md` glob으로 대상 파일 수집 (하위 디렉토리 포함 안 함, maxdepth=1).
   - **왜:** 에이전트 정의는 `.claude/agents/` 직속에 두는 구조라, 하위 폴더를 훑으면 에이전트가 아닌 .md가 감사 대상에 섞인다.
2. 각 파일마다 `agent-frontmatter-auditor` 를 **병렬 호출**. 10개 단위 배치.
   - **왜:** 파일마다 감사 에이전트를 띄우므로 10개씩 끊어 동시에 떠 있는 에이전트 수를 제한한다.
3. 집계 표:

```
| Agent | Required | Recommended | Body | Verdict |
|-------|:--------:|:-----------:|:----:|---------|
```

4. 끝에 "BROKEN N건 / INCOMPLETE M건 / 전체 K건" 요약.
   - **왜:** 표는 어느 항목이 빠졌는지, 요약 한 줄은 전체 상태를 보여 주어 두 질문에 각각 답하게 한다.

---

## 임계값 override

- `REQUIRED_FIELDS` (기본 `name,description,model,tools`): 쉼표 구분 필수 필드 목록.
  - **왜:** 이 4개가 빠지면 BROKEN(로드 실패 위험)으로 판정되므로 필수로 묶는다.
- `RECOMMENDED_FIELDS` (기본 `color`): 권장 필드. 누락 시 INCOMPLETE 사유에만 포함, BROKEN은 아님.
  - **왜:** color는 로드에 영향이 없으므로 장애(BROKEN)와 개선 제안(INCOMPLETE)을 구분해 다룬다.
- `MIN_BODY_LINES` (기본 `3`): frontmatter 뒤 본문 최소 라인 수. 그 미만이면 "본문 부재"로 판정.
  - **왜:** frontmatter만 있고 프롬프트가 비어 있는 에이전트(`no-body` 샘플)를 잡는 하한이다. 3은 이 스킬의 기본 휴리스틱이므로, 본문이 원래 짧은 프로젝트는 override로 낮춘다.

---

## 자가 검증

```
<플러그인 루트>/.claude/skills/agent-frontmatter/samples/
├── complete/sample-agent.md       # 필수 4 + 권장 + 본문 → COMPLETE
├── missing-tools/sample-agent.md  # tools 누락 → BROKEN
└── no-body/sample-agent.md        # frontmatter만, 본문 없음 → BROKEN
```

3/3 Verdict 일치 → PASS.

**왜:** 감사 기준이 샘플에서 의도대로 COMPLETE / BROKEN을 가르는지 먼저 확인해야, 실제 프로젝트 점검 결과를 믿을 수 있다.

---

## 범용 적용 메모

이 스킬은 `harness-structure` 가 뼈대를 확인한 뒤 각 agent 품질을 보장한다.
반대로 `agent-tools-contract` 는 `tools:` 필드의 **역할 적합성**을 본다 (권한 과소/과잉).
세 스킬 역할 분리:
- harness-structure: 뼈대 존재 여부
- agent-frontmatter: 메타 필드 완비성
- agent-tools-contract: 권한 적합성

**왜:** 세 스킬이 같은 파일을 읽어도 질문이 다르다(뼈대 / 메타 / 권한). 나눠 두어야 실패가 어느 단계에서 났는지 분명해진다.
